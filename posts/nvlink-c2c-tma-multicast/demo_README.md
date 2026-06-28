# TMA multicast 挂卡的真相:是 mbarrier 协议,不是 NVLink

## TL;DR

流传的说法:**"NVLink 上用 TMA multicast 访问远程内存会直接让卡挂逼。"**

现象是真的,但**根因被归错了**。挂卡的真正原因是 **mbarrier 协议写错**——cluster 内的 consumer CTA 没有 arm 自己的 `expect_tx`。这跟 NVLink / peer / 远程内存**没有关系**:

- 本 demo 的源用的是**本地 HBM**(`cudaMalloc`),错误协议照样**挂死**。
- 反过来,协议写对了,在 NVLink peer 内存上(双卡)也**稳定不挂**(另见上级目录 `H100双卡_mode1实测_重要修正.md`)。

下面这个最小 demo 用本地 HBM 就能复现挂卡,并用 cuda-gdb 抓到 consumer CTA 卡死在 `mbarrier.try_wait` 的字面现场。

实测环境:H100 SXM5 / GH200,CUDA 12.8,driver 580(任意 Hopper `sm_90a` 即可)。

---

## 就差一个 `if`:正确 vs 错误协议

TMA multicast(`cp.async.bulk.tensor...multicast::cluster`)会把同一个 tile 扇出到 cluster 内多个 CTA 的 shared memory,并把 **complete-tx 分别发往每个目标 CTA 自己的 mbarrier**(同一 offset)。所以**每个目标 CTA 都必须 init 并 arm 自己的 `expect_tx`**:

```cpp
if (threadIdx.x == 0) {
    asm("mbarrier.init.shared::cta.b64 [%0], 1;" :: ...);     // 每个 CTA 都 init

#ifdef BROKEN_BARRIER
    if (rank == 0)        // ❌ 错误:只有发起 CTA arm,consumer CTA 忘了 arm
#endif
    asm("mbarrier.arrive.expect_tx.shared::cta.b64 _, [%0], %1;" :: ...);  // ✅ 正确:每个 CTA 都 arm
}
```

错误版里,consumer CTA 的 mbarrier 收到了 multicast 的 complete-tx,但因为从没 `expect_tx`,它的事务记账永远闭合不了 → `mbarrier.try_wait` 的 phase 永不翻转 → consumer CTA 永久自旋 → 整个 kernel 挂死。

---

## 跑一下

```bash
# 正确协议
nvcc -arch=sm_90a -O3 -lcuda            tma_multicast_barrier.cu -o demo
# 错误协议(只发起 CTA arm)
nvcc -arch=sm_90a -O3 -lcuda -DBROKEN_BARRIER tma_multicast_barrier.cu -o demo_broken

./demo          # => ALL 2/2 DONE
./demo_broken   # => consumer CTA 挂(用 GPU 挂钟有界自旋,~2s 后报告,不锁卡)
```

实测输出:

```
======== CORRECT ========
  CTA 0: completed=1 word=0x01010101 (got the multicast data)
  CTA 1: completed=1 word=0x01010101 (got the multicast data)
=> ALL 2/2 DONE  [OK]

======== BROKEN ========
  CTA 0: completed=1 word=0x01010101 (got the multicast data)
  CTA 1: completed=0 word=0xdeadbeef (NEVER completed -> stuck on mbarrier.try_wait)
=> consumer CTA HUNG -> BROKEN mbarrier protocol, NOT NVLink
```

注意错误版里:**issuer CTA(0)拿到了数据并完成,只有 consumer CTA(1)挂住** —— 说明 multicast 投递本身是好的,问题纯粹在 consumer 的 barrier 记账。

---

## 用 cuda-gdb 抓"卡住"的字面现场

```bash
# 需要 cuda-gdb:  sudo apt-get install -y nvidia-cuda-gdb
bash capture_hang.sh
```

它编译一个"真挂"版本(`-DBROKEN_BARRIER -DINFINITE_WAIT`,consumer 无限等待),后台跑、attach、dump。实测:

```
[Switching focus to ... block (1,0,0), thread (0,0,0), ... sm 125 ...]
0x...570 in tma_mcast_demo<<<(2,1,1),(32,1,1)>>> () at tma_multicast_barrier.cu:112
112               : "r"((unsigned)__cvta_generic_to_shared(&mbar)), "r"(phase)

  BlockIdx ThreadIdx  ...  PC            Filename                    Line
* (1,0,0)   (0,0,0)   ...  0x...570      tma_multicast_barrier.cu     112
=> 0x...570 <tma_mcast_demo+880>: SEL R7,RZ,0x1,!P0      # try_wait -> selp 自旋
```

- **只有 consumer CTA(block (1,0,0))还活着,PC 卡在 `mbarrier.try_wait`(line 112)**。
- **issuer CTA(block (0,0,0))已经退出**(cuda-gdb 找不到它)。

这就是 folklore 里"卡住"的字面现场;但它证明的是 **mbarrier 协议 bug**,不是 NVLink。(`kill` 后 GPU 立即恢复 0 MiB,无需 reset。)

---

## 为什么 folklore 会怪到 NVLink 头上

因为 **TMA multicast 的典型使用场景就是跨卡 / 远程 offloading**(把权重、KV cache 放远端,用 multicast 扇出给多个 SM)。大家都是在"NVLink 远程内存"这个场景里**第一次写 TMA multicast**,协议没写对就挂了,于是把现象记成"NVLink + TMA multicast + 远程内存"。

而**没人会在本地 HBM 上用 multicast**(本地直接 load 就行),所以"本地其实也会挂"这件事从来没被注意到。

> **结论:folklore 抓对了现象(确实挂),抓错了归因。挂卡 ⟺ mbarrier 协议错误(consumer CTA 没 arm `expect_tx`),与源是不是 peer / 远程无关。**

补充实测(见上级目录报告):在 2×H100 NVLink 上,用**正确协议**让 TMA multicast 从 peer GPU 内存读取,稳定成功(数据正确 + `nvlrx≈41KB` 证明数据经 NVLink 拉回本地)。TMA 是主动 bulk DMA,会把远端数据搬到本地 SMEM,`complete_tx` 由数据到达驱动,不存在"无本地 L2 源就死锁"那回事。

---

## 文件

| 文件 | 说明 |
|---|---|
| `tma_multicast_barrier.cu` | 自包含 demo;`-DBROKEN_BARRIER` 切错误协议,`-DINFINITE_WAIT` 切真挂 |
| `capture_hang.sh` | 编译真挂版 + cuda-gdb attach,dump consumer CTA 的现场 |
| `README.md` | 本文件 |

依赖:Hopper GPU(`sm_90a`)、CUDA ≥ 12.3、`nvidia-cuda-gdb`(仅 `capture_hang.sh` 需要)。
