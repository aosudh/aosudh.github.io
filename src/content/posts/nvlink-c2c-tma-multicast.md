---
title: "NVLink-C2C × TMA Multicast：从一条 folklore 到真相"
published: 2026-06-29
description: "动手验证“NVLink 上用 TMA multicast 访问远程内存会挂卡”的说法：用 NCU 与 cuda-gdb 定位到真凶是 mbarrier 协议误用（未 arm expect_tx），与 NVLink 无关。"
image: "/assets/covers/nvlink-tma.svg"
category: "GPU / 算力"
tags: ["NVLink", "H100", "CUDA"]
pinned: false
draft: false
---

> [!TIP]
> 本页为 **Astro + Mizuki** 自动导入预览版；若需查看原始手写排版（含原版内联 SVG 与附件下载），可访问 [原版 HTML 正文](/legacy-posts/nvlink-c2c-tma-multicast.html)。

起点是两个互相矛盾的东西。 

一条流传很广的说法：**“NVLink 上用 TMA multicast 访问远程内存会直接让卡挂逼。”** 有不少人附和、看着像能复现。 

一篇论文：DAK（[Direct-Access-Enabled GPU Memory Offloading](https://arxiv.org/abs/2604.26074)，arXiv:2604.26074），却反其道而行——在 **NVLink-C2C** 上用 TMA + TMA multicast 把 offload 出去的权重 / KV cache 直接读进 SMEM，号称比 prefetch baseline 最高 3×。 

如果“NVLink 上 TMA multicast 访问远端会挂”，DAK 凭什么能在 NVLink-C2C 上跑？社区给的假说是： 

> TMA multicast 的扇出要从**本地 L2** 取源；NVLink peer 内存是非一致“外部窗口”，数据只 cache 在对端、绕过本地 L2，于是 multicast 找不到本地源 → mbarrier 死锁 → 挂卡。而 C2C 是一致内存、读它会落本地 L2，所以能跑。 

这篇就是把这个假说**拿到真硬件上动手验证**的全过程。剧透：假说一半对、一半错，而真凶完全是另一回事。 

## 实验环境

        

|  | GH200（单卡） | 2× H100 SXM5 |
| --- | --- | --- |
| GPU | GH200 480GB（Grace+Hopper, `sm_90a`） | 2× H100 80GB SXM5（`sm_90a`） |
| 互连 | NVLink-**C2C**（GPU↔Grace，一致） | GPU0↔GPU1 = **NV18**（18×NVLink） |
| 形态 | aarch64，带 Grace + LPDDR（有 C2C） | x86_64，无 C2C，两块独立物理 GPU |

 

软件统一为 CUDA 12.8 / driver 580 / Nsight Compute 2025.1 / cuda-gdb 12.8。探针的思路：一个 cluster of N 个 CTA，CTA0 发 `cp.async.bulk.tensor…multicast::cluster` 把一个 tile 扇出到 cluster 内各 CTA 的 SMEM，每个 CTA 在自己的 mbarrier 上等待；**只改 TMA 源地址的内存类型**做对照。 

## 实验一：C2C 上的数据通路（GH200）

 

先验证假说的前半句——“C2C 内存读会落本地 L2”。固定一切，只改 TMA 源：本地 HBM（mode 0）、强制不迁移的 C2C Grace 内存（mode 3）、host-pinned mapped（mode 4）。功能上三者**全部完成（DONE）**。用 Nsight Compute 看 L2 的填充来源（32 KB tile，cluster=2）：        

| 指标 | mode 0 本地 HBM | mode 3 C2C（不迁移） | mode 4 host-mapped |
| --- | --- | --- | --- |
| `fill_device`（从 HBM 填 L2） | **1204** | 207 | 199 |
| `fill_sysmem`（从 Grace/C2C 填 L2） | **0** | **1024**（=1 tile） | **1024** |
| `dram__bytes_read` | 38.66 KB | 6.66 KB | 5.89 KB |

 

`fill_sysmem = 1024 sector` 正好是一个 32 KB tile：**C2C 远端读确实穿过本地 L2 填进来。** 本地 HBM 与 C2C 的填充来源方向相反（device vs system），但都落进同一个本地 L2，所以都能当 multicast 的本地扇出源。下图把这两条通路画在一起： 

所以假说前半句**成立**：C2C 内存对 TMA 引擎就是“挂在本地 L2 后面的内存”。 

## 实验二：单卡 / MIG 为何造不出“挂卡”

 

要验证后半句（NVLink peer 会挂），得有一个**非一致 peer 外部窗口**。但 GH200 是单卡，连 host-mapped 内存都走 C2C 一致路径，物理上造不出。试着用 MIG 切两个实例模拟双卡——结论是**模拟不出来**，而且原因很有意思：       

|  | mode 0（本实例 HBM） | mode 1（peer MIG 实例） |
| --- | --- | --- |
| `op_read`（L2 读扇出） | 1792 | **1790** |
| 结果 | DONE | **DONE** |

 

两者 `op_read` 几乎相同 → peer 实例的数据同样落本地 L2。根因：**MIG 两个实例物理上是同一块 GPU、共享同一 L2 fabric**。要构造真正的“独立物理 L2”外部窗口，必须两块独立物理 GPU。 

## 实验三：双卡 H100 上的反转 —— peer 也不挂

 

换到 2× H100 SXM5（NVLink），终于能做真正的 mode 1：**以 peer GPU 内存作 TMA multicast 的源**。这正是 folklore 说必挂的场景。结果——**没挂**。探针回写“实际搬进 SMEM 的首字”做校验（`src` 全填 `0x01010101`）：         

| 配置 | 结果 | 每个 CTA 的 SMEM 首字 |
| --- | --- | --- |
| mode 0 本地 HBM | 2/2 DONE | `0x01010101` |
| **mode 1 peer NVLink（cluster=2）** | **2/2 DONE** | **`0x01010101`** |
| mode 1 peer（cluster=4） | 4/4 DONE | `0x01010101` |
| mode 1 peer（单播 TMA） | DONE | `0x01010101` |

 

不是假完成：首字是正确的 peer 数据，且所有 CTA（含非发起的 consumer）都完成。NCU 的 NVLink 流量坐实数据确实经 NVLink 从对端而来：       

| 指标 | mode 0（本地） | mode 1（peer） |
| --- | --- | --- |
| `nvlrx__bytes`（NVLink 接收） | **0** | **40.99 KB**（≈1 tile） |
| `nvltx__bytes`（NVLink 发送） | 16 B | 25.20 KB |

 

假说为什么错？它把**普通 `ld` 指令读 peer 的 L2 缓存行为**错套到了 TMA 上。**TMA（`cp.async.bulk`）是主动的 bulk DMA**：它从 global 地址（含 peer，经 NVLink）主动拉数据、写入本地 SMEM，`complete_tx` 由“字节实际到达”驱动，**不依赖本地 L2 是否预先持有源行**。所以源是 peer 也不会“无本地源死锁”——TMA 会把数据搬过来。 

## 实验四：挂卡的真正根因 —— mbarrier 协议

 

但“有人反映挂卡”是真实信号。继续深挖，把挂卡稳定复现出来了，但真凶**不是 NVLink**。 

TMA multicast 的 `complete_tx` 会**分别发往 cluster 内每个目标 CTA 自己的 mbarrier**，所以**每个目标 CTA 都必须 arm 自己的 `expect_tx`**。一个极常见的错误是：以为只有发起 CTA 需要 arm，consumer CTA 只 init 不 arm。就差一个 `if`： 

```text
if (threadIdx.x == 0) {
    mbarrier.init [mbar], 1;                        // 每个 CTA 都 init
#ifdef BROKEN_BARRIER
    if (rank == 0)              // 错误：只有发起 CTA arm，consumer 忘了
#endif
    mbarrier.arrive.expect_tx [mbar], TILE_BYTES;  // 正确：每个 CTA 都 arm 自己的
}
```

 

做一个 2×2 对照（源 × 协议）：       

| mbarrier 协议 | mode 0 本地 HBM | mode 1 peer NVLink |
| --- | --- | --- |
| **正确**（每个 CTA arm） | 2/2 DONE ✓ | 2/2 DONE ✓ |
| **错误**（只发起 CTA arm） | **挂死** | **挂死** |

 

**关键：错误协议在本地 HBM 上一样挂死，正确协议在 peer 上一样不挂 —— 挂卡与 peer/NVLink 完全无关。** 

用 cuda-gdb attach 挂死的 kernel，抓到“卡住”的字面现场： 

```text
* (1,0,0) (0,0,0) ... at tma_multicast_barrier.cu:112   # mbarrier.try_wait 自旋
  => SEL R7,RZ,0x1,!P0                                   # try_wait -> selp
  （block (0,0,0) 已退出：cuda-gdb 报 Invalid coordinates）
```

 

只有 consumer CTA（block 1）还活着、死死卡在 `mbarrier.try_wait`；issuer CTA（block 0）早已完成退出。含义：multicast 投递本身正常、数据（从 peer）也到了、issuer 完成了，唯独没 arm `expect_tx` 的 consumer 记账永远闭合不了。 

> folklore 抓对了现象（确实挂），抓错了归因。挂卡 ⟺ mbarrier 协议错误，与源是不是 peer/远程无关。之所以总在“NVLink 远程内存”场景挂，是因为 multicast 的典型用法就是跨卡 offloading，大家都在那里第一次写 multicast；没人在本地 HBM 上用 multicast，所以“本地也会挂”从没被注意到。 

## 实验五：DAK 论文代码复现

 

DAK 有[开源代码](https://github.com/shouxulin/DirectAccessKernel)。在 GH200 上 clone、构建、运行（构建需补 CUTLASS include、装 pybind11、并 patch CUTLASS 一处 host/device 标注）。其核心 direct-access offloading 复现成功（decode GEMV，bsz=8）：         

| 类型 | 权重位置 | 有效带宽 | MAPE |
| --- | --- | --- | --- |
| vanila（cuBLAS） | HBM | **1942 GB/s** | 0% |
| DAK direct | HBM | 1567 GB/s | 1.17% |
| **DAK direct** | **Grace（C2C）** | **304 GB/s** | 2.05% |
| **DAK direct** | **Grace（C2C）** | **323 GB/s**（11008×4096） | 0.88% |

 

权重 offload 到 Grace 后不 prefetch 回 HBM、直接经 C2C 读进 SMEM 计算，达到 C2C 单向带宽（450 GB/s）的约 70%，结果正确——这正是论文相比 prefetch 提速的根源。另外核实了社区的一个观察：DAK 的 `gemv_multicast_prefill` 实际上把 TMA multicast 注释掉了（没有 `__cluster_dims__`、走的是非-multicast 路径），只有 decode 路径的 `gemv_multicast` 真正用到 multicast。 

## 总结

         

| 命题 | 结论 |
| --- | --- |
| C2C 内存读会落本地 L2 | ✅ 证实（`fill_sysmem`=1 tile） |
| C2C 上 TMA multicast 能跑（DAK） | ✅ 证实（DAK direct 304–323 GB/s） |
| **NVLink peer 上 TMA multicast 必挂** | ❌ **推翻**（双 H100 实测稳定 DONE，nvlrx 证明数据经 NVLink 拉回本地） |
| 挂卡的真正根因 | **mbarrier 协议误用**（consumer 没 arm `expect_tx`），与 peer/NVLink 无关 |

 

一句话：能不能跑 TMA multicast，取决于“数据是否被搬到了本地、每个 consumer CTA 的 mbarrier 是否正确记账”，而**不是**“源是不是 NVLink 远程内存”。C2C、本地 HBM、甚至 NVLink peer，只要协议写对都能跑；协议写错，无论源在哪都挂死，现场就是 consumer CTA 卡在 `mbarrier.try_wait`。真正的分界线从来不是链路类型。 

## 交付件 / 可复现

 

本文涉及的代码、脚本、图与报告： 
 
- [tma_mc_probe.cu](/posts/nvlink-c2c-tma-multicast/tma_mc_probe.cu) — 主探针（多 mode、bf16、cluster 可配、每-CTA 校验、`BROKEN_BARRIER` 开关） 
- 最小可复现示例：[tma_multicast_barrier.cu](/posts/nvlink-c2c-tma-multicast/tma_multicast_barrier.cu)、[capture_hang.sh](/posts/nvlink-c2c-tma-multicast/capture_hang.sh)、[README](/posts/nvlink-c2c-tma-multicast/demo_README.md)（本地 HBM 即可演示正确 vs 错误协议 + cuda-gdb 现场） 
- [attach_gdb.sh](/posts/nvlink-c2c-tma-multicast/attach_gdb.sh) — cuda-gdb 抓挂死现场脚本 
- [memory_chart.html](/posts/nvlink-c2c-tma-multicast/memory_chart.html) — 实验一的内存通路图（独立页面） 
- 完整记录（Markdown）：[实验全过程](/posts/nvlink-c2c-tma-multicast/实验全过程.md)、[H100 mode 1 修正](/posts/nvlink-c2c-tma-multicast/H100双卡_mode1实测.md)
