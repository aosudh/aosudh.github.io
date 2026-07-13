# MTT S5000 单卡与八卡实测：从 PCIe、FP8 到 MTLink 与 MCCL

> 测试时间：2026-07-13 至 2026-07-14。本文只写本机实测，不把产品标称、成功启动、正确性通过和性能峰值混为一谈。`GB/s` 为十进制；文中的 logical/effective bandwidth 是程序请求字节量除以时间，不等于硬件计数器测得的物理总线流量。

## 1. 硬件环境

| 项目 | 本机实测环境 |
|:---|:---|
| GPU | 8 × MTT S5000；GMI 显示每卡 81,920 MiB，runtime device property 为 85,813,358,592 B（约 79.92 GiB） |
| CPU | 2 × Intel Xeon Platinum 8358P；2 个 NUMA 节点；系统枚举 256 个 CPU，CPU 239 offline |
| OS / Kernel | Ubuntu 22.04.5 LTS / `5.15.0-105-generic` |
| Driver | `3.3.5-server` |
| MUSA | Toolkit 4.3.5，安装在 `/usr/local/musa-4.3.5`；`mcc 4.3.5` |
| Python 栈 | Python `3.10.12`、PyTorch `2.7.1a0`、Torch-MUSA `2.7.1`、Triton-MUSA `3.2.0` |
| Kernel/DSL 库 | MUTLASS `0.2.0`、FlagGems `4.2.0`；其它 DSL 见单卡兼容表 |
| 管理工具 | `mthreads-gmi 2.3.2` |
| MCCL | 包元数据 `2.1.5`；测试横幅和 SONAME 为 `2.11.4`；commit 都指向 `b1ac16e7...` |

MCCL 的两个版本字符串互相冲突，所以本文把它们同时保留，不擅自挑一个“修正”另一个。单卡测试只使用 GPU0；多卡阶段只运行真实 2/4/8 卡程序，没有把单卡 benchmark 混进多卡结果。

![mthreads-gmi 八卡枚举](/assets/s5000/gmi-eight-gpu-overview.png)

*八卡枚举截图：8 张卡均为 S5000、每卡 81,920 MiB，PCIe lane width 为 x16。截图底部的进程查询失败不是“确认没有进程”，而是该接口本次不可用。*

## 2. 连接拓扑

八张卡按 4+4 分在两个 NUMA 节点，PCIe 均保持 32.0 GT/s ×16：

| GPU | PCI BDF | NUMA | 本地 CPU |
|---:|:---|---:|:---|
| 0 | `0000:03:00.0` | 0 | `0-63,128-191` |
| 1 | `0000:24:00.0` | 0 | `0-63,128-191` |
| 2 | `0000:44:00.0` | 0 | `0-63,128-191` |
| 3 | `0000:63:00.0` | 0 | `0-63,128-191` |
| 4 | `0000:83:00.0` | 1 | `64-127,192-238,240-255` |
| 5 | `0000:a3:00.0` | 1 | `64-127,192-238,240-255` |
| 6 | `0000:c3:00.0` | 1 | `64-127,192-238,240-255` |
| 7 | `0000:e3:00.0` | 1 | `64-127,192-238,240-255` |

`mthreads-gmi topo -mg` 把任意两张 GPU 之间都报告为 `MT2`。按 GMI 自己的定义，`MTx` 是由 x 条 MTLink 绑定而成的路径。端口布局进一步确认：

- 8 张卡组成 28 个无序 GPU 对；
- 每个 GPU 对有 2 条物理 MtLink，共 56 条物理链路；
- 每张卡用 14 个 Link 端口连接其余 7 张卡，合计 112 个端口端点；
- 测试前后 `112/112 LINK UP`，端口双向映射校验通过。

说人话就是：CPU/PCIe 拓扑是 4+4 双 NUMA，但 GPU 互联没有被切成两个四卡孤岛；全部 28 个卡对都有 MT2 路径，后面的严格 P2P 也验证了全部 56 个传输方向。

![mthreads-gmi topo -m 输出](/assets/s5000/gmi-topology-matrix.png)

*拓扑矩阵同时列出了 8 张 GPU、11 个 NIC、CPU affinity 和 NUMA。GPU4–7 行末的 CPU/NUMA 字段存在粘连，正文的 NUMA 表以 sysfs 交叉核对结果为准。本文没有做跨节点 RDMA，NIC 只作为拓扑背景。*

[打开可交互的 MTLink 端口图](/assets/s5000/mtlink-layout-map.html)。它可以按 GPU 或 GPU 对筛选，并显示两端具体 Link 编号；正文不再抄 28 行端口映射。

## 3. 单卡规格

下面是 runtime、sysfs、GMI 和实测 probe 能互相对上的程序可见规格，不是宣传页参数摘抄：

| 项目 | 程序可见值 |
|:---|:---|
| 显存 | GMI 80 GiB；runtime 可见约 79.92 GiB |
| 计算资源 | 60 MP；warp 32；MUSA compute capability 3.1 |
| 线程 | 1024 threads/block；3072 resident threads/MP |
| Runtime property | core clock 1500 MHz、memory clock 20,000 MHz、memory bus width 640 bit；只作设备属性记录，不据此反推物理显存带宽 |
| L2 | 60 MiB |
| Shared memory | 192 KiB/block |
| PCIe | Gen5 x16，32 GT/s |
| ECC/EDC | GMI 报告 On-die EDC 开启、Inline ECC 关闭；不据此扩展解释未暴露的错误模型 |
| FP8 标称参照 | 官方口径“高达 1000 TFLOPS”；本机同合同最佳实测为 899.417 TFLOP/s |

![mthreads-gmi -q 单卡详情](/assets/s5000/gmi-single-card-detail.png)

*单卡 `-q` 截图能确认 PCIe Gen5 x16、80 GiB、EDC 和管理接口功率字段；其中显存带宽、核心时钟、部分 ECC 统计为 `N/A`，不能拿空字段补写规格。950 W 是 GMI 暴露的功率限制值，不是本轮测得的实际板卡功耗。*

## 4. 单卡测试性能

最终 full suite 共 24 个 stage：21 PASS、3 FAIL。统一汇总要求的 19 个 formal product 为 14 PASS、5 ERROR、0 MISSING；5 个 ERROR 分别落在严格 FP32、Torch INT8/低精度汇总、FlagGems attention/BLAS、FlagGems supplement 和 DSL compatibility。ERROR 都保留在文中，没有用“能跑一个 case”冒充整个后端兼容。

### 4.1 Runtime、PCIe、显存和 TME

| 项目 | 实测结果 | 口径 |
|:---|---:|:---|
| Kernel launch | 6.258 µs | 3 次 core run 中位数 |
| Graph launch | 27.904 µs | 输出校验 PASS |
| 4 个长 kernel：串行 / 4 stream | 6.933 / 1.811 ms | 3.829× |
| D2D，512 MiB | 670.452 GB/s | API payload |
| STREAM copy / triad | 1228.208 / 1422.448 GB/s | logical traffic |
| PCIe pinned H2D / D2H，512 MiB | 56.790 / 55.896 GB/s | 3 次中位数 |
| PCIe pinned async H2D / D2H，256 MiB | **57.103 / 56.133 GB/s** | 约为只扣 128b/130b 编码上限的 90.62% / 89.08% |
| PCIe pageable sync H2D / D2H，256 MiB | 14.762 / 5.593 GB/s | pageable 明显更慢 |
| PCIe 同时双向，256 MiB | 68.081 GB/s aggregate | 两方向共享瓶颈 |
| H2D 与约 5 ms 计算重叠 | 1.886× | makespan 从 8.973 降到 4.760 ms |
| Pure TME copy，256 MiB | 1314.700 GB/s | pointer 为 1197.410，TME 快 1.098×；均为 read+write logical bandwidth |

Pinned memory 是 PCIe 跑满的关键。NUMA 对照中，remote pageable D2H 两轮都大约减半；pinned H2D/D2H 则基本不受本轮 CPU 节点选择影响。这里做了 affinity 和 first-touch，没有用 `move_pages` 验证每个物理页，所以不能把它写成严格的页级 NUMA 归属实验。

显存完整性测试同时驻留 76,678,358,632 B（76.678 GB，约为空闲显存的 90%），运行 951.119 秒：141 PASS、2 INFO、0 FAIL/ERROR，aggregate error 为 0，18/18 allocation 正常释放。旧版本看似“卡死”是一次排队约 63,360 个后台 kernel 导致的队列回压；加定期 drain 后完整退出，不再误报为死锁。

管理接口在 PCIe 专项中记录到 P0 平均/最大功耗 394.02/404.50 W、最高 35 °C；显存 soak 时约 73,320 MiB 被占用，功耗中位约 394.03 W、温度 35 °C。与此同时 GMI 的 `gpu_util_pct` 在显存 kernel 持续工作时仍全部报 0%，所以这个利用率字段不能拿来判断 GPU 是否真的空闲。

### 4.2 L1、L2、Shared 和访问延迟

| 探针 | 代表结果 |
|:---|---:|
| L1 replicated effective read | 1480.735 GB/s，64 KiB/MP working set |
| L2 partitioned effective read | 2701.727 GB/s，16 MiB aggregate |
| L2 64 / 128 / 256 MiB sweep | 2440.694 / 2124.148 / 1667.770 GB/s |
| Shared effective read | 3085.987 GB/s，32 KiB |
| Shared dependent load | 39.43–39.45 ns/access，约 69 cycles |
| Pointer chase，4 KiB → 128 MiB | 106.9 → 253.8 ns/access |
| Shared atomic，单 counter / 32 stripe | 104.20 / 1577.27 Gop/s |
| Global atomic，单 counter / 每 CTA 一个 counter | 0.1778 / 1.618 Gop/s |

这些是固定访问模式下的 effective bandwidth 和稳态延迟；没有可用硬件 counter，不能由此反推出 cache hit rate、TLB entry 数、物理 bank 数或真实 fabric 流量。

### 4.3 计算与低精度

先看不同合同下的可执行能力：

| 路径 | Shape | 实测 |
|:---|:---|---:|
| FP32 independent FMA | 固定微基准 | 14.052 TFLOP/s |
| 严格 FP32 GEMM | 4096×4096×1024 | 约 24.36 TFLOP/s |
| TF32-enabled Torch GEMM | 4096×4096×1024 | 158.867 TFLOP/s |
| FP16 Torch GEMM | 4096³ | 384.74 TFLOP/s |
| BF16 Torch GEMM | 2048³ | 296.511 TFLOP/s |
| MUTLASS INT8 S8×S8→S32 | 4096³ | **446.355 TOP/s** |

严格 FP32 矩阵 72 条全部执行，68/72 通过 dtype oracle；4 条阈值 FAIL 都来自两个大 GEMM，最大绝对误差分别为 `4.654e-4` 和 `2.365e-4`。误差不大，但越过预先声明的阈值就保留 FAIL。Torch `_int_mm` 的 3 个 INT8 case 则在 dispatcher 处 `NotImplementedError`；MUTLASS 的 8 个实际 INT8 launch 全部 reference PASS，所以这是 Torch-MUSA 后端缺口，不是硬件没有 INT8。

FP8 的公平主轴固定为 `16384³`、E4M3×E4M3、A row-major、B column-major、BF16 输出：

| 实现 | 正式中位数 | 相对 Torch | 结论 |
|:---|---:|---:|:---|
| Torch-MUSA `_scaled_mm` | **899.417 TFLOP/s** | 100% | 达到 1000T 宣传口径的 89.94% |
| MUTLASS K64/stage4/H2 | **713.500 TFLOP/s** | 79.329% | 相对同轮 control 提升 6.309%，仍未追平 |
| Triton-MUSA single-panel | **335.686723 TFLOP/s** | 37.323% | M-fastest raster 和 two-panel 分别慢 2.042% / 2.278%，均被 gate 拒绝 |

MUTLASS 的提升只能归给 K64/stage4/H2 组合，因为 K-depth 和 stage 同时变化。Triton 已生成 SQMMA 路径，差距不是“根本没用 FP8 指令”；但当前 muPTI 只有 Activity trace，缺 occupancy、stall、cache、bank conflict 和动态 spill counter，不能编造唯一根因。

### 4.4 GEMM 之外：Attention、Triton workload 与其它 DSL

固定 `B4/Hq=Hkv32/S4096/D128/FP16/noncausal` 的 attention：

| 路径 | 实测 | 正确性边界 |
|:---|---:|:---|
| Torch-MUSA flash | **372.573849 TFLOP/s** | 实际 flash kernel，15 个 Event 样本 |
| MUTLASS MP31 FMHA | **318.061950 TFLOP/s** | 大 shape 为 performance-only；小模板有 CPU reference |
| FlagGems FA2 | **64.829545 TFLOP/s** | 完整输出对 Torch PASS |
| FlagGems FA3 | UNSUPPORTED | 不给性能数字 |

MUTLASS 相对 Torch 低 14.631%。减少静态 shared、block 和 private allocation 的候选反而从约 316.6T 跌到 205.7T，说明“资源数字更小”不等于一定更快。

Triton-MUSA 的 elementwise/reduction 路径比它的手写 GEMM 成熟得多：64M FP32 vector add 为 1314.31 GB/s，接近 Torch 的 1329.48；16384×4096 softmax 为 1244.16 GB/s，略高于 Torch 的 1194.89。固定 tile 的 FP16 GEMM 在 4096³ 只有 41.89T，而 Torch 为 384.74T。另一个 45-case workload 覆盖 SwiGLU、RMSNorm、RoPE、softmax 和 row sum，45/45 custom oracle PASS；RoPE 9/9 快于 eager，row sum 9/9 慢于 eager。

| 编程路径 | 本机结论 |
|:---|:---|
| MUSA C++ | Runtime、STREAM、cache、显存 pattern、TME 等主测试的底层路径，实际编译运行 |
| Triton-MUSA 3.2 | 基础 kernel 和 45-case workload PASS；descriptor-TME 在 `MTGPULowerArgs` 编译崩溃 |
| MUTLASS 0.2.0 | FP8、INT8、FMHA 均有实际 kernel；reference 和 performance 边界分别记录 |
| FlagGems 4.2.0 | fused/norm 185 个计时点；7/7 direct API oracle PASS；部分 BLAS descriptor ABI 和 scaled-softmax 导入失败 |
| NineToothed 0.23.0 | 生成 Triton kernel 并在 MUSA 上执行；单个 add case 1074.77 GB/s、max-abs 0；属于超范围单 case |
| MATE 0.1.3 | 官方要求 Toolkit ≥4.3.6；4.3.5 强制 BMM 单 case 73.54T、max-abs 0，不升级为官方支持 |
| TileLang-MUSA 0.1.8+musa.3 | 依赖 `libmusart.so.5`，当前 4.3.5 环境在 import 阶段失败，未生成 kernel |
| TVM-FFI / Gluon / Helion / Liger | TVM-FFI 仅 import；Gluon 缺当前 Triton API；Helion 版本门不满足；Liger 未 opt-in，不给兼容或性能结论 |

FlagGems 也不能一句“兼容”带过：fused/norm harness 的 185 个计时点全部产表，speedup 中位 1.595×，但范围从 0.042× 到 14.091×，RMSNorm 最低约 0.045×；attention/BLAS 的 pytest 为 3 failed、9 passed、2 skipped，SDPA 20 点中位仅 0.117×。独立 direct API oracle 是 7/7 case、10/10 check PASS，它只证明这些 case 正确，不能反向替 185 个性能点背书。

### 4.5 明显慢算子的 profiling 结果

按官方调优顺序固定 shape、正确性和 MUSA Event 计时后，6/6 个诊断 case 都通过输出校验：

| 算子 | 原路径 | 候选路径 | 加速 |
|:---|---:|---:|---:|
| amax FP16，`[1024,1024,1024]` dim1 | 4.853 ms | 1.557 ms | 3.12× |
| std FP32，同 shape/dim | 10.265 ms | 3.775 ms | 2.72× |
| RMSNorm FP16，`[1024,65536]` | 5.826 ms | 0.308 ms | **18.93×** |
| log-softmax FP16，同宽 | 2.037 ms | 0.369 ms | 5.53× |
| group norm FP16，N20/C6/HW65536/G3 | 1.200 ms | 0.123 ms | 9.78× |
| baddbmm BF16，B2、4096³ | 5.636 ms | tile64/warp4 2.758 ms | 2.04× |

amax/std 的“预物化 reduction”把物化成本移出了计时，只能说明 reduction core 是主要热点，不能直接当成生产修复。RMSNorm、log-softmax、group norm 的 split 原型和 baddbmm tile64/warp4 都通过 correctness；把 baddbmm 增到 warp8 反而退化到 3.089 ms，说明参数更大并不自动更快。

单卡逐项原始日志与 JSON 保留在本地测试归档；网页随附 [Markdown 版](/assets/s5000/mtt-s5000-single-and-8gpu-benchmark.md)。

## 5. 多卡测试性能

### 5.1 全向 P2P

严格单向测试为每个 `src→dst` 单独启动进程，使用 `musaMemcpyPeerAsync`，目标预填 poison，传输后完整 D2H 做逐字节比较和 hash 校验。56/56 个有向 pair 全部支持并 PASS。

同时双向测试为每个无向 pair 启动两个 host thread、两个 endpoint stream，在共同 barrier 后并发 A→B 与 B→A；28/28 pair 全部 PASS。aggregate 按 `2S/max(tAB,tBA)` 计算，不是把两个独立单向峰值直接相加。

| Payload | 单向同/跨 NUMA中位 | 同时双向同/跨 NUMA aggregate |
|---:|---:|---:|
| 1 MiB | 32.875 / 32.891 GB/s | 62.135 / 62.046 GB/s |
| 64 MiB | 约 35.36 / 35.36 GB/s | 69.135 / 69.121 GB/s |
| 256 MiB | **35.704 / 35.702 GB/s** | **69.491 / 69.496 GB/s** |

256 MiB 双向方向不对称度中位仅 0.020%，最大 0.126%。大消息同/跨 NUMA 基本重合，说明数据驻留 GPU 时没有测到稳定的跨 NUMA 惩罚；不能外推到 host staging 或 RDMA。

### 5.2 MCCL AllReduce 扩展

正式矩阵为 6 种卡组/顺序 × 5 个消息大小 × 3 个独立 round，共 90 个真实多卡进程。全部退出 0，out-of-place 和 in-place 的 `#wrong` 均为 0。下面只列 1 GiB：

| 卡组 | N | OOP 时间 | OOP busbw | IP busbw |
|:---|---:|---:|---:|---:|
| GPU0,1，同 NUMA | 2 | 34.193 ms | 31.40 GB/s | 25.63 GB/s |
| GPU0,4，跨 NUMA | 2 | 34.193 ms | 31.40 GB/s | 25.78 GB/s |
| GPU0–3，NUMA0 | 4 | 16.049 ms | 100.36 GB/s | 86.55 GB/s |
| GPU4–7，NUMA1 | 4 | 16.038 ms | 100.42 GB/s | 86.45 GB/s |
| 8 卡 grouped | 8 | 8.021 ms | **234.28 GB/s** | 217.88 GB/s |
| 8 卡 interleaved | 8 | 8.022 ms | **234.24 GB/s** | 218.06 GB/s |

1 GiB 的 wall time 从两卡 34.193 ms 降到四卡约 16.04 ms、八卡约 8.02 ms，约为 2.13× 和 4.26×。`busbw` 的修正因子会随卡数变化，不能用 `234/31` 直接宣称“7.5 倍线性扩展”。grouped 与 interleaved 在大消息上基本没有差别。

### 5.3 Collective 覆盖与诊断 A/B

八卡 grouped 顺序下，9 类 collective、Broadcast/Reduce 各两个 root，共 11 个逻辑 case；所有适用 correctness 均为 `#wrong=0`。256 MiB out-of-place 代表值如下：

| Collective | busbw |
|:---|---:|
| AllReduce | 211.86 GB/s |
| AllGather | 196.99 GB/s |
| ReduceScatter | 201.81 GB/s |
| AllToAll | 155.70 GB/s |
| Broadcast，root 0 / 7 | 95.59 / 95.59 GB/s |
| Reduce，root 0 / 7 | 102.66 / 102.27 GB/s |
| Gather | 220.90 GB/s |
| Scatter | 236.31 GB/s |
| SendRecv | 38.24 GB/s |

不同 collective 的 `busbw` 修正因子不同，这张表用于同一 collective 的版本回归，不适合横向评选“谁最快”。AllToAll 和 SendRecv 的 in-place correctness 在工具中定义为 `N/A`，没有偷换成 PASS。

最有解释力的 A/B 是关闭 P2P：八卡 1 GiB AllReduce OOP 从 234.59 降到 25.34 GB/s，AUTO/P2P-off 为 **9.258×**。小消息差别小，消息越大差距越明显，说明大消息 MCCL 性能高度依赖 GPU direct P2P。

协议单变量对照中，1 GiB OOP 的 AUTO/Simple/LL 为 234.47/234.55/234.54 GB/s，IP 为 217.76/217.85/217.77 GB/s；差异只有约 0.04%，没有证据支持固定协议优于 AUTO。

真正的问题在显式算法选择：强制 `Ring/Tree × LL/LL128/Simple` 的 24/24 个进程全部 SIGSEGV，且没有数据行。进一步隔离后，单独设置 `MCCL_ALGO=Ring` 或 `Tree` 仍崩溃；只设置 `MCCL_PROTO=Simple` 或 `LL` 则八个 rank 全部完成并通过。现有证据把问题定位到 **显式 `MCCL_ALGO` 选择/初始化入口**，不等于证明 AUTO 内部的 Ring/Tree kernel 本身不可用。当前最稳妥的配置是保持 AUTO，不显式设置 `MCCL_ALGO`。

MCCL INFO 还反复出现 `Attribute class of node nic not found` 和 `TOPO Detect Failed`。它们同时存在于全部成功的 AUTO/PROTO case 和崩溃 case，所以既不是 SIGSEGV 的充分原因，也不能简单当成无害噪声；只能说当前 workload 在某个回退路径上完成且结果正确，不能宣称 MCCL 的平台识别和最优拓扑选择完全健康。

全部 workload 结束后仍为 112/112 MTLink UP，replay/recovery 各 112 项全 0，PCIe 8/8 保持 32.0 GT/s ×16；framing 112 项均为 `N/A`。FEC correction 的累计值为 91,570,182，范围 14,887–7,425,617，但没有测试前 baseline 和固定采样窗口，不能归因给 benchmark，也不能单凭累计非零判链路故障。进程查询接口返回“不支持”，因此也不能把它当成“系统无残留 GPU 进程”的证明。

多卡逐项原始日志与 JSON 保留在本地测试归档；网页随附 [Markdown 版](/assets/s5000/mtt-s5000-single-and-8gpu-benchmark.md)。

## 6. MTHREADS_GMI_CLI_吐槽_PART

先说结论：`mthreads-gmi` 的查询能力不差，但 CLI 设计很不利于自动化。本次针对 2.3.2 版实测了 61 条命令，逐条保存 stdout、stderr 和退出码；122 个 raw 输出文件与 124 项 SHA-256 均已复核。

| 问题 | 实测表现 |
|:---|:---|
| 子命令帮助不统一 | `mthreads-gmi -h`、`event -h` 返回 0；`topo -h`、`mtlink -h`、`vgpu -h` 全部返回 1，只提示去看全局帮助。 |
| 短选项反复换含义 | 顶层 `-r` 是 GPU reset，`mtlink -r` 却是只读远端链路查询；顶层 `-e` 是 ECC 配置，`mtlink -e` 是错误计数。少写一个上下文，查询就可能变成改设备状态。 |
| 参数格式靠猜 | 普通 `-i` 接收一张卡；拓扑卡对必须写成 `-i 0,1`。写成 `-i 0 1` 或两个 `-i` 都返回 1，提示又不告诉你缺逗号。 |
| `-l` 单位不固定 | `-q -l` 是秒，`-mm -l` 是毫秒，`mtlink -l` 又变成端口编号。 |
| 错误流形同虚设 | 61 条命令对应的 61 个 stderr 文件全部为 0 字节，连 `Error:` 都写进 stdout。只按 stderr 判断会误判。 |
| 退出码没有统一语义 | 普通参数错误多为 1；`mtlink -r` 缺 GPU/端口返回 5；`vgpu -es/-ds` 相似失败分别返回 6 和 4；外层 timeout 的 124 还要另外区分。 |
| 正确命令也会随状态变脸 | `topo -p2p r/w` 曾返回“operation is not available”，后续相同命令又返回完整 8×8 `OK`；`-pm` 也出现过正常进程表和 exit 1“接口不可用”两种结果。 |
| JSON 不够机器友好 | `-q --json` 可以解析，但 `Attached GPUs: "8"`、`Total: "81920MiB"`、`Temp: "27C"`、`Power: "96.13W"` 仍是带单位字符串，甚至有尾部带空格的键 `Power Draw `。 |

它也不是一无是处：单卡遥测的 573 次 JSON 查询全部解析成功且退出码为 0；`topo -mg` 能给出完整 GPU 拓扑；`mtlink -s` 能检查 112/112 个端口；`mtlink -e` 能读取逐端口 replay、recovery 和 FEC。

问题是这些状态接口不能代替真实 workload。FEC 只有累计值，没有采样区间和前置基线；P2P 状态也不能证明真实传输正确或跑到多少。因此本文最终以 runtime correctness、完整输出校验和带宽测试为准，GMI 只负责设备清单、状态快照与辅助诊断。自动化脚本必须同时检查退出码、stdout 内容和结果结构，不能只信其中任何一个。

61 条命令的逐项输出与原始证据保留在本地测试归档；这里仅保留能由本轮实测直接支持的结论。
