// tma_mc_probe.cu
// Three-way TMA-multicast L2-datapath probe for GH200 (sm_90a).
// src mode: 0 = local HBM, 1 = peer GPU (foreign window), 2 = C2C (Grace, coherent)
//
// Build: nvcc -arch=sm_90a -O3 -lcuda tma_mc_probe.cu -o tma_mc_probe
// Run:   ./tma_mc_probe <mode> [peer_gpu_id]
//
// WARNING: mode 1 is EXPECTED TO HANG the kernel (mbarrier deadlock). Run on a
// non-critical GPU; have `nvidia-smi --gpu-reset` ready.

#include <cuda.h>
#include <cuda_runtime.h>
#include <cooperative_groups.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#ifdef USE_BF16
#include <cuda_bf16.h>
#endif

#define CU_CHECK(x) do { CUresult r = (x); if (r != CUDA_SUCCESS) { \
  const char* s; cuGetErrorString(r, &s); \
  fprintf(stderr, "CU error %d (%s) at %s:%d\n", r, s, __FILE__, __LINE__); exit(1);} } while(0)
#define RT_CHECK(x) do { cudaError_t e = (x); if (e != cudaSuccess) { \
  fprintf(stderr, "RT error %s at %s:%d\n", cudaGetErrorString(e), __FILE__, __LINE__); exit(1);} } while(0)

// ---- Cluster size (compile-time; sweep via -DCLUSTER=N) ----
#ifndef CLUSTER
#define CLUSTER 2
#endif

// ---- Tile geometry (configurable: -DTILE_M=.. -DTILE_N=..) ----
#ifndef TILE_M
#define TILE_M 128   // rows
#endif
#ifndef TILE_N
#define TILE_N 64    // cols
#endif
#ifdef USE_BF16
using elem_t = __nv_bfloat16;    // -DUSE_BF16 selects bf16
#else
using elem_t = float;            // default fp32
#endif
static const size_t TILE_BYTES = (size_t)TILE_M * TILE_N * sizeof(elem_t);

// ---- Device kernel: CTA0 issues a multicast TMA load into all cluster CTAs' SMEM ----
extern "C" __global__ void __cluster_dims__(CLUSTER,1,1)
tma_mc_kernel(const __grid_constant__ CUtensorMap tmap, int* done_flag, int* out_val)
{
    namespace cg = cooperative_groups;
    extern __shared__ __align__(128) elem_t smem_tile[]; // TILE_BYTES
    __shared__ __align__(8) uint64_t mbar;

    unsigned ctarank;
    asm volatile("mov.u32 %0, %%cluster_ctarank;" : "=r"(ctarank));

    // init mbarrier (1 arrival = the TMA tx completion path)
    if (threadIdx.x == 0) {
        asm volatile("mbarrier.init.shared::cta.b64 [%0], 1;" :: "r"((unsigned)__cvta_generic_to_shared(&mbar)));
#ifdef BROKEN_BARRIER
        // BROKEN (a very common mistake): only the ISSUING CTA arms expect_tx; the
        // consumer CTAs init their mbarrier but never expect_tx -> their mbarrier
        // accounting can never close -> they spin on try_wait forever (hang).
        if (ctarank == 0)
#endif
        // Each destination CTA arms its own mbarrier with the bytes it will receive.
        asm volatile("mbarrier.arrive.expect_tx.shared::cta.b64 _, [%0], %1;"
                     :: "r"((unsigned)__cvta_generic_to_shared(&mbar)),
                        "r"((unsigned)TILE_BYTES));
    }
    __syncthreads();
    // make mbarrier visible cluster-wide before multicast targets it
    asm volatile("fence.proxy.async.shared::cluster;");
    cg::cluster_group cluster = cg::this_cluster();
    cluster.sync();

#ifdef NO_MULTICAST
    // CONTROL: every CTA issues its OWN (non-multicast) TMA load of the same tile.
    // => N CTAs cause N independent L2 reads of the tile (fan-out does NOT happen).
    if (threadIdx.x == 0) {
        asm volatile(
          "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes"
          " [%0], [%1, {%2, %3}], [%4];"
          :
          : "r"((unsigned)__cvta_generic_to_shared(smem_tile)),
            "l"(&tmap),
            "r"(0), "r"(0),
            "r"((unsigned)__cvta_generic_to_shared(&mbar))
          : "memory");
    }
#else
    // MULTICAST: only CTA0 issues; mask covers all CTAs in the cluster.
    // => ONE L2 read of the tile, fanned out into all CTAs' SMEM.
    if (ctarank == 0 && threadIdx.x == 0) {
        uint16_t ctamask = (uint16_t)((1u << CLUSTER) - 1u);
        asm volatile(
          "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.multicast::cluster"
          " [%0], [%1, {%2, %3}], [%4], %5;"
          :
          : "r"((unsigned)__cvta_generic_to_shared(smem_tile)),
            "l"(&tmap),
            "r"(0), "r"(0),
            "r"((unsigned)__cvta_generic_to_shared(&mbar)),
            "h"(ctamask)
          : "memory");
    }
#endif

    // Each CTA waits on its own mbarrier phase 0.
    // *** mode=1 (peer/foreign window) is expected to spin here forever ***
    if (threadIdx.x == 0) {
        unsigned phase = 0;
        unsigned ok = 0;
        // bounded spin (real deadlock never returns 1; bounded so we don't hang the GPU)
        for (int i = 0; i < (1<<28); ++i) {
            asm volatile(
              "{ .reg .pred p; mbarrier.try_wait.parity.shared::cta.b64 p, [%1], %2; selp.u32 %0, 1, 0, p; }"
              : "=r"(ok)
              : "r"((unsigned)__cvta_generic_to_shared(&mbar)), "r"(phase)
              : "memory");
            if (ok) break;
        }
        // EACH CTA's leader reports ITS OWN result, so we can detect whether the
        // multicast fan-out actually completed on the NON-issuing CTAs too.
        // (folklore: the consumer CTA's mbarrier may never flip when source is peer)
        if (ok) {
            out_val[ctarank] = ((const int*)smem_tile)[0];
            atomicAdd(done_flag, 1);             // count CTAs whose mbarrier flipped
        } else {
            out_val[ctarank] = (int)0xDEADBEEF;  // this CTA spun out -> NEVER completed
        }
    }
}

// ---- Host: build CUtensorMap over the chosen source buffer ----
static void build_tensormap(CUtensorMap* tmap, void* src, size_t pitch_bytes)
{
    uint64_t dims[2]    = { (uint64_t)TILE_N, (uint64_t)TILE_M };
    uint64_t strides[1] = { (uint64_t)pitch_bytes };
    uint32_t box[2]     = { (uint32_t)TILE_N, (uint32_t)TILE_M };
    uint32_t elem_str[2]= { 1, 1 };

#ifdef USE_BF16
    CUtensorMapDataType dt = CU_TENSOR_MAP_DATA_TYPE_BFLOAT16;
#else
    CUtensorMapDataType dt = CU_TENSOR_MAP_DATA_TYPE_FLOAT32;
#endif

    CU_CHECK(cuTensorMapEncodeTiled(
        tmap, dt, /*rank=*/2, src, dims, strides, box, elem_str,
        CU_TENSOR_MAP_INTERLEAVE_NONE,
        CU_TENSOR_MAP_SWIZZLE_NONE,
        CU_TENSOR_MAP_L2_PROMOTION_NONE,
        CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE));
}

int main(int argc, char** argv)
{
    int mode = (argc > 1) ? atoi(argv[1]) : 0;
    int peer = (argc > 2) ? atoi(argv[2]) : 1;

    CU_CHECK(cuInit(0));
    RT_CHECK(cudaSetDevice(0));

    const size_t pitch = (size_t)TILE_N * sizeof(elem_t);
    const size_t bytes = (size_t)TILE_M * pitch;

    void* src = nullptr;

    if (mode == 0) {
        RT_CHECK(cudaMalloc(&src, bytes));
        RT_CHECK(cudaMemset(src, 1, bytes));
        printf("[mode 0] src = LOCAL HBM (%p)  CLUSTER=%d\n", src, CLUSTER);

    } else if (mode == 1) {
        int ndev = 0; RT_CHECK(cudaGetDeviceCount(&ndev));
        if (ndev < 2) {
            fprintf(stderr, "[mode 1] need >=2 GPUs for true peer foreign window; "
                            "see degraded options in the .md (MIG / BAR).\n");
            return 2;
        }
        int canAccess = 0;
        RT_CHECK(cudaDeviceCanAccessPeer(&canAccess, 0, peer));
        if (!canAccess) { fprintf(stderr, "[mode 1] GPU0 cannot peer-access GPU%d\n", peer); return 2; }
        RT_CHECK(cudaDeviceEnablePeerAccess(peer, 0));
        RT_CHECK(cudaSetDevice(peer));
        RT_CHECK(cudaMalloc(&src, bytes));
        RT_CHECK(cudaMemset(src, 1, bytes));
        RT_CHECK(cudaSetDevice(0));
        printf("[mode 1] src = PEER GPU%d foreign window (%p)  *** EXPECT HANG ***\n", peer, src);

    } else if (mode == 2) {
        // (c) C2C-backed Grace memory: managed, prefetched to CPU NUMA node.
        // NOTE: default managed memory may FAULT-MIGRATE the page back to HBM on GPU
        // access, so this can end up reading from device memory, not C2C. Use mode 3
        // to force a genuine no-migration remote C2C read.
        RT_CHECK(cudaMallocManaged(&src, bytes));
        RT_CHECK(cudaMemset(src, 1, bytes));
        int cpu_node = cudaCpuDeviceId; // place pages on the Grace CPU -> read traverses C2C into local L2
        RT_CHECK(cudaMemPrefetchAsync(src, bytes, cpu_node, 0));
        RT_CHECK(cudaDeviceSynchronize());
        printf("[mode 2] src = C2C (Grace, managed@CPU, may-migrate) (%p)  CLUSTER=%d\n", src, CLUSTER);

    } else if (mode == 3) {
        // (c') C2C-backed Grace memory, FORCED no-migration:
        //   preferred location = CPU (Grace LPDDR), accessed-by GPU0.
        // => GPU reads traverse C2C into the LOCAL L2 each time; pages STAY on Grace
        //    (no fault-migration to HBM). This is the genuine DAK remote-read path.
        RT_CHECK(cudaMallocManaged(&src, bytes));
        RT_CHECK(cudaMemset(src, 1, bytes));
        RT_CHECK(cudaMemAdvise(src, bytes, cudaMemAdviseSetPreferredLocation, cudaCpuDeviceId));
        RT_CHECK(cudaMemAdvise(src, bytes, cudaMemAdviseSetAccessedBy, 0));
        RT_CHECK(cudaMemPrefetchAsync(src, bytes, cudaCpuDeviceId, 0));
        RT_CHECK(cudaDeviceSynchronize());
        printf("[mode 3] src = C2C (Grace, pinned-CPU no-migrate) (%p)  CLUSTER=%d\n", src, CLUSTER);

    } else { // mode == 4: host-pinned MAPPED memory
        // On a discrete x86 + PCIe box this device pointer is a PCIe FOREIGN WINDOW
        // (non-coherent, bypasses the local L2) and TMA multicast would HANG.
        // On GH200, host memory is mapped through the COHERENT C2C path, so it
        // should land in the local L2 -> multicast completes (DONE). This is the
        // single-GPU stand-in for the "mode 1" foreign-window question.
        void* hptr = nullptr;
        RT_CHECK(cudaHostAlloc(&hptr, bytes, cudaHostAllocMapped));
        memset(hptr, 1, bytes);
        RT_CHECK(cudaHostGetDevicePointer(&src, hptr, 0));
        printf("[mode 4] src = host-pinned MAPPED (dev ptr %p)  CLUSTER=%d\n", src, CLUSTER);
    }

    CUtensorMap tmap;
    build_tensormap(&tmap, src, pitch);

    int* d_done = nullptr; RT_CHECK(cudaMalloc(&d_done, sizeof(int)));
    RT_CHECK(cudaMemset(d_done, 0, sizeof(int)));
    int* d_val = nullptr; RT_CHECK(cudaMalloc(&d_val, CLUSTER * sizeof(int)));
    RT_CHECK(cudaMemset(d_val, 0, CLUSTER * sizeof(int)));

    cudaLaunchConfig_t cfg = {};
    cfg.gridDim  = dim3(CLUSTER,1,1);
    cfg.blockDim = dim3(32,1,1);
    cfg.dynamicSmemBytes = TILE_BYTES;
    cudaLaunchAttribute attr[1];
    attr[0].id = cudaLaunchAttributeClusterDimension;
    attr[0].val.clusterDim.x = CLUSTER;
    attr[0].val.clusterDim.y = 1;
    attr[0].val.clusterDim.z = 1;
    cfg.attrs = attr; cfg.numAttrs = 1;

    RT_CHECK(cudaFuncSetAttribute(tma_mc_kernel,
             cudaFuncAttributeMaxDynamicSharedMemorySize, (int)TILE_BYTES));

    printf("launching...\n"); fflush(stdout);
    RT_CHECK(cudaLaunchKernelEx(&cfg, tma_mc_kernel, tmap, d_done, d_val));

    cudaError_t e = cudaDeviceSynchronize();
    if (e != cudaSuccess) {
        fprintf(stderr, "[result] sync error: %s  (mode %d)\n", cudaGetErrorString(e), mode);
        return 1;
    }
    int h_done = 0; RT_CHECK(cudaMemcpy(&h_done, d_done, sizeof(int), cudaMemcpyDeviceToHost));
    int h_val[16] = {0}; RT_CHECK(cudaMemcpy(h_val, d_val, CLUSTER * sizeof(int), cudaMemcpyDeviceToHost));
    printf("[result] mode %d: %d/%d CTAs completed%s\n", mode, h_done, CLUSTER,
           (h_done==CLUSTER) ? "  (ALL DONE)" : "  *** SOME CTA HUNG / INCOMPLETE ***");
    for (int i = 0; i < CLUSTER; i++)
        printf("    CTA %d: word=0x%08x %s\n", i, (unsigned)h_val[i],
               h_val[i]==0x01010101 ? "(correct src data)"
               : (h_val[i]==(int)0xDEADBEEF ? "(NEVER COMPLETED <-- hang)" : "(unexpected/zero)"));
    return 0;
}
