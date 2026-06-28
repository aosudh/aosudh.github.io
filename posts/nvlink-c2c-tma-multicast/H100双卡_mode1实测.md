# 双卡 H100 实测:mode 1(NVLink peer)未复现挂卡 —— 对核心命题的重要修正

> 在一台 **2× H100 80GB SXM5(NVLink NV18 全互连,x86_64)** 上,终于能构造实验文档里那个一直无法测的 **mode 1:以 peer GPU 内存作为 TMA multicast 的源**。
>
> 文档/folklore 的预测:peer 是"非一致 foreign window,数据只 cache 在对端、绕过本地 L2 → multicast 无本地 L2 源 → mbarrier 的 expect-tx 永不凑齐 → `mbarrier.try_wait` 死等 → **挂卡**"。
>
> **实测结论:在 H100 SXM5 + CUDA 12.8 + driver 580 上,mode 1 没有挂卡,TMA multicast 从 peer GPU 内存读取完全成功(数据正确)。这推翻了该配置下的"必挂卡"预测。**

---

## 一、实验环境

| 项 | 值 |
|---|---|
| GPU | **2× NVIDIA H100 80GB HBM3 SXM5**,x86_64(无 Grace/C2C) |
| 互连 | **GPU0 ↔ GPU1 = NV18**(18 条 NVLink 4 全互连),`cudaDeviceCanAccessPeer=1` |
| 驱动 / CUDA | driver 580.105.08;nvcc 12.8;Nsight Compute 2025.1 |
| 机器 | `ubuntu@dual-h100-host`(Lambda) |

与 GH200 的关键区别:这是**两块独立物理 GPU**(各自独立 L2、独立 HBM),通过 NVLink 互连。peer GPU 的内存对本地 GPU 就是文档所说的"非一致外部窗口"。这正是 mode 1 需要的、之前在单卡 GH200 / MIG 上都造不出的场景。

---

## 二、功能结果:mode 1 DONE,数据正确

探针在完成时把"实际搬进 SMEM 的首字"回写,用于校验数据是否真从 `src` 读到(`src` 全填 `0x01010101`)。

| 配置 | 结果 | SMEM 首字 | 判定 |
|---|---|---|---|
| mode 0 本地 HBM | DONE | `0x01010101` | 基线正常 |
| **mode 1 peer(multicast, cluster=2)** | **DONE** | **`0x01010101`** | **从 peer 读到真数据,multicast 完成** |
| mode 1 peer(multicast, cluster=4) | DONE | `0x01010101` | 扇出到 4 个 CTA 也成功 |
| mode 1 peer(非-multicast 单播) | DONE | `0x01010101` | 单播 TMA from peer 也成功 |

mode 1 连跑 3 次稳定 DONE + 正确数据。**不是"假完成"**:`first SMEM word = 0x01010101` 证明 TMA 真的把 GPU1 内存里的数据搬进了 GPU0 的 SMEM。

> 安全说明:探针的 `mbarrier.try_wait` 用有界自旋(`1<<28` 次),即使真死锁也会 ~1–2 s 退出返回 `NO-COMPLETE`,不会锁死 GPU。实测从未出现 `NO-COMPLETE`,均为 DONE。

---

## 三、机制证据:数据确实经 NVLink 从对端而来(NCU)

| NCU 指标 | mode 0(本地 HBM) | mode 1(peer GPU1) | 含义 |
|---|---|---|---|
| `nvlrx__bytes`(NVLink 接收) | **0** | **40.99 KB** | mode 1 经 NVLink 收到 ≈1 个 tile(32KB)+协议开销 |
| `nvltx__bytes`(NVLink 发送) | 16 B | 25.20 KB | mode 1 经 NVLink 发出读请求+协议 |
| `lts__t_sectors_op_read` | 3191 | 1636 | 两者 L2 都有读扇出活动 |
| `lts__d_sectors_fill_device` | 1188 | 163 | mode 1 几乎不从本地 HBM 填 |
| `lts__t_requests_aperture_peer` | 0 | 0 | (见下:TMA 的 peer 路径不计入此计数) |

完整因果链:**请求经 NVLink 发往 GPU1(nvltx)→ 数据经 NVLink 从 GPU1 返回(nvlrx=41KB)→ TMA 把数据搬进本地 SMEM(首字校验通过)→ multicast 的 `complete_tx` 完成 → 不挂卡。**

---

## 四、为什么文档的"必挂卡"推论在 TMA 上不成立

文档的死锁推论链是:
> multicast 要求源在本地 L2 → peer 读绕过本地 L2、只 cache 在对端 → 本地 L2 没有可扇出的源行 → complete_tx 永不触发 → 死锁。

这个推论把 **普通 `ld` 指令读 peer 时的 L2 缓存行为**,错误地套用到了 **TMA(`cp.async.bulk`)** 上。实测表明二者机制不同:

- **TMA 是主动的 bulk async DMA,不是依赖"L2 缓存命中"的 load。** 它从 global 地址(可以是本地 HBM、C2C、或 peer GPU)主动拉取数据,经互连返回,写入本地 SMEM,并在**数据实际到达**时触发 `complete_tx`。
- `complete_tx` 由"字节实际到达本地"驱动,**不依赖"本地 L2 是否预先持有源行"**。所以源是不是 peer、本地 L2 缓不缓存这段地址,都不影响 multicast 完成 —— TMA 会把数据搬过来。
- `nvlrx=41KB` 正是这一过程的直接证据:peer 数据经 NVLink 被主动拉回本地,而不是"卡在没有本地源"。

> `aperture_peer=0` 但数据确实经 NVLink 到达(nvlrx=41KB):说明 H100 的 TMA 引擎从 peer 拉数据的路径,不经过被 `lts__t_requests_aperture_peer` 计数的那条常规 L2 peer-load 请求通道(TMA 有自己的 global→shared 数据通路)。这是计数归类问题,不影响"数据到达 + multicast 完成"的功能事实。

---

## 五、那"有人挂卡"是真的吗?——是真的,但根因是 mbarrier 协议,不是 NVLink

确实有人反映"nvlink 上用 tma multicast 访问远程内存会直接挂卡",还有不少人附和。这个现象是**真实的**,我也复现出了**稳定的挂死**——但根因定位到 **mbarrier 协议写错**,与 peer/NVLink 无关。

TMA multicast 的正确协议要求:**cluster 内每个目标 CTA 都必须 `init` 并 `arrive.expect_tx` 自己的 mbarrier**(multicast 的 `complete_tx` 会分别发往每个目标 CTA 同 offset 的 mbarrier)。一个非常常见的错误写法是:**以为只有发起 multicast 的 CTA 需要 arm expect_tx**,consumer CTA 只 init 不 arm。

用探针的 `-DBROKEN_BARRIER` 开关复现这个错误写法,做 2×2 对照:

| mbarrier 协议 | mode 0(本地 HBM) | mode 1(peer NVLink) |
|---|---|---|
| **正确**(每个 CTA arm 自己的 expect_tx) | 2/2 CTA 完成 ✓ | 2/2 CTA 完成 ✓ |
| **错误**(只发起 CTA arm,consumer 不 arm) | **挂死(60 s timeout, rc=124)** | **挂死(60 s timeout, rc=124)** |

挂死是**真死锁**:连探针的有界自旋(`1<<28`)都跳不出,kernel 60 s 不返回(`timeout` 杀进程后 GPU context 被清理,正常协议立即恢复 2/2,无需 reset)。

**关键:错误协议在本地 HBM 上一样挂死,与 peer/NVLink 完全无关;反过来,正确协议在 peer NVLink 上稳定不挂。** 所以:

> 挂卡 ⟺ **mbarrier 协议错误**(consumer CTA 的 expect-tx 记账永不闭合 → `try_wait` 永不翻转 / TMA 投递挂起),**与"源是不是 peer/远程"无关**。

**那为什么 folklore 偏偏说"nvlink 上访问远程内存"挂?** 因为 TMA multicast 的典型使用场景就是跨卡/远程 offloading(比如 DAK)。大家是在"NVLink 远程内存"这个场景里第一次写 TMA multicast,协议没写对就挂了,于是把现象归因成"NVLink + TMA multicast + 远程内存";而**没人会在本地 HBM 上用 multicast**(本地直接 load 即可),所以"本地其实也会挂"这件事从没被注意到。**folklore 抓对了现象,抓错了归因。**

```bash
# 复现挂死(错误协议),本地和 peer 都挂:
nvcc -arch=sm_90a -O3 -lcuda -DBROKEN_BARRIER tma_mc_probe.cu -o p_broken
timeout 60 ./p_broken 0     ; echo "rc=$?"   # rc=124 (本地 HBM 也挂死)
timeout 60 ./p_broken 1 1   ; echo "rc=$?"   # rc=124 (peer 也挂死)
# 正确协议(默认),本地和 peer 都不挂:
./tma_mc_probe 0 ; ./tma_mc_probe 1 1         # 都 2/2 ALL DONE
```

### cuda-gdb 抓到的"卡住"字面现场

用 `cuda-gdb` attach 挂死的 BROKEN kernel(peer 源),`info cuda threads`:

```
  BlockIdx  ThreadIdx   PC                    Filename             Line
* (1,0,0)    (0,0,0)    0x...eb7ac6f0   tma_mc_probe.cu       120
```

- **只有 consumer CTA(block (1,0,0))的 thread 0 还活着,PC 卡在 `tma_mc_probe.cu:120`** —— 正是 `mbarrier.try_wait` 自旋循环(SASS `SEL R2,RZ,0x1,!P0`,即 try_wait→selp),phase 永不翻转。
- **issuer CTA(block (0,0,0))已经退出**(cuda-gdb 报 `Invalid coordinates requested`,block 0 已不存在)。

含义:multicast 投递本身**正常**,`complete_tx` 到达了正确 arm 的 CTA0、它完成退出;**唯独没 arm `expect_tx` 的 CTA1,mbarrier 记账永远闭合不了,死在 `try_wait`**。这就是 folklore 里"卡住"的字面现场——而它证明的是 **mbarrier 协议 bug(consumer 没 arm),不是 NVLink 的锅**:数据(从 peer)已经到了、issuer 已经完成,卡住的纯粹是 consumer CTA 的 barrier 记账。(GPU 在 `kill` 后立即恢复 0% / 0 MiB,无需 reset。)

---

## 六、对整个实验结论的修正

| 源 | 物理 | 之前预测 | **H100 双卡实测** |
|---|---|---|---|
| 本地 HBM(mode 0) | 本地 | 正常 | DONE ✓ |
| C2C Grace(mode 3,GH200) | 一致链路 | 正常 | DONE ✓(已验证) |
| MIG peer 实例(GH200) | 同物理 GPU | — | DONE ✓(共享 L2 fabric) |
| **peer GPU NVLink(mode 1)** | **两块独立物理 GPU** | **挂卡** | **DONE ✓(本配置未复现挂卡)** |

**核心修正:在 H100 SXM5 + CUDA 12.8 + driver 580 这套配置上,"NVLink peer 上 TMA multicast 会挂卡"未能复现 —— 恰恰相反,TMA multicast 从 peer GPU 内存读取稳定成功。** 根因是 TMA 作为主动 bulk DMA,会把 peer 数据经 NVLink 搬到本地 SMEM,`complete_tx` 由数据到达驱动,不存在"无本地 L2 源"的死锁条件。

### 严谨边界(不过度外推)
- 本结论限定于:**本探针的 `cp.async.bulk.tensor.2d...multicast::cluster` 用法 + H100 SXM5 + CUDA 12.8 / driver 580**。
- folklore 里的"挂卡"可能源于:不同的多播机制(如 `multimem`/NVLS 对 peer 地址)、更老的 GPU 代(如 A100,无 TMA)、更老的 CUDA/驱动、或特定的非法用法。这些**未在本机覆盖**。
- 能确定的是:文档给出的那条**特定因果链(TMA multicast 因"peer 绕过本地 L2、无本地源"而 mbarrier 死锁)**,在本配置下不成立,且有 NVLink 流量 + 数据校验两路证据反驳。

---

## 七、复现命令

```bash
# 2x H100, NVLink。探针带数据校验(回写 SMEM 首字)。
nvcc -arch=sm_90a -O3 -lcuda tma_mc_probe.cu -o tma_mc_probe
./tma_mc_probe 0       # 本地 HBM:DONE, 0x01010101
./tma_mc_probe 1 1     # peer GPU1(NVLink):DONE, 0x01010101  <- 未挂卡

# 机制证据:mode 1 有 NVLink rx 流量,mode 0 没有
NCU=/usr/lib/nsight-compute/ncu
sudo $NCU --launch-count 1 --metrics nvlrx__bytes.sum,nvltx__bytes.sum ./tma_mc_probe 1 1
```

*报告完。探针源码 `tma_mc_probe.cu`(含数据校验)见本目录;远端在 `ubuntu@dual-h100-host:~/tma_exp/`。*
