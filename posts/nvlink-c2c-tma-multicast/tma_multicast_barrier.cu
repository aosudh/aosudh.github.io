// tma_multicast_barrier.cu
// -----------------------------------------------------------------------------
// Minimal demo: why "TMA multicast hangs the GPU" is a *protocol* bug, not NVLink.
//
// A cluster of 2 CTAs. CTA0 issues ONE TMA-multicast bulk-tensor load that fans
// the same tile into BOTH CTAs' shared memory. Each CTA then waits on its OWN
// mbarrier for the copy to complete.
//
// The source buffer is plain LOCAL HBM (cudaMalloc) on purpose: if it hangs, it
// has NOTHING to do with NVLink / peer / remote memory.
//
//   CORRECT protocol (default):
//       every CTA in the cluster arms ITS OWN mbarrier with expect_tx, because
//       a multicast copy delivers complete-tx to the mbarrier (same offset) in
//       EACH destination CTA.  -> both CTAs complete.
//
//   BROKEN protocol (-DBROKEN_BARRIER):
//       only the *issuing* CTA arms expect_tx; consumer CTAs init their mbarrier
//       but forget to arm it. Their transaction accounting never closes, so
//       mbarrier.try_wait never flips -> the consumer CTA spins forever -> hang.
//
// Build (Hopper, sm_90a):
//   nvcc -arch=sm_90a -O3 -lcuda tma_multicast_barrier.cu -o demo          # correct
//   nvcc -arch=sm_90a -O3 -lcuda -DBROKEN_BARRIER tma_multicast_barrier.cu -o demo_broken
//   nvcc -arch=sm_90a -O3 -lcuda -lineinfo -DBROKEN_BARRIER -DINFINITE_WAIT \
//        tma_multicast_barrier.cu -o demo_hang   # real hang, for cuda-gdb
//
// Run:
//   ./demo            # => ALL 2/2 DONE
//   ./demo_broken     # => consumer CTA NEVER completed (bounded spin reports it)
//
// See README.md for the cuda-gdb "stuck on mbarrier.try_wait" capture.
// -----------------------------------------------------------------------------
#include <cuda.h>
#include <cuda_runtime.h>
#include <cooperative_groups.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>

#define CU_CHECK(x) do { CUresult r=(x); if(r!=CUDA_SUCCESS){ const char* s; \
  cuGetErrorString(r,&s); fprintf(stderr,"CU error %d (%s) at %s:%d\n",r,s,__FILE__,__LINE__); exit(1);} } while(0)
#define RT_CHECK(x) do { cudaError_t e=(x); if(e!=cudaSuccess){ \
  fprintf(stderr,"RT error %s at %s:%d\n",cudaGetErrorString(e),__FILE__,__LINE__); exit(1);} } while(0)

static const int    TILE_M = 128;
static const int    TILE_N = 64;
using elem_t = float;                                  // each word == 0x01010101 after memset(0x01)
static const size_t TILE_BYTES = (size_t)TILE_M * TILE_N * sizeof(elem_t);

// Bounded by GPU wall-clock so a BROKEN run REPORTS the stuck consumer instead of
// locking the GPU. Compile with -DINFINITE_WAIT to get a real permanent hang (cuda-gdb).
#ifndef WAIT_CYCLES
#define WAIT_CYCLES 3000000000LL   // ~2 s at ~1.5 GHz
#endif

extern "C" __global__ void __cluster_dims__(2,1,1)
tma_mcast_demo(const __grid_constant__ CUtensorMap tmap, int* completed /*[2]*/, int* firstword /*[2]*/)
{
    namespace cg = cooperative_groups;
    extern __shared__ __align__(128) elem_t smem[];     // TILE_BYTES
    __shared__ __align__(8) uint64_t mbar;

    unsigned rank;
    asm volatile("mov.u32 %0, %%cluster_ctarank;" : "=r"(rank));

    if (threadIdx.x == 0) {
        asm volatile("mbarrier.init.shared::cta.b64 [%0], 1;"
                     :: "r"((unsigned)__cvta_generic_to_shared(&mbar)));
#ifdef BROKEN_BARRIER
        // BUG: only the issuing CTA arms expect_tx; consumer CTAs do not.
        if (rank == 0)
#endif
        // CORRECT: each destination CTA arms its OWN mbarrier with the bytes it
        // will receive from the multicast copy.
        asm volatile("mbarrier.arrive.expect_tx.shared::cta.b64 _, [%0], %1;"
                     :: "r"((unsigned)__cvta_generic_to_shared(&mbar)),
                        "r"((unsigned)TILE_BYTES));
    }
    __syncthreads();
    asm volatile("fence.proxy.async.shared::cluster;");
    cg::this_cluster().sync();                           // all CTAs' mbarriers ready before the copy

    // CTA0 issues ONE multicast load; mask 0b11 -> fan out into CTA0 AND CTA1 SMEM.
    if (rank == 0 && threadIdx.x == 0) {
        uint16_t mask = 0b11;
        asm volatile(
          "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster"
          " [%0], [%1, {%2, %3}], [%4], %5;"
          :
          : "r"((unsigned)__cvta_generic_to_shared(smem)),
            "l"(&tmap), "r"(0), "r"(0),
            "r"((unsigned)__cvta_generic_to_shared(&mbar)),
            "h"(mask)
          : "memory");
    }

    // Each CTA waits on ITS OWN mbarrier. In BROKEN mode the consumer CTA's
    // mbarrier never flips -> it stays in this loop (line of the try_wait below).
    if (threadIdx.x == 0) {
        unsigned ok = 0, phase = 0;
#ifdef INFINITE_WAIT
        while (!ok)                              // real consumer waits forever -> true hang
#else
        long long t0 = clock64();
        while (!ok && (clock64() - t0) < (long long)WAIT_CYCLES)
#endif
        {
            asm volatile(
              "{ .reg .pred p; mbarrier.try_wait.parity.shared::cta.b64 p, [%1], %2; selp.u32 %0,1,0,p; }"
              : "=r"(ok)
              : "r"((unsigned)__cvta_generic_to_shared(&mbar)), "r"(phase)
              : "memory");
        }
        completed[rank] = ok;
        firstword[rank] = ok ? ((const int*)smem)[0] : (int)0xDEADBEEF;
    }
}

static void build_tensormap(CUtensorMap* tmap, void* src, size_t pitch_bytes)
{
    uint64_t dims[2]    = { (uint64_t)TILE_N, (uint64_t)TILE_M };
    uint64_t strides[1] = { (uint64_t)pitch_bytes };
    uint32_t box[2]     = { (uint32_t)TILE_N, (uint32_t)TILE_M };
    uint32_t estride[2] = { 1, 1 };
    CU_CHECK(cuTensorMapEncodeTiled(
        tmap, CU_TENSOR_MAP_DATA_TYPE_FLOAT32, /*rank=*/2, src, dims, strides, box, estride,
        CU_TENSOR_MAP_INTERLEAVE_NONE, CU_TENSOR_MAP_SWIZZLE_NONE,
        CU_TENSOR_MAP_L2_PROMOTION_NONE, CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
}

int main()
{
    CU_CHECK(cuInit(0));
    RT_CHECK(cudaSetDevice(0));

    const size_t pitch = (size_t)TILE_N * sizeof(elem_t);
    const size_t bytes = (size_t)TILE_M * pitch;

    void* src = nullptr;                       // source = LOCAL HBM (on purpose)
    RT_CHECK(cudaMalloc(&src, bytes));
    RT_CHECK(cudaMemset(src, 0x01, bytes));    // every float word -> 0x01010101

    CUtensorMap tmap;
    build_tensormap(&tmap, src, pitch);

    int *d_completed=nullptr, *d_word=nullptr;
    RT_CHECK(cudaMalloc(&d_completed, 2*sizeof(int)));
    RT_CHECK(cudaMalloc(&d_word,      2*sizeof(int)));
    RT_CHECK(cudaMemset(d_completed, 0, 2*sizeof(int)));
    RT_CHECK(cudaMemset(d_word,      0, 2*sizeof(int)));

    cudaLaunchConfig_t cfg = {};
    cfg.gridDim  = dim3(2,1,1);                // 2 CTAs == one cluster of 2
    cfg.blockDim = dim3(32,1,1);
    cfg.dynamicSmemBytes = TILE_BYTES;
    cudaLaunchAttribute attr[1];
    attr[0].id = cudaLaunchAttributeClusterDimension;
    attr[0].val.clusterDim.x = 2;
    attr[0].val.clusterDim.y = 1;
    attr[0].val.clusterDim.z = 1;
    cfg.attrs = attr; cfg.numAttrs = 1;
    RT_CHECK(cudaFuncSetAttribute(tma_mcast_demo,
             cudaFuncAttributeMaxDynamicSharedMemorySize, (int)TILE_BYTES));

#ifdef BROKEN_BARRIER
    const char* proto = "BROKEN  (only the issuing CTA arms expect_tx)";
#else
    const char* proto = "CORRECT (every CTA arms its own expect_tx)";
#endif
    printf("== TMA multicast mbarrier-protocol demo ==\n");
    printf("protocol : %s\n", proto);
    printf("source   : LOCAL HBM  (any hang here is NOT about NVLink/peer)\n");
    printf("launching cluster of 2 CTAs ...\n"); fflush(stdout);

    RT_CHECK(cudaLaunchKernelEx(&cfg, tma_mcast_demo, tmap, d_completed, d_word));
    cudaError_t e = cudaDeviceSynchronize();   // INFINITE_WAIT + BROKEN never returns
    if (e != cudaSuccess) { fprintf(stderr, "sync error: %s\n", cudaGetErrorString(e)); return 1; }

    int comp[2]={0,0}, word[2]={0,0};
    RT_CHECK(cudaMemcpy(comp, d_completed, 2*sizeof(int), cudaMemcpyDeviceToHost));
    RT_CHECK(cudaMemcpy(word, d_word,      2*sizeof(int), cudaMemcpyDeviceToHost));
    for (int i = 0; i < 2; i++)
        printf("  CTA %d: completed=%d word=0x%08x %s\n", i, comp[i], (unsigned)word[i],
               comp[i] ? "(got the multicast data)"
                       : "(NEVER completed -> stuck on mbarrier.try_wait)");
    int done = comp[0] + comp[1];
    printf("=> %s\n", done==2 ? "ALL 2/2 DONE  [OK]"
                              : "consumer CTA HUNG -> BROKEN mbarrier protocol, NOT NVLink");
    return done==2 ? 0 : 2;
}
