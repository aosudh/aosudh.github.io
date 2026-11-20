---
title: "NVIDIA GPU PCI Device ID 全量对照：Rubin / Blackwell × Vera / Grace / NVSwitch"
published: 2026-06-24
updated: 2026-11-21
description: "把 lspci 里的 10DE:xxxx 翻译成芯片 / 架构 / 产品与具体用途：整合 pci.ids v2026.11.19、open-gpu-kernel-modules 620.73.04（含 g_nv_name_released.h 全部物理与 vGPU/MIG 子系统）、gpu-admin-tools、DCGM、edk2-nvidia 与 Linux 主线源码，按 Rubin → Blackwell → Hopper → Ada → Ampere 排序，并附 NVSwitch/15B3、Grace/Vera CPU 与可折叠历史 6 代老卡（共 1149 项）。"
image: "/assets/covers/nvidia-pci-ids.svg"
category: "资料与随笔"
tags: ["NVIDIA", "PCIe", "Rubin", "Blackwell", "Grace", "Vera", "NVSwitch", "速查表"]
pinned: true
draft: false
---

把 `lspci` 里那串 `10de:xxxx`（及配套互联 `15b3:xxxx`）翻译成「到底是哪颗芯片、哪代架构、哪个产品与具体用途」。正文按 **Rubin → Blackwell → Hopper → Ada Lovelace → Ampere** 从新到旧直出主力 GPU，随后汇总 **NVSwitch & `15B3` 互联**、**Grace / Vera / Tegra CPU** 与 **SM / Bit-6 规律**，末尾将 **Ampere 之前的 6 代历史老卡（Turing → Fermi，681 项）** 默认折叠收纳。

📊 **原始数据**：[下载全量多表 Excel（.xlsx · 17 个工作表 · 1149 个 PCI ID · 156 KB）](/assets/files/nvidia-gpu-pci-ids-ampere-to-rubin.xlsx) ｜ [打开 1520px 实时搜索宽表页](/legacy-posts/nvidia-gpu-pci-device-ids.html)（本文表格亦支持右上角 **「⤢ 宽屏展开表格」**）

> [!NOTE]
> **最后更新日期：2026-11-21** ｜ 共收录 **1149** 条一手实证 PCI Device ID（GPU **1026** 条，其中开放驱动 `620.73.04` 官方收录 **299** 条；NVSwitch **33** 条；`15B3` 配套互联 **50** 条；Grace / Vera / Tegra CPU & SoC **40** 条）。
> - **数据快照**：`pci.ids v2026.11.19`（与实时 `pci-ids.ucw.cz` 一致，`systemd/hwdb` 与 `go-nvlib` 验证 `>= 0x2900` 零额外）、`open-gpu-kernel-modules 620.73.04`（含 `g_nv_name_released.h` 1,985 条物理+vGPU/MIG 编译表与 `detect-self-hosted.h`）、`NVIDIA/gpu-admin-tools`、`NVIDIA/DCGM`、`NVIDIA/edk2-nvidia`、`NVIDIA/nvtrust`、`torvalds/linux` 主线与 `CUDA 13.5 GA`。
> - **Rubin & Blackwell 核心实锤**：`3041`（`NVIDIA VR NVL72`）实锤 **280 GB 可用 HBM4**（7 档 MIG `2304–230A`）；`31C2`（`GB300 NVL72`）实锤 **278 GB 可用 HBM3e**（区分 **`21F1` Bianca 1399W** 与 **`20E5` Galaxy 1299W**）；`31C3` 区分 **`23AB` GB300-252**（DGX Station）；`2BB5` 含 **102 档 vGPU/MIG + 云游戏切片**；`2BB9`（RTX 6000D）实锤 **2×42 GB MIG** 与 **249W 液冷 LC（`2279`）**。
> - **明确未分配公开 ID 的边界**：截至 `2026-11-21`，**Rubin Ultra（`GR150` / Kyber NVL576，2027 H2）**、**消费级 Rubin（`GR20x`）**、**Rubin CPX（GTC 2026 已移出核心路线图）** 及 **RTX 5080 SUPER / 5070 Ti SUPER** 均尚未分配公开 PCI ID。

## 一、Rubin（10 个 ID · sm_107 / CC 10.7）

交叉核验 **`pci.ids v2026.11.19`**、**`NVIDIA/open-gpu-kernel-modules 620.73.04`**（含编译头文件 `g_nv_name_released.h` 与 `detect-self-hosted.h`）、**`NVIDIA/gpu-admin-tools`**、**`NVIDIA/edk2-nvidia`**、**`NVIDIA/DCGM`** 与 **CUDA 13.5 GA** 官方文档，Rubin 代际目前公开可信的一手 PCI Device ID 共 **10 个**（GR100 7 个 + GR102 3 个）：

- **官方架构实证**：Compute Capability = **`sm_107`（CC 10.7，含 `sm_107a` / `sm_107f`）**；TSMC 3nm 双裸片 CoWoS-L 封装（336B 晶体管，GR100 = 2× GR102 dielet，每 dielet 4×NVDEC / 4×NVJPG / 1×OFA）；单卡 **288 GB HBM4**（22 TB/s）、**50 PFLOPS NVFP4**、**NVLink 6（3.6 TB/s）**、每 SM 328 KB 共享内存。
- **首发量产 `3041` 显存与 MIG 实锤**：`g_nv_name_released.h` 收录物理卡 `10DE:3041 · 10DE:221A`（`NVIDIA VR NVL72`）及 **`2304–230A` 共 7 档 MIG/vCS**（`1-35C ~ 7-280C / 280C`），源码直接实锤单卡可用 HBM4 为 **280 GB**。
- **Endpoint vs Self-Hosted 分区**：`detect-self-hosted.h` 硬编码 `3040–307F`（GR100）与 `30C0–30FF`（GR102）为 Vera C2C Self-Hosted 段；非 C2C 端点段 `3000–303F` 含 **`3002`**（`2277` SXM）与 **`3021`**（`PCIe Faber`）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 用途 / 规格 / 子系统 / 一手来源 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3000 | GR100 | sm_107 | GPU | GR100 [Reserved Dev ID A] | — | 【硅前保留·Endpoint】GR100 Endpoint 保留基准 ID（edk2-nvidia 划定 3000–303F 为非 C2C 端点段；open-gpu 落地 arch/rubin/kern_gpu_gr100.c） | — |
| 3002 | GR100 | sm_107 | GPU | GR100 | — | 【数据中心·x86 HGX SXM】GR100 非 C2C 独立 SXM 形态（gpu-admin-tools 实锤 is_sxm、subsys 10DE:2277），用于常规 HGX/x86 主机侧 Rubin 算力节点；尚未进入 open-gpu 620.73.04 发行列表 | — |
| 3021 | GR100 | sm_107 | GPU | GR100 [PCIe Faber] | GR100 PCIe (Faber) (社区) | 【数据中心·PCIe 扩展卡】GR100 PCIe 形态/平台，pci.ids 标注代号 'PCIe Faber'（位于 3000–303F Endpoint 段），面向标准机架服务器的 PCIe 推理与计算部署；尚未进入开放驱动 | — |
| 3040 | GR100 | sm_107 | GPU | GR100 [Reserved Dev ID B] | — | 【硅前保留·Self-Hosted】GR100 Self-Hosted 保留基准 ID（detect-self-hosted.h 划定 3040–307F 为 Vera+Rubin C2C 一致性内存段） | — |
| 3041 | GR100 | sm_107 | GPU | GR100 [VR NVL72] | NVIDIA VR NVL72 | 【旗舰机架·超大规模 AI 训练/Agentic 推理】Vera Rubin NVL72 首发量产 ID（open-gpu 620.73.04 ✓ / DCGM ✓）；物理 subsys 221A（has_c2c+is_sxm），双芯 TSMC 3nm 336B 晶体管·288GB HBM4 (22TB/s)·50 PFLOPS NVFP4·NVLink 6 (3.6TB/s)；g_nv_name_released.h 含 2304–230A 7 档 MIG/vCS（实锤 280GB 可用显存，1-35C~7-280C） | ✓ |
| 307E | GR100 | sm_107 | GPU | GR100 | — | 【数据中心·Vera+Rubin 变体/验证】GR100 Self-Hosted C2C+SXM 变体（gpu-admin-tools subsys 221A，DCGM 已内置 Rubin 诊断 profile），用于 Vera Rubin 平台验证与 OEM 定制 | — |
| 307F | GR100 | sm_107 | GPU | GR100 | — | 【数据中心·Vera+Rubin 内部/诊断】GR100 Self-Hosted 段末尾 ID（DCGM 已内置 Rubin 诊断 profile，detect-self-hosted.h 纳入 3040–307F 区间），尚未在 pci.ids 赋予产品名 | — |
| 3080 | GR102 | sm_107 | GPU | GR102 [Reserved Dev ID A] | — | 【硅前保留·GR102 Endpoint】GR102 基础硅片 Endpoint 保留基准（open-gpu 落地 arch/rubin/kern_gpu_gr102.c；GR100 封装由 2× GR102 裸片组成，每 dielet 含 4×NVDEC/4×NVJPG/1×OFA） | — |
| 30C0 | GR102 | sm_107 | GPU | GR102 [Reserved Dev ID B] | — | 【硅前保留·GR102 Self-Hosted】GR102 Self-Hosted 保留基准（detect-self-hosted.h 划定 30C0–30FF 为 GR102 C2C 段） | — |
| 30FF | GR102 | sm_107 | GPU | GR102 | — | 【数据中心·GR102 Vera+Rubin 变体】GR102 Self-Hosted C2C+SXM 变体（gpu-admin-tools 实锤 has_c2c+is_sxm，subsys 10DE:221B / 221C），用于单裸片/定制 Vera+Rubin 平台验证 | — |

### 1.1 Rubin 架构硬件规格与路线图可信度边界

| 代号 / 维度 | 实锤状态、硬件规格与用途定位（严格区分已证实 vs 规划中） |
| --- | --- |
| **GR100（7 个公开 ID）** | **已量产进入开放驱动 `620.73.04`**：TSMC 3nm 双裸片 CoWoS-L 封装（336B 晶体管），288 GB HBM4（12-Hi，22 TB/s，驱动实锤 **280 GB 可用**），50 PFLOPS NVFP4，NVLink 6（3.6 TB/s）。主力 **`3041`**（`NVIDIA VR NVL72`，`221A` + 7 档 MIG/vCS `2304–230A`）用于 72 卡液冷整柜前沿大模型训练与 Agentic 推理；**`3002`**（`2277` SXM 非 C2C）与 **`3021`**（`PCIe Faber`）覆盖独立 x86/PCIe 服务器；`307E / 307F` 已入 DCGM 诊断。 |
| **GR102（3 个公开 ID）** | **驱动源码已落地 `kern_gpu_gr102.c`**：GR100 封装基础裸片（GR100 = 2× GR102 dielet，每 dielet 4×NVDEC/4×NVJPG/1×OFA）；`3080 / 30C0` 为 Endpoint/Self-Hosted 保留基准，**`30FF`**（`subsys 221B/221C`）为 Vera+Rubin C2C+SXM 验证变体。 |
| **Rubin Ultra（GR150 · H2 2027）** | **路线图已官宣，尚无公开 PCI ID**：面向 Kyber 机架（NVL576，~600 kW 级），采用 4 颗计算裸片封装，~100 PFLOPS NVFP4，最高 **1 TB HBM4e**，配套 `15B3:D2FA` NVLink-7 Switch 与 BlueField-4 KV-Cache 卸载。 |
| **Rubin CPX（路线图已调整）** | **尚无公开 PCI ID，GTC 2026 已移出核心路线图**：原 2025 年底预告为 128 GB GDDR7 长上下文 Prefill 专用卡（NVL144 CPX），GTC 2026 转向高密度 HBM4 集群 + Groq 3 LPU/LPX 低延迟解码架构。 |
| **消费级 Rubin（GR20x）** | **尚无公开 PCI ID**：仍处于未来路线阶段，目前所有公开 `30xx` ID 全部属于数据中心 GR100/GR102。 |
| **配套 Vera CPU 与互联** | **Vera CPU（`TB500`）**：88 核自研 Olympus 核心 + 不对称 SMT + Caliptra RoT，PCIe RP `10DE:2F95–2F99`；整柜配套 36× Vera CPU + 36× **NVLink-6 Switch（`15B3:D2F8`）** + **ConnectX-9（`15B3:1025`）** + **BlueField-4（`15B3:A2DD–A2DF`）**。 |

## 二、Blackwell & Blackwell Ultra（91 个 ID · sm_100 / 103 / 110 / 120 / 121）

一个代号、五个 SM，涵盖超大规模数据中心整柜（`GB100 / GB110`）、个人桌面超算（`DGX Station GB300` / `DGX Spark GB10`）、企业级虚拟化服务器（`RTX PRO 6000/4500 Server` 与中国合规 `RTX 6000D`）、专业工作站与工业 MXM 嵌入模块、Arm AI PC（`RTX Spark N1X`）、机器人（`Jetson AGX Thor`）及消费级 GeForce RTX 50 全系：

- **数据中心 Blackwell（`GB100 / GB102` · `sm_100`）**：`2901`（HGX/DGX B200 180GB，含 1000W/999W/850W 与 8 档 MIG）、`2909`（HGX B200 168GB `22EB`，7×24GB 均分 MIG）、`2941`（GB200 NVL72/36，186GB 可用，1199W，`nvgrace-gpu` VFIO ✓）、`2920 / 29BC`（B100）、`29BB`（**DRIVE P2021** 50W 自动驾驶）。
- **Blackwell Ultra（`GB110 / GB112 / GB120` · `sm_103`）**：`3182`（HGX B300 SXM6 风冷 1099W，269GB 可用）、`31C2`（**GB300 NVL72**，278GB 可用；子系统区分 **`21F1` Bianca 1399W** 与 **`20E5` Galaxy 1299W**）、`31C3`（**DGX Station GB300-252**，252GB HBM3e + 496GB LPDDR5X = 748GB）、`31A1`（**GB300 Max-Q 1199W**，`detect-self-hosted.h` 特例 C2C）、`3183/3184/3224/323E/3340`（SXM 变体与 `GB112/GB120`）。
- **专业工作站 / 服务器 / 工业嵌入（`sm_120`）**：`2BB5`（RTX PRO 6000 Server 96GB 600W + **102 档 vGPU/MIG + 云游戏 slice**）、`2BB9`（RTX 6000D 84GB，含 **249W 液冷 LC `2279`** 与 **2×42GB MIG**）、`2BBD`（RTX PRO 5500 84GB ECC ✓）、`2BB3`（RTX PRO 5000 `204D` 48GB / `227A` 72GB + 26 档 vGPU）、`2C3A`（RTX PRO 4500 Server 单槽 32GB 165W + 46 档 vGPU）、工作站/移动/MXM 嵌入全系。
- **消费级 RTX 50 & 端侧（`sm_120 / 110 / 121`）**：完整区分双硅片分档（`RTX 5070` `2C09/2F04`；`RTX 5060` `2F06/2D05`）、中国合规（`5090 D 2B87` / `5090 D V2 2B8C`）、未发售首个 SUPER（`2F02` RTX 5070 SUPER）、`RTX Spark N1X`（`2E03/2E06/2E13`）、`DGX Spark GB10`（`2E12`）与 `Jetson AGX Thor`（`2B00` / `T268 3400`）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 用途 / 规格 / 子系统 / 一手来源 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2900 | GB100 | sm_100 | GPU | GB100 [Reserved Dev ID A] | — | 【硅前保留·Endpoint】GB100 Endpoint 保留基准 ID（edk2-nvidia 划定 2901–293F 为非 C2C 端点段） | — |
| 2901 | GB100 | sm_100 | GPU | GB100 [B200] | NVIDIA B200 | 【旗舰数据中心·HGX/DGX B200 训练与推理】8 卡 HGX/DGX B200 主力 ID（open-gpu ✓）；180GB HBM3e·8TB/s·NVLink 5 (1.8TB/s)；物理 subsys 1999(PG525-220 1000W)/199B(999W)/20DA(850W 低功耗风冷)，另含 21D7–21EA 8 档 MIG/vCS（1-23CME~7-180C） | ✓ |
| 2909 | GB100 | sm_100 | GPU | GB100 [HGX B200 168GB] | NVIDIA B200 | 【数据中心·MIG 均分型 HGX B200 168GB】HGX B200 168GB 专属 ID（open-gpu ✓ subsys 22EB，DCGM 1000W）；168GB HBM3e 精确对应 7×24GB 均分 MIG 切分，面向多租户云推理与细分算力租赁 | ✓ |
| 290A | GB100 | sm_100 | GPU | GB100 [B200] | B200 (GB100 variant) (社区) | 【数据中心·B200 变体】gpu-admin-tools 与 pci.ids v2026.11.19 均确认为数据中心 B200 SKU（2901–293F Endpoint 段），尚未单独出现在 open-gpu 620.73.04 README | — |
| 2920 | GB100 | sm_100 | GPU | GB100 [TS4 / B100] | B100 (TS4 sample) (社区) | 【数据中心·HGX B100 (700W/850W)】面向既有 700W 风冷 HGX 机箱原位升级的 B100 SXM（DCGM 代号 'TS4' 700W / subsys 197F 850W；gat subsys 197F/20DE is_sxm），用于过渡期 AI 训练与大批量推理 | — |
| 2924 | GB100 | sm_100 | GPU | GB100 | — | 【数据中心·GB100 PCIe 样片/定制】GB100 PCIe 形态 ID（gpu-admin-tools 实锤 is_pcie，subsys 18B6/20D4），非公开零售 SKU，用于 PCIe 平台验证或超大规模定制 | — |
| 2925 | GB100 | sm_100 | GPU | GB100 | — | 【数据中心·GB100 PCIe 样片/定制】GB100 PCIe 形态 ID（gpu-admin-tools 实锤 is_pcie，subsys 18B7），内部/合作验证形态 | — |
| 293D | GB100 | sm_100 | GPU | GB100 | — | 【数据中心·GB100 混合形态验证】gpu-admin-tools 同时记录 PCIe(18B6) 与 SXM(197F/1999) 子系统，属 GB100 工程/Bring-up 通用验证 ID | — |
| 2940 | GB100 | sm_100 | GPU | GB100 [Reserved Dev ID B] | — | 【硅前保留·Self-Hosted】GB100 Self-Hosted 保留基准 ID（detect-self-hosted.h 划定 2940–297F 为 Grace+GB100 C2C 段） | — |
| 2941 | GB100 | sm_100 | GPU | GB100 [HGX GB200] | NVIDIA GB200 | 【旗舰机架·GB200 NVL72/NVL36 超大规模训练与推理】Grace+Blackwell 超级芯片主力 ID（open-gpu ✓ / Linux nvgrace-gpu VFIO ✓ / DCGM 1199W）；186GB 可用 HBM3e·NVLink-C2C 900GB/s；含 6 物理子系统（2046/20CA/20D5/21C9/21CA/22C4）及 20CB–20D2 8 档 MIG/vCS（1-23CME~7-186C） | ✓ |
| 297E | GB100 | sm_100 | GPU | GB100 | — | 【数据中心·GB200 C2C 变体】TH500+GB100 Self-Hosted C2C+SXM 变体（gpu-admin-tools subsys 2046，detect-self-hosted.h 纳入 2940–297F），用于 GB200 工程验证 | — |
| 2980 | GB102 | sm_100 | GPU | GB102 [Reserved Dev ID A] | — | 【硅前保留·GB102 Endpoint】GB102 Endpoint 保留基准 ID（edk2-nvidia 划定 2981–29BF 为 GB102 端点段） | — |
| 29BB | GB102 | sm_100 | GPU | GB102 [DRIVE P2021] | NVIDIA DRIVE P2021 | 【汽车自动驾驶·DRIVE P2021】GB102 车载/自动驾驶计算平台官方 ID（open-gpu ✓ subsys 10DE:207C，DCGM 目标功耗 50W），用于 NVIDIA DRIVE 自动驾驶域控与车载 AI 研发验证 | ✓ |
| 29BC | GB102 | sm_100 | GPU | GB102 [B100] | B100 (GB102 variant) (社区) | 【数据中心·GB102 B100 (350W)】GB102 精简功耗 B100 变体（DCGM 350W；gpu-admin-tools 录有 PCIe 1997/1998、SXM 1985、C2C 2045），面向低功耗数据中心推理/测试 | — |
| 29C0 | GB102 | sm_100 | GPU | GB102 [Reserved Dev ID B] | — | 【硅前保留·GB102 Self-Hosted】GB102 Self-Hosted 保留基准 ID（edk2-nvidia 划定 29C1–29FF 为 TH500+GB102 C2C 段） | — |
| 29F1 | GB102 | sm_100 | GPU | GB102 | — | 【数据中心·GB102 SXM 变体】GB102 SXM 形态 ID（gpu-admin-tools 实锤 is_sxm，subsys 20DC），位于 29C1–29FF 段，未公开发售 | — |
| 3180 | GB110 | sm_103 | GPU | GB110 [Reserved Dev ID A] | — | 【硅前保留·GB110 Endpoint】Blackwell Ultra GB110 Endpoint 保留基准 ID（edk2-nvidia 划定 3181–31BF 为非 C2C 端点段，特例 31A1 除外） | — |
| 3182 | GB110 | sm_103 | GPU | GB110 [B300 SXM6 AC] | NVIDIA B300 SXM6 AC | 【旗舰数据中心·HGX B300 风冷 SXM6】8 卡 HGX B300 主力 ID（open-gpu ✓ subsys 20E6，DCGM 1099W，最高 1100W）；288GB HBM3e 12-Hi (8TB/s)·FP4 推理与长思维链强化；g_nv_name_released.h 含 22CB–22D2 8 档 MIG/vCS（实锤 269GB 可用显存，1-34CME~7-269C） | ✓ |
| 3183 | GB110 | sm_103 | GPU | GB110 | — | 【数据中心·B300 SXM 变体】GB110 B300 独立 SXM 变体（gpu-admin-tools 实锤 is_sxm，subsys 22F2），面向 OEM/液冷或定制 HGX B300 基板 | — |
| 3184 | GB110 | sm_103 | GPU | GB110 | — | 【数据中心·B300 SXM 变体】GB110 B300 独立 SXM 变体（gpu-admin-tools 实锤 is_sxm，subsys 22F3），面向特定区域或客户定制 SXM 模块 | — |
| 31A1 | GB110 | sm_103 | GPU | GB110 [GB300 MaxQ] | GB300 Max-Q (社区) | 【旗舰机架·GB300 Max-Q 能效版】能效上限版 Grace+GB300（detect-self-hosted.h 与 edk2-nvidia 均专门硬编码 0x31A1 为 Self-Hosted C2C 特例；gat subsys 2274 C2C+SXM，DCGM 1199W），面向功耗受限机房的 GB300 集群部署 | — |
| 31C0 | GB110 | sm_103 | GPU | GB110 [Reserved Dev ID B] | — | 【硅前保留·GB110 Self-Hosted】GB110 Self-Hosted 保留基准 ID（detect-self-hosted.h 划定 31C0–31FF 为 Grace+GB110 C2C 段） | — |
| 31C2 | GB110 | sm_103 | GPU | GB110 [GB300] | NVIDIA GB300 | 【旗舰机架·GB300 NVL72 液冷超算】72 卡全液冷 GB300 NVL72 主力 ID（open-gpu ✓ / Linux nvgrace-gpu VFIO ✓）；288GB HBM3e (278GB 可用)·每机架 20TB HBM3e·132–155kW；物理 subsys 区分 21F1 (Bianca 1399W) 与 20E5 (Galaxy 1299W)，另含 22D3–22DA 8 档 MIG/vCS（1-35CME~7-278C） | ✓ |
| 31C3 | GB110 | sm_103 | GPU | GB110 [GB300-252] | NVIDIA GB300 / NVIDIA GB300-252 | 【桌面 AI 超算·DGX Station GB300】桌面级 Grace+GB300 超算主力 ID（open-gpu ✓）；subsys 23AB = NVIDIA GB300-252（252GB HBM3e @ 7.1TB/s + 496GB LPDDR5X = 748GB 一致性内存，20 PFLOPS FP4，~1600W），用于本地 1T 参数推理与 200B–400B 微调；另含 subsys 22F8 (GB300) | ✓ |
| 31FE | GB110 | sm_103 | GPU | GB110 | — | 【数据中心·GB110 内部/验证】GB110 SXM 变体（gpu-admin-tools subsys 20E5 is_sxm，位于 31C0–31FF 段），用于 GB300 平台验证 | — |
| 3200 | GB112 | sm_103 | GPU | GB112 | — | 【硅前保留·GB112】Blackwell Ultra 衍生芯片 GB112 基准 ID（open-gpu rmconfig.h 已开启 RMCFG_CHIP_GB112=1），具体商用形态尚未官宣 | — |
| 3224 | GB112 | sm_103 | GPU | GB112 | — | 【数据中心·GB112 SXM 变体】GB112 SXM 形态 ID（gpu-admin-tools 实锤 is_sxm，subsys 215F），尚未进入 open-gpu 发行表 | — |
| 323E | GB112 | sm_103 | GPU | GB112 | — | 【数据中心·GB112 SXM 变体】GB112 SXM 形态 ID（gpu-admin-tools 实锤 is_sxm，subsys 215F），工程/验证变体 | — |
| 3340 | GB120 | sm_103 | GPU | GB120 | — | 【硅前保留·GB120 Self-Hosted】edk2-nvidia 明确预留 3341–337F 为 TH500+GB120 Self-Hosted C2C 段（3340 为段基准），尚无量产产品公开 | — |
| 2B00 | GB10B | sm_110 | GPU | GB10B [Jetson AGX Thor] | — | 【具身智能/机器人·Jetson AGX Thor】Tegra T264 (CS_NVIDIA_T264) 集成 Blackwell iGPU；14 核 Neoverse-V3AE + 128GB LPDDR5X (273GB/s)·2,070 FP4 TFLOPS (稀疏)·40–130W 可调；用于人形机器人、自主移动机器人与端侧物理 AI | — |
| 3400 | GB10B | sm_110 | GPU | GB10B [Tegra RP iGPU] | Tegra RP iGPU (GB10B) (社区) | 【嵌入式/车载 SoC·T268】open-gpu nvcst.h 实锤为 CS_NVIDIA_T268 Tegra Root Port iGPU（pci.ids 归入 GB10B），用于下一代 Tegra/DRIVE 嵌入式平台（open-gpu rmconfig.h 同步出现 GB10C/GB20C 车载虚拟化芯片） | — |
| 2B85 | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090] | NVIDIA GeForce RTX 5090 | 【消费旗舰·4K 极限游戏/本地 AI 开发】GeForce RTX 5090（open-gpu ✓）；21,760 CUDA·32GB GDDR7 (512-bit, 1.79TB/s)·575W·PCIe 5.0 x16；旗舰 4K 路径追踪游戏、DLSS 4、个人大模型/文生视频推理 | ✓ |
| 2B87 | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090 D] | NVIDIA GeForce RTX 5090 D | 【中国合规旗舰·RTX 5090 D】面向中国市场出口合规初代版（open-gpu ✓）；21,760 CUDA·32GB GDDR7 (512-bit)·575W，通过固件/AI TOPS 限速满足出口规则，定位高端游戏与 3D 渲染 | ✓ |
| 2B8C | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090 D V2] | NVIDIA GeForce RTX 5090 D v2 | 【中国合规改款·RTX 5090 D V2】GB202-240 改款（open-gpu ✓）；保留 21,760 CUDA 但显存缩减为 24GB GDDR7 (384-bit)·575W，进一步降低带宽/容量以合规满足中国高端游戏与创作市场 | ✓ |
| 2BB1 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Workstation Edition] | NVIDIA RTX PRO 6000 Blackwell Workstation Edition | 【专业旗舰工作站·RTX PRO 6000 Workstation】桌塔工作站满血旗舰（open-gpu ✓ subsys 204B，覆 Dell/HP/NVIDIA/Lenovo）；24,064 CUDA·96GB GDDR7 ECC (512-bit, 1.79TB/s)·600W 双槽主动散热；面向本地 70B+ 大模型开发、工业仿真、8K 影视特效与数字孪生 | ✓ |
| 2BB2 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000D Blackwell Workstation Edition] | — | 【中国合规专业工作站·RTX PRO 6000D Workstation】中国市场合规版工作站 SKU（pci.ids 已录，尚未单独入 open-gpu README）；基于削减版 GB202 (84GB GDDR7 / 448-bit / 无 NVLink)，满足国内企业工作站 AI 与 CAD 需求 | — |
| 2BB3 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 5000 Blackwell / RTX PRO 5000 72GB Blackwell] | NVIDIA RTX PRO 5000 Blackwell / NVIDIA RTX PRO 5000 72GB Blackwell | 【专业工作站·RTX PRO 5000 (48GB / 72GB)】一 ID 双容量（open-gpu ✓，DCGM 349W 目标，300W 级）；14,080 CUDA；subsys 204D = 48GB 版，subsys 227A = 72GB 版（g_nv_name_released.h 含 26 档 vGPU/MIG 2324–2372，2Q~72Q），面向多卡工作站本地 AI 推理、渲染与仿真 | ✓ |
| 2BB4 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Max-Q Workstation Edition] | NVIDIA RTX PRO 6000 Blackwell Max-Q Workstation Edition | 【多卡静音工作站·RTX PRO 6000 Max-Q】低功耗单塔多卡旗舰（open-gpu ✓ subsys 204C；DCGM 代号 'Galaxy TS2' 299W，标称 300W）；保持 96GB GDDR7 ECC 大显存但功耗减半，专为单机 2–4 卡密集插槽工作站与低噪实验室设计 | ✓ |
| 2BB5 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Server Edition] | NVIDIA RTX PRO 6000 Blackwell Server Edition | 【企业级全能服务器卡·RTX PRO 6000 Server】数据中心被动散热旗舰 PCIe 卡（open-gpu ✓ subsys 204E/220B；DCGM 'PG153 SKU 210' 600W）；96GB GDDR7 ECC·支持 4×24GB MIG；g_nv_name_released.h 含 102 档 vGPU/MIG（2160–23A2，2GB~96GB Q/A/B/C/E）+ 21A6/21A7 云游戏切片，覆盖企业 LLM 推理、Omniverse 渲染、VDI 与云游戏 | ✓ |
| 2BB9 | GB202 | sm_120 | GPU | GB202GL [RTX 6000D] | NVIDIA RTX 6000D | 【中国合规数据中心推理卡·RTX 6000D】中国出口合规服务器/工作站 GPU（open-gpu ✓）；19,968 CUDA·84GB GDDR7 (448-bit, ~1.4TB/s, 无 NVLink)；物理 subsys 2091/2092 (600W) 与 2279 (DCGM 'RTX6000D LC' 249W 液冷低功耗版)；含 12 档 MIG/vGPU（实锤 2×42GB MIG）+ 22EE/22EF 云游戏切片 | ✓ |
| 2BBC | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000D Blackwell Max-Q Workstation Edition] | — | 【中国合规多卡工作站·RTX PRO 6000D Max-Q】中国合规 84GB 版低功耗 Max-Q 工作站形态（pci.ids 已录，尚未单独入 open-gpu README），面向国内多卡工作站部署 | — |
| 2BBD | GB202 | sm_120 | GPU | GB202GL [RTX PRO 5500 Blackwell Workstation Edition] | NVIDIA RTX PRO 5500 Blackwell Workstation Edition | 【专业工作站·RTX PRO 5500 (84GB ECC)】2026 年 9 月新增大显存工作站主力（open-gpu 620.x ✓ subsys 23AE，覆 Dell/HP/NVIDIA/Lenovo）；21,760 CUDA·84GB GDDR7 ECC (416-bit)·600W·支持 2×42GB MIG；填补 5000(72GB) 与 6000(96GB) 之间空白，面向中型企业大模型微调与重度渲染 | ✓ |
| 2C02 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5080] | NVIDIA GeForce RTX 5080 | 【次旗舰游戏/创作·RTX 5080】GB203 满血桌面卡（open-gpu ✓）；10,752 CUDA·16GB GDDR7 (256-bit, 960GB/s)·360W·PCIe 5.0 x16；定位 4K 高帧游戏、视频剪辑（双 9 代 NVENC 4:2:2）与轻量本地 AI | ✓ |
| 2C05 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5070 Ti] | NVIDIA GeForce RTX 5070 Ti | 【高端游戏/性价比 AI·RTX 5070 Ti】GB203 精简桌面卡（open-gpu ✓）；8,960 CUDA·16GB GDDR7 (256-bit, 896GB/s)·300W；2K/4K 游戏与 16GB 大显存个人 AI/Stable Diffusion 热门卡 | ✓ |
| 2C09 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5070] | NVIDIA GeForce RTX 5070 | 【中高端游戏·RTX 5070 (GB203 分档版)】利用更大 GB203 硅片屏蔽而成的 RTX 5070 第二分档（open-gpu ✓，与 GB205 2F04 规格对齐：6,144 CUDA·12GB GDDR7 192-bit·250W），用于优化晶圆良率供应 | ✓ |
| 2C18 | GB203 | sm_120 | GPU | GB203M / GN22 [GeForce RTX 5090 Max-Q / Mobile] | NVIDIA GeForce RTX 5090 Laptop GPU | 【旗舰游戏本·RTX 5090 Laptop】GB203M / GN22 移动旗舰（open-gpu ✓）；10,496 CUDA·24GB GDDR7 (256-bit)·95–175W；定位顶级移动游戏与便携式本地大模型推理（标准/Max-P 分支） | ✓ |
| 2C19 | GB203 | sm_120 | GPU | GB203M / GN22 [GeForce RTX 5080 Max-Q / Mobile] | NVIDIA GeForce RTX 5080 Laptop GPU | 【高端游戏本·RTX 5080 Laptop】GB203M / GN22 移动高端（open-gpu ✓）；7,680 CUDA·16GB GDDR7 (256-bit)·80–175W；面向 2K/4K 旗舰游戏本与移动内容创作 | ✓ |
| 2C2C | GB203 | sm_120 | GPU | GB6-256(N22W-ES-A1) | GN22 Mobile/Workstation 256-bit ES-A1 (社区) | 【工程样品·GB203M ES】pci.ids 标注 'GB6-256(N22W-ES-A1)'，256-bit 位宽 GB203M (RTX 5080/5090 Laptop 级) 早期工程样品，非量产零售 ID | — |
| 2C31 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4500 Blackwell] | NVIDIA RTX PRO 4500 Blackwell | 【中高端专业工作站·RTX PRO 4500】单槽/双槽企业主力（open-gpu ✓ subsys 2051，覆四大 OEM）；10,496 CUDA·32GB GDDR7 ECC (256-bit)·200W；定位 3D CAD/BIM、中等规模本地 AI 推理与多屏可视化 | ✓ |
| 2C33 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4000 Blackwell SFF Edition] | NVIDIA RTX PRO 4000 Blackwell SFF Edition | 【紧凑型工作站·RTX PRO 4000 SFF】半高双槽小机箱专业卡（open-gpu ✓ subsys 2053，覆四大 OEM）；8,960 CUDA·24GB GDDR7 ECC·70W 无需外接供电；专为 SFF 紧凑工作站、医疗影像主机与边缘机柜设计 | ✓ |
| 2C34 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4000 Blackwell] | NVIDIA RTX PRO 4000 Blackwell | 【单槽专业工作站·RTX PRO 4000】全高单槽主流专业卡（open-gpu ✓ subsys 2052，覆四大 OEM）；8,960 CUDA·24GB GDDR7 ECC·140W；面向建筑工程、工业设计、广播广电与 AI 推理 | ✓ |
| 2C38 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 5000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 5000 Blackwell Generation Laptop GPU | 【旗舰移动工作站·RTX PRO 5000 Laptop】移动工作站顶级卡（open-gpu ✓）；10,496 CUDA·24GB GDDR7 ECC (256-bit, 896GB/s)·80–175W；面向现场 AI 开发、重度 3D 渲染与便携式仿真 | ✓ |
| 2C39 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 4000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 4000 Blackwell Generation Laptop GPU | 【高端移动工作站·RTX PRO 4000 Laptop】移动工作站次旗舰（open-gpu ✓）；7,680 CUDA·16GB GDDR7 ECC (256-bit, 896GB/s)·38.7 TFLOPS FP32 / 1,334 AI TOPS·80–175W；面向移动 CAD/CAE 与实时光线追踪 | ✓ |
| 2C3A | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4500 Blackwell Server Edition] | NVIDIA RTX PRO 4500 Blackwell Server Edition | 【企业推理/虚拟化服务器卡·RTX PRO 4500 Server】单槽低功耗服务器 PCIe 5.0 卡（open-gpu ✓ subsys 21F4；DCGM 164W，标称 165W）；32GB GDDR7 (800GB/s)·g_nv_name_released.h 含 46 档 vGPU/MIG（2295–22C2，2GB~32GB），专为小模型 LLM 推理、向量数据库 (Milvus/cuVS)、Metropolis 视觉 AI 与视频转码优化 | ✓ |
| 2C58 | GB203 | sm_120 | GPU | GB203M / GN22-X11 [GeForce RTX 5090 Max-Q / Mobile] | NVIDIA GeForce RTX 5090 Laptop GPU | 【旗舰轻薄游戏本·RTX 5090 Laptop (Max-Q/GN22-X11)】RTX 5090 Laptop 第二移动 ID（open-gpu ✓，pci.ids 标 GN22-X11），用于不同功耗/OEM 配置（如轻薄 Max-Q 或特定主板识别） | ✓ |
| 2C59 | GB203 | sm_120 | GPU | GB203M / GN22-X9 [GeForce RTX 5080 Max-Q / Mobile] | NVIDIA GeForce RTX 5080 Laptop GPU | 【高端轻薄游戏本·RTX 5080 Laptop (Max-Q/GN22-X9)】RTX 5080 Laptop 第二移动 ID（open-gpu ✓，pci.ids 标 GN22-X9），用于不同 TGP/OEM 平台区分 | ✓ |
| 2C77 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 5000 Blackwell Embedded GPU] | NVIDIA RTX PRO 5000 Blackwell Embedded GPU | 【工业嵌入式 MXM·RTX PRO 5000 Embedded】MXM 3.1 Type B (82×105mm) 工业模块（open-gpu ✓）；10,496 CUDA·24GB GDDR7 ECC (896GB/s)·最高 ~150W·5+ 年长生命周期/宽温可选；面向医疗成像、航空航天、国防与高端边缘 AI 盒 | ✓ |
| 2C79 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 4000 Blackwell Embedded GPU] | NVIDIA RTX PRO 4000 Blackwell Embedded GPU | 【工业嵌入式 MXM·RTX PRO 4000 Embedded】MXM 3.1 Type B 工业模块（open-gpu ✓）；7,680 CUDA·16GB GDDR7 ECC (896GB/s)·最高 ~150W·长生命周期；用于工业检测、机器人上位机与舰载/车载加固计算 | ✓ |
| 2D04 | GB206 | sm_120 | GPU | GB206 [GeForce RTX 5060 Ti] | NVIDIA GeForce RTX 5060 Ti | 【甜品游戏/16GB 轻量 AI·RTX 5060 Ti】GB206 桌面主力（open-gpu ✓）；4,608 CUDA·8GB / 16GB GDDR7 (128-bit, 448GB/s)·180W；16GB 版本广泛用于个人高性价比本地大模型/生图推理及 2K 游戏 | ✓ |
| 2D05 | GB206 | sm_120 | GPU | GB206 [GeForce RTX 5060] | NVIDIA GeForce RTX 5060 | 【入门甜品游戏·RTX 5060 (标准 GB206 版)】GB206 主力甜品卡（open-gpu ✓）；3,840 CUDA·8GB GDDR7 (128-bit, 448GB/s)·145W·PCIe 5.0 x8；定位 1080p/2K 主流电竞与日常视频加速 | ✓ |
| 2D18 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5070 Max-Q / Mobile] | NVIDIA GeForce RTX 5070 Laptop GPU | 【主流游戏本·RTX 5070 Laptop】GB206M 移动卡主 ID（open-gpu ✓）；4,608 CUDA·8GB GDDR7 (128-bit)·50–115W；覆盖主流 14–16 寸游戏本与全能创作本 | ✓ |
| 2D19 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5060 Max-Q / Mobile] | NVIDIA GeForce RTX 5060 Laptop GPU | 【普及型游戏本·RTX 5060 Laptop】GB206M 入门主力移动卡（open-gpu ✓）；3,328 CUDA·8GB GDDR7 (128-bit)·45–115W；覆盖高性价比主流游戏本与学生全能本 | ✓ |
| 2D2C | GB206 | sm_120 | GPU | GB6-128 (N22Y-ES-A1) | GN22 Mobile/Workstation 128-bit ES-A1 (社区) | 【工程样品·GB206M ES】pci.ids 标注 'GB6-128 (N22Y-ES-A1)'，128-bit 位宽 GB206M (RTX 5060/5070 Laptop 级) 早期工程样品，非量产零售 ID | — |
| 2D30 | GB206 | sm_120 | GPU | GB206GL [RTX PRO 2000 Blackwell] | NVIDIA RTX PRO 2000 Blackwell | 【入门专业工作站·RTX PRO 2000】免外接供电半高/单槽专业卡（open-gpu ✓ subsys 2054，覆四大 OEM）；16GB GDDR7 ECC·70W；面向多屏金融终端、2D/3D CAD、轻量 AI 推理与紧凑工控机 | ✓ |
| 2D39 | GB206 | sm_120 | GPU | GB206GLM [RTX PRO 2000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 2000 Blackwell Generation Laptop GPU | 【轻薄移动工作站·RTX PRO 2000 Laptop】GB206GLM 轻薄专业本 GPU（open-gpu ✓）；3,328 CUDA·8GB GDDR7 (128-bit, 384GB/s)·17.7 TFLOPS FP32 / 572 AI TOPS·45–115W；适配 14–16 寸移动工作站 | ✓ |
| 2D58 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5070 Max-Q / Mobile] | NVIDIA GeForce RTX 5070 Laptop GPU | 【主流轻薄游戏本·RTX 5070 Laptop (Max-Q 变体)】RTX 5070 Laptop 第二移动 ID（open-gpu ✓），用于低功耗 Max-Q / 特定 OEM 笔记本识别 | ✓ |
| 2D59 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5060 Max-Q / Mobile] | NVIDIA GeForce RTX 5060 Laptop GPU | 【普及型轻薄游戏本·RTX 5060 Laptop (Max-Q 变体)】RTX 5060 Laptop 第二移动 ID（open-gpu ✓），用于低功耗 Max-Q / OEM 配置区分 | ✓ |
| 2D79 | GB206 | sm_120 | GPU | GB206GLM [RTX PRO 2000 Blackwell Embedded GPU] | NVIDIA RTX PRO 2000 Blackwell Embedded GPU | 【工业嵌入式 MXM·RTX PRO 2000 Embedded】MXM 3.1 Type A (82×70mm) 紧凑工业模块（open-gpu ✓）；3,328 CUDA·8GB GDDR7 ECC (384GB/s)·PCIe 5.0 x8·长生命周期；用于便携医疗超声、工控视觉检测与边缘盒子 | ✓ |
| 2D83 | GB207 | sm_120 | GPU | GB207 [GeForce RTX 5050] | NVIDIA GeForce RTX 5050 | 【入门桌面卡·RTX 5050】GB207 桌面入门卡（open-gpu ✓）；2,560 CUDA·8GB GDDR6 (128-bit，区别于高阶 GDDR7)·130W·PCIe 5.0 x8；定位 1080p 入门电竞、亮机与 AV1/4:2:2 编解码加速 | ✓ |
| 2D98 | GB207 | sm_120 | GPU | GB207M [GeForce RTX 5050 Max-Q / Mobile] | NVIDIA GeForce RTX 5050 Laptop GPU | 【入门轻薄游戏本·RTX 5050 Laptop】GB207M 入门移动卡主 ID（open-gpu ✓）；2,560 CUDA·8GB GDDR7 (128-bit)·35–115W；适配轻薄全能本与入门级游戏本 | ✓ |
| 2DB8 | GB207 | sm_120 | GPU | GB207GLM [RTX PRO 1000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 1000 Blackwell Generation Laptop GPU | 【入门移动工作站·RTX PRO 1000 Laptop】GB207GLM 入门专业移动卡（open-gpu ✓）；2,560 CUDA·8GB GDDR7 (128-bit, ~384GB/s)·13.6 TFLOPS FP32 / 440 AI TOPS·35–115W；面向 14 寸轻薄商用/设计本 | ✓ |
| 2DB9 | GB207 | sm_120 | GPU | GB207GLM [RTX PRO 500 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 500 Blackwell Generation Laptop GPU | 【超轻薄移动工作站·RTX PRO 500 Laptop】GB207GLM 超低功耗专业移动卡（open-gpu ✓）；1,792 CUDA·6GB GDDR7 (96-bit, 288GB/s)·9.2 TFLOPS FP32 / 294 AI TOPS·35–75W；面向超轻薄企业 CAD/AI 办公本 | ✓ |
| 2DD8 | GB207 | sm_120 | GPU | GB207M [GeForce RTX 5050 Max-Q / Mobile] | NVIDIA GeForce RTX 5050 Laptop GPU | 【入门超薄本·RTX 5050 Laptop (Max-Q 变体)】RTX 5050 Laptop 第二移动 ID（open-gpu ✓），用于更低 TGP Max-Q 超薄本平台 | ✓ |
| 2DF9 | GB207 | sm_120 | GPU | GB207GLM [RTX PRO 500 Blackwell Embedded GPU] | NVIDIA RTX PRO 500 Blackwell Embedded GPU | 【紧凑工业嵌入式·RTX PRO 500 Embedded】GB207GLM 低功耗工业嵌入模块（open-gpu ✓）；6GB GDDR7 (96-bit)·35–75W·长生命周期；用于自助终端、轻量化工业视觉、轨交显控与医疗便携设备 | ✓ |
| 2F02 | GB205 | sm_120 | GPU | GB205 [GeForce RTX 5070 SUPER] | GeForce RTX 5070 SUPER (社区) | 【未发售·RTX 5070 SUPER】首个浮出水面的 RTX 50 SUPER PCI ID（2026-10-28 并入 pci.ids，尚未入 open-gpu 620.73.04）；基于 GB205，预计 2027 年初推出（定位 18GB GDDR7 中高端升级款，规格待 NVIDIA 官宣） | — |
| 2F04 | GB205 | sm_120 | GPU | GB205 [GeForce RTX 5070] | NVIDIA GeForce RTX 5070 | 【主流中高端游戏·RTX 5070 (标准 GB205 版)】RTX 5070 主力硅片版本（open-gpu ✓）；6,144 CUDA·12GB GDDR7 (192-bit, 672GB/s)·250W；定位 2K 高刷游戏、DLSS 4 多帧生成与个人 AIGC | ✓ |
| 2F06 | GB205 | sm_120 | GPU | GB205 [GeForce RTX 5060] | NVIDIA GeForce RTX 5060 | 【主流甜品游戏·RTX 5060 (GB205 分档版)】由更大 GB205 硅片降规封装的 RTX 5060 分档（open-gpu ✓，与 GB206 2D05 规格一致：3,840 CUDA·8GB GDDR7 128-bit·145–155W·PCIe 5.0 x8） | ✓ |
| 2F18 | GB205 | sm_120 | GPU | GB205M [GeForce RTX 5070 Ti Mobile] | NVIDIA GeForce RTX 5070 Ti Laptop GPU | 【中高端游戏本·RTX 5070 Ti Laptop】GB205M 移动卡主 ID（open-gpu ✓）；5,888 CUDA·12GB GDDR7 (192-bit)·60–140W；2K 高画质游戏本与轻度本地 AI 创作主力 | ✓ |
| 2F38 | GB205 | sm_120 | GPU | GB205GLM [RTX PRO 3000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 3000 Blackwell Generation Laptop GPU | 【主流移动工作站·RTX PRO 3000 Laptop】GB205GLM 专业移动卡（open-gpu ✓）；5,888 CUDA·12GB GDDR7 ECC (192-bit, 672GB/s)·29.1 TFLOPS FP32 / 992 AI TOPS·60–140W；面向中端专业设计本与工程仿真 | ✓ |
| 2F58 | GB205 | sm_120 | GPU | GB205M [GeForce RTX 5070 Ti Mobile] | NVIDIA GeForce RTX 5070 Ti Laptop GPU | 【中高端轻薄游戏本·RTX 5070 Ti Laptop (变体)】RTX 5070 Ti Laptop 第二移动 ID（open-gpu ✓），用于 Max-Q / 不同 OEM（如 ROG/Legion）功耗档位区分 | ✓ |
| 22E8 | GB202 | sm_120 | **HD Audio** | GB202 High Definition Audio Controller | — | 【板载伴生功能·HDMI/DP 音频】GB202 芯片（RTX 5090 / RTX PRO 6000/5500/5000）的 Function 1 高清音频控制器（非独立 GPU；VFIO 直通时需与 Function 0 同步解绑） | — |
| 22E9 | GB203 | sm_120 | **HD Audio** | GB203 High Definition Audio Controller | — | 【板载伴生功能·HDMI/DP 音频】GB203 芯片（RTX 5080/5070 Ti / RTX PRO 4500/4000）的 Function 1 高清音频控制器（非独立 GPU；VFIO 直通配套设备） | — |
| 22EB | GB206 | sm_120 | **HD Audio** | GB206 High Definition Audio Controller | — | 【板载伴生功能·HDMI/DP 音频】GB206 芯片（RTX 5060 Ti/5060 / RTX PRO 2000）的 Function 1 高清音频控制器（非独立 GPU；VFIO 直通配套设备） | — |
| 22EC | GB207 | sm_120 | **HD Audio** | GB207 High Definition Audio Controller | — | 【板载伴生功能·HDMI/DP 音频】GB207 芯片（RTX 5050 / RTX PRO 1000/500）的 Function 1 高清音频控制器（非独立 GPU；VFIO 直通配套设备） | — |
| 2F80 | GB205 | sm_120 | **HD Audio** | GB205 High Definition Audio Controller | — | 【板载伴生功能·HDMI/DP 音频】GB205 芯片（RTX 5070/5070 SUPER / RTX PRO 3000）的 Function 1 高清音频控制器（非独立 GPU；VFIO 直通配套设备） | — |
| 2E02 | GB20B | sm_121 | GPU | GB20B [JMJWOA-Generic-GPU] | — | 【工程样品·N1X 硅前】pci.ids 注释 '# N1X' 标为 JMJWOA-Generic-GPU（Windows on Arm 预量产 ID）；Linux quirks.c 对 2E00–2E3F 全段强制启用 PCIe ATS 模拟 CXL.cache | — |
| 2E03 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (6144-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (6144-core Blackwell RTX GPU) | 【Arm AI PC·RTX Spark N1X 满血版】6,144 CUDA 核 Blackwell 集成 GPU + 20 核 Grace Arm CPU（open-gpu ✓，最高 128GB LPDDR5X，45–80W 笔记本 / 140W 迷你主机），面向 Windows 11 on Arm AI PC 端侧大模型推理、本地开发与轻度 3D 创作 | ✓ |
| 2E06 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (5120-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (5120-core Blackwell RTX GPU) | 【Arm AI PC·RTX Spark N1X 精简版】5,120 CUDA 核 Blackwell 集成 GPU + 20 核 Grace Arm CPU（open-gpu ✓，Linux quirks.c ATS 段 2E00–2E3F），定位主流 Arm AI 笔记本与迷你主机 | ✓ |
| 2E12 | GB10 | sm_121 | GPU | GB20B [GB10] | NVIDIA GB10 | 【个人 AI 超算·NVIDIA DGX Spark (GB10)】桌上型个人 AI 开发者超算（open-gpu ✓ subsys 10DE:21EC）；20 核 Grace CPU + Blackwell GPU·128GB 统一 LPDDR5X (273GB/s)·1 PFLOPS FP4 (稀疏)，支持本地运行最高 200B 参数模型（双机互联达 405B）原型开发与微调 | ✓ |
| 2E13 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (6144-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (6144-core Blackwell RTX GPU) | 【Arm AI PC·RTX Spark N1X 6144 核 OEM/高功耗变体】6,144 CUDA 核版本第二 PCI ID（open-gpu ✓，同属 Linux quirks.c 2E00–2E3F ATS 区间），用于不同 TDP/OEM 平台区分 | ✓ |
| 2E2A | GB20B | sm_121 | GPU | GB20B [JMJWOA-Generic-GPU] | — | 【工程样品·N1X 硅前】pci.ids 注释 '# N1X' 标为 JMJWOA-Generic-GPU（与 2E02 对应的预量产测试 ID，位于 2E00–2E3F ATS 段） | — |

### 2.1 Blackwell & Rubin 关键子系统 ID（`VID:DID · SVID:SDID`）与 vGPU / MIG 精解表

同一个 PCI Device ID 往往承载多款不同显存容量、不同 TDP 功耗墙（风冷 vs 液冷）乃至上百个 vGPU/MIG 虚拟化切片（例如 `2BB3` 同时对应 RTX PRO 5000 48GB 与 72GB，`31C2` 区分 1399W Bianca 与 1299W Galaxy，`2BB5` 挂载 106 个子系统 ID）。下表直接提取自 **`open-gpu 620.73.04` `g_nv_name_released.h`**、**`NVIDIA/DCGM`** 与 **`NVIDIA/gpu-admin-tools`**，可用于 `lspci -nnv` 精确识别：

| 代际 | PCI DID | 芯片 | 物理子系统（SVID:SDID） | vGPU / MIG 虚拟化子系统（g_nv_name_released.h） | 官方 SKU 名称 | 核心规格与功耗 | 核心用途与部署定位 | 一手来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Rubin | 3041 | GR100 | 10DE:221A (C2C+SXM) | 2304–230A (7 档: 1-35C~7-280C / 280C) | NVIDIA VR NVL72 | 288GB HBM4 (280GB 可用) · 22TB/s · 50 PFLOPS NVFP4 · NVLink 6 | 72 卡全液冷前沿大模型训练、超大规模 Agentic 推理与多租户 MIG 云算力 | open-gpu g_nv_name_released.h ✓ + DCGM + gat |
| Rubin | 3002 | GR100 | 10DE:2277 (SXM 非 C2C) | — | GR100 Endpoint SXM | 独立 x86/HGX SXM 形态（非 Vera C2C） | 常规 x86 机头 HGX Rubin 训练与推理节点（尚未入开放驱动列表） | gpu-admin-tools |
| Rubin | 307E | GR100 | 10DE:221A (C2C+SXM) | — | GR100 Vera+Rubin 变体 | Self-Hosted C2C 形态（3040–307F 段） | Vera Rubin 平台验证 / OEM 诊断（DCGM 已内置 Rubin profile） | gpu-admin-tools + DCGM |
| Rubin | 30FF | GR102 | 10DE:221B / 221C (C2C+SXM) | — | GR102 Vera+Rubin 变体 | GR102 单裸片 / 定制 C2C+SXM（GR100 = 2×GR102） | Rubin 基础硅片验证与定制 C2C 形态 | gpu-admin-tools + detect-self-hosted.h |
| Blackwell Ultra | 31C2 | GB110 | 10DE:21F1 (Bianca) · 10DE:20E5 (Galaxy) | 22D3–22DA (8 档: 1-35CME~7-278C / 278C) | NVIDIA GB300 (NVL72) | 288GB HBM3e (278GB 可用) · Bianca 1399W / Galaxy 1299W · 液冷机架 | 72 卡整柜超大规模训练、长思维链推理 (Test-Time Scaling) 与多租户 MIG | open-gpu ✓ + DCGM + Linux nvgrace-gpu |
| Blackwell Ultra | 31C3 | GB110 | 10DE:23AB (GB300-252) · 10DE:22F8 (GB300) | — | NVIDIA GB300-252 (DGX Station GB300) | 252GB HBM3e (7.1TB/s) + 496GB LPDDR5X = 748GB · 20 PFLOPS FP4 · ~1600W | 桌面级个人/实验室 AI 超算：本地 1T 参数模型推理与 200B–400B 微调 | open-gpu ✓ + gat (C2C+SXM) |
| Blackwell Ultra | 3182 | GB110 | 10DE:20E6 (另有 gat 20E5/220C) | 22CB–22D2 (8 档: 1-34CME~7-269C / 269C) | NVIDIA B300 SXM6 AC | 288GB HBM3e (269GB 可用) · 8TB/s · DCGM 1099W (最高 1100W) · SXM6 | 8 卡 x86 HGX B300 风冷/液冷企业 AI 训练与高吞吐推理节点 | open-gpu ✓ + DCGM + gat |
| Blackwell Ultra | 3183 / 3184 | GB110 | 10DE:22F2 (3183) · 10DE:22F3 (3184) | — | GB110 B300 SXM 变体 | 独立 SXM 形态（非 C2C） | OEM / 定制 HGX B300 模块变体 | gpu-admin-tools |
| Blackwell Ultra | 31A1 | GB110 | 10DE:2274 (C2C+SXM) | — | GB300 Max-Q | DCGM 1199W 功耗上限 · detect-self-hosted.h / edk2 特例 C2C ID | 面向功耗/散热受限机房的能效优化型 GB300 集群 | detect-self-hosted.h + edk2 + DCGM + gat |
| Blackwell Ultra | 3224 / 323E | GB112 | 10DE:215F (SXM) | — | GB112 SXM 变体 | Blackwell Ultra 衍生芯片 GB112（rmconfig.h 已开启） | GB112 数据中心 SXM 工程/定制形态 | gpu-admin-tools + open-gpu rmconfig.h |
| Blackwell DC | 2941 | GB100 | 10DE:2046 / 20CA / 20D5 / 21C9 / 21CA / 22C4 | 20CB–20D2 (8 档: 1-23CME~7-186C / 186C) | NVIDIA GB200 (NVL72/36) | 186GB 可用 HBM3e · DCGM 1199W · NVLink-C2C 900GB/s | 72/36 卡液冷机架超大规模 AI 训练、MoE 大模型实时推理与 MIG 云切分 | open-gpu ✓ + DCGM + Linux nvgrace-gpu |
| Blackwell DC | 2901 | GB100 | 10DE:1999 (1000W) · 199B (999W) · 20DA (850W) | 21D7–21DD / 21EA (8 档: 1-23CME~7-180C / 180C) | NVIDIA B200 (HGX/DGX) | 180GB 可用 HBM3e · 8TB/s · PG525 SKU 220/225(1000W) 与 230(850W) | 8 卡 x86 HGX/DGX B200 主力训练集群与风冷低功耗机房适配 (20DA) | open-gpu ✓ + DCGM + gat |
| Blackwell DC | 2909 | GB100 | 10DE:22EB | — | NVIDIA HGX B200 168GB | 168GB HBM3e · DCGM 1000W · 精准对齐 7×24GB MIG 切分 | 多租户云厂商均分型 MIG 推理与细粒度算力租赁 | open-gpu ✓ + DCGM |
| Blackwell DC | 2920 / 29BC | GB100/102 | 2920: 197F(850W)/20DE · 29BC: 1997/1998/1985/2045 | — | NVIDIA B100 (TS4 / GB102) | 2920 TS4 700W / 197F 850W；29BC DCGM 350W | 700W 风冷 HGX 机箱平滑升级 / 低功耗数据中心推理测试 | DCGM + gpu-admin-tools |
| Blackwell DC | 29BB | GB102 | 10DE:207C | — | NVIDIA DRIVE P2021 | DCGM 50W 目标功耗 | NVIDIA DRIVE 自动驾驶计算域控与车载 AI 平台验证 | open-gpu ✓ + DCGM |
| Blackwell Pro | 2BB5 | GB202GL | 10DE:204E · 10DE:220B | 2160–23A2 (102 档 2GB~96GB Q/A/B/C/E) + 21A6/21A7 (云游戏) | RTX PRO 6000 Server Edition | 96GB GDDR7 ECC · 600W 被动散热 · DCGM PG153 SKU 210 · 4×24GB MIG | 企业级全能服务器：大模型推理、Omniverse 渲染、VDI 虚拟工作站与云游戏 | open-gpu g_nv_name_released.h ✓ + DCGM |
| Blackwell Pro | 2BB9 | GB202GL | 10DE:2091 / 2092 (600W) · 10DE:2279 (LC 249W) | 2233–226F (12 档 1-42/2-84/84) + 22EE/22EF (云游戏) | NVIDIA RTX 6000D (中国合规) | 84GB GDDR7 (448-bit, 无 NVLink) · 600W 标配 / 249W 液冷 LC · 2×42GB MIG | 中国出口合规企业推理、渲染、VDI 与云游戏多租户虚拟化 | open-gpu g_nv_name_released.h ✓ + DCGM |
| Blackwell Pro | 2BB3 | GB202GL | 204D (48GB) · 227A (72GB) [1028/103C/10DE/17AA] | 2324–2372 (26 档 2Q~72Q，限 72GB 版) | RTX PRO 5000 (48GB / 72GB) | 14,080 CUDA · 48GB 或 72GB GDDR7 ECC · 300W 级 (DCGM 349W) | 工作站大模型推理/微调、仿真渲染；72GB 版额外支持企业 vGPU/MIG | open-gpu g_nv_name_released.h ✓ + DCGM |
| Blackwell Pro | 2BB1 / 2BB4 / 2BBD | GB202GL | 204B(6000 WS) · 204C(Max-Q) · 23AE(5500 WS) [四大 OEM] | — | RTX PRO 6000 WS / Max-Q / 5500 WS | 6000 WS 96GB 600W · Max-Q 96GB 300W(Galaxy TS2) · 5500 84GB ECC 600W(2×42GB MIG) | 单卡旗舰桌塔 / 2–4 卡低功耗多卡工作站 / 中大型本地模型微调 | open-gpu ✓ + DCGM |
| Blackwell Pro | 2C3A | GB203GL | 10DE:21F4 | 2295–22C2 (46 档 2GB~32GB Q/A/B/C/裸) | RTX PRO 4500 Server Edition | 32GB GDDR7 (800GB/s) · 165W 单槽被动/服务器卡 (DCGM 164W) · PCIe 5.0 | 高密度 1U/2U 服务器：小模型推理、向量数据库 (Milvus/cuVS)、Metropolis 视觉与 VDI | open-gpu g_nv_name_released.h ✓ + DCGM |
| Blackwell Pro | 2C31 / 2C34 / 2C33 / 2D30 | GB203/206GL | 2051(4500) · 2052(4000) · 2053(4000 SFF) · 2054(2000) [四大 OEM] | — | RTX PRO 4500 / 4000 / 4000 SFF / 2000 | 4500 32GB 200W · 4000 24GB 140W · 4000 SFF 24GB 70W · 2000 16GB 70W | 企业级 CAD/BIM、单槽/半高 SFF 紧凑工作站、多屏显控与轻量 AI 推理 | open-gpu g_nv_name_released.h ✓ |
| Blackwell Spark | 2E12 | GB20B (GB10) | 10DE:21EC | — | NVIDIA GB10 (DGX Spark) | 20 核 Grace + Blackwell · 128GB 统一 LPDDR5X (273GB/s) · 1 PFLOPS FP4 | 个人桌面 AI 超算：本地 200B 模型原型开发与双机 405B 微调 | open-gpu ✓ + Linux quirks.c |

## 三、Hopper（29 个 ID · sm_90）

**GH100** 单芯片家族（含 `gpu-admin-tools` 独家收录、尚未入 `pci.ids` 的 **`2309` H20**；LS10 NVSwitch 全部 16 个 ID 归入第六章）。经 `gpu-admin-tools` 与 `DCGM` 交叉验证：`2343` / `2345` 均正式确认为 **GH200**（`has_c2c + is_sxm`），`2342` / `2345` / `2348` 位于 Linux 主线 `nvgrace-gpu` VFIO 白名单；DCGM 亦披露了内部代号 **`Scout`（`2337/2339`）**、**`SkinnyJoe`（`237F/2342`）** 与 **`PG502`（`2336/2338`）**。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2302 | GH100 | sm_90 | GPU | GH100 | — | GH100 internal/CSP variant — no public SKU mapping | — |
| 2309 | GH100 | sm_90 | GPU | GH100 [H20] (gpu-admin-tools) | H20 (gat/DCGM) | H20 variant (confirmed in NVIDIA/gpu-admin-tools GPU_NAME_BY_DEVID; not yet in pci.ids) | — |
| 230C | GH100 | sm_90 | GPU | GH100 [H20 NVL16] | H20 NVL16 (China SKU) (社区) | DCGM: H20_NVL16 600W | — |
| 230E | GH100 | sm_90 | GPU | GH100 [H20 NVL16] | NVIDIA H20 NVL16 | DCGM: H20 NVL16 500W | ✓ |
| 2313 | GH100 | sm_90 | GPU | GH100 [H100 CNX] | H100 CNX (Converged Accelerator) (社区) |  | — |
| 2321 | GH100 | sm_90 | GPU | GH100 [H100L 94GB] | NVIDIA H100 NVL | DCGM: H100NVL 399W；gat: PCIe (subsys 1839) | ✓ |
| 2322 | GH100 | sm_90 | GPU | GH100 [H800 PCIe] | NVIDIA H800 PCIe | DCGM: H800 PCIe 310W；gat: PCIe (subsys 17A4) | ✓ |
| 2324 | GH100 | sm_90 | GPU | GH100 [H800] | NVIDIA H800 | DCGM: Nvidia H800 80GB 700W；gat: SXM (subsys 17A6/17A8) | ✓ |
| 2328 | GH100 | sm_90 | GPU | GH100 [H20B] | H20B (China SKU) (社区) | DCGM: H20B 400W；gat: SXM (subsys 1905/1906) | — |
| 2329 | GH100 | sm_90 | GPU | GH100 [H20] | NVIDIA H20 | DCGM: H20A 500W；gat: SXM (subsys 198B/198C) | ✓ |
| 232C | GH100 | sm_90 | GPU | GH100 [H20 HBM3e] | NVIDIA H20-3e | DCGM: H20 HBM3e 500W；gat: SXM (subsys 2063/2064) | ✓ |
| 2330 | GH100 | sm_90 | GPU | GH100 [H100 SXM5 80GB] | NVIDIA H100 80GB HBM3 | DCGM: H100 80GB HBM3 700W；gat: SXM (subsys 16C0/16C1/2044/20C1) | ✓ |
| 2331 | GH100 | sm_90 | GPU | GH100 [H100 PCIe] | NVIDIA H100 PCIe | DCGM: Nvidia P1010 350W；gat: PCIe (subsys 1626) | ✓ |
| 2335 | GH100 | sm_90 | GPU | GH100 [H200 SXM 141GB] | NVIDIA H200 | DCGM: H200 700W；gat: SXM (subsys 18BE/18BF) | ✓ |
| 2336 | GH100 | sm_90 | GPU | GH100 [H100] | H100 (PCIe variant, TPU-listed) (社区) | H100 SXM variant; gat: SXM (16C2/16C7); DCGM PG502-20x 700W | — |
| 2337 | GH100 | sm_90 | GPU | GH100 [H100 SXM5 64GB] | H100 SXM5 64GB (TPU-listed) (社区) | H100 SXM5 64GB; gat: SXM (16E5/16EF); DCGM 'Scout H100 64GB HBM2e' 700W | — |
| 2338 | GH100 | sm_90 | GPU | GH100 [H100 SXM5 96GB] | H100 SXM5 96GB (TPU-listed) (社区) | H100 SXM5 96GB; gat: SXM (16F6/16F7); DCGM PG502-221 700W | — |
| 2339 | GH100 | sm_90 | GPU | GH100 [H100 SXM5 94GB] | NVIDIA H100 | H100 SXM5 94GB; gat: SXM (17D9/17FC); DCGM 'Scout H100 94GB HBM2e' 700W | ✓ |
| 233A | GH100 | sm_90 | GPU | GH100 [H800L 94GB] | NVIDIA H800 NVL | DCGM: H100NVL 400W；gat: PCIe (subsys 183A) | ✓ |
| 233B | GH100 | sm_90 | GPU | GH100 [H200 NVL] | NVIDIA H200 NVL | DCGM: H200 600W；gat: PCIe (subsys 1996) | ✓ |
| 233D | GH100 | sm_90 | GPU | GH100 [H100 96GB] | H100 96GB (TPU-listed) (社区) | gat: PCIe (subsys 1626) | — |
| 2342 | GH100 | sm_90 | GPU | GH100 [GH200 120GB / 480GB] | NVIDIA GH200 120GB / NVIDIA GH200 480GB | GH200 120GB/480GB; Linux nvgrace-gpu VFIO (0x2342); gat: C2C+SXM; DCGM 'SkinnyJoe A02' 900W | ✓ |
| 2343 | GH100 | sm_90 | GPU | GH100 | GH200 (gat/DCGM) | Confirmed GH200 in gpu-admin-tools; gat: C2C+SXM (subsys 16EC) | — |
| 2345 | GH100 | sm_90 | GPU | GH100 [GH100-88K-A1] | GH200 (gat/DCGM) | Confirmed GH200 (GH100-88K-A1); Linux nvgrace-gpu VFIO (0x2345); gat: C2C+SXM (16ED); DCGM 700W | — |
| 2348 | GH100 | sm_90 | GPU | GH100 [GH200 144G HBM3e] | NVIDIA GH200 144G HBM3e | GH200 144GB HBM3e; Linux nvgrace-gpu VFIO (0x2348); gat: C2C+SXM (18D2); DCGM 900W | ✓ |
| 237E | GH100 | sm_90 | GPU | GH100 [H100 GH3] | — |  | — |
| 237F | GH100 | sm_90 | GPU | GH100 [Skinny Joe] | SkinnyJoe (gat/DCGM) | GH100 Self-Hosted internal variant; DCGM 'SkinnyJoe' 700W | — |
| 23B0 | GH100 | sm_90 | GPU | GH100 | — | GH100 internal/CSP variant — no public SKU mapping | — |
| 23F0 | GH100 | sm_90 | GPU | GH100 | — | GH100 internal/CSP variant — no public SKU mapping | — |

## 四、Ada Lovelace（69 个 ID · sm_89）

消费级 **RTX 40 系**、专业工作站 **RTX 6000~500 Ada**、数据中心 **L40 / L40S / L20 / L20A / L30 / L4 / L2**（含 `2682` 未发售 RTX 4090 Ti、`2687` AD102 RTX 4080 变体及 5 个 HD Audio；DCGM 补充了 L40S 350W / L20 275W / L20A 350W / L30 350W 等实测目标功耗）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2681 | AD102 | sm_89 | GPU | AD102 [RTX TITAN Ada] | — |  | — |
| 2682 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4090 Ti] | GeForce RTX 4090 Ti (未发售 / 样片) (社区) | Unreleased AD102 flagship SKU added to pci.ids (v2026.11.19) | — |
| 2684 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4090] | NVIDIA GeForce RTX 4090 |  | ✓ |
| 2685 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4090 D] | NVIDIA GeForce RTX 4090 D |  | ✓ |
| 2687 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4080] | GeForce RTX 4080 (AD102 变体) (社区) | AD102-based RTX 4080 variant recorded in pci.ids (v2026.11.19) | — |
| 2689 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4070 Ti SUPER] | NVIDIA GeForce RTX 4070 Ti SUPER |  | ✓ |
| 26AF | AD102 | sm_89 | GPU | AD102 [PG137] | — |  | — |
| 26B1 | AD102 | sm_89 | GPU | AD102GL [RTX 6000 Ada Generation] | NVIDIA RTX 6000 Ada Generation |  | ✓ |
| 26B2 | AD102 | sm_89 | GPU | AD102GL [RTX 5000 Ada Generation] | NVIDIA RTX 5000 Ada Generation |  | ✓ |
| 26B3 | AD102 | sm_89 | GPU | AD102GL [RTX 5880 Ada Generation] | NVIDIA RTX 5880 Ada Generation |  | ✓ |
| 26B5 | AD102 | sm_89 | GPU | AD102GL [L40] | NVIDIA L40 | DCGM: Nvidia L40 299W | ✓ |
| 26B7 | AD102 | sm_89 | GPU | AD102GL [L20] | L20 (gat/DCGM) | DCGM: L20 275W | — |
| 26B8 | AD102 | sm_89 | GPU | AD102GL [L40G] | PG133 SKU 255 (gat/DCGM) | DCGM: PG133 SKU 255 299W | — |
| 26B9 | AD102 | sm_89 | GPU | AD102GL [L40S] | NVIDIA L40S | DCGM: NVIDIA L40S 350W | ✓ |
| 26BA | AD102 | sm_89 | GPU | AD102GL [L20] | NVIDIA L20 | DCGM: L20A 350W | ✓ |
| 26BB | AD102 | sm_89 | GPU | AD102GL [L30] | L30 (gat/DCGM) | DCGM: L30 350W | — |
| 26F5 | AD102 | sm_89 | GPU | AD102GL [L40 CNX] | Nvidia L40 (gat/DCGM) | DCGM: Nvidia L40 349W | — |
| 2702 | AD103 | sm_89 | GPU | AD103 [GeForce RTX 4080 SUPER] | NVIDIA GeForce RTX 4080 SUPER |  | ✓ |
| 2703 | AD103 | sm_89 | GPU | AD103 [GeForce RTX 4080 SUPER] | — |  | — |
| 2704 | AD103 | sm_89 | GPU | AD103 [GeForce RTX 4080] | NVIDIA GeForce RTX 4080 |  | ✓ |
| 2705 | AD103 | sm_89 | GPU | AD103 [GeForce RTX 4070 Ti SUPER] | NVIDIA GeForce RTX 4070 Ti SUPER |  | ✓ |
| 2709 | AD103 | sm_89 | GPU | AD103 [GeForce RTX 4070] | NVIDIA GeForce RTX 4070 |  | ✓ |
| 2717 | AD103 | sm_89 | GPU | AD103M / GN21-X11 [GeForce RTX 4090 Laptop GPU] | NVIDIA GeForce RTX 4090 Laptop GPU |  | ✓ |
| 2730 | AD103 | sm_89 | GPU | AD103GLM [RTX 5000 Ada Generation Laptop GPU] | NVIDIA RTX 5000 Ada Generation Laptop GPU |  | ✓ |
| 2757 | AD103 | sm_89 | GPU | AD103M / GN21-X11 [GeForce RTX 4090 Laptop GPU] | NVIDIA GeForce RTX 4090 Laptop GPU |  | ✓ |
| 2770 | AD103 | sm_89 | GPU | AD103GLM [RTX 5000 Ada Generation Embedded GPU] | NVIDIA RTX 5000 Ada Generation Embedded GPU |  | ✓ |
| 2782 | AD104 | sm_89 | GPU | AD104 [GeForce RTX 4070 Ti] | NVIDIA GeForce RTX 4070 Ti |  | ✓ |
| 2783 | AD104 | sm_89 | GPU | AD104 [GeForce RTX 4070 SUPER] | NVIDIA GeForce RTX 4070 SUPER |  | ✓ |
| 2785 | AD104 | sm_89 | GPU | AD104 [AC AD104 20GB] | — |  | — |
| 2786 | AD104 | sm_89 | GPU | AD104 [GeForce RTX 4070] | NVIDIA GeForce RTX 4070 |  | ✓ |
| 2788 | AD104 | sm_89 | GPU | AD104 [GeForce RTX 4060 Ti] | NVIDIA GeForce RTX 4060 Ti |  | ✓ |
| 27A0 | AD104 | sm_89 | GPU | AD104M [GeForce RTX 4080 Max-Q / Mobile] | NVIDIA GeForce RTX 4080 Laptop GPU |  | ✓ |
| 27B0 | AD104 | sm_89 | GPU | AD104GL [RTX 4000 SFF Ada Generation] | NVIDIA RTX 4000 SFF Ada Generation |  | ✓ |
| 27B1 | AD104 | sm_89 | GPU | AD104GL [RTX 4500 Ada Generation] | NVIDIA RTX 4500 Ada Generation |  | ✓ |
| 27B2 | AD104 | sm_89 | GPU | AD104GL [RTX 4000 Ada Generation] | NVIDIA RTX 4000 Ada Generation |  | ✓ |
| 27B6 | AD104 | sm_89 | GPU | AD104GL [L2] | NVIDIA L2 | DCGM: L2 72W | ✓ |
| 27B7 | AD104 | sm_89 | GPU | AD104GL [L16] | — |  | — |
| 27B8 | AD104 | sm_89 | GPU | AD104GL [L4] | NVIDIA L4 | DCGM: Nvidia L4 75W | ✓ |
| 27BA | AD104 | sm_89 | GPU | AD104GLM [RTX 4000 Ada Generation Laptop GPU] | NVIDIA RTX 4000 Ada Generation Laptop GPU |  | ✓ |
| 27BB | AD104 | sm_89 | GPU | AD104GLM [RTX 3500 Ada Generation Laptop GPU] | NVIDIA RTX 3500 Ada Generation Laptop GPU |  | ✓ |
| 27E0 | AD104 | sm_89 | GPU | AD104M [GeForce RTX 4080 Max-Q / Mobile] | NVIDIA GeForce RTX 4080 Laptop GPU |  | ✓ |
| 27FA | AD104 | sm_89 | GPU | AD104GLM [RTX 4000 Ada Generation Embedded GPU] | — |  | — |
| 27FB | AD104 | sm_89 | GPU | AD104GLM [RTX 3500 Ada Generation Embedded GPU] | NVIDIA RTX 3500 Ada Generation Embedded GPU |  | ✓ |
| 2803 | AD106 | sm_89 | GPU | AD106 [GeForce RTX 4060 Ti] | NVIDIA GeForce RTX 4060 Ti |  | ✓ |
| 2805 | AD106 | sm_89 | GPU | AD106 [GeForce RTX 4060 Ti 16GB] | NVIDIA GeForce RTX 4060 Ti |  | ✓ |
| 2808 | AD106 | sm_89 | GPU | AD106 [GeForce RTX 4060] | NVIDIA GeForce RTX 4060 |  | ✓ |
| 2820 | AD106 | sm_89 | GPU | AD106M [GeForce RTX 4070 Max-Q / Mobile] | NVIDIA GeForce RTX 4070 Laptop GPU |  | ✓ |
| 2822 | AD106 | sm_89 | GPU | AD106M [GeForce RTX 3050 A Laptop GPU] | NVIDIA GeForce RTX 3050 A Laptop GPU |  | ✓ |
| 2838 | AD106 | sm_89 | GPU | AD106GLM [RTX 3000 Ada Generation Laptop GPU] | NVIDIA RTX 3000 Ada Generation Laptop GPU |  | ✓ |
| 2860 | AD106 | sm_89 | GPU | AD106M [GeForce RTX 4070 Max-Q / Mobile] | NVIDIA GeForce RTX 4070 Laptop GPU |  | ✓ |
| 2878 | AD106 | sm_89 | GPU | AD106GLM [RTX 3000 Ada Generation Embedded GPU] | — |  | — |
| 2882 | AD107 | sm_89 | GPU | AD107 [GeForce RTX 4060] | NVIDIA GeForce RTX 4060 |  | ✓ |
| 28A0 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 4060 Max-Q / Mobile] | NVIDIA GeForce RTX 4060 Laptop GPU |  | ✓ |
| 28A1 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 4050 Max-Q / Mobile] | NVIDIA GeForce RTX 4050 Laptop GPU |  | ✓ |
| 28A3 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 3050 A Laptop GPU] | NVIDIA GeForce RTX 3050 A Laptop GPU |  | ✓ |
| 28B0 | AD107 | sm_89 | GPU | AD107GL [RTX 2000 / 2000E Ada Generation] | NVIDIA RTX 2000 Ada Generation / NVIDIA RTX 2000E Ada Generation | DCGM: NVIDIA RTX 2000 Ada Generation 70W | ✓ |
| 28B8 | AD107 | sm_89 | GPU | AD107GLM [RTX 2000 Ada Generation Laptop GPU] | NVIDIA RTX 2000 Ada Generation Laptop GPU |  | ✓ |
| 28B9 | AD107 | sm_89 | GPU | AD107GLM [RTX 1000 Ada Generation Laptop GPU] | NVIDIA RTX 1000 Ada Generation Laptop GPU |  | ✓ |
| 28BA | AD107 | sm_89 | GPU | AD107GLM [RTX 500 Ada Generation Laptop GPU] | NVIDIA RTX 500 Ada Generation Laptop GPU |  | ✓ |
| 28BB | AD107 | sm_89 | GPU | AD107GLM [RTX 500 Ada Generation Laptop GPU] | NVIDIA RTX 500 Ada Generation Laptop GPU |  | ✓ |
| 28E0 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 4060 Max-Q / Mobile] | NVIDIA GeForce RTX 4060 Laptop GPU |  | ✓ |
| 28E1 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 4050 Max-Q / Mobile] | NVIDIA GeForce RTX 4050 Laptop GPU |  | ✓ |
| 28E3 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 3050 A Laptop GPU] | NVIDIA GeForce RTX 3050 A Laptop GPU |  | ✓ |
| 28F8 | AD107 | sm_89 | GPU | AD107GLM [RTX 2000 Ada Generation Embedded GPU] | NVIDIA RTX 2000 Ada Generation Embedded GPU |  | ✓ |
| 22BA | AD102 | sm_89 | **HD Audio** | AD102 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22BB | AD103 | sm_89 | **HD Audio** | AD103 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22BC | AD104 | sm_89 | **HD Audio** | AD104 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22BD | AD106 | sm_89 | **HD Audio** | AD106M High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22BE | AD107 | sm_89 | **HD Audio** | AD107 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |

## 五、Ampere（146 个 ID · sm_80 / 86）

数据中心 **GA100**（`sm_80`，A100 / A800 / A30 / AX800 / CMP 170HX）与消费/专业卡 **GA102–GA107**（`sm_86`，RTX 30 系 / RTX A 系 / A40 / A10 / A16 / A2），含 5 个 HD Audio。（LR10 NVSwitch 全部 17 个 ID 归入第六章，Orin T234 PCIe Root Port 归入第七章。）

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2080 | GA100 | sm_80 | GPU | GA100 | — | GA100 (A100-class) internal/CSP variant — no public SKU mapping | — |
| 2081 | GA100 | sm_80 | GPU | GA100 | — | GA100 (A100-class) internal/CSP variant — no public SKU mapping | — |
| 2082 | GA100 | sm_80 | GPU | GA100 [CMP 170HX] | CMP 170HX (crypto-mining) (社区) |  | — |
| 20B0 | GA100 | sm_80 | GPU | GA100 [A100 SXM4 40GB] | NVIDIA A100-SXM4-40GB / NVIDIA A100-PG509-200 | DCGM: GA100 20b0 399W | ✓ |
| 20B1 | GA100 | sm_80 | GPU | GA100 [A100 PCIe 40GB] | A100 (gat/DCGM) |  | — |
| 20B2 | GA100 | sm_80 | GPU | GA100 [A100 SXM4 80GB] | NVIDIA A100-SXM4-80GB / NVIDIA PG509-210 | DCGM: A100-SXM4-80GB 399W; A100-SXM4-80GB-147F [147F] 274W | ✓ |
| 20B3 | GA100 | sm_80 | GPU | GA100 [A100-SXM-64GB] | NVIDIA A100-SXM-64GB | DCGM: PG506-242 [14A7] 499W; PG506-243 [14A8] 549W | ✓ |
| 20B4 | GA100 | sm_80 | GPU | GA100 | — | GA100 (A100-class) internal/CSP variant — no public SKU mapping | — |
| 20B5 | GA100 | sm_80 | GPU | GA100 [A100 PCIe 80GB] | NVIDIA A100 80GB PCIe | DCGM: A100-20b5 299W | ✓ |
| 20B6 | GA100 | sm_80 | GPU | GA100GL [PG506-232] | NVIDIA PG506-232 | DCGM: PG506-230 194W | ✓ |
| 20B7 | GA100 | sm_80 | GPU | GA100GL [A30 PCIe] | NVIDIA A30 | DCGM: A30 194W; A30LC [1804] 164W | ✓ |
| 20B8 | GA100 | sm_80 | GPU | GA100 [A100X] | A100X (converged w/ BlueField-3) (社区) | DCGM: GA100 SKU 20b8 299W | — |
| 20B9 | GA100 | sm_80 | GPU | GA100 [A30X] | A30X (converged w/ BlueField-3) (社区) | DCGM: P1004 230W | — |
| 20BB | GA100 | sm_80 | GPU | GA100 [DRIVE A100 PROD] | DRIVE A100 (automotive) (社区) | DCGM: NVIDIA Ampere Auto Module 374W | — |
| 20BD | GA100 | sm_80 | GPU | GA100 [A800 SXM4 40GB] | NVIDIA A800-SXM4-40GB | DCGM: A800-20bd 399W | ✓ |
| 20BE | GA100 | sm_80 | GPU | GA100 [GRID A100A] | GRID A100A (vGPU) (社区) |  | — |
| 20BF | GA100 | sm_80 | GPU | GA100 [GRID A100B] | GRID A100B (vGPU) (社区) | DCGM: GA100 SKU 20bf 199W | — |
| 20C0 | GA100 | sm_80 | GPU | GA100 [Initial DevID] | — |  | — |
| 20C2 | GA100 | sm_80 | GPU | GA100 [CMP 170HX] | — |  | — |
| 20F0 | GA100 | sm_80 | GPU | GA100 [A100-PG506-207] | A100 (PG506-207 SKU) (社区) | DCGM: A100-20F0 400W | — |
| 20F1 | GA100 | sm_80 | GPU | GA100 [A100 PCIe 40GB] | NVIDIA A100-PCIE-40GB | DCGM: A100 PCIe 299W | ✓ |
| 20F2 | GA100 | sm_80 | GPU | GA100 [A100-PG506-217] | A100 (PG506-217 SKU) (社区) | DCGM: A100-20F2 80GB 400W | — |
| 20F3 | GA100 | sm_80 | GPU | GA100 [A800-SXM4-80GB] | NVIDIA A800-SXM4-80GB | DCGM: A800-SXM4-80GB Watercooled [179C] 499W; A800-SXM4-80GB 399W | ✓ |
| 20F5 | GA100 | sm_80 | GPU | GA100 [A800 80GB PCIe] | NVIDIA A800 80GB PCIe / NVIDIA A800 80GB PCIe LC | DCGM: A800-20f5 80GB 299W | ✓ |
| 20F6 | GA100 | sm_80 | GPU | GA100 [A800 40GB PCIe] | NVIDIA A800 40GB Active | DCGM: A100-20f6 40GB 249W | ✓ |
| 20FD | GA100 | sm_80 | GPU | GA100 [AX800 Converged Accelerator] | NVIDIA AX800 | DCGM: AX800 349W | ✓ |
| 20FE | GA100 | sm_80 | GPU | GA100 [INT SKU] | — |  | — |
| 20FF | GA100 | sm_80 | GPU | GA100 | — | GA100 (A100-class) internal/CSP variant — no public SKU mapping | — |
| 2200 | GA102 | sm_86 | GPU | GA102 | — | Internal/engineering variant — no public marketing name | — |
| 2203 | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3090 Ti] | NVIDIA GeForce RTX 3090 Ti |  | ✓ |
| 2204 | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3090] | NVIDIA GeForce RTX 3090 |  | ✓ |
| 2205 | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3080 Ti 20GB] | — |  | — |
| 2206 | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3080] | NVIDIA GeForce RTX 3080 |  | ✓ |
| 2207 | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3070 Ti] | NVIDIA GeForce RTX 3070 Ti |  | ✓ |
| 2208 | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3080 Ti] | NVIDIA GeForce RTX 3080 Ti |  | ✓ |
| 220A | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3080 12GB] | NVIDIA GeForce RTX 3080 |  | ✓ |
| 220D | GA102 | sm_86 | GPU | GA102 [CMP 90HX] | NVIDIA CMP 90HX |  | ✓ |
| 2216 | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3080 Lite Hash Rate] | NVIDIA GeForce RTX 3080 |  | ✓ |
| 222B | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3090 Engineering Sample] | — | [ES 工程样品] | — |
| 222F | GA102 | sm_86 | GPU | GA102 [GeForce RTX 3080 11GB / 12GB Engineering Sample] | — | [ES 工程样品] | — |
| 2230 | GA102 | sm_86 | GPU | GA102GL [RTX A6000] | NVIDIA RTX A6000 | DCGM: A6000 PCIe 299W | ✓ |
| 2231 | GA102 | sm_86 | GPU | GA102GL [RTX A5000] | NVIDIA RTX A5000 | DCGM: A5000 229W | ✓ |
| 2232 | GA102 | sm_86 | GPU | GA102GL [RTX A4500] | NVIDIA RTX A4500 |  | ✓ |
| 2233 | GA102 | sm_86 | GPU | GA102GL [RTX A5500] | NVIDIA RTX A5500 |  | ✓ |
| 2235 | GA102 | sm_86 | GPU | GA102GL [A40] | NVIDIA A40 | DCGM: A40 299W | ✓ |
| 2236 | GA102 | sm_86 | GPU | GA102GL [A10] | NVIDIA A10 | DCGM: A10c/noc - PG133 SKU215 [1482] 149W; EGX BF-2 A100 [149D] 224W | ✓ |
| 2237 | GA102 | sm_86 | GPU | GA102GL [A10G] | NVIDIA A10G | DCGM: A10g - PG133 SKU210 299W | ✓ |
| 2238 | GA102 | sm_86 | GPU | GA102GL [A10M] | NVIDIA A10M | DCGM: Nvidia A10M 150W | ✓ |
| 223F | GA102 | sm_86 | GPU | GA102GL | — | Internal/engineering variant — no public marketing name | — |
| 2414 | GA103 | sm_86 | GPU | GA103 [GeForce RTX 3060 Ti] | NVIDIA GeForce RTX 3060 Ti |  | ✓ |
| 2420 | GA103 | sm_86 | GPU | GA103M [GeForce RTX 3080 Ti Mobile] | NVIDIA GeForce RTX 3080 Ti Laptop GPU |  | ✓ |
| 2438 | GA103 | sm_86 | GPU | GA103GLM [RTX A5500 Laptop GPU] | NVIDIA RTX A5500 Laptop GPU |  | ✓ |
| 2460 | GA103 | sm_86 | GPU | GA103M [GeForce RTX 3080 Ti Laptop GPU] | NVIDIA GeForce RTX 3080 Ti Laptop GPU |  | ✓ |
| 2480 | GA104 | sm_86 | GPU | GA104 [Reserved Dev ID A] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 2482 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070 Ti] | NVIDIA GeForce RTX 3070 Ti |  | ✓ |
| 2483 | GA104 | sm_86 | GPU | GA104 | — | Internal/engineering variant — no public marketing name | — |
| 2484 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070] | NVIDIA GeForce RTX 3070 |  | ✓ |
| 2486 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3060 Ti] | NVIDIA GeForce RTX 3060 Ti |  | ✓ |
| 2487 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3060] | NVIDIA GeForce RTX 3060 |  | ✓ |
| 2488 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070 Lite Hash Rate] | NVIDIA GeForce RTX 3070 |  | ✓ |
| 2489 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3060 Ti Lite Hash Rate] | NVIDIA GeForce RTX 3060 Ti |  | ✓ |
| 248A | GA104 | sm_86 | GPU | GA104 [CMP 70HX] | NVIDIA CMP 70HX |  | ✓ |
| 248C | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070 Ti] | — |  | — |
| 248D | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070] | — |  | — |
| 248E | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3060 Ti] | — |  | — |
| 249C | GA104 | sm_86 | GPU | GA104M [GeForce RTX 3080 Mobile / Max-Q 8GB/16GB] | NVIDIA GeForce RTX 3080 Laptop GPU / NVIDIA GeForce RTX 3060 Laptop GPU |  | ✓ |
| 249D | GA104 | sm_86 | GPU | GA104M [GeForce RTX 3070 Mobile / Max-Q] | NVIDIA GeForce RTX 3070 Laptop GPU |  | ✓ |
| 249F | GA104 | sm_86 | GPU | GA104M | — | Internal/engineering variant — no public marketing name | — |
| 24A0 | GA104 | sm_86 | GPU | GA104 [Geforce RTX 3070 Ti Laptop GPU] | NVIDIA GeForce RTX 3070 Ti Laptop GPU / NVIDIA GeForce RTX 3060 Laptop GPU |  | ✓ |
| 24A4 | GA104 | sm_86 | GPU | GA104M | — | Internal/engineering variant — no public marketing name | — |
| 24AC | GA104 | sm_86 | GPU | GA104 [GeForce RTX 30x0 Engineering Sample] | — | [ES 工程样品] | — |
| 24AD | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3060 Engineering Sample] | — | [ES 工程样品] | — |
| 24AF | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070 Engineering Sample] | — | [ES 工程样品] | — |
| 24B0 | GA104 | sm_86 | GPU | GA104GL [RTX A4000] | NVIDIA RTX A4000 | DCGM: A4000 139W | ✓ |
| 24B1 | GA104 | sm_86 | GPU | GA104GL [RTX A4000H] | NVIDIA RTX A4000H |  | ✓ |
| 24B6 | GA104 | sm_86 | GPU | GA104GLM [RTX A5000 Mobile] | NVIDIA RTX A5000 Laptop GPU |  | ✓ |
| 24B7 | GA104 | sm_86 | GPU | GA104GLM [RTX A4000 Mobile] | NVIDIA RTX A4000 Laptop GPU |  | ✓ |
| 24B8 | GA104 | sm_86 | GPU | GA104GLM [RTX A3000 Mobile] | NVIDIA RTX A3000 Laptop GPU |  | ✓ |
| 24B9 | GA104 | sm_86 | GPU | GA104GLM [RTX A3000 12GB Laptop GPU] | NVIDIA RTX A3000 12GB Laptop GPU |  | ✓ |
| 24BA | GA104 | sm_86 | GPU | GA104GLM [RTX A4500 Laptop GPU] | NVIDIA RTX A4500 Laptop GPU |  | ✓ |
| 24BB | GA104 | sm_86 | GPU | GA104GLM [RTX A3000 Laptop GPU] | NVIDIA RTX A3000 12GB Laptop GPU |  | ✓ |
| 24BF | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070 Engineering Sample] | — | [ES 工程样品] | — |
| 24C0 | GA104 | sm_86 | GPU | GA104 [Initial Dev ID B] | — |  | — |
| 24C7 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3060 8GB] | NVIDIA GeForce RTX 3060 |  | ✓ |
| 24C8 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070 GDDR6X] | — |  | — |
| 24C9 | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3060 Ti GDDR6X] | NVIDIA GeForce RTX 3060 Ti |  | ✓ |
| 24DC | GA104 | sm_86 | GPU | GA104M [GeForce RTX 3080 Mobile / Max-Q 8GB/16GB] | NVIDIA GeForce RTX 3080 Laptop GPU |  | ✓ |
| 24DD | GA104 | sm_86 | GPU | GA104M [GeForce RTX 3070 Mobile / Max-Q] | NVIDIA GeForce RTX 3070 Laptop GPU |  | ✓ |
| 24DF | GA104 | sm_86 | GPU | GA104M | — | Internal/engineering variant — no public marketing name | — |
| 24E0 | GA104 | sm_86 | GPU | GA104M [Geforce RTX 3070 Ti Laptop GPU] | NVIDIA GeForce RTX 3070 Ti Laptop GPU |  | ✓ |
| 24FA | GA104 | sm_86 | GPU | GA104 [RTX A4500 Embedded GPU] | NVIDIA RTX A4500 Embedded GPU |  | ✓ |
| 2501 | GA106 | sm_86 | GPU | GA106 [GeForce RTX 3060] | — |  | — |
| 2503 | GA106 | sm_86 | GPU | GA106 [GeForce RTX 3060] | NVIDIA GeForce RTX 3060 |  | ✓ |
| 2504 | GA106 | sm_86 | GPU | GA106 [GeForce RTX 3060 Lite Hash Rate] | NVIDIA GeForce RTX 3060 |  | ✓ |
| 2505 | GA106 | sm_86 | GPU | GA106 | — | Internal/engineering variant — no public marketing name | — |
| 2507 | GA106 | sm_86 | GPU | GA106 [Geforce RTX 3050] | NVIDIA GeForce RTX 3050 |  | ✓ |
| 2508 | GA106 | sm_86 | GPU | GA106 [GeForce RTX 3050 OEM] | NVIDIA GeForce RTX 3050 OEM |  | ✓ |
| 2509 | GA106 | sm_86 | GPU | GA106 [GeForce RTX 3060 12GB Rev. 2] | — |  | — |
| 2520 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3060 Mobile / Max-Q] | NVIDIA GeForce RTX 3060 Laptop GPU |  | ✓ |
| 2521 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3060 Laptop GPU] | NVIDIA GeForce RTX 3060 Laptop GPU |  | ✓ |
| 2523 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3050 Ti Mobile / Max-Q] | NVIDIA GeForce RTX 3050 Ti Laptop GPU |  | ✓ |
| 252F | GA106 | sm_86 | GPU | GA106 [GeForce RTX 3060 Engineering Sample] | — | [ES 工程样品] | — |
| 2531 | GA106 | sm_86 | GPU | GA106 [RTX A2000] | NVIDIA RTX A2000 | DCGM: Nvidia A2000_6GB 70W | ✓ |
| 2544 | GA106 | sm_86 | GPU | GA106 [GeForce RTX 3060] | NVIDIA GeForce RTX 3060 |  | ✓ |
| 2560 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3060 Mobile / Max-Q] | NVIDIA GeForce RTX 3060 Laptop GPU |  | ✓ |
| 2561 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3060 Laptop GPU] | — |  | — |
| 2563 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3050 Ti Mobile / Max-Q] | NVIDIA GeForce RTX 3050 Ti Laptop GPU |  | ✓ |
| 2571 | GA106 | sm_86 | GPU | GA106 [RTX A2000 12GB] | NVIDIA RTX A2000 12GB | DCGM: Nvidia A2000_12GB 70W | ✓ |
| 2582 | GA107 | sm_86 | GPU | GA107 [GeForce RTX 3050 8GB] | NVIDIA GeForce RTX 3050 |  | ✓ |
| 2583 | GA107 | sm_86 | GPU | GA107 [GeForce RTX 3050 4GB] | — |  | — |
| 2584 | GA107 | sm_86 | GPU | GA107 [GeForce RTX 3050 6GB] | NVIDIA GeForce RTX 3050 |  | ✓ |
| 25A0 | GA107 | sm_86 | GPU | GA107M [GeForce RTX 3050 Ti Mobile] | NVIDIA GeForce RTX 3050 Ti Laptop GPU / NVIDIA GeForce RTX 3050Ti Laptop GPU / NVIDIA GeForce RTX 3060 Laptop GPU |  | ✓ |
| 25A2 | GA107 | sm_86 | GPU | GA107M [GeForce RTX 3050 Mobile] | NVIDIA GeForce RTX 3050 Laptop GPU / NVIDIA GeForce RTX 3050 Ti Laptop GPU / NVIDIA GeForce RTX 3060 Laptop GPU |  | ✓ |
| 25A3 | GA107 | sm_86 | GPU | GA107 | — | Internal/engineering variant — no public marketing name | — |
| 25A4 | GA107 | sm_86 | GPU | GA107 | — | Internal/engineering variant — no public marketing name | — |
| 25A5 | GA107 | sm_86 | GPU | GA107M [GeForce RTX 3050 Mobile] | NVIDIA GeForce RTX 3050 Laptop GPU |  | ✓ |
| 25A6 | GA107 | sm_86 | GPU | GA107M [GeForce MX570] | NVIDIA GeForce MX570 |  | ✓ |
| 25A7 | GA107 | sm_86 | GPU | GA107M [GeForce MX570] | NVIDIA GeForce RTX 2050 |  | ✓ |
| 25A9 | GA107 | sm_86 | GPU | GA107M [GeForce RTX 2050] | NVIDIA GeForce RTX 2050 |  | ✓ |
| 25AA | GA107 | sm_86 | GPU | GA107M [GeForce MX570 A] | NVIDIA GeForce MX570 A |  | ✓ |
| 25AB | GA107 | sm_86 | GPU | GA107M [GeForce RTX 3050 4GB Laptop GPU] | NVIDIA GeForce RTX 3050 4GB Laptop GPU |  | ✓ |
| 25AC | GA107 | sm_86 | GPU | GA107BM / GN20-P0-R-K2 [GeForce RTX 3050 6GB Laptop GPU] | NVIDIA GeForce RTX 3050 6GB Laptop GPU |  | ✓ |
| 25AD | GA107 | sm_86 | GPU | GA107 [GeForce RTX 2050] | NVIDIA GeForce RTX 2050 |  | ✓ |
| 25AF | GA107 | sm_86 | GPU | GA107 [GeForce RTX 3050 Engineering Sample] | — | [ES 工程样品] | — |
| 25B0 | GA107 | sm_86 | GPU | GA107GL [RTX A1000] | NVIDIA RTX A1000 |  | ✓ |
| 25B2 | GA107 | sm_86 | GPU | GA107GL [RTX A400] | NVIDIA RTX A400 |  | ✓ |
| 25B5 | GA107 | sm_86 | GPU | GA107GLM [RTX A4 Mobile] | — |  | — |
| 25B6 | GA107 | sm_86 | GPU | GA107GL [A2 / A16] | NVIDIA A16 / NVIDIA A2 | DCGM: A16 - PG171 SKU200 62W; Nvidia A2 70W | ✓ |
| 25B8 | GA107 | sm_86 | GPU | GA107GLM [RTX A2000 Mobile] | NVIDIA RTX A2000 Laptop GPU |  | ✓ |
| 25B9 | GA107 | sm_86 | GPU | GA107GLM [RTX A1000 Laptop GPU] | NVIDIA RTX A1000 Laptop GPU |  | ✓ |
| 25BA | GA107 | sm_86 | GPU | GA107GLM [RTX A2000 8GB Laptop GPU] | NVIDIA RTX A2000 8GB Laptop GPU |  | ✓ |
| 25BB | GA107 | sm_86 | GPU | GA107GLM [RTX A500 Laptop GPU] | NVIDIA RTX A500 Laptop GPU |  | ✓ |
| 25BC | GA107 | sm_86 | GPU | GA107GLM [RTX A1000 6GB Laptop GPU] | NVIDIA RTX A1000 6GB Laptop GPU |  | ✓ |
| 25BD | GA107 | sm_86 | GPU | GA107GLM [RTX A500 Laptop GPU] | NVIDIA RTX A500 Laptop GPU |  | ✓ |
| 25E0 | GA107 | sm_86 | GPU | GA107BM [GeForce RTX 3050 Ti Mobile] | NVIDIA GeForce RTX 3050 Ti Laptop GPU |  | ✓ |
| 25E2 | GA107 | sm_86 | GPU | GA107BM [GeForce RTX 3050 Mobile] | NVIDIA GeForce RTX 3050 Laptop GPU |  | ✓ |
| 25E5 | GA107 | sm_86 | GPU | GA107BM [GeForce RTX 3050 Mobile] | NVIDIA GeForce RTX 3050 Laptop GPU |  | ✓ |
| 25EC | GA107 | sm_86 | GPU | GA107BM / GN20-P0-R-K2 [GeForce RTX 3050 6GB Laptop GPU] | NVIDIA GeForce RTX 3050 6GB Laptop GPU |  | ✓ |
| 25ED | GA107 | sm_86 | GPU | GA107 [GeForce RTX 2050] | NVIDIA GeForce RTX 2050 |  | ✓ |
| 25F9 | GA107 | sm_86 | GPU | GA107 [RTX A1000 Embedded GPU] | NVIDIA RTX A1000 Embedded GPU |  | ✓ |
| 25FA | GA107 | sm_86 | GPU | GA107 [RTX A2000 Embedded GPU] | NVIDIA RTX A2000 Embedded GPU |  | ✓ |
| 25FB | GA107 | sm_86 | GPU | GA107 [RTX A500 Embedded GPU] | NVIDIA RTX A500 Embedded GPU |  | ✓ |
| 1AEF | GA102 | sm_86 | **HD Audio** | GA102 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 228B | GA104 | sm_86 | **HD Audio** | GA104 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 228E | GA106 | sm_86 | **HD Audio** | GA106 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 2291 | GA107 | sm_86 | **HD Audio** | GA107 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |

## 六、NVSwitch（`10DE` 全量 33 项）与 `15B3` 集群互联家族（50 项）

### 6.1 `10DE` NVSwitch Gen2（LR10 / LimeRock）与 Gen3（LS10 / Laguna）全量表

`pci.ids` 仅收录了最常见的 `1AF1` 与 `22A3` 两条，`NVIDIA/open-gpu-kernel-modules` 的 `src/common/nvswitch/kernel/nvswitch.c` 完整定义了全部 **33 个** PCI Device ID（含 LS10 的管理端点、Function 0 PCI-PCI Bridge 与 Function 1 NTB）：

| Vendor | ID | 代际 | 芯片代号 | 功能角色 | pci.ids 名称 | 驱动源码说明 |
| --- | --- | --- | --- | --- | --- | --- |
| 10DE | 1AE8 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF0 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF1 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | GA100 [A100 NVSwitch] | HGX/DGX A100 常见公开 ID (Class 0x068000) |
| 10DE | 1AF2 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF3 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF4 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF5 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF6 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF7 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF8 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AF9 | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AFA | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AFB | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AFC | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AFD | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AFE | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 1AFF | NVSwitch Gen2 (Ampere) | LR10 (LimeRock) | NVSwitch | — (仅在 open-gpu nvswitch.c) | open-gpu nvswitch_lr10_device_ids[] (LimeRock / NVSwitch Gen2) |
| 10DE | 22A0 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NVSwitch EP | — (仅在 open-gpu nvswitch.c) | LS10 PCIe endpoint to manage NVLink switch HW (nvswitch_ls10_device_ids[]) |
| 10DE | 22A1 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NVSwitch EP | — (仅在 open-gpu nvswitch.c) | LS10 PCIe endpoint to manage NVLink switch HW (nvswitch_ls10_device_ids[]) |
| 10DE | 22A2 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NVSwitch EP | — (仅在 open-gpu nvswitch.c) | LS10 PCIe endpoint to manage NVLink switch HW (nvswitch_ls10_device_ids[]) |
| 10DE | 22A3 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NVSwitch EP | GH100 [H100 NVSwitch] | HGX/DGX H100/H200 常见公开 ID (Class 0x068000) |
| 10DE | 22A4 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NVSwitch EP | — (仅在 open-gpu nvswitch.c) | LS10 PCIe endpoint to manage NVLink switch HW (nvswitch_ls10_device_ids[]) |
| 10DE | 22A5 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NVSwitch EP | — (仅在 open-gpu nvswitch.c) | LS10 PCIe endpoint to manage NVLink switch HW (nvswitch_ls10_device_ids[]) |
| 10DE | 22A6 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NVSwitch EP | — (仅在 open-gpu nvswitch.c) | LS10 PCIe endpoint to manage NVLink switch HW (nvswitch_ls10_device_ids[]) |
| 10DE | 22A7 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NVSwitch EP | — (仅在 open-gpu nvswitch.c) | LS10 PCIe endpoint to manage NVLink switch HW (nvswitch_ls10_device_ids[]) |
| 10DE | 22A8 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | PCI-PCI Bridge F0 | — (仅在 open-gpu nvswitch.c) | Laguna Switch Function 0 PCI-PCI Bridge (nvswitch_ls10_device_ids[]) |
| 10DE | 22A9 | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | PCI-PCI Bridge F0 | — (仅在 open-gpu nvswitch.c) | Laguna Switch Function 0 PCI-PCI Bridge (nvswitch_ls10_device_ids[]) |
| 10DE | 22AA | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | PCI-PCI Bridge F0 | — (仅在 open-gpu nvswitch.c) | Laguna Switch Function 0 PCI-PCI Bridge (nvswitch_ls10_device_ids[]) |
| 10DE | 22AB | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | PCI-PCI Bridge F0 | — (仅在 open-gpu nvswitch.c) | Laguna Switch Function 0 PCI-PCI Bridge (nvswitch_ls10_device_ids[]) |
| 10DE | 22AC | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NTB Bridge F1 | — (仅在 open-gpu nvswitch.c) | Laguna Switch Function 1 Non-Transparent Bridge (nvswitch_ls10_device_ids[]) |
| 10DE | 22AD | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NTB Bridge F1 | — (仅在 open-gpu nvswitch.c) | Laguna Switch Function 1 Non-Transparent Bridge (nvswitch_ls10_device_ids[]) |
| 10DE | 22AE | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NTB Bridge F1 | — (仅在 open-gpu nvswitch.c) | Laguna Switch Function 1 Non-Transparent Bridge (nvswitch_ls10_device_ids[]) |
| 10DE | 22AF | NVSwitch Gen3 (Hopper) | LS10 (Laguna) | NTB Bridge F1 | — (仅在 open-gpu nvswitch.c) | Laguna Switch Function 1 Non-Transparent Bridge (nvswitch_ls10_device_ids[]) |

### 6.2 `15B3` 配套高速互联表（NVLink-6/7/8 Switch · ConnectX-6~11 · BlueField-1~4 · Quantum / Spectrum）

在大规模 Grace/Blackwell/Vera Rubin 集群的 `lspci` 中，除 `10DE` 外还会密集出现 **`15B3`（Mellanox / NVIDIA Networking）** 设备——**从 NVLink-6 Switch（Vera Rubin）起，机架级 NVLink 交换芯片的 PCI ID 已正式并入 `15B3:D2F8/D2FA/D2FC`**，而 **ConnectX-10/11（`15B3:2101/2102`）** 更是原生支持 **NVLink-C2C**：

| Vendor | ID | 产品家族 | 芯片 / ASIC | 功能角色 | pci.ids 名称（v2026.11.19） | 说明 / Linux 实证 |
| --- | --- | --- | --- | --- | --- | --- |
| 15B3 | D2F8 | NVLink Switch Gen6 | NVLink-6 | NVLink Switch | NVLink-6 Switch | Vera Rubin 机架级 NVLink-6 交换芯片（从 Gen6 起并入 15B3 段位） |
| 15B3 | 0278 | NVLink Switch Gen6 | NVLink-6 | Flash Recovery | NVLink-6 Switch in Flash Recovery Mode | NVLink-6 Switch Flash Recovery |
| 15B3 | 0279 | NVLink Switch Gen6 | NVLink-6 | RMA | NVLink-6 Switch RMA | NVLink-6 Switch RMA |
| 15B3 | D2FA | NVLink Switch Gen7 | NVLink-7 | NVLink Switch | NVLink-7 Switch | Rubin Ultra / 下一代 NVLink-7 交换芯片 |
| 15B3 | 027C | NVLink Switch Gen7 | NVLink-7 | Flash Recovery | NVLink-7 Switch in Flash Recovery Mode | NVLink-7 Switch Flash Recovery |
| 15B3 | 027D | NVLink Switch Gen7 | NVLink-7 | RMA | NVLink-7 Switch RMA | NVLink-7 Switch RMA |
| 15B3 | D2FC | NVLink Switch Gen8 | NVLink-8 | NVLink Switch | NVLink-8 Switch | 远期规划 NVLink-8 交换芯片（已入 pci.ids v2026.11.19） |
| 15B3 | 02A0 | NVLink Switch Gen8 | NVLink-8 | Flash Recovery | NVLink-8 Switch in Flash Recovery Mode | NVLink-8 Switch Flash Recovery |
| 15B3 | 02A1 | NVLink Switch Gen8 | NVLink-8 | RMA | NVLink-8 Switch RMA | NVLink-8 Switch RMA |
| 15B3 | 101B | ConnectX-6 | MT28908 | NIC / HCA | MT28908 Family [ConnectX-6] | 200G HDR IB / Ethernet |
| 15B3 | 101D | ConnectX-6 Dx | MT2892 | NIC | MT2892 Family [ConnectX-6 Dx] | 100G/200G Ethernet |
| 15B3 | 101F | ConnectX-6 Lx | MT2894 | NIC | MT2894 Family [ConnectX-6 Lx] | 25G/50G Ethernet |
| 15B3 | 1021 | ConnectX-7 | MT2910 | NIC / HCA | MT2910 Family [ConnectX-7] | 400G NDR IB / 400GbE（HGX H100/H200/GB200 标配） |
| 15B3 | 1979 | ConnectX-7 | MT2910 | PCIe Bridge | MT2910 Family [ConnectX-7 PCIe Bridge] | ConnectX-7 PCIe Bridge（gpu-admin-tools cx7.py 识别） |
| 15B3 | 1023 | ConnectX-8 | CX8 | SuperNIC / HCA | CX8 Family [ConnectX-8] | 800G XDR IB / 800GbE（GB300 / B300 标配） |
| 15B3 | 1024 | ConnectX-8 | CX8 | PCIe Switch | CX8 PCIe Switch Family [ConnectX-8 PCIe Switch] | ConnectX-8 内置 PCIe Gen6 Switch |
| 15B3 | 197D | ConnectX-8 | CX8 | PCIe Bridge | CX8 Family [ConnectX-8 PCIe Bridge] | ConnectX-8 PCIe Bridge |
| 15B3 | 1025 | ConnectX-9 | CX9 | SuperNIC / HCA | CX9 Family [ConnectX-9] | Vera Rubin 世代 1.6T / 800G SuperNIC |
| 15B3 | 197E | ConnectX-9 | CX9 | PCIe Bridge | CX9 Family [ConnectX-9 PCIe Bridge] | ConnectX-9 PCIe Bridge |
| 15B3 | 1027 | ConnectX-10 | CX10 | SuperNIC / HCA | CX10 Family [ConnectX-10] | 下一代 ConnectX-10 SuperNIC |
| 15B3 | 1028 | ConnectX-10 | CX10 | TNCM | CX10 Family [ConnectX-10 Trusted Network Control Memory] | ConnectX-10 Trusted Network Control Memory |
| 15B3 | 197F | ConnectX-10 | CX10 | PCIe Bridge | CX10 Family [ConnectX-10 PCIe Bridge] | ConnectX-10 PCIe Bridge |
| 15B3 | 2101 | ConnectX-10 | CX10 | NVLink-C2C | CX10 Family [ConnectX-10 NVLink-C2C] | Linux 主线 drivers/pci/quirks.c 实锤：强制 PCIe ATS 的 NVLink-C2C 网卡 |
| 15B3 | 1029 | ConnectX-11 | CX11 | SuperNIC / HCA | CX11 Family [ConnectX-11] | 远期 ConnectX-11 SuperNIC |
| 15B3 | 102A | ConnectX-11 | CX11 | TNCM | CX11 Family [ConnectX-11 Trusted Network Control Memory] | ConnectX-11 Trusted Network Control Memory |
| 15B3 | 1980 | ConnectX-11 | CX11 | PCIe Bridge | CX11 Family [ConnectX-11 PCIe Bridge] | ConnectX-11 PCIe Bridge |
| 15B3 | 2102 | ConnectX-11 | CX11 | NVLink-C2C | CX11 Family [ConnectX-11 NVLink-C2C] | ConnectX-11 NVLink-C2C |
| 15B3 | A2D0 | BlueField-1 | MT416842 | DPU SoC | MT416842 BlueField SoC Crypto enabled | open-gpu nvcst.h (CS_MELLANOX_BLUEFIELD) Crypto enabled |
| 15B3 | A2D4 | BlueField-2 | MT42822 | DPU SoC | MT42822 BlueField-2 SoC Crypto enabled | open-gpu nvcst.h (CS_MELLANOX_BLUEFIELD2) Crypto enabled |
| 15B3 | A2D5 | BlueField-2 | MT42822 | DPU SoC | MT42822 BlueField-2 SoC Crypto disabled | open-gpu nvcst.h (CS_MELLANOX_BLUEFIELD2) Crypto disabled |
| 15B3 | A2D6 | BlueField-2 | MT42822 | DPU NIC | MT42822 BlueField-2 integrated ConnectX-6 Dx network controller | BlueField-2 集成 ConnectX-6 Dx |
| 15B3 | A2D7 | BlueField-3 Lx | MT43162 | DPU SoC | MT43162 BlueField-3 Lx SoC Crypto enabled | BlueField-3 Lx Crypto enabled |
| 15B3 | A2DA | BlueField-3 | MT43244 | DPU SoC | MT43244 BlueField-3 SoC Crypto enabled | open-gpu nvcst.h (CS_MELLANOX_BLUEFIELD3, Disable IOMAP WC) Crypto enabled |
| 15B3 | A2DB | BlueField-3 | MT43244 | DPU SoC | MT43244 BlueField-3 SoC Crypto disabled | open-gpu nvcst.h (CS_MELLANOX_BLUEFIELD3) Crypto disabled |
| 15B3 | A2DC | BlueField-3 | MT43244 | DPU NIC | MT43244 BlueField-3 integrated ConnectX-7 network controller | BlueField-3 集成 ConnectX-7（GB200/GB300 管理/东西向 DPU） |
| 15B3 | A2DD | BlueField-4 | BF4 | DPU SoC | BF4 Family Crypto enabled [BlueField-4 SoC Crypto enabled] | Vera Rubin 世代 BlueField-4 SoC (Crypto enabled) |
| 15B3 | A2DE | BlueField-4 | BF4 | DPU SoC | BF4 Family Crypto disabled [BlueField-4 SoC Crypto disabled] | BlueField-4 SoC (Crypto disabled) |
| 15B3 | A2DF | BlueField-4 | BF4 | DPU NIC | BF4 Family integrated network controller [BlueField-4 integrated network controller] | BlueField-4 集成网络控制器 |
| 15B3 | C2D6 | BlueField-4 | BF4 | Mgmt Interface | BF4 Family Management Interface [BlueField-4 SoC Management Interface] | BlueField-4 管理接口 |
| 15B3 | D2F0 | Quantum | QM8700 | IB Switch | Quantum HDR (200Gbps) switch | Quantum HDR (200G) InfiniBand 交换芯片 |
| 15B3 | D2F2 | Quantum-2 | QM9700 | IB Switch | Quantum-2 NDR (400Gbps) switch | Quantum-2 NDR (400G) InfiniBand 交换芯片 |
| 15B3 | D2F4 | Quantum-3 | Quantum-X800 | IB Switch | Quantum-3 | Quantum-3 XDR (800G) InfiniBand 交换芯片 |
| 15B3 | D2F6 | Quantum-3 CPO | Quantum-X800 | IB Switch CPO | Quantum-3CPO | Quantum-3 共封装光学 (CPO) 交换芯片 |
| 15B3 | CF6C | Spectrum-2 | MT53100 | Eth Switch | MT53100 [Spectrum-2] | 100G/200G Ethernet 交换芯片 |
| 15B3 | CF70 | Spectrum-3 | SN4000 | Eth Switch | Spectrum-3 | 200G/400G Ethernet 交换芯片 |
| 15B3 | CF80 | Spectrum-4 | SN5000 | Eth Switch | Spectrum-4 | 400G/800G Spectrum-X 交换芯片 |
| 15B3 | CF82 | Spectrum-5 | Spectrum-5 | Eth Switch | Spectrum-5 | 新一代 Spectrum-5 交换芯片 |
| 15B3 | CF84 | Spectrum-6 | Spectrum-6 | Eth Switch | Spectrum-6 | Spectrum-6 (含 0277 Tile) |
| 15B3 | CF86 | Spectrum-7 | Spectrum-7 | Eth Switch | Spectrum-7 | Spectrum-7 (含 027E Tile) |
| 15B3 | C788 | Spectrum-8 | Spectrum-8 | Eth Switch | Spectrum-8 | Spectrum-8 (含 027F Tile) |

## 七、Grace（`TH500`）· Vera（`TB500`）· Tegra / Thor / N1 CPU & SoC（40 项）

> [!IMPORTANT]
> Grace（`TH500`）的 6 个 Root Port ID（`22B1–22B4 / 22B8 / 22B9`）和 Thor（`T264`）的 `22D6 / 22DA` 并未录入 `pci.ids`，全部提取自 `open-gpu-kernel-modules` 的 `src/nvidia/inc/kernel/core/nvcst.h`；Vera（`TB500`）的 `2F95–2F99` 与 N1 客户端 SoC `2F88`（`T256`）则已在 `pci.ids v2026.11.19` 与 `nvcst.h` 中双双落地。

| ID | 平台 / CPU | 内部代号 | 功能 | pci.ids 名称 | 驱动 / 官方定义 | 技术说明 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2F95 | Vera CPU | TB500 | PCIe Root Port | TB500 RP x16 | NVIDIA Vera CPU (TB500) PCIe Root Port x16 | pci.ids + open-gpu nvcst.h (CS_NVIDIA_TB500, I/O Coherent + PCIe Atomics) | pci.ids + open-gpu |
| 2F96 | Vera CPU | TB500 | PCIe Root Port | TB500 RP x8 | NVIDIA Vera CPU (TB500) PCIe Root Port x8 | pci.ids + open-gpu nvcst.h (CS_NVIDIA_TB500, Nvidia_TB500_setupFunc) | pci.ids + open-gpu |
| 2F97 | Vera CPU | TB500 | PCIe Root Port | TB500 RP x4 | NVIDIA Vera CPU (TB500) PCIe Root Port x4 | pci.ids + open-gpu nvcst.h (CS_NVIDIA_TB500) | pci.ids + open-gpu |
| 2F98 | Vera CPU | TB500 | PCIe Root Port | TB500 RP x2 | NVIDIA Vera CPU (TB500) PCIe Root Port x2 | pci.ids + open-gpu nvcst.h (CS_NVIDIA_TB500) | pci.ids + open-gpu |
| 2F99 | Vera CPU | TB500 | PCIe Root Port | TB500 RP x1 | NVIDIA Vera CPU (TB500) PCIe Root Port x1 | pci.ids + open-gpu nvcst.h (CS_NVIDIA_TB500) | pci.ids + open-gpu |
| 22B1 | Grace CPU | TH500 | PCIe Root Port | — (未入 pci.ids) | NVIDIA Grace CPU (TH500) RP for GH100 GPU in GH180 | open-gpu nvcst.h (CS_NVIDIA_TH500, I/O Coherent + PCIe Atomics WAR 3562968) | open-gpu nvcst.h |
| 22B2 | Grace CPU | TH500 | PCIe Root Port | — (未入 pci.ids) | NVIDIA Grace CPU (TH500) PCIe Root Port x16 | open-gpu nvcst.h (CS_NVIDIA_TH500; P2P via PCIe switch enabled in chipset_pcie.c) | open-gpu nvcst.h |
| 22B3 | Grace CPU | TH500 | PCIe Root Port | — (未入 pci.ids) | NVIDIA Grace CPU (TH500) PCIe Root Port x4 | open-gpu nvcst.h (CS_NVIDIA_TH500) | open-gpu nvcst.h |
| 22B4 | Grace CPU | TH500 | PCIe Root Port | — (未入 pci.ids) | NVIDIA Grace CPU (TH500) PCIe Root Port x1 | open-gpu nvcst.h (CS_NVIDIA_TH500) | open-gpu nvcst.h |
| 22B8 | Grace CPU | TH500 | PCIe Root Port | — (未入 pci.ids) | NVIDIA Grace CPU (TH500) PCIe Root Port x8 | open-gpu nvcst.h (CS_NVIDIA_TH500) | open-gpu nvcst.h |
| 22B9 | Grace CPU | TH500 | PCIe Root Port | — (未入 pci.ids) | NVIDIA Grace CPU (TH500) PCIe Root Port x2 | open-gpu nvcst.h (CS_NVIDIA_TH500) | open-gpu nvcst.h |
| 22D6 | Thor SoC | T264 | PCIe Root Port | — (未入 pci.ids) | NVIDIA Tegra T264 (Thor) PCIe Root Port x8 | open-gpu nvcst.h (CS_NVIDIA_T264) | open-gpu nvcst.h |
| 22D8 | Thor SoC | T264 | PCIe Root Port | THOR Processor PCI Express Root Port | NVIDIA Tegra T264 (Thor) PCIe Root Port x4 | pci.ids + open-gpu nvcst.h (CS_NVIDIA_T264) | pci.ids + open-gpu |
| 22DA | Thor SoC | T264 | PCIe Root Port | — (未入 pci.ids) | NVIDIA Tegra T264 (Thor) PCIe Root Port x2 | open-gpu nvcst.h (CS_NVIDIA_T264) | open-gpu nvcst.h |
| 22E6 | Thor SoC | T264 | iGPU Root Port | THOR Processor PCI Express x16 Controller | NVIDIA Tegra T264 (Thor) iGPU Root Port | pci.ids + open-gpu nvcst.h (CS_NVIDIA_T264) | pci.ids + open-gpu |
| 22CE | DGX Spark / GB10 | GB10 | PCIe Host Bridge | GB10 GEN5 X4 PCIe host | NVIDIA GB10 Gen5 x4 PCIe Host | pci.ids + Linux quirks.c (quirk_no_bus_reset) | pci.ids + Linux |
| 22D0 | DGX Spark / GB10 | GB10 | PCIe Host Bridge | GB10 GEN4 X1 PCIe host | NVIDIA GB10 Gen4 x1 PCIe Host | pci.ids + Linux quirks.c (quirk_no_bus_reset) | pci.ids + Linux |
| 22D1 | Spark / N1 SoC | T254 / GB20B | PCI Bridge | GB20B PCI bridge | NVIDIA T254 / GB20B PCI Bridge | pci.ids + open-gpu nvcst.h (CS_NVIDIA_T254) | pci.ids + open-gpu |
| 2F88 | N1 Client SoC | T256 (N1) | PCIe Root/Host | T256 | NVIDIA T256 (N1) Client Arm SoC | pci.ids + open-gpu nvcst.h (CS_NVIDIA_T256, comment: NVIDIA T256 (N1)) | pci.ids + open-gpu |
| 200A | Tegra / SoC | NPU | NPU | NPU | NVIDIA Neural Processing Unit (NPU) | Added in pci.ids v2026.11.19 | pci.ids |
| 229A | Orin SoC | T234 | PCIe Root Port | Orin PCIe x8 Root Complex | NVIDIA Tegra T234 (Orin) RP0 x8 | pci.ids + nvcst.h + Linux quirks.c (disable_rp_msi) | pci.ids + Linux + og |
| 229C | Orin SoC | T234 | PCIe Root Port | Orin PCIe x4/x8 Endpoint/Root Complex | NVIDIA Tegra T234 (Orin) RP1 x4/x8 | pci.ids + nvcst.h + Linux quirks.c (disable_rp_msi) | pci.ids + Linux + og |
| 229E | Orin SoC | T234 | PCIe Root Port | Orin PCIe x1 Root Complex | NVIDIA Tegra T234 (Orin) RP2 x1 | pci.ids + nvcst.h + Linux quirks.c (disable_rp_msi) | pci.ids + Linux + og |
| 2296 | Orin / Tegra | Tegra | Virtual NIC | Tegra PCIe Endpoint Virtual Network | Tegra PCIe Endpoint Virtual Network | pci.ids | pci.ids |
| 22C2 | Tegra T23x | T23x | PCIe Root Port | — (未入 pci.ids) | NVIDIA Tegra T23x RP0 | open-gpu nvcst.h (CS_NVIDIA_T23x) | open-gpu nvcst.h |
| 22C3 | Tegra T23x | T23x | PCIe Root Port | — (未入 pci.ids) | NVIDIA Tegra T23x RP1 | open-gpu nvcst.h (CS_NVIDIA_T23x) | open-gpu nvcst.h |
| 1AD0 | Xavier SoC | T194 | PCIe Root Port | Tegra PCIe x8 Endpoint | NVIDIA Tegra V1 (T194 / Xavier) RP0 x8 | pci.ids + nvcst.h + Linux quirks.c | pci.ids + Linux + og |
| 1AD1 | Xavier SoC | T194 | PCIe Root Port | Tegra PCIe x4/x8 Endpoint/Root Complex | NVIDIA Tegra V1 (T194 / Xavier) RP1 x4/x8 | pci.ids + nvcst.h + Linux quirks.c | pci.ids + Linux + og |
| 1AD2 | Xavier SoC | T194 | PCIe Root Port | Tegra PCIe x1 Root Complex | NVIDIA Tegra V1 (T194 / Xavier) RP2 x1 | pci.ids + nvcst.h + Linux quirks.c | pci.ids + Linux + og |
| 1AD3 | Xavier SoC | T194 | SATA | Xavier SATA Controller | NVIDIA Jetson AGX Xavier SATA Controller | pci.ids | pci.ids |
| 10E5 | Parker SoC | T186 | PCIe Root Port | Parker PCIe x4 Root Complex | NVIDIA Tegra P1 (T186 / TX2) RP0 x4 | pci.ids + nvcst.h + Linux quirks.c | pci.ids + Linux + og |
| 10E6 | Parker SoC | T186 | PCIe Root Port | Parker PCIe x1 Root Complex | NVIDIA Tegra P1 (T186 / TX2) RP1 x1 | pci.ids + nvcst.h + Linux quirks.c | pci.ids + Linux + og |
| 0FAE | Tegra X1 | T210 | PCIe Root Port | Tegra X1 PCIe x4 Root Complex | NVIDIA Tegra X1 (T210 / Nano) RP0 x4 | pci.ids + nvcst.h + Linux quirks.c | pci.ids + Linux + og |
| 0FAF | Tegra X1 | T210 | PCIe Root Port | Tegra X1 PCIe x1 Root Complex | NVIDIA Tegra X1 (T210 / Nano) RP1 x1 | pci.ids + nvcst.h + Linux quirks.c | pci.ids + Linux + og |
| 0E12 | Tegra K1 | T124 | PCIe Bridge | TegraK1 PCIe x4 Bridge | NVIDIA Tegra K1 PCIe x4 Bridge | pci.ids + Linux quirks.c | pci.ids + Linux |
| 0E13 | Tegra K1 | T124 | PCIe Bridge | TegraK1 PCIe x1 Bridge | NVIDIA Tegra K1 PCIe x1 Bridge | pci.ids + Linux quirks.c | pci.ids + Linux |
| 0E1C | Tegra 3+ | T30/T114 | PCIe Bridge | Tegra3+ PCIe x4 Bridge | NVIDIA Tegra 3+ PCIe x4 Bridge | pci.ids + Linux quirks.c | pci.ids + Linux |
| 0E1D | Tegra 3+ | T30/T114 | PCIe Bridge | Tegra3+ PCIe x2 Bridge | NVIDIA Tegra 3+ PCIe x2 Bridge | pci.ids + Linux quirks.c | pci.ids + Linux |
| 0BF0 | Tegra 2 | T20 | PCIe Bridge | Tegra2 PCIe x4 Bridge | NVIDIA Tegra 2 PCIe x4 Bridge | pci.ids + Linux quirks.c | pci.ids + Linux |
| 0BF1 | Tegra 2 | T20 | PCIe Bridge | Tegra2 PCIe x2 Bridge | NVIDIA Tegra 2 PCIe x2 Bridge | pci.ids + Linux quirks.c | pci.ids + Linux |

### 7.1 Grace / Vera 非 PCI 硬件标识（Linux 主线 `nvidia_cspmu.c` & `edk2-nvidia`）

Grace（`Tegra241 / TH500`，Neoverse V2 核心）与 Vera（`TB500`，88 核自研 Olympus 核心 + 不对称 SMT + OCP Caliptra Root of Trust）的片上互联与性能计数器通过 **ACPI / Arm CoreSight PMU（CSPMU）** 与 **SMMUv3 CMDQV（`tegra241-cmdqv.c`）** 暴露：

| Arm CSPMU Product ID | Linux `perf` PMU 名称 | 适用平台 | 监控域与关键特性 |
| --- | --- | --- | --- |
| 0x10300000 | nvidia_pcie_pmu_%u | Grace (TH500) | PCIe Root Port 带宽与请求计数（v1） |
| 0x10301000 | nvidia_pcie_pmu_%u_rc_%u | Grace / Vera | PCIe v2 PMU，支持 BDF 过滤与 `dst_loc_pcie_cxl`（CXL 流量计数！） |
| 0x10700000 | nvidia_pcie_tgt_pmu_%u_rc_%u | Vera / Next | PCIe Target 地址区间过滤 PMU（base/mask 64-bit） |
| 0x10400000 | nvidia_nvlink_c2c1_pmu_%u | Grace / Vera | NVLink-C2C Port 1 一致性互联流量 PMU |
| 0x10500000 | nvidia_nvlink_c2c0_pmu_%u | Grace / Vera | NVLink-C2C Port 0 一致性互联流量 PMU |
| 0x10600000 | nvidia_cnvlink_pmu_%u | Grace / Vera | 跨 Socket Coherent NVLink (cNVLink) PMU |
| 0x2CF00000 | nvidia_scf_pmu_%u | Grace (TH500) | Scalable Coherency Fabric (SCF) 缓存/GMEM/CMEM PMU |
| 0x2CF20000 | nvidia_ucf_pmu_%u | Vera / Next | Unified Coherency Fabric (UCF) SLC/Snoop/GMEM/CMEM PMU |

## 八、架构 × SM / Bit-6 硬件分配规律与核对方法论

### 8.1 全架构 × SM / Compute Capability × PCI Hex 段位速查

| 架构 | 芯片 | SM | CC | PCI Hex 段位 | 代表产品 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| Rubin (DC) | GR100 / GR102 | sm_107 | 10.7 | 3000–307F (GR100) / 3080–30FF (GR102) | VR NVL72 (3041), PCIe Faber (3021), R100/R200 | CUDA 13.4/13.5 GA (sm_107a/107f); 328 KB SMEM; 288GB HBM4 (280GB 可用), NVLink 6; open-gpu 620.x |
| Blackwell (Spark/N1X) | GB10 / GB20B | sm_121 | 12.1 | 2E00–2E3F (Linux quirks ATS) | DGX Spark (GB10), RTX Spark N1X (5120/6144-core) | sm_121a; 强制 PCIe ATS 模拟 CXL.cache; 128GB 统一 LPDDR5X |
| Blackwell (Consumer/Pro) | GB202/203/205/206/207 | sm_120 | 12.0 | 2B80–2DFF, 2F00–2F7F | RTX 50 / 5070 SUPER, RTX PRO 6000/5500/5000/4500/4000/2000 | mma.sync (非 tcgen05); FP4/FP6; 另有 GB20C 车载虚拟化 |
| Blackwell (Thor/T268) | GB10B (T264 / T268) | sm_110 | 11.0 | 2B00 (T264), 3400 (T268) | Jetson AGX Thor (2070 FP4 TFLOPS), DRIVE Thor, T268 | CUDA 13.0 由 sm_101 改名; 另有 GB10C |
| Blackwell Ultra (DC) | GB110 / GB112 / GB120 | sm_103 | 10.3 | 3180–327F, 3300–337F | B300 (3182), GB300 Bianca/Galaxy (31C2), GB300-252 (31C3) | sm_103a/103f; 288GB HBM3e; 1400W 级; edk2 确认 GB120 段 3341–337F |
| Blackwell (DC) | GB100 / GB102 | sm_100 | 10.0 | 2900–297F (GB100) / 2980–29FF (GB102) | B100, B200 (180/168GB), GB200 NVL72 (2941), DRIVE P2021 (29BB) | TMEM, tcgen05, 2-SM MMA; sm_100a/100f; nvtrust CC 架构 10 |
| Hopper | GH100 | sm_90 | 9.0 | 2300–237F (+ 23B0/23F0) | H100, H200, H800, H20/H20-3e, GH200 (2342/2345/2348) | WGMMA, TMA; sm_90a; 2301–233F EP vs 2341–237F SH |
| Ada Lovelace | AD102/103/104/106/107 | sm_89 | 8.9 | 2680–28FF | RTX 40 系, RTX 6000 Ada, L40/L40S/L20/L4/L2 | FP8 Transformer Engine |
| Ampere (Orin) | GA10B (T234) | sm_87 | 8.7 | SoC 集成 (RP: 229A/9C/9E) | Jetson AGX Orin, DRIVE Orin | Tegra 嵌入式 iGPU |
| Ampere (Consumer/Pro) | GA102/103/104/106/107 | sm_86 | 8.6 | 2200–227F, 2400–25FF | RTX 30 系, RTX A6000~A2000, A40/A10/A16/A2 | 2× FP32/SM vs sm_80 |
| Ampere (DC) | GA100 | sm_80 | 8.0 | 2080–20FF | A100, A800, A30, AX800, CMP 170HX | HBM2e; TF32 + 原生 FP64 Tensor Core |
| Turing | TU102/104/106/116/117 | sm_75 | 7.5 | 1E00–1FFF, 2180–21FF | RTX 20 / GTX 16, T4/T4G, Quadro RTX 8000 | open-gpu-kernel-modules 支持起点 (81 IDs ✓) |
| Volta | GV100 / GV11B | sm_70 / 72 | 7.0 / 7.2 | 1D80–1DFF (GV100) | Tesla V100 / V100S, TITAN V, Quadro GV100, Xavier (7.2) | 初代 Tensor Core + HBM2 + NVLink 2.0 |
| Pascal | GP100 / GP102–108 / GP10B | sm_60 / 61 / 62 | 6.0–6.2 | 15C0–15FF, 1700–173F, 1B00–1D7F | Tesla P100 (6.0), P40/P4/GTX 10 系 (6.1), TX2 (6.2) | GP100 原生 FP16 + HBM2; GP102–108 补 DP4A |
| Maxwell | GM107–108 / GM200–206 / GM20B | sm_50 / 52 / 53 | 5.0–5.3 | 1340–143F, 1600–167F, 1740–183F | GTX 750/900/TITAN X, Tesla M60/M40/M10/M4, Nano (5.3) | SMM 高能效重构 |
| Kepler | GK104–107 / GK110–208 / GK210 | sm_30 / 35 / 37 | 3.0 / 3.5 / 3.7 | 0FC0–103F, 1180–12BF | GTX 600/700, Tesla K10/K20/K40 (3.5), K80 (3.7) | Dynamic Parallelism; GK210 (K80) 独享 sm_37 |
| Fermi | GF100/110 · GF104–119 | sm_20 / 21 | 2.0 / 2.1 | 06C0–06FF, 0DC0–107F | GTX 480/580, Tesla C2050/M2090 (2.0), GTX 460/560 (2.1) | 初代 IEEE-754 + ECC + L1/L2 缓存 CUDA 架构 |

### 8.2 数据中心 GPU Bit-6（`+0x40`）Endpoint vs Self-Hosted 分配规律

来自 **`NVIDIA/open-gpu-kernel-modules` `kernel-open/nvidia/detect-self-hosted.h`** 与 **`NVIDIA/edk2-nvidia` `TH500GpuDxe/DriverBinding.c`** 的双源码交叉确认：从 Hopper 起，数据中心芯片按 **Bit-6（`+0x40`）** 严格区分独立主机直连（Endpoint，x86/HGX）与 Grace/Vera C2C 一致性内存耦合（Self-Hosted）：

| 芯片家族 | Recovery / 保留基准 | Endpoint 段（`+0x00`） | Self-Hosted C2C 段（`+0x40`） | 源码来源 | 典型实例 |
| --- | --- | --- | --- | --- | --- |
| GH100 (Hopper) | 0x2300 (Recovery) | 0x2301 – 0x233F | 0x2340 – 0x237F | detect-self-hosted.h + edk2 | 2330 H100 SXM (EP) vs 2342/2345/2348 GH200 (SH) |
| GB100 (Blackwell) | 0x2900 (Reserved A) | 0x2901 – 0x293F | 0x2940 – 0x297F | detect-self-hosted.h + edk2 | 2901/2909 B200 (EP) vs 2941/297E GB200 (TH500 SH) |
| GB102 (Blackwell) | 0x2980 (Reserved A) | 0x2981 – 0x29BF | 0x29C0 – 0x29FF | edk2-nvidia TH500GpuDxe | 29BB DRIVE P2021 / 29BC B100 (EP) vs 29C1–29FF (TH500 SH) |
| GB110 (Blackwell Ultra) | 0x3180 (Reserved A) | 0x3181 – 0x31BF (特例 31A1=SH) | 0x31C0 – 0x31FF (+ 31A1) | detect-self-hosted.h + edk2 | 3182 B300 (EP) vs 31C2/31C3 GB300 & 31A1 MaxQ (SH) |
| GB120 (Blackwell Ultra) | 0x3300 / 0x3340 | 0x3301 – 0x333F | 0x3341 – 0x337F | edk2-nvidia TH500GpuDxe | edk2 明确预留 TH500+GB120 SH 段 3341–337F |
| GR100 (Rubin) | 0x3000 (Reserved A) | 0x3000 – 0x303F | 0x3040 – 0x307F | detect-self-hosted.h + edk2 | 3002 SXM / 3021 PCIe Faber (EP) vs 3041 VR NVL72 / 307E / 307F (Vera SH) |
| GR102 (Rubin) | 0x3080 (Reserved A) | 0x3081 – 0x30BF | 0x30C0 – 0x30FF | detect-self-hosted.h + gat | 30C0 Reserved B / 30FF [221B/221C] C2C+SXM (Vera SH) |

### 8.3 Linux 主线内核、PCI-SIG 与八大一手数据源

- **Linux `nvgrace-gpu` + PCI-SIG CXL DVSEC**：主线 `drivers/vfio/pci/nvgrace-gpu/main.c` 明确收录 5 个一致性内存 VFIO ID（`2342` / `2345` / `2348` / `2941` / `31C2`），并通过 PCI-SIG CXL DVSEC（`PCI_VENDOR_ID_CXL`）探测 Blackwell-Next / Rubin 显存就绪状态（物理层仍为 NVLink-C2C，接口走向 CXL 标准化，详见本站 [Blackwell-Next CXL DVSEC 考据](/posts/blackwell-next-cxl-dvsec/)）。
- **Linux `drivers/pci/quirks.c` 的两处 CXL.cache / ATS 特例**：`quirk_nvidia_gpu_ats_required()` 强制对 **`10DE:2E00–2E3F`（GB20B / Spark / N1X）** 与 **`15B3:2101`（ConnectX-10 NVLink-C2C）** 开启 PCIe ATS，注释明确说明这些设备不暴露标准 CXL 配置空间但会发出类似 `CXL.cache` 的一致性事务。
- **Linux Rust 驱动 `nova-core` & `rmconfig.h` & `nvtrust`**：主线 `drivers/gpu/nova-core/gpu.rs` 已定义 `GA100–GA107`、`GH100`、`AD102–AD107`、`GB100/102`、`GB202–GB207`，并留下注释 *`Somewhere in the Rubin timeframe, boot0 will no longer have space to add new GPU IDs.`*；R620 `rmconfig.h` 已枚举 `GB10C / GB20C / GB112 / GR100 / GR102`；`NVIDIA/nvtrust` 将 Blackwell 注册为机密计算硬件架构 `GPU_ARCH = 10`（Hopper 为 `9`）。

1. **`pciutils/pciids`（`pci.ids v2026.11.19`）**：实时核对 `pci-ids.ucw.cz` 一致，`systemd/hwdb` 与 `NVIDIA/go-nvlib` 验证 `>= 0x2900` 零额外条目。
2. **`NVIDIA/open-gpu-kernel-modules`（`620.73.04`，2026-11-18）**：`g_nv_name_released.h`（全部 1,985 条物理+vGPU/MIG 编译表）、`detect-self-hosted.h`、`README.md`、`nvcst.h`、`nvswitch.c`、`rmconfig.h`、`arch/rubin/` 与 `arch/blackwell/`。
3. **`NVIDIA/gpu-admin-tools`（`main`）**：`devid_chips.py`、`devid_names.py`、`devid_properties.py`（子系统级 `is_sxm` / `is_pcie` / `has_c2c` 硬件属性）。
4. **`NVIDIA/DCGM`（`master` / `v4.7.0`）**：`nvvs/diag-skus.yaml.in`（实测目标功耗、内部板卡代号 `Bianca / Galaxy / Galaxy TS2 / TS4 / PG153 / RTX6000D LC`）与 Rubin `3041 / 307E / 307F` 诊断支持。
5. **`NVIDIA/edk2-nvidia`（`main`）**：`TH500GpuDxe/efihand/DriverBinding.c`（Endpoint vs Self-Hosted Bit-6 分配规则与 `GB120 3341–337F`）。
6. **`torvalds/linux` 主线源码**：`nvgrace-gpu/main.c`、`nova-core/gpu.rs`、`drivers/pci/quirks.c`、`drivers/perf/arm_cspmu/nvidia_cspmu.c`、`sound/hda/controllers/intel.c`。
7. **`NVIDIA/nvtrust`**：机密计算 GPU 架构校验（`Hopper=9 / Blackwell=10`）与 VBIOS RIM 签章识别。
8. **NVIDIA 官方规格书、GTC 2026 与 CUDA 13.5 GA 文档**：核实 Vera Rubin `sm_107`、B300/GB300/DGX Station GB300/DGX Spark/Thor/RTX PRO Blackwell 与 GeForce RTX 50 全系官方参数与定位。

## 九、Ampere 之前的历史架构：Turing ← Fermi（6 代 · 681 项）

<div class="legacy-fold-bar" id="legacy-pre-ampere" data-fold-section="legacy-pre-ampere" data-expanded="false" data-closed-label="展开 Ampere 前 6 代历史架构（681 项）" data-open-label="收起历史架构（Turing ~ Fermi）" data-toc-closed-label="展开 6 代老卡目录 (Turing~Fermi)" data-toc-open-label="收起 6 代老卡目录">
  <div class="legacy-fold-desc">包含 <strong>Turing（124 · 开放驱动起点）</strong>、<strong>Volta（21）</strong>、<strong>Pascal（113）</strong>、<strong>Maxwell（91）</strong>、<strong>Kepler（197）</strong> 与 <strong>Fermi（135）</strong>，共 <strong>681 个</strong> PCI Device ID。为保持正文与目录清爽默认折叠，点击按钮（正文或目录中均可）一键展开 / 收起。</div>
  <button type="button" class="legacy-fold-btn" aria-expanded="false"><span class="legacy-fold-arrow">▶</span><span class="legacy-fold-btn-label">展开 Ampere 前 6 代历史架构（681 项）</span></button>
</div>

### Turing（124 个 ID · sm_75 · 开放驱动支持起点）

**NVIDIA Open GPU Kernel Modules（`620.73.04`）官方支持的最低代际**（共 **81 个** ID 在开放驱动列表内 ✓），涵盖 **TU102 / TU104 / TU106 / TU116 / TU117**（RTX 20 系、GTX 16 系、Quadro RTX 8000~3000、推理常青树 **Tesla T4 `1EB8/1EB9` & T4G `1EB4`**），并包含 Turing 特有的板载 **VirtualLink USB 3.1 + Type-C UCSI** 控制器及 HD Audio。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1E02 | TU102 | sm_75 | GPU | TU102 [TITAN RTX] | NVIDIA TITAN RTX |  | ✓ |
| 1E03 | TU102 | sm_75 | GPU | TU102 [GeForce RTX 2080 Ti 12GB] | — |  | — |
| 1E04 | TU102 | sm_75 | GPU | TU102 [GeForce RTX 2080 Ti] | NVIDIA GeForce RTX 2080 Ti |  | ✓ |
| 1E07 | TU102 | sm_75 | GPU | TU102 [GeForce RTX 2080 Ti Rev. A] | NVIDIA GeForce RTX 2080 Ti |  | ✓ |
| 1E09 | TU102 | sm_75 | GPU | TU102 [CMP 50HX] | NVIDIA CMP 50HX |  | ✓ |
| 1E2D | TU102 | sm_75 | GPU | TU102 [GeForce RTX 2080 Ti Engineering Sample] | — | [ES 工程样品] | — |
| 1E2E | TU102 | sm_75 | GPU | TU102 [GeForce RTX 2080 Ti 12GB Engineering Sample] | — | [ES 工程样品] | — |
| 1E30 | TU102 | sm_75 | GPU | TU102GL [Quadro RTX 6000/8000] | Quadro RTX 6000 / Quadro RTX 8000 | DCGM: RTX 8000 and 6000 (Quadro) 259W | ✓ |
| 1E35 | TU102 | sm_75 | GPU | TU102GL [Tesla T10] | — |  | — |
| 1E36 | TU102 | sm_75 | GPU | TU102GL [Quadro RTX 6000] | Quadro RTX 6000 |  | ✓ |
| 1E37 | TU102 | sm_75 | GPU | TU102GL [Tesla T10 16GB / GRID RTX T10-2/T10-4/T10-8] | Tesla T10 (gat/DCGM) | DCGM: Tesla T10 149W | — |
| 1E38 | TU102 | sm_75 | GPU | TU102GL [Tesla T40 24GB] | Tesla T40 - TU102-895 (gat/DCGM) | DCGM: Tesla T40 - TU102-895 249W | — |
| 1E3C | TU102 | sm_75 | GPU | TU102GL | — |  | — |
| 1E3D | TU102 | sm_75 | GPU | TU102GL | — |  | — |
| 1E3E | TU102 | sm_75 | GPU | TU102GL | — |  | — |
| 1E78 | TU102 | sm_75 | GPU | TU102GL [Quadro RTX 6000/8000] | Quadro RTX 8000 / Quadro RTX 6000 | DCGM: RTX 6000/8000 passive SKUs 249W | ✓ |
| 1E81 | TU104 | sm_75 | GPU | TU104 [GeForce RTX 2080 SUPER] | NVIDIA GeForce RTX 2080 SUPER |  | ✓ |
| 1E82 | TU104 | sm_75 | GPU | TU104 [GeForce RTX 2080] | NVIDIA GeForce RTX 2080 |  | ✓ |
| 1E84 | TU104 | sm_75 | GPU | TU104 [GeForce RTX 2070 SUPER] | NVIDIA GeForce RTX 2070 SUPER |  | ✓ |
| 1E87 | TU104 | sm_75 | GPU | TU104 [GeForce RTX 2080 Rev. A] | NVIDIA GeForce RTX 2080 |  | ✓ |
| 1E89 | TU104 | sm_75 | GPU | TU104 [GeForce RTX 2060] | NVIDIA GeForce RTX 2060 |  | ✓ |
| 1E90 | TU104 | sm_75 | GPU | TU104M [GeForce RTX 2080 Mobile] | NVIDIA GeForce RTX 2080 / NVIDIA GeForce RTX 2080 with Max-Q Design |  | ✓ |
| 1E91 | TU104 | sm_75 | GPU | TU104M [GeForce RTX 2070 SUPER Mobile / Max-Q] | NVIDIA GeForce RTX 2070 Super / NVIDIA GeForce RTX 2070 Super with Max-Q Design |  | ✓ |
| 1E93 | TU104 | sm_75 | GPU | TU104M [GeForce RTX 2080 SUPER Mobile / Max-Q] | NVIDIA GeForce RTX 2080 Super / NVIDIA GeForce RTX 2080 Super with Max-Q Design |  | ✓ |
| 1EAB | TU104 | sm_75 | GPU | TU104M | — |  | — |
| 1EAE | TU104 | sm_75 | GPU | TU104M [GeForce GTX 2080 Engineering Sample] | — | [ES 工程样品] | — |
| 1EB0 | TU104 | sm_75 | GPU | TU104GL [Quadro RTX 5000] | Quadro RTX 5000 |  | ✓ |
| 1EB1 | TU104 | sm_75 | GPU | TU104GL [Quadro RTX 4000] | Quadro RTX 4000 |  | ✓ |
| 1EB4 | TU104 | sm_75 | GPU | TU104GL [T4G] | T4G (gat/DCGM) | DCGM: T4G 69W | — |
| 1EB5 | TU104 | sm_75 | GPU | TU104GLM [Quadro RTX 5000 Mobile / Max-Q] | Quadro RTX 5000 / Quadro RTX 5000 with Max-Q Design |  | ✓ |
| 1EB6 | TU104 | sm_75 | GPU | TU104GLM [Quadro RTX 4000 Mobile / Max-Q] | Quadro RTX 4000 / Quadro RTX 4000 with Max-Q Design |  | ✓ |
| 1EB8 | TU104 | sm_75 | GPU | TU104GL [Tesla T4] | Tesla T4 | DCGM: Tesla T4 - TU104_PG183_SKU200 65W | ✓ |
| 1EB9 | TU104 | sm_75 | GPU | TU104GL | T4 (gat/DCGM) |  | — |
| 1EBA | TU104 | sm_75 | GPU | TU104GL [PG189 SKU600] | Nvidia Turing Auto Module (gat/DCGM) | DCGM: Nvidia Turing Auto Module 188W | — |
| 1EBE | TU104 | sm_75 | GPU | TU104GL | — |  | — |
| 1EC2 | TU104 | sm_75 | GPU | TU104 [GeForce RTX 2070 SUPER] | NVIDIA GeForce RTX 2070 SUPER |  | ✓ |
| 1EC7 | TU104 | sm_75 | GPU | TU104 [GeForce RTX 2070 SUPER] | NVIDIA GeForce RTX 2070 SUPER |  | ✓ |
| 1ED0 | TU104 | sm_75 | GPU | TU104BM [GeForce RTX 2080 Mobile] | NVIDIA GeForce RTX 2080 / NVIDIA GeForce RTX 2080 with Max-Q Design |  | ✓ |
| 1ED1 | TU104 | sm_75 | GPU | TU104BM [GeForce RTX 2070 SUPER Mobile / Max-Q] | NVIDIA GeForce RTX 2070 Super / NVIDIA GeForce RTX 2070 Super with Max-Q Design |  | ✓ |
| 1ED3 | TU104 | sm_75 | GPU | TU104BM [GeForce RTX 2080 SUPER Mobile / Max-Q] | NVIDIA GeForce RTX 2080 Super / NVIDIA GeForce RTX 2080 Super with Max-Q Design |  | ✓ |
| 1EF5 | TU104 | sm_75 | GPU | TU104GLM [Quadro RTX 5000 Mobile Refresh] | Quadro RTX 5000 |  | ✓ |
| 1F02 | TU106 | sm_75 | GPU | TU106 [GeForce RTX 2070] | NVIDIA GeForce RTX 2070 |  | ✓ |
| 1F03 | TU106 | sm_75 | GPU | TU106 [GeForce RTX 2060 12GB] | NVIDIA GeForce RTX 2060 |  | ✓ |
| 1F04 | TU106 | sm_75 | GPU | TU106 | — |  | — |
| 1F06 | TU106 | sm_75 | GPU | TU106 [GeForce RTX 2060 SUPER] | NVIDIA GeForce RTX 2060 SUPER |  | ✓ |
| 1F07 | TU106 | sm_75 | GPU | TU106 [GeForce RTX 2070 Rev. A] | NVIDIA GeForce RTX 2070 |  | ✓ |
| 1F08 | TU106 | sm_75 | GPU | TU106 [GeForce RTX 2060 Rev. A] | NVIDIA GeForce RTX 2060 |  | ✓ |
| 1F09 | TU106 | sm_75 | GPU | TU106 [GeForce GTX 1660 SUPER] | — |  | — |
| 1F0A | TU106 | sm_75 | GPU | TU106 [GeForce GTX 1650] | NVIDIA GeForce GTX 1650 |  | ✓ |
| 1F0B | TU106 | sm_75 | GPU | TU106 [CMP 40HX] | NVIDIA CMP 40HX |  | ✓ |
| 1F10 | TU106 | sm_75 | GPU | TU106M [GeForce RTX 2070 Mobile] | NVIDIA GeForce RTX 2070 / NVIDIA GeForce RTX 2070 with Max-Q Design |  | ✓ |
| 1F11 | TU106 | sm_75 | GPU | TU106M [GeForce RTX 2060 Mobile] | NVIDIA GeForce RTX 2060 |  | ✓ |
| 1F12 | TU106 | sm_75 | GPU | TU106M [GeForce RTX 2060 Max-Q] | NVIDIA GeForce RTX 2060 / NVIDIA GeForce RTX 2060 with Max-Q Design |  | ✓ |
| 1F14 | TU106 | sm_75 | GPU | TU106M [GeForce RTX 2070 Mobile / Max-Q Refresh] | NVIDIA GeForce RTX 2070 / NVIDIA GeForce RTX 2070 with Max-Q Design |  | ✓ |
| 1F15 | TU106 | sm_75 | GPU | TU106M [GeForce RTX 2060 Mobile] | NVIDIA GeForce RTX 2060 |  | ✓ |
| 1F2E | TU106 | sm_75 | GPU | TU106M | — |  | — |
| 1F36 | TU106 | sm_75 | GPU | TU106GLM [Quadro RTX 3000 Mobile / Max-Q] | Quadro RTX 3000 / Quadro RTX 3000 with Max-Q Design |  | ✓ |
| 1F42 | TU106 | sm_75 | GPU | TU106 [GeForce RTX 2060 SUPER] | NVIDIA GeForce RTX 2060 SUPER |  | ✓ |
| 1F47 | TU106 | sm_75 | GPU | TU106 [GeForce RTX 2060 SUPER] | NVIDIA GeForce RTX 2060 SUPER |  | ✓ |
| 1F50 | TU106 | sm_75 | GPU | TU106BM [GeForce RTX 2070 Mobile / Max-Q] | NVIDIA GeForce RTX 2070 / NVIDIA GeForce RTX 2070 with Max-Q Design |  | ✓ |
| 1F51 | TU106 | sm_75 | GPU | TU106BM [GeForce RTX 2060 Mobile] | NVIDIA GeForce RTX 2060 |  | ✓ |
| 1F54 | TU106 | sm_75 | GPU | TU106BM [GeForce RTX 2070 Mobile] | NVIDIA GeForce RTX 2070 / NVIDIA GeForce RTX 2070 with Max-Q Design |  | ✓ |
| 1F55 | TU106 | sm_75 | GPU | TU106BM [GeForce RTX 2060 Mobile] | NVIDIA GeForce RTX 2060 |  | ✓ |
| 1F76 | TU106 | sm_75 | GPU | TU106GLM [Quadro RTX 3000 Mobile Refresh] | Quadro RTX 3000 / Matrox D-Series D2450 / Matrox D-Series D2480 |  | ✓ |
| 1F81 | TU117 | sm_75 | GPU | TU117 | — |  | — |
| 1F82 | TU117 | sm_75 | GPU | TU117 [GeForce GTX 1650] | NVIDIA GeForce GTX 1650 |  | ✓ |
| 1F83 | TU117 | sm_75 | GPU | TU117 [GeForce GTX 1630] | NVIDIA GeForce GTX 1630 |  | ✓ |
| 1F91 | TU117 | sm_75 | GPU | TU117M [GeForce GTX 1650 Mobile / Max-Q] | NVIDIA GeForce GTX 1650 / NVIDIA GeForce GTX 1650 with Max-Q Design |  | ✓ |
| 1F92 | TU117 | sm_75 | GPU | TU117M [GeForce GTX 1650 Mobile] | — |  | — |
| 1F94 | TU117 | sm_75 | GPU | TU117M [GeForce GTX 1650 Mobile] | — |  | — |
| 1F95 | TU117 | sm_75 | GPU | TU117M [GeForce GTX 1650 Ti Mobile] | NVIDIA GeForce GTX 1650 Ti / NVIDIA GeForce GTX 1650 Ti with Max-Q Design |  | ✓ |
| 1F96 | TU117 | sm_75 | GPU | TU117M [GeForce GTX 1650 Mobile / Max-Q] | NVIDIA GeForce GTX 1650 / NVIDIA GeForce GTX 1650 with Max-Q Design |  | ✓ |
| 1F97 | TU117 | sm_75 | GPU | TU117M [GeForce MX450] | NVIDIA GeForce MX450 |  | ✓ |
| 1F98 | TU117 | sm_75 | GPU | TU117M [GeForce MX450] | NVIDIA GeForce MX450 |  | ✓ |
| 1F99 | TU117 | sm_75 | GPU | TU117M [GeForce GTX 1650 Mobile / Max-Q] | NVIDIA GeForce GTX 1650 / NVIDIA GeForce GTX 1650 with Max-Q Design |  | ✓ |
| 1F9C | TU117 | sm_75 | GPU | TU117M [GeForce MX450] | NVIDIA GeForce MX450 |  | ✓ |
| 1F9D | TU117 | sm_75 | GPU | TU117M [GeForce GTX 1650 Mobile / Max-Q] | NVIDIA GeForce GTX 1650 / NVIDIA GeForce GTX 1650 with Max-Q Design |  | ✓ |
| 1F9F | TU117 | sm_75 | GPU | TU117M [GeForce MX550] | NVIDIA GeForce MX550 |  | ✓ |
| 1FA0 | TU117 | sm_75 | GPU | TU117M [GeForce MX550] | NVIDIA GeForce MX550 |  | ✓ |
| 1FA1 | TU117 | sm_75 | GPU | TU117M | — |  | — |
| 1FAE | TU117 | sm_75 | GPU | TU117GL | — |  | — |
| 1FB0 | TU117 | sm_75 | GPU | TU117GLM [Quadro T1000 Mobile] | NVIDIA T1000 / NVIDIA DGX Display |  | ✓ |
| 1FB1 | TU117 | sm_75 | GPU | TU117GL [T600] | NVIDIA T600 |  | ✓ |
| 1FB2 | TU117 | sm_75 | GPU | TU117GLM [Quadro T400 Mobile] | NVIDIA T400 |  | ✓ |
| 1FB6 | TU117 | sm_75 | GPU | TU117GLM [T600 Laptop GPU] | NVIDIA T600 Laptop GPU |  | ✓ |
| 1FB7 | TU117 | sm_75 | GPU | TU117GLM [T550 Laptop GPU] | NVIDIA T550 Laptop GPU |  | ✓ |
| 1FB8 | TU117 | sm_75 | GPU | TU117GLM [Quadro T2000 Mobile / Max-Q] | Quadro T2000 / Quadro T2000 with Max-Q Design |  | ✓ |
| 1FB9 | TU117 | sm_75 | GPU | TU117GLM [Quadro T1000 Mobile] | Quadro T1000 / Quadro T1000 with Max-Q Design |  | ✓ |
| 1FBA | TU117 | sm_75 | GPU | TU117GLM [T600 Mobile] | NVIDIA T600 Laptop GPU |  | ✓ |
| 1FBB | TU117 | sm_75 | GPU | TU117GLM [Quadro T500 Mobile] | NVIDIA T500 |  | ✓ |
| 1FBC | TU117 | sm_75 | GPU | TU117GLM [T1200 Laptop GPU] | NVIDIA T1200 Laptop GPU |  | ✓ |
| 1FBF | TU117 | sm_75 | GPU | TU117GL | — |  | — |
| 1FD9 | TU117 | sm_75 | GPU | TU117BM [GeForce GTX 1650 Mobile Refresh] | — |  | — |
| 1FDD | TU117 | sm_75 | GPU | TU117BM [GeForce GTX 1650 Mobile Refresh] | NVIDIA GeForce GTX 1650 |  | ✓ |
| 1FF0 | TU117 | sm_75 | GPU | TU117GL [T1000 8GB] | NVIDIA T1000 8GB |  | ✓ |
| 1FF2 | TU117 | sm_75 | GPU | TU117GL [T400 4GB / T400E] | NVIDIA T400 4GB / NVIDIA T400E |  | ✓ |
| 1FF9 | TU117 | sm_75 | GPU | TU117GLM [Quadro T1000 Mobile] | Quadro T1000 |  | ✓ |
| 2182 | TU116 | sm_75 | GPU | TU116 [GeForce GTX 1660 Ti] | NVIDIA GeForce GTX 1660 Ti |  | ✓ |
| 2183 | TU116 | sm_75 | GPU | TU116 | — |  | — |
| 2184 | TU116 | sm_75 | GPU | TU116 [GeForce GTX 1660] | NVIDIA GeForce GTX 1660 |  | ✓ |
| 2186 | TU116 | sm_75 | GPU | TU116 [PG160 SKU18] | — |  | — |
| 2187 | TU116 | sm_75 | GPU | TU116 [GeForce GTX 1650 SUPER] | NVIDIA GeForce GTX 1650 SUPER |  | ✓ |
| 2188 | TU116 | sm_75 | GPU | TU116 [GeForce GTX 1650] | NVIDIA GeForce GTX 1650 |  | ✓ |
| 2189 | TU116 | sm_75 | GPU | TU116 [CMP 30HX] | NVIDIA CMP 30HX |  | ✓ |
| 2191 | TU116 | sm_75 | GPU | TU116M [GeForce GTX 1660 Ti Mobile] | NVIDIA GeForce GTX 1660 Ti / NVIDIA GeForce GTX 1660 Ti with Max-Q Design |  | ✓ |
| 2192 | TU116 | sm_75 | GPU | TU116M [GeForce GTX 1650 Ti Mobile] | NVIDIA GeForce GTX 1650 Ti |  | ✓ |
| 21AE | TU116 | sm_75 | GPU | TU116GL | — |  | — |
| 21BF | TU116 | sm_75 | GPU | TU116GL | — |  | — |
| 21C2 | TU116 | sm_75 | GPU | TU116 | — |  | — |
| 21C3 | TU116 | sm_75 | GPU | TU116 | — |  | — |
| 21C4 | TU116 | sm_75 | GPU | TU116 [GeForce GTX 1660 SUPER] | NVIDIA GeForce GTX 1660 SUPER |  | ✓ |
| 21D1 | TU116 | sm_75 | GPU | TU116BM [GeForce GTX 1660 Ti Mobile] | NVIDIA GeForce GTX 1660 Ti |  | ✓ |
| 10F7 | TU102 | sm_75 | **HD Audio** | TU102 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 10F8 | TU104 | sm_75 | **HD Audio** | TU104 HD Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 10F9 | TU106 | sm_75 | **HD Audio** | TU106 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 1AD6 | TU102 | sm_75 | **USB 3.1** | TU102 USB 3.1 Host Controller | — | On-board VirtualLink USB/Type-C controller on Turing GPU | — |
| 1AD7 | TU102 | sm_75 | **USB-C UCSI** | TU102 USB Type-C UCSI Controller | — | On-board VirtualLink USB/Type-C controller on Turing GPU | — |
| 1AD8 | TU104 | sm_75 | **USB 3.1** | TU104 USB 3.1 Host Controller | — | On-board VirtualLink USB/Type-C controller on Turing GPU | — |
| 1AD9 | TU104 | sm_75 | **USB-C UCSI** | TU104 USB Type-C UCSI Controller | — | On-board VirtualLink USB/Type-C controller on Turing GPU | — |
| 1ADA | TU106 | sm_75 | **USB 3.1** | TU106 USB 3.1 Host Controller | — | On-board VirtualLink USB/Type-C controller on Turing GPU | — |
| 1ADB | TU106 | sm_75 | **USB-C UCSI** | TU106 USB Type-C UCSI Controller | — | On-board VirtualLink USB/Type-C controller on Turing GPU | — |
| 1AEB | TU116 | sm_75 | **HD Audio** | TU116 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 1AEC | TU116 | sm_75 | **USB 3.1** | TU116 USB 3.1 Host Controller | — | On-board VirtualLink USB/Type-C controller on Turing GPU | — |
| 1AED | TU116 | sm_75 | **USB-C UCSI** | TU116 USB Type-C UCSI Controller | — | On-board VirtualLink USB/Type-C controller on Turing GPU | — |

### Volta（21 个 ID · sm_70 / 72 · 初代 Tensor Core）

**GV100** 单芯片（`sm_70`；Jetson AGX Xavier 嵌入式 `GV11B` 为 `sm_72`，其 PCIe RC 归入第七章）。虽不在开放内核模块支持列表内（仅闭源 R580 及之前分支支持），但在存量集群中 **V100 SXM2 16GB/32GB（`1DB0/1DB1`）**、**V100 PCIe 16GB/32GB（`1DB4/1DB6`）**、**V100S（`1DF6`）** 与 **DGX-1V / DGX Station（`1DBD/1DB2`）** 依然极常见。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1D81 | GV100 | sm_70 | GPU | GV100 [TITAN V] | — |  | — |
| 1D83 | GV100 | sm_70 | GPU | GV100 [CMP 100-200] | — |  | — |
| 1D84 | GV100 | sm_70 | GPU | GV100 [CMP 100-210] | — |  | — |
| 1DB0 | GV100 | sm_70 | GPU | GV100GL [Tesla GV100 SXM2-16GB SKU 890] | Tesla GV100 SXM2-16GB SKU 890 (gat/DCGM) | DCGM: Tesla GV100 SXM2-16GB SKU 890 299W | — |
| 1DB1 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 SXM2 16GB] | V100 (gat/DCGM) | DCGM: Tesla GV100 SXM2-32GB SKU 895 299W | — |
| 1DB2 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 DGXS 16GB] | V100 (gat/DCGM) | DCGM: Tesla GV100 DGX Station 299W | — |
| 1DB3 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 FHHL 16GB] | V100 (gat/DCGM) | DCGM: Tesla V100-HS 149W | — |
| 1DB4 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 PCIe 16GB] | V100 (gat/DCGM) | DCGM: Tesla GV100 PCIE-16GB SKU 893 249W | — |
| 1DB5 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 SXM2 32GB] | V100 (gat/DCGM) | DCGM: Tesla V100 32GB 299W | — |
| 1DB6 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 PCIe 32GB] | V100 (gat/DCGM) | DCGM: Tesla V100 PCI-E-32GB (Passive) 249W | — |
| 1DB7 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 DGXS 32GB] | V100 (gat/DCGM) | DCGM: Tesla V100 DGX-Station 32GB 299W | — |
| 1DB8 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 SXM3 32GB] | V100 (gat/DCGM) | DCGM: Tesla V100 DGX-Station 32GB 349W | — |
| 1DBA | GV100 | sm_70 | GPU | GV100GL [Quadro GV100] | — |  | — |
| 1DBD | GV100 | sm_70 | GPU | GV100GL [Tesla GV100 DGX1-V] | Tesla GV100 DGX1-V (gat/DCGM) | DCGM: Tesla GV100 DGX1-V 299W | — |
| 1DBE | GV100 | sm_70 | GPU | GV100 Engineering Sample | — | [ES 工程样品] | — |
| 1DC1 | GV100 | sm_70 | GPU | GV100 [CMP 100-200] | — |  | — |
| 1DF0 | GV100 | sm_70 | GPU | GV100GL [Tesla PG500-216] | — |  | — |
| 1DF2 | GV100 | sm_70 | GPU | GV100GL [Tesla PG503-216] | PG50x-216 (gat/DCGM) | DCGM: PG50x-216 300W | — |
| 1DF4 | GV100 | sm_70 | GPU | GV100 [CMP 100-210] | V100 (gat/DCGM) |  | — |
| 1DF5 | GV100 | sm_70 | GPU | GV100GL [Tesla V100 SXM2 16GB] | V100 (gat/DCGM) |  | — |
| 1DF6 | GV100 | sm_70 | GPU | GV100GL [Tesla V100S PCIe 32GB] | V100S (gat/DCGM) | DCGM: V100S 249W | — |

### Pascal（113 个 ID · sm_60 / 61）

数据中心 **GP100**（`sm_60`，Tesla P100 SXM2/PCIe，初代 HBM2 + NVLink 1.0 + 原生 FP16）与 **GP102–GP108**（`sm_61`，GTX 10 系 / TITAN Xp / Quadro P 系 / **Tesla P40 `1B38`、P10 `1B39`、P6 `1BB4`、P4 `1BB3`**）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 15C2 | GP100 | sm_60 | GPU | GP100 [CMP 100-100] | — |  | — |
| 15F0 | GP100 | sm_60 | GPU | GP100GL [Quadro GP100] | — |  | — |
| 15F1 | GP100 | sm_60 | GPU | GP100GL | — |  | — |
| 15F7 | GP100 | sm_60 | GPU | GP100GL [Tesla P100 PCIe 12GB] | P100 (gat/DCGM) | DCGM: Tesla P100-PCIE-12GB 249W | — |
| 15F8 | GP100 | sm_60 | GPU | GP100GL [Tesla P100 PCIe 16GB] | P100 (gat/DCGM) | DCGM: Tesla P100-PCIE-16GB 249W | — |
| 15F9 | GP100 | sm_60 | GPU | GP100GL [Tesla P100 SXM2 16GB] | P100 (gat/DCGM) | DCGM: Tesla P100-SXM2-16GB 299W | — |
| 15FA | GP100 | sm_60 | GPU | GP100GL [DGX Station / PH402 SKU 200] | DGX Station (gat/DCGM) | DCGM: DGX Station 249W | — |
| 15FB | GP100 | sm_60 | GPU | GP100GL [GP100 SKU 200] | GP100 SKU 200 (gat/DCGM) | DCGM: GP100 SKU 200 249W | — |
| 15FC | GP100 | sm_60 | GPU | GP100GL [Tesla P100-DGXS-16GB] | P100 (gat/DCGM) | DCGM: GP100 SKU 201 299W | — |
| 15FF | GP100 | sm_60 | GPU | GP100GL [GP100 SKU 15ff] | GP100 SKU 15ff (gat/DCGM) | DCGM: GP100 SKU 15ff 249W | — |
| 1725 | GP100 | sm_60 | GPU | GP100 | — |  | — |
| 172E | GP100 | sm_60 | GPU | GP100 | — |  | — |
| 172F | GP100 | sm_60 | GPU | GP100 | — |  | — |
| 1B00 | GP102 | sm_61 | GPU | GP102 [TITAN X Pascal] | — |  | — |
| 1B01 | GP102 | sm_61 | GPU | GP102 [GeForce GTX 1080 Ti 10GB] | — |  | — |
| 1B02 | GP102 | sm_61 | GPU | GP102 [TITAN Xp] | — |  | — |
| 1B04 | GP102 | sm_61 | GPU | GP102 | — |  | — |
| 1B06 | GP102 | sm_61 | GPU | GP102 [GeForce GTX 1080 Ti] | — |  | — |
| 1B07 | GP102 | sm_61 | GPU | GP102 [P102-100] | — |  | — |
| 1B30 | GP102 | sm_61 | GPU | GP102GL [Quadro P6000] | — |  | — |
| 1B38 | GP102 | sm_61 | GPU | GP102GL [Tesla P40] | P40 (gat/DCGM) | DCGM: Tesla P40 249W | — |
| 1B39 | GP102 | sm_61 | GPU | GP102GL [Tesla P10] | Tesla P10 (gat/DCGM) | DCGM: Tesla P10 149W | — |
| 1B70 | GP102 | sm_61 | GPU | GP102GL | — |  | — |
| 1B78 | GP102 | sm_61 | GPU | GP102GL | — |  | — |
| 1B80 | GP104 | sm_61 | GPU | GP104 [GeForce GTX 1080] | — |  | — |
| 1B81 | GP104 | sm_61 | GPU | GP104 [GeForce GTX 1070] | — |  | — |
| 1B82 | GP104 | sm_61 | GPU | GP104 [GeForce GTX 1070 Ti] | — |  | — |
| 1B83 | GP104 | sm_61 | GPU | GP104 [GeForce GTX 1060 6GB] | — |  | — |
| 1B84 | GP104 | sm_61 | GPU | GP104 [GeForce GTX 1060 3GB] | — |  | — |
| 1B87 | GP104 | sm_61 | GPU | GP104 [P104-100] | — |  | — |
| 1BA0 | GP104 | sm_61 | GPU | GP104M [GeForce GTX 1080 Mobile] | — |  | — |
| 1BA1 | GP104 | sm_61 | GPU | GP104M [GeForce GTX 1070 Mobile] | — |  | — |
| 1BA2 | GP104 | sm_61 | GPU | GP104M [GeForce GTX 1070 Mobile] | — |  | — |
| 1BA9 | GP104 | sm_61 | GPU | GP104M | — |  | — |
| 1BAA | GP104 | sm_61 | GPU | GP104M | — |  | — |
| 1BAD | GP104 | sm_61 | GPU | GP104 [GeForce GTX 1070 Engineering Sample] | — | [ES 工程样品] | — |
| 1BB0 | GP104 | sm_61 | GPU | GP104GL [Quadro P5000] | — |  | — |
| 1BB1 | GP104 | sm_61 | GPU | GP104GL [Quadro P4000] | — |  | — |
| 1BB3 | GP104 | sm_61 | GPU | GP104GL [Tesla P4] | P4 (gat/DCGM) | DCGM: Tesla P4 50W | — |
| 1BB4 | GP104 | sm_61 | GPU | GP104GL [Tesla P6] | Tesla P6 (gat/DCGM) | DCGM: Tesla P6 89W | — |
| 1BB5 | GP104 | sm_61 | GPU | GP104GLM [Quadro P5200 Mobile] | — |  | — |
| 1BB6 | GP104 | sm_61 | GPU | GP104GLM [Quadro P5000 Mobile] | — |  | — |
| 1BB7 | GP104 | sm_61 | GPU | GP104GLM [Quadro P4000 Mobile] | — |  | — |
| 1BB8 | GP104 | sm_61 | GPU | GP104GLM [Quadro P3000 Mobile] | — |  | — |
| 1BB9 | GP104 | sm_61 | GPU | GP104GLM [Quadro P4200 Mobile] | — |  | — |
| 1BBB | GP104 | sm_61 | GPU | GP104GLM [Quadro P3200 Mobile] | — |  | — |
| 1BC7 | GP104 | sm_61 | GPU | GP104 [P104-101] | — |  | — |
| 1BE0 | GP104 | sm_61 | GPU | GP104BM [GeForce GTX 1080 Mobile] | — |  | — |
| 1BE1 | GP104 | sm_61 | GPU | GP104BM [GeForce GTX 1070 Mobile] | — |  | — |
| 1C00 | GP106 | sm_61 | GPU | GP106 | — |  | — |
| 1C01 | GP106 | sm_61 | GPU | GP106 | — |  | — |
| 1C02 | GP106 | sm_61 | GPU | GP106 [GeForce GTX 1060 3GB] | — |  | — |
| 1C03 | GP106 | sm_61 | GPU | GP106 [GeForce GTX 1060 6GB] | — |  | — |
| 1C04 | GP106 | sm_61 | GPU | GP106 [GeForce GTX 1060 5GB] | — |  | — |
| 1C06 | GP106 | sm_61 | GPU | GP106 [GeForce GTX 1060 6GB Rev. 2] | — |  | — |
| 1C07 | GP106 | sm_61 | GPU | GP106 [P106-100] | — |  | — |
| 1C09 | GP106 | sm_61 | GPU | GP106 [P106-090] | — |  | — |
| 1C20 | GP106 | sm_61 | GPU | GP106M [GeForce GTX 1060 Mobile] | — |  | — |
| 1C21 | GP106 | sm_61 | GPU | GP106M [GeForce GTX 1050 Ti Mobile] | — |  | — |
| 1C22 | GP106 | sm_61 | GPU | GP106M [GeForce GTX 1050 Mobile] | — |  | — |
| 1C23 | GP106 | sm_61 | GPU | GP106M [GeForce GTX 1060 Mobile Rev. 2] | — |  | — |
| 1C2D | GP106 | sm_61 | GPU | GP106M | — |  | — |
| 1C30 | GP106 | sm_61 | GPU | GP106GL [Quadro P2000] | — |  | — |
| 1C31 | GP106 | sm_61 | GPU | GP106GL [Quadro P2200] | — |  | — |
| 1C35 | GP106 | sm_61 | GPU | GP106M [Quadro P2000 Mobile / DRIVE PX 2 AutoChauffeur] | — |  | — |
| 1C36 | GP106 | sm_61 | GPU | GP106 [P106M] | — |  | — |
| 1C60 | GP106 | sm_61 | GPU | GP106BM [GeForce GTX 1060 Mobile 6GB] | — |  | — |
| 1C61 | GP106 | sm_61 | GPU | GP106BM [GeForce GTX 1050 Ti Mobile] | — |  | — |
| 1C62 | GP106 | sm_61 | GPU | GP106BM [GeForce GTX 1050 Mobile] | — |  | — |
| 1C70 | GP106 | sm_61 | GPU | GP106GL | — |  | — |
| 1C81 | GP107 | sm_61 | GPU | GP107 [GeForce GTX 1050] | — |  | — |
| 1C82 | GP107 | sm_61 | GPU | GP107 [GeForce GTX 1050 Ti] | — |  | — |
| 1C83 | GP107 | sm_61 | GPU | GP107 [GeForce GTX 1050 3GB] | — |  | — |
| 1C8C | GP107 | sm_61 | GPU | GP107M [GeForce GTX 1050 Ti Mobile] | — |  | — |
| 1C8D | GP107 | sm_61 | GPU | GP107M [GeForce GTX 1050 Mobile] | — |  | — |
| 1C8E | GP107 | sm_61 | GPU | GP107M | — |  | — |
| 1C8F | GP107 | sm_61 | GPU | GP107M [GeForce GTX 1050 Ti Max-Q] | — |  | — |
| 1C90 | GP107 | sm_61 | GPU | GP107M [GeForce MX150] | — |  | — |
| 1C91 | GP107 | sm_61 | GPU | GP107M [GeForce GTX 1050 3 GB Max-Q] | — |  | — |
| 1C92 | GP107 | sm_61 | GPU | GP107M [GeForce GTX 1050 Mobile] | — |  | — |
| 1C94 | GP107 | sm_61 | GPU | GP107M [GeForce MX350] | — |  | — |
| 1C96 | GP107 | sm_61 | GPU | GP107M [GeForce MX350] | — |  | — |
| 1CA7 | GP107 | sm_61 | GPU | GP107GL | — |  | — |
| 1CA8 | GP107 | sm_61 | GPU | GP107GL | — |  | — |
| 1CAA | GP107 | sm_61 | GPU | GP107GL | — |  | — |
| 1CB1 | GP107 | sm_61 | GPU | GP107GL [Quadro P1000] | — |  | — |
| 1CB2 | GP107 | sm_61 | GPU | GP107GL [Quadro P600] | — |  | — |
| 1CB3 | GP107 | sm_61 | GPU | GP107GL [Quadro P400] | — |  | — |
| 1CB6 | GP107 | sm_61 | GPU | GP107GL [Quadro P620] | — |  | — |
| 1CBA | GP107 | sm_61 | GPU | GP107GLM [Quadro P2000 Mobile] | — |  | — |
| 1CBB | GP107 | sm_61 | GPU | GP107GLM [Quadro P1000 Mobile] | — |  | — |
| 1CBC | GP107 | sm_61 | GPU | GP107GLM [Quadro P600 Mobile] | — |  | — |
| 1CBD | GP107 | sm_61 | GPU | GP107GLM [Quadro P620] | — |  | — |
| 1CCC | GP107 | sm_61 | GPU | GP107BM [GeForce GTX 1050 Ti Mobile] | — |  | — |
| 1CCD | GP107 | sm_61 | GPU | GP107BM [GeForce GTX 1050 Mobile] | — |  | — |
| 1CFA | GP107 | sm_61 | GPU | GP107GL [Quadro P2000] | — |  | — |
| 1CFB | GP107 | sm_61 | GPU | GP107GL [Quadro P1000] | — |  | — |
| 1D01 | GP108 | sm_61 | GPU | GP108 [GeForce GT 1030] | — |  | — |
| 1D02 | GP108 | sm_61 | GPU | GP108 [GeForce GT 1010] | — |  | — |
| 1D10 | GP108 | sm_61 | GPU | GP108M [GeForce MX150] | — |  | — |
| 1D11 | GP108 | sm_61 | GPU | GP108M [GeForce MX230] | — |  | — |
| 1D12 | GP108 | sm_61 | GPU | GP108M [GeForce MX150] | — |  | — |
| 1D13 | GP108 | sm_61 | GPU | GP108M [GeForce MX250] | — |  | — |
| 1D16 | GP108 | sm_61 | GPU | GP108M [GeForce MX330] | — |  | — |
| 1D33 | GP108 | sm_61 | GPU | GP108GLM [Quadro P500 Mobile] | — |  | — |
| 1D34 | GP108 | sm_61 | GPU | GP108GLM [Quadro P520] | — |  | — |
| 1D52 | GP108 | sm_61 | GPU | GP108BM [GeForce MX250] | — |  | — |
| 1D56 | GP108 | sm_61 | GPU | GP108BM [GeForce MX330] | — |  | — |
| 0FB8 | GP108 | sm_61 | **HD Audio** | GP108 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0FB9 | GP107 | sm_61 | **HD Audio** | GP107GL High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 10EF | GP102 | sm_61 | **HD Audio** | GP102 HDMI Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 10F0 | GP104 | sm_61 | **HD Audio** | GP104 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 10F1 | GP106 | sm_61 | **HD Audio** | GP106 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |

### Maxwell（91 个 ID · sm_50 / 52）

一代 Maxwell **GM107 / GM108**（`sm_50`，GTX 750/750 Ti、Tesla M10 `13BD`）与二代 Maxwell **GM200 / GM204 / GM206**（`sm_52`，GTX 980 Ti/TITAN X、**Tesla M60 `13F2`、M40 `17FD`、M6 `13F3`、M4 `1431`**）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1340 | GM108 | sm_50 | GPU | GM108M [GeForce 830M] | — |  | — |
| 1341 | GM108 | sm_50 | GPU | GM108M [GeForce 840M] | — |  | — |
| 1344 | GM108 | sm_50 | GPU | GM108M [GeForce 845M] | — |  | — |
| 1346 | GM108 | sm_50 | GPU | GM108M [GeForce 930M] | — |  | — |
| 1347 | GM108 | sm_50 | GPU | GM108M [GeForce 940M] | — |  | — |
| 1348 | GM108 | sm_50 | GPU | GM108M [GeForce 945M / 945A] | — |  | — |
| 1349 | GM108 | sm_50 | GPU | GM108M [GeForce 930M] | — |  | — |
| 134B | GM108 | sm_50 | GPU | GM108M [GeForce 940MX] | — |  | — |
| 134D | GM108 | sm_50 | GPU | GM108M [GeForce 940MX] | — |  | — |
| 134E | GM108 | sm_50 | GPU | GM108M [GeForce 930MX] | — |  | — |
| 134F | GM108 | sm_50 | GPU | GM108M [GeForce 920MX] | — |  | — |
| 137A | GM108 | sm_50 | GPU | GM108GLM [Quadro K620M / Quadro M500M] | — |  | — |
| 137B | GM108 | sm_50 | GPU | GM108GLM [Quadro M520 Mobile] | — |  | — |
| 137D | GM108 | sm_50 | GPU | GM108M [GeForce 940A] | — |  | — |
| 1380 | GM107 | sm_50 | GPU | GM107 [GeForce GTX 750 Ti] | — |  | — |
| 1381 | GM107 | sm_50 | GPU | GM107 [GeForce GTX 750] | — |  | — |
| 1382 | GM107 | sm_50 | GPU | GM107 [GeForce GTX 745] | — |  | — |
| 1389 | GM107 | sm_50 | GPU | GM107GL [GRID M30] | — |  | — |
| 1390 | GM107 | sm_50 | GPU | GM107M [GeForce 845M] | — |  | — |
| 1391 | GM107 | sm_50 | GPU | GM107M [GeForce GTX 850M] | — |  | — |
| 1392 | GM107 | sm_50 | GPU | GM107M [GeForce GTX 860M] | — |  | — |
| 1393 | GM107 | sm_50 | GPU | GM107M [GeForce 840M] | — |  | — |
| 1398 | GM107 | sm_50 | GPU | GM107M [GeForce 845M] | — |  | — |
| 1399 | GM107 | sm_50 | GPU | GM107M [GeForce 945M] | — |  | — |
| 139A | GM107 | sm_50 | GPU | GM107M [GeForce GTX 950M] | — |  | — |
| 139B | GM107 | sm_50 | GPU | GM107M [GeForce GTX 960M] | — |  | — |
| 139C | GM107 | sm_50 | GPU | GM107M [GeForce 940M] | — |  | — |
| 139D | GM107 | sm_50 | GPU | GM107M [GeForce GTX 750 Ti] | — |  | — |
| 13B0 | GM107 | sm_50 | GPU | GM107GLM [Quadro M2000M] | — |  | — |
| 13B1 | GM107 | sm_50 | GPU | GM107GLM [Quadro M1000M] | — |  | — |
| 13B2 | GM107 | sm_50 | GPU | GM107GLM [Quadro M600M] | — |  | — |
| 13B3 | GM107 | sm_50 | GPU | GM107GLM [Quadro K2200M] | — |  | — |
| 13B4 | GM107 | sm_50 | GPU | GM107GLM [Quadro M620 Mobile] | — |  | — |
| 13B6 | GM107 | sm_50 | GPU | GM107GLM [Quadro M1200 Mobile] | — |  | — |
| 13B9 | GM107 | sm_50 | GPU | GM107GL [NVS 810] | — |  | — |
| 13BA | GM107 | sm_50 | GPU | GM107GL [Quadro K2200] | — |  | — |
| 13BB | GM107 | sm_50 | GPU | GM107GL [Quadro K620] | — |  | — |
| 13BC | GM107 | sm_50 | GPU | GM107GL [Quadro K1200] | — |  | — |
| 13BD | GM107 | sm_50 | GPU | GM107GL [Tesla M10] | Tesla M10 (gat/DCGM) | DCGM: Tesla M10 53W | — |
| 174D | GM108 | sm_50 | GPU | GM108M [GeForce MX130] | — |  | — |
| 174E | GM108 | sm_50 | GPU | GM108M [GeForce MX110] | — |  | — |
| 1789 | GM107 | sm_50 | GPU | GM107GL [GRID M3-3020] | — |  | — |
| 179C | GM107 | sm_50 | GPU | GM107 [GeForce 940MX] | — |  | — |
| 0FBC | GM107 | sm_50 | **HD Audio** | GM107 High Definition Audio Controller [GeForce 940MX] | — | On-board HD Audio function (not a standalone GPU) | — |
| 13AD | GM204 | sm_52 | GPU | GM204 [GM107 INT52] | — |  | — |
| 13AE | GM204 | sm_52 | GPU | GM204 [GM107 CS1] | — |  | — |
| 13BE | GM204 | sm_52 | GPU | GM204 [GM107 CS1] | — |  | — |
| 13BF | GM204 | sm_52 | GPU | GM204 [GM107 INT52] | — |  | — |
| 13C0 | GM204 | sm_52 | GPU | GM204 [GeForce GTX 980] | — |  | — |
| 13C1 | GM204 | sm_52 | GPU | GM204 | — |  | — |
| 13C2 | GM204 | sm_52 | GPU | GM204 [GeForce GTX 970] | — |  | — |
| 13C3 | GM204 | sm_52 | GPU | GM204 | — |  | — |
| 13C4 | GM204 | sm_52 | GPU | GM204 [D17U-20] | — |  | — |
| 13D7 | GM204 | sm_52 | GPU | GM204M [GeForce GTX 980M] | — |  | — |
| 13D8 | GM204 | sm_52 | GPU | GM204M [GeForce GTX 960 OEM / 970M] | — |  | — |
| 13D9 | GM204 | sm_52 | GPU | GM204M [GeForce GTX 965M] | — |  | — |
| 13DA | GM204 | sm_52 | GPU | GM204M [GeForce GTX 980 Mobile] | — |  | — |
| 13E4 | GM204 | sm_52 | GPU | GM204 [Graphics Device ES-A] | — |  | — |
| 13E7 | GM204 | sm_52 | GPU | GM204GL [GeForce GTX 980 Engineering Sample] | — | [ES 工程样品] | — |
| 13F0 | GM204 | sm_52 | GPU | GM204GL [Quadro M5000] | Quadro M5000 (gat/DCGM) | DCGM: Quadro M5000 149W | — |
| 13F1 | GM204 | sm_52 | GPU | GM204GL [Quadro M4000] | — |  | — |
| 13F2 | GM204 | sm_52 | GPU | GM204GL [Tesla M60] | M60 (gat/DCGM) | DCGM: Tesla M60 161W | — |
| 13F3 | GM204 | sm_52 | GPU | GM204GL [Tesla M6] | Tesla M6 (gat/DCGM) | DCGM: Tesla M6 161W | — |
| 13F8 | GM204 | sm_52 | GPU | GM204GLM [Quadro M5000M / M5000 SE] | — |  | — |
| 13F9 | GM204 | sm_52 | GPU | GM204GLM [Quadro M4000M] | — |  | — |
| 13FA | GM204 | sm_52 | GPU | GM204GLM [Quadro M3000M] | — |  | — |
| 13FB | GM204 | sm_52 | GPU | GM204GLM [Quadro M5500] | — |  | — |
| 1401 | GM206 | sm_52 | GPU | GM206 [GeForce GTX 960] | — |  | — |
| 1402 | GM206 | sm_52 | GPU | GM206 [GeForce GTX 950] | — |  | — |
| 1404 | GM206 | sm_52 | GPU | GM206 [GeForce GTX 960 FAKE] | — |  | — |
| 1406 | GM206 | sm_52 | GPU | GM206 [GeForce GTX 960 OEM] | — |  | — |
| 1407 | GM206 | sm_52 | GPU | GM206 [GeForce GTX 750 v2] | — |  | — |
| 1427 | GM206 | sm_52 | GPU | GM206M [GeForce GTX 965M] | — |  | — |
| 1430 | GM206 | sm_52 | GPU | GM206GL [Quadro M2000] | — |  | — |
| 1431 | GM206 | sm_52 | GPU | GM206GL [Tesla M4] | Tesla M4 (gat/DCGM) | DCGM: Tesla M4 74W | — |
| 1436 | GM206 | sm_52 | GPU | GM206GLM [Quadro M2200 Mobile] | — |  | — |
| 1613 | GM204 | sm_52 | GPU | GM204GL [GRID M60 Service Provider] | M60 (gat/DCGM) |  | — |
| 1617 | GM204 | sm_52 | GPU | GM204M [GeForce GTX 980M] | — |  | — |
| 1618 | GM204 | sm_52 | GPU | GM204M [GeForce GTX 970M] | — |  | — |
| 1619 | GM204 | sm_52 | GPU | GM204M [GeForce GTX 965M] | — |  | — |
| 161A | GM204 | sm_52 | GPU | GM204M [GeForce GTX 980 Mobile] | — |  | — |
| 1667 | GM204 | sm_52 | GPU | GM204M [GeForce GTX 965M] | — |  | — |
| 1676 | GM204 | sm_52 | GPU | GM204GLM [Quadro M2200 Mobile] | — |  | — |
| 17C2 | GM200 | sm_52 | GPU | GM200 [GeForce GTX TITAN X] | GeForce GTX TITAN X (gat/DCGM) | DCGM: GeForce GTX TITAN X 249W | — |
| 17C8 | GM200 | sm_52 | GPU | GM200 [GeForce GTX 980 Ti] | — |  | — |
| 17F0 | GM200 | sm_52 | GPU | GM200GL [Quadro M6000] | Quadro M6000 (gat/DCGM) | DCGM: Quadro M6000 249W | — |
| 17F1 | GM200 | sm_52 | GPU | GM200GL [Quadro M6000 24GB] | — |  | — |
| 17FD | GM200 | sm_52 | GPU | GM200GL [Tesla M40] | Tesla M40 (gat/DCGM) | DCGM: Tesla M40 249W | — |
| 0FB0 | GM200 | sm_52 | **HD Audio** | GM200 High Definition Audio | — | On-board HD Audio function (not a standalone GPU) | — |
| 0FBA | GM206 | sm_52 | **HD Audio** | GM206 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0FBB | GM204 | sm_52 | **HD Audio** | GM204 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |

### Kepler（197 个 ID · sm_30 / 35 / 37）

**GK104 / GK106 / GK107**（`sm_30`，GTX 600/700、Tesla K10 `118F` / K8 `1194`）、**GK110 / GK110B / GK180 / GK208**（`sm_35`，GTX 780/TITAN、**Tesla K20X / K40m / K40c / K40d**），以及独享 **`sm_37`**（双倍寄存器与共享内存）的双芯经典卡 **GK210 Tesla K80（`102D`）**；另收录 `0FA0/0FA5/0FA7`（GK11x FPGA / PEATRANS）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0FC0 | GK107 | sm_30 | GPU | GK107 [GeForce GT 640 OEM] | — |  | — |
| 0FC1 | GK107 | sm_30 | GPU | GK107 [GeForce GT 640] | — |  | — |
| 0FC2 | GK107 | sm_30 | GPU | GK107 [GeForce GT 630 OEM] | — |  | — |
| 0FC4 | GK107 | sm_30 | GPU | GK107 [D14P1-15] | — |  | — |
| 0FC5 | GK107 | sm_30 | GPU | GK107 [GeForce GT 1030] | — |  | — |
| 0FC6 | GK107 | sm_30 | GPU | GK107 [GeForce GTX 650] | — |  | — |
| 0FC8 | GK107 | sm_30 | GPU | GK107 [GeForce GT 740] | — |  | — |
| 0FC9 | GK107 | sm_30 | GPU | GK107 [GeForce GT 730] | — |  | — |
| 0FCB | GK107 | sm_30 | GPU | GK107 [EXK107] | — |  | — |
| 0FCC | GK107 | sm_30 | GPU | GK107 [GeForce GT 720] | — |  | — |
| 0FCD | GK107 | sm_30 | GPU | GK107M [GeForce GT 755M] | — |  | — |
| 0FCE | GK107 | sm_30 | GPU | GK107M [GeForce GT 640M LE] | — |  | — |
| 0FCF | GK107 | sm_30 | GPU | GK107 [GEN3 ESI] | — |  | — |
| 0FD0 | GK107 | sm_30 | GPU | GK107 [NB1G] | — |  | — |
| 0FD1 | GK107 | sm_30 | GPU | GK107M [GeForce GT 650M] | — |  | — |
| 0FD2 | GK107 | sm_30 | GPU | GK107M [GeForce GT 640M] | — |  | — |
| 0FD3 | GK107 | sm_30 | GPU | GK107M [GeForce GT 640M LE] | — |  | — |
| 0FD4 | GK107 | sm_30 | GPU | GK107M [GeForce GTX 660M] | — |  | — |
| 0FD5 | GK107 | sm_30 | GPU | GK107M [GeForce GT 650M Mac Edition] | — |  | — |
| 0FD6 | GK107 | sm_30 | GPU | GK107M [N13P-GS-W] | — |  | — |
| 0FD7 | GK107 | sm_30 | GPU | GK107 [GK107-GTX] | — |  | — |
| 0FD8 | GK107 | sm_30 | GPU | GK107M [GeForce GT 640M Mac Edition] | — |  | — |
| 0FD9 | GK107 | sm_30 | GPU | GK107M [GeForce GT 645M] | — |  | — |
| 0FDA | GK107 | sm_30 | GPU | GK107 [GK107-ES-A1] | — |  | — |
| 0FDB | GK107 | sm_30 | GPU | GK107 [GK107-ESP-A1] | — |  | — |
| 0FDC | GK107 | sm_30 | GPU | GK107 [GK107-INT22-A1] | — |  | — |
| 0FDD | GK107 | sm_30 | GPU | GK107 [GK107-INT11-A1] | — |  | — |
| 0FDE | GK107 | sm_30 | GPU | GK107 [GK107-ES-KA-E1] | — |  | — |
| 0FDF | GK107 | sm_30 | GPU | GK107M [GeForce GT 740M] | — |  | — |
| 0FE0 | GK107 | sm_30 | GPU | GK107M [GeForce GTX 660M Mac Edition] | — |  | — |
| 0FE1 | GK107 | sm_30 | GPU | GK107M [GeForce GT 730M] | — |  | — |
| 0FE2 | GK107 | sm_30 | GPU | GK107M [GeForce GT 745M] | — |  | — |
| 0FE3 | GK107 | sm_30 | GPU | GK107M [GeForce GT 745M] | — |  | — |
| 0FE4 | GK107 | sm_30 | GPU | GK107M [GeForce GT 750M] | — |  | — |
| 0FE5 | GK107 | sm_30 | GPU | GK107 [GeForce K340 USM] | — |  | — |
| 0FE6 | GK107 | sm_30 | GPU | GK107 [GRID K1 NVS USM] | — |  | — |
| 0FE7 | GK107 | sm_30 | GPU | GK107GL [GRID K100 vGPU] | — |  | — |
| 0FE8 | GK107 | sm_30 | GPU | GK107M [N14P-GS] | — |  | — |
| 0FE9 | GK107 | sm_30 | GPU | GK107M [GeForce GT 750M Mac Edition] | — |  | — |
| 0FEA | GK107 | sm_30 | GPU | GK107M [GeForce GT 755M Mac Edition] | — |  | — |
| 0FEC | GK107 | sm_30 | GPU | GK107M [GeForce 710A] | — |  | — |
| 0FED | GK107 | sm_30 | GPU | GK107M [GeForce 820M] | — |  | — |
| 0FEE | GK107 | sm_30 | GPU | GK107M [GeForce 810M] | — |  | — |
| 0FEF | GK107 | sm_30 | GPU | GK107GL [GRID K340] | — |  | — |
| 0FF0 | GK107 | sm_30 | GPU | GK107 [NB1Q] | — |  | — |
| 0FF1 | GK107 | sm_30 | GPU | GK107 [NVS 1000] | — |  | — |
| 0FF2 | GK107 | sm_30 | GPU | GK107GL [GRID K1] | — |  | — |
| 0FF3 | GK107 | sm_30 | GPU | GK107GL [Quadro K420] | — |  | — |
| 0FF5 | GK107 | sm_30 | GPU | GK107GL [GRID K1 Tesla USM] | — |  | — |
| 0FF6 | GK107 | sm_30 | GPU | GK107GLM [Quadro K1100M] | — |  | — |
| 0FF7 | GK107 | sm_30 | GPU | GK107GL [GRID K140Q vGPU] | — |  | — |
| 0FF8 | GK107 | sm_30 | GPU | GK107GLM [Quadro K500M] | — |  | — |
| 0FF9 | GK107 | sm_30 | GPU | GK107GL [Quadro K2000D] | — |  | — |
| 0FFA | GK107 | sm_30 | GPU | GK107GL [Quadro K600] | — |  | — |
| 0FFB | GK107 | sm_30 | GPU | GK107GLM [Quadro K2000M] | — |  | — |
| 0FFC | GK107 | sm_30 | GPU | GK107GLM [Quadro K1000M] | — |  | — |
| 0FFD | GK107 | sm_30 | GPU | GK107 [NVS 510] | — |  | — |
| 0FFE | GK107 | sm_30 | GPU | GK107GL [Quadro K2000] | — |  | — |
| 0FFF | GK107 | sm_30 | GPU | GK107GL [Quadro 410] | — |  | — |
| 1180 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 680] | — |  | — |
| 1182 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 760 Ti] | — |  | — |
| 1183 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 660 Ti] | — |  | — |
| 1184 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 770] | — |  | — |
| 1185 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 660 OEM] | — |  | — |
| 1186 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 660 Ti] | — |  | — |
| 1187 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 760] | — |  | — |
| 1188 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 690] | — |  | — |
| 1189 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 670] | — |  | — |
| 118A | GK104 | sm_30 | GPU | GK104GL [GRID K520] | K520 (gat/DCGM) |  | — |
| 118B | GK104 | sm_30 | GPU | GK104GL [GRID K2 GeForce USM] | — |  | — |
| 118C | GK104 | sm_30 | GPU | GK104 [GRID K2 NVS USM] | — |  | — |
| 118D | GK104 | sm_30 | GPU | GK104GL [GRID K200 vGPU] | — |  | — |
| 118E | GK104 | sm_30 | GPU | GK104 [GeForce GTX 760 OEM] | — |  | — |
| 118F | GK104 | sm_30 | GPU | GK104GL [Tesla K10] | Tesla K10 (gat/DCGM) | DCGM: Tesla K10 116W | — |
| 1191 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 760 Rev. 2] | — |  | — |
| 1193 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 760 Ti OEM] | — |  | — |
| 1194 | GK104 | sm_30 | GPU | GK104GL [Tesla K8] | Tesla K8 (gat/DCGM) | DCGM: Tesla K8 75W | — |
| 1195 | GK104 | sm_30 | GPU | GK104 [GeForce GTX 660 Rev. 2] | — |  | — |
| 1198 | GK104 | sm_30 | GPU | GK104M [GeForce GTX 880M] | — |  | — |
| 1199 | GK104 | sm_30 | GPU | GK104M [GeForce GTX 870M] | — |  | — |
| 119A | GK104 | sm_30 | GPU | GK104M [GeForce GTX 860M] | — |  | — |
| 119D | GK104 | sm_30 | GPU | GK104M [GeForce GTX 775M Mac Edition] | — |  | — |
| 119E | GK104 | sm_30 | GPU | GK104M [GeForce GTX 780M Mac Edition] | — |  | — |
| 119F | GK104 | sm_30 | GPU | GK104M [GeForce GTX 780M] | — |  | — |
| 11A0 | GK104 | sm_30 | GPU | GK104M [GeForce GTX 680M] | — |  | — |
| 11A1 | GK104 | sm_30 | GPU | GK104M [GeForce GTX 670MX] | — |  | — |
| 11A2 | GK104 | sm_30 | GPU | GK104M [GeForce GTX 675MX Mac Edition] | — |  | — |
| 11A3 | GK104 | sm_30 | GPU | GK104M [GeForce GTX 680MX] | — |  | — |
| 11A4 | GK104 | sm_30 | GPU | GK104 [GK104-ESA] | — |  | — |
| 11A5 | GK104 | sm_30 | GPU | GK104 [GK104-ESA] | — |  | — |
| 11A7 | GK104 | sm_30 | GPU | GK104M [GeForce GTX 675MX] | — |  | — |
| 11A8 | GK104 | sm_30 | GPU | GK104GLM [Quadro K5100M] | — |  | — |
| 11A9 | GK104 | sm_30 | GPU | GK104M [GeForce GTX 870M] | — |  | — |
| 11AA | GK104 | sm_30 | GPU | GK104 [GK104-INT] | — |  | — |
| 11AC | GK104 | sm_30 | GPU | GK104 [GK104-CS] | — |  | — |
| 11AF | GK104 | sm_30 | GPU | GK104GLM [GRID IceCube] | — |  | — |
| 11B0 | GK104 | sm_30 | GPU | GK104GL [GRID K240Q / K260Q vGPU] | — |  | — |
| 11B1 | GK104 | sm_30 | GPU | GK104GL [GRID K2 Tesla USM] | — |  | — |
| 11B4 | GK104 | sm_30 | GPU | GK104GL [Quadro K4200] | — |  | — |
| 11B6 | GK104 | sm_30 | GPU | GK104GLM [Quadro K3100M] | — |  | — |
| 11B7 | GK104 | sm_30 | GPU | GK104GLM [Quadro K4100M] | — |  | — |
| 11B8 | GK104 | sm_30 | GPU | GK104GLM [Quadro K5100M] | — |  | — |
| 11B9 | GK104 | sm_30 | GPU | GK104GLM | — |  | — |
| 11BA | GK104 | sm_30 | GPU | GK104GL [Quadro K5000] | — |  | — |
| 11BB | GK104 | sm_30 | GPU | GK104GL [Quadro 4100] | — |  | — |
| 11BC | GK104 | sm_30 | GPU | GK104GLM [Quadro K5000M] | — |  | — |
| 11BD | GK104 | sm_30 | GPU | GK104GLM [Quadro K4000M] | — |  | — |
| 11BE | GK104 | sm_30 | GPU | GK104GLM [Quadro K3000M] | — |  | — |
| 11BF | GK104 | sm_30 | GPU | GK104GL [GRID K2] | — |  | — |
| 11C0 | GK106 | sm_30 | GPU | GK106 [GeForce GTX 660] | — |  | — |
| 11C1 | GK106 | sm_30 | GPU | GK106 [D14P2-30] | — |  | — |
| 11C2 | GK106 | sm_30 | GPU | GK106 [GeForce GTX 650 Ti Boost] | — |  | — |
| 11C3 | GK106 | sm_30 | GPU | GK106 [GeForce GTX 650 Ti OEM] | — |  | — |
| 11C4 | GK106 | sm_30 | GPU | GK106 [GeForce GTX 645 OEM] | — |  | — |
| 11C5 | GK106 | sm_30 | GPU | GK106 [GeForce GT 740] | — |  | — |
| 11C6 | GK106 | sm_30 | GPU | GK106 [GeForce GTX 650 Ti] | — |  | — |
| 11C7 | GK106 | sm_30 | GPU | GK106 [GeForce GTX 750 Ti] | — |  | — |
| 11C8 | GK106 | sm_30 | GPU | GK106 [GeForce GTX 650 OEM] | — |  | — |
| 11CB | GK106 | sm_30 | GPU | GK106 [GeForce GT 740] | — |  | — |
| 11D0 | GK106 | sm_30 | GPU | GK106 [GK106-INT353] | — |  | — |
| 11D1 | GK106 | sm_30 | GPU | GK106 [GK106-INT343] | — |  | — |
| 11D2 | GK106 | sm_30 | GPU | GK106 [GK106-INT232] | — |  | — |
| 11D3 | GK106 | sm_30 | GPU | GK106 [GK106-ES] | — |  | — |
| 11E0 | GK106 | sm_30 | GPU | GK106M [GeForce GTX 770M] | — |  | — |
| 11E1 | GK106 | sm_30 | GPU | GK106M [GeForce GTX 765M] | — |  | — |
| 11E2 | GK106 | sm_30 | GPU | GK106M [GeForce GTX 765M] | — |  | — |
| 11E3 | GK106 | sm_30 | GPU | GK106M [GeForce GTX 760M] | — |  | — |
| 11E7 | GK106 | sm_30 | GPU | GK106M | — |  | — |
| 11FA | GK106 | sm_30 | GPU | GK106GL [Quadro K4000] | — |  | — |
| 11FC | GK106 | sm_30 | GPU | GK106GLM [Quadro K2100M] | — |  | — |
| 11FF | GK106 | sm_30 | GPU | GK106 [NB1Q] | — |  | — |
| 0E0A | GK104 | sm_30 | **HD Audio** | GK104 HDMI Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0E0B | GK106 | sm_30 | **HD Audio** | GK106 HDMI Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0E1B | GK107 | sm_30 | **HD Audio** | GK107 HDMI Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0FA0 | GK11x | sm_35 | GPU | GK11x [GK11x_FPGA] | — |  | — |
| 0FA5 | GK11x | sm_35 | GPU | GK11x | — |  | — |
| 0FA7 | GK11x | sm_35 | GPU | GK11x [Tegra on x86 (PEATRANS)] | — |  | — |
| 1001 | GK110B | sm_35 | GPU | GK110B [GeForce GTX TITAN Z] | — |  | — |
| 1003 | GK110 | sm_35 | GPU | GK110 [GeForce GTX Titan LE] | — |  | — |
| 1004 | GK110 | sm_35 | GPU | GK110 [GeForce GTX 780] | — |  | — |
| 1005 | GK110 | sm_35 | GPU | GK110 [GeForce GTX TITAN] | — |  | — |
| 1007 | GK110 | sm_35 | GPU | GK110 [GeForce GTX 780 Rev. 2] | — |  | — |
| 1008 | GK110 | sm_35 | GPU | GK110 [GeForce GTX 780 Ti 6GB] | — |  | — |
| 100A | GK110B | sm_35 | GPU | GK110B [GeForce GTX 780 Ti] | — |  | — |
| 100C | GK110B | sm_35 | GPU | GK110B [GeForce GTX TITAN Black] | — |  | — |
| 101E | GK110 | sm_35 | GPU | GK110GL [Tesla K20X] | Tesla K20X (gat/DCGM) | DCGM: Tesla K20X 234W | — |
| 101F | GK110 | sm_35 | GPU | GK110GL [Tesla K20] | — |  | — |
| 1020 | GK110 | sm_35 | GPU | GK110GL [Tesla K20X] | Tesla K20X (gat/DCGM) | DCGM: Tesla K20X 234W | — |
| 1021 | GK110 | sm_35 | GPU | GK110GL [Tesla K20Xm] | Tesla K20Xm (gat/DCGM) | DCGM: Tesla K20Xm 234W | — |
| 1022 | GK110 | sm_35 | GPU | GK110GL [Tesla K20c] | Tesla K20c (gat/DCGM) | DCGM: Tesla K20c 224W | — |
| 1023 | GK110B | sm_35 | GPU | GK110BGL [Tesla K40m] | Tesla K40m (gat/DCGM) | DCGM: Tesla K40m 200W | — |
| 1024 | GK180 | sm_35 | GPU | GK180GL [Tesla K40c] | Tesla K40c (gat/DCGM) | DCGM: Tesla K40c 134W | — |
| 1026 | GK110 | sm_35 | GPU | GK110GL [Tesla K20s] | — |  | — |
| 1027 | GK110B | sm_35 | GPU | GK110BGL [Tesla K40st] | — |  | — |
| 1028 | GK110 | sm_35 | GPU | GK110GL [Tesla K20m] | Tesla K20m (gat/DCGM) | DCGM: Tesla K20m 234W | — |
| 1029 | GK110B | sm_35 | GPU | GK110BGL [Tesla K40s] | Tesla K40s (gat/DCGM) | DCGM: Tesla K40s 234W | — |
| 102A | GK110B | sm_35 | GPU | GK110BGL [Tesla K40t] | Tesla K40t SKU 102A (gat/DCGM) | DCGM: Tesla K40t SKU 102A 234W | — |
| 102E | GK110B | sm_35 | GPU | GK110BGL [Tesla K40d] | Tesla K40d (gat/DCGM) | DCGM: Tesla K40d 234W | — |
| 102F | GK110B | sm_35 | GPU | GK110BGL [Tesla Stella Solo] | Tesla SKU 102f (gat/DCGM) | DCGM: Tesla SKU 102f 234W | — |
| 103A | GK110 | sm_35 | GPU | GK110GL [Quadro K6000] | — |  | — |
| 103C | GK110 | sm_35 | GPU | GK110GL [Quadro K5200] | — |  | — |
| 103F | GK110B | sm_35 | GPU | GK110BGL [Tesla Stella SXM] | — |  | — |
| 1280 | GK208 | sm_35 | GPU | GK208 [GeForce GT 635] | — |  | — |
| 1281 | GK208 | sm_35 | GPU | GK208 [GeForce GT 710] | — |  | — |
| 1282 | GK208 | sm_35 | GPU | GK208 [GeForce GT 640 Rev. 2] | — |  | — |
| 1283 | GK208 | sm_35 | GPU | GK208 [D15M2-10] | — |  | — |
| 1284 | GK208 | sm_35 | GPU | GK208 [GeForce GT 630 Rev. 2] | — |  | — |
| 1285 | GK208 | sm_35 | GPU | GK208 [GK208-100] | — |  | — |
| 1286 | GK208 | sm_35 | GPU | GK208 [GeForce GT 720] | — |  | — |
| 1287 | GK208B | sm_35 | GPU | GK208B [GeForce GT 730] | — |  | — |
| 1288 | GK208B | sm_35 | GPU | GK208B [GeForce GT 720] | — |  | — |
| 1289 | GK208 | sm_35 | GPU | GK208 [GeForce GT 710] | — |  | — |
| 128A | GK208B | sm_35 | GPU | GK208B | — |  | — |
| 128B | GK208B | sm_35 | GPU | GK208B [GeForce GT 710] | — |  | — |
| 128C | GK208B | sm_35 | GPU | GK208B | — |  | — |
| 1290 | GK208 | sm_35 | GPU | GK208M [GeForce GT 730M] | — |  | — |
| 1291 | GK208 | sm_35 | GPU | GK208M [GeForce GT 735M] | — |  | — |
| 1292 | GK208 | sm_35 | GPU | GK208M [GeForce GT 740M] | — |  | — |
| 1293 | GK208 | sm_35 | GPU | GK208M [GeForce GT 730M] | — |  | — |
| 1294 | GK208 | sm_35 | GPU | GK208M [GeForce GT 740M] | — |  | — |
| 1295 | GK208 | sm_35 | GPU | GK208M [GeForce 710M] | — |  | — |
| 1296 | GK208 | sm_35 | GPU | GK208M [GeForce 825M] | — |  | — |
| 1298 | GK208 | sm_35 | GPU | GK208M [GeForce GT 720M] | — |  | — |
| 1299 | GK208B | sm_35 | GPU | GK208BM [GeForce 920M] | — |  | — |
| 129A | GK208B | sm_35 | GPU | GK208BM [GeForce 910M] | — |  | — |
| 12A0 | GK208 | sm_35 | GPU | GK208 | — |  | — |
| 12AD | GK208 | sm_35 | GPU | GK208 [GK208-ES] | — |  | — |
| 12AE | GK208 | sm_35 | GPU | GK208 [GK208-CS1-C] | — |  | — |
| 12AF | GK208 | sm_35 | GPU | GK208 [GK208-INT] | — |  | — |
| 12B0 | GK208 | sm_35 | GPU | GK208 [GK208-CS-Q] | — |  | — |
| 12B1 | GK208 | sm_35 | GPU | GK208 [GK208 INT] | — |  | — |
| 12B9 | GK208 | sm_35 | GPU | GK208GLM [Quadro K610M] | — |  | — |
| 12BA | GK208 | sm_35 | GPU | GK208GLM [Quadro K510M] | — |  | — |
| 130B | GK110 | sm_35 | GPU | GK110 [Q12U-1] | — |  | — |
| 0E0F | GK208 | sm_35 | **HD Audio** | GK208 HDMI/DP Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0E1A | GK110 | sm_35 | **HD Audio** | GK110 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 102D | GK210 | sm_37 | GPU | GK210GL [Tesla K80] | K80 (gat/DCGM) | DCGM: Tesla K80 148W | — |

### Fermi（135 个 ID · sm_20 / 21）

现代通用计算 GPU 的起点（首个支持原生 IEEE-754、ECC 显存与可配置 L1/L2 缓存的 CUDA 架构）：**GF100 / GF110**（`sm_20`，GTX 480/580、Tesla C2050/M2050/M2070/M2090）与 **GF104 / GF106 / GF108 / GF114 / GF116 / GF117 / GF119**（`sm_21`，GTX 460/560、GT 430/610 等）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 06C0 | GF100 | sm_20 | GPU | GF100 [GeForce GTX 480] | — |  | — |
| 06C4 | GF100 | sm_20 | GPU | GF100 [GeForce GTX 465] | — |  | — |
| 06CA | GF100 | sm_20 | GPU | GF100M [GeForce GTX 480M] | — |  | — |
| 06CB | GF100 | sm_20 | GPU | GF100 [GeForce GTX 480] | — |  | — |
| 06CD | GF100 | sm_20 | GPU | GF100 [GeForce GTX 470] | — |  | — |
| 06D0 | GF100 | sm_20 | GPU | GF100GL | — |  | — |
| 06D1 | GF100 | sm_20 | GPU | GF100GL [Tesla C2050 / C2070] | — |  | — |
| 06D2 | GF100 | sm_20 | GPU | GF100GL [Tesla M2070] | — |  | — |
| 06D8 | GF100 | sm_20 | GPU | GF100GL [Quadro 6000] | — |  | — |
| 06D9 | GF100 | sm_20 | GPU | GF100GL [Quadro 5000] | — |  | — |
| 06DA | GF100 | sm_20 | GPU | GF100GLM [Quadro 5000M] | — |  | — |
| 06DC | GF100 | sm_20 | GPU | GF100GL [Quadro 6000] | — |  | — |
| 06DD | GF100 | sm_20 | GPU | GF100GL [Quadro 4000] | — |  | — |
| 06DE | GF100 | sm_20 | GPU | GF100GL [Tesla T20 Processor] | — |  | — |
| 06DF | GF100 | sm_20 | GPU | GF100GL [Tesla M2070-Q] | — |  | — |
| 1080 | GF110 | sm_20 | GPU | GF110 [GeForce GTX 580] | — |  | — |
| 1081 | GF110 | sm_20 | GPU | GF110 [GeForce GTX 570] | — |  | — |
| 1082 | GF110 | sm_20 | GPU | GF110 [GeForce GTX 560 Ti OEM] | — |  | — |
| 1084 | GF110 | sm_20 | GPU | GF110 [GeForce GTX 560 OEM] | — |  | — |
| 1086 | GF110 | sm_20 | GPU | GF110 [GeForce GTX 570 Rev. 2] | — |  | — |
| 1087 | GF110 | sm_20 | GPU | GF110 [GeForce GTX 560 Ti 448 Cores] | — |  | — |
| 1088 | GF110 | sm_20 | GPU | GF110 [GeForce GTX 590] | — |  | — |
| 1089 | GF110 | sm_20 | GPU | GF110 [GeForce GTX 580 Rev. 2] | — |  | — |
| 108B | GF110 | sm_20 | GPU | GF110 [GeForce GTX 580] | — |  | — |
| 108E | GF110 | sm_20 | GPU | GF110GL [Tesla C2090] | — |  | — |
| 1091 | GF110 | sm_20 | GPU | GF110GL [Tesla M2090] | — |  | — |
| 1094 | GF110 | sm_20 | GPU | GF110GL [Tesla M2075] | — |  | — |
| 1096 | GF110 | sm_20 | GPU | GF110GL [Tesla C2050 / C2075] | — |  | — |
| 109A | GF100 | sm_20 | GPU | GF100GLM [Quadro 5010M] | — |  | — |
| 109B | GF100 | sm_20 | GPU | GF100GL [Quadro 7000] | — |  | — |
| 0BE5 | GF100 | sm_20 | **HD Audio** | GF100 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0E09 | GF110 | sm_20 | **HD Audio** | GF110 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0DC0 | GF106 | sm_21 | GPU | GF106 [GeForce GT 440] | — |  | — |
| 0DC4 | GF106 | sm_21 | GPU | GF106 [GeForce GTS 450] | — |  | — |
| 0DC5 | GF106 | sm_21 | GPU | GF106 [GeForce GTS 450 OEM] | — |  | — |
| 0DC6 | GF106 | sm_21 | GPU | GF106 [GeForce GTS 450 OEM] | — |  | — |
| 0DCD | GF106 | sm_21 | GPU | GF106M [GeForce GT 555M] | — |  | — |
| 0DCE | GF106 | sm_21 | GPU | GF106M [GeForce GT 555M] | — |  | — |
| 0DD1 | GF106 | sm_21 | GPU | GF106M [GeForce GTX 460M] | — |  | — |
| 0DD2 | GF106 | sm_21 | GPU | GF106M [GeForce GT 445M] | — |  | — |
| 0DD3 | GF106 | sm_21 | GPU | GF106M [GeForce GT 435M] | — |  | — |
| 0DD6 | GF106 | sm_21 | GPU | GF106M [GeForce GT 550M] | — |  | — |
| 0DD8 | GF106 | sm_21 | GPU | GF106GL [Quadro 2000] | — |  | — |
| 0DDA | GF106 | sm_21 | GPU | GF106GLM [Quadro 2000M] | — |  | — |
| 0DE0 | GF108 | sm_21 | GPU | GF108 [GeForce GT 440] | — |  | — |
| 0DE1 | GF108 | sm_21 | GPU | GF108 [GeForce GT 430] | — |  | — |
| 0DE2 | GF108 | sm_21 | GPU | GF108 [GeForce GT 420] | — |  | — |
| 0DE3 | GF108 | sm_21 | GPU | GF108M [GeForce GT 635M] | — |  | — |
| 0DE4 | GF108 | sm_21 | GPU | GF108 [GeForce GT 520] | — |  | — |
| 0DE5 | GF108 | sm_21 | GPU | GF108 [GeForce GT 530] | — |  | — |
| 0DE7 | GF108 | sm_21 | GPU | GF108 [GeForce GT 610] | — |  | — |
| 0DE8 | GF108 | sm_21 | GPU | GF108M [GeForce GT 620M] | — |  | — |
| 0DE9 | GF108 | sm_21 | GPU | GF108M [GeForce GT 620M/630M/635M/640M LE] | — |  | — |
| 0DEA | GF108 | sm_21 | GPU | GF108M [GeForce 610M] | — |  | — |
| 0DEB | GF108 | sm_21 | GPU | GF108M [GeForce GT 555M] | — |  | — |
| 0DEC | GF108 | sm_21 | GPU | GF108M [GeForce GT 525M] | — |  | — |
| 0DED | GF108 | sm_21 | GPU | GF108M [GeForce GT 520M] | — |  | — |
| 0DEE | GF108 | sm_21 | GPU | GF108M [GeForce GT 415M] | — |  | — |
| 0DEF | GF108 | sm_21 | GPU | GF108M [NVS 5400M] | — |  | — |
| 0DF0 | GF108 | sm_21 | GPU | GF108M [GeForce GT 425M] | — |  | — |
| 0DF1 | GF108 | sm_21 | GPU | GF108M [GeForce GT 420M] | — |  | — |
| 0DF2 | GF108 | sm_21 | GPU | GF108M [GeForce GT 435M] | — |  | — |
| 0DF3 | GF108 | sm_21 | GPU | GF108M [GeForce GT 420M] | — |  | — |
| 0DF4 | GF108 | sm_21 | GPU | GF108M [GeForce GT 540M] | — |  | — |
| 0DF5 | GF108 | sm_21 | GPU | GF108M [GeForce GT 525M] | — |  | — |
| 0DF6 | GF108 | sm_21 | GPU | GF108M [GeForce GT 550M] | — |  | — |
| 0DF7 | GF108 | sm_21 | GPU | GF108M [GeForce GT 520M] | — |  | — |
| 0DF8 | GF108 | sm_21 | GPU | GF108GL [Quadro 600] | — |  | — |
| 0DF9 | GF108 | sm_21 | GPU | GF108GLM [Quadro 500M] | — |  | — |
| 0DFA | GF108 | sm_21 | GPU | GF108GLM [Quadro 1000M] | — |  | — |
| 0DFC | GF108 | sm_21 | GPU | GF108GLM [NVS 5200M] | — |  | — |
| 0E22 | GF104 | sm_21 | GPU | GF104 [GeForce GTX 460] | — |  | — |
| 0E23 | GF104 | sm_21 | GPU | GF104 [GeForce GTX 460 SE] | — |  | — |
| 0E24 | GF104 | sm_21 | GPU | GF104 [GeForce GTX 460 OEM] | — |  | — |
| 0E30 | GF104 | sm_21 | GPU | GF104M [GeForce GTX 470M] | — |  | — |
| 0E31 | GF104 | sm_21 | GPU | GF104M [GeForce GTX 485M] | — |  | — |
| 0E3A | GF104 | sm_21 | GPU | GF104GLM [Quadro 3000M] | — |  | — |
| 0E3B | GF104 | sm_21 | GPU | GF104GLM [Quadro 4000M] | — |  | — |
| 0F00 | GF108 | sm_21 | GPU | GF108 [GeForce GT 630] | — |  | — |
| 0F01 | GF108 | sm_21 | GPU | GF108 [GeForce GT 620] | — |  | — |
| 0F02 | GF108 | sm_21 | GPU | GF108 [GeForce GT 730] | — |  | — |
| 0F03 | GF108 | sm_21 | GPU | GF108 [GeForce GT 610] | — |  | — |
| 0F06 | GF108 | sm_21 | GPU | GF108 [GeForce GT 730] | — |  | — |
| 1040 | GF119 | sm_21 | GPU | GF119 [GeForce GT 520] | — |  | — |
| 1042 | GF119 | sm_21 | GPU | GF119 [GeForce 510] | — |  | — |
| 1045 | GF119 | sm_21 | GPU | GF119 | — |  | — |
| 1048 | GF119 | sm_21 | GPU | GF119 [GeForce 605] | — |  | — |
| 1049 | GF119 | sm_21 | GPU | GF119 [GeForce GT 620 OEM] | — |  | — |
| 104A | GF119 | sm_21 | GPU | GF119 [GeForce GT 610] | — |  | — |
| 104B | GF119 | sm_21 | GPU | GF119 [GeForce GT 625 OEM] | — |  | — |
| 104C | GF119 | sm_21 | GPU | GF119 [GeForce GT 705] | — |  | — |
| 104D | GF119 | sm_21 | GPU | GF119 [GeForce GT 710] | — |  | — |
| 1050 | GF119 | sm_21 | GPU | GF119M [GeForce GT 520M] | — |  | — |
| 1051 | GF119 | sm_21 | GPU | GF119M [GeForce GT 520MX] | — |  | — |
| 1052 | GF119 | sm_21 | GPU | GF119M [GeForce GT 520M] | — |  | — |
| 1054 | GF119 | sm_21 | GPU | GF119M [GeForce 410M] | — |  | — |
| 1055 | GF119 | sm_21 | GPU | GF119M [GeForce 410M] | — |  | — |
| 1056 | GF119 | sm_21 | GPU | GF119M [NVS 4200M] | — |  | — |
| 1057 | GF119 | sm_21 | GPU | GF119M [Quadro NVS 4200M] | — |  | — |
| 1058 | GF119 | sm_21 | GPU | GF119M [GeForce 610M] | — |  | — |
| 1059 | GF119 | sm_21 | GPU | GF119M [GeForce 610M] | — |  | — |
| 105A | GF119 | sm_21 | GPU | GF119M [GeForce 610M] | — |  | — |
| 105B | GF119 | sm_21 | GPU | GF119M [GeForce 705M] | — |  | — |
| 107C | GF119 | sm_21 | GPU | GF119 [NVS 315] | — |  | — |
| 107D | GF119 | sm_21 | GPU | GF119 [NVS 310] | — |  | — |
| 1140 | GF117 | sm_21 | GPU | GF117M [GeForce 610M/710M/810M/820M / GT 620M/625M/630M/720M] | — |  | — |
| 1200 | GF114 | sm_21 | GPU | GF114 [GeForce GTX 560 Ti] | — |  | — |
| 1201 | GF114 | sm_21 | GPU | GF114 [GeForce GTX 560] | — |  | — |
| 1202 | GF114 | sm_21 | GPU | GF114 [GeForce GTX 560 Ti OEM] | — |  | — |
| 1203 | GF114 | sm_21 | GPU | GF114 [GeForce GTX 460 SE v2] | — |  | — |
| 1205 | GF114 | sm_21 | GPU | GF114 [GeForce GTX 460 v2] | — |  | — |
| 1206 | GF114 | sm_21 | GPU | GF114 [GeForce GTX 555] | — |  | — |
| 1207 | GF114 | sm_21 | GPU | GF114 [GeForce GT 645 OEM] | — |  | — |
| 1208 | GF114 | sm_21 | GPU | GF114 [GeForce GTX 560 SE] | — |  | — |
| 1210 | GF114 | sm_21 | GPU | GF114M [GeForce GTX 570M] | — |  | — |
| 1211 | GF114 | sm_21 | GPU | GF114M [GeForce GTX 580M] | — |  | — |
| 1212 | GF114 | sm_21 | GPU | GF114M [GeForce GTX 675M] | — |  | — |
| 1213 | GF114 | sm_21 | GPU | GF114M [GeForce GTX 670M] | — |  | — |
| 1241 | GF116 | sm_21 | GPU | GF116 [GeForce GT 545 OEM] | — |  | — |
| 1243 | GF116 | sm_21 | GPU | GF116 [GeForce GT 545] | — |  | — |
| 1244 | GF116 | sm_21 | GPU | GF116 [GeForce GTX 550 Ti] | — |  | — |
| 1245 | GF116 | sm_21 | GPU | GF116 [GeForce GTS 450 Rev. 2] | — |  | — |
| 1246 | GF116 | sm_21 | GPU | GF116M [GeForce GT 550M] | — |  | — |
| 1247 | GF116 | sm_21 | GPU | GF116M [GeForce GT 555M/635M] | — |  | — |
| 1248 | GF116 | sm_21 | GPU | GF116M [GeForce GT 555M/635M] | — |  | — |
| 1249 | GF116 | sm_21 | GPU | GF116 [GeForce GTS 450 Rev. 3] | — |  | — |
| 124B | GF116 | sm_21 | GPU | GF116 [GeForce GT 640 OEM] | — |  | — |
| 124D | GF116 | sm_21 | GPU | GF116M [GeForce GT 555M/635M] | — |  | — |
| 1251 | GF116 | sm_21 | GPU | GF116M [GeForce GT 560M] | — |  | — |
| 0BE9 | GF106 | sm_21 | **HD Audio** | GF106 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0BEA | GF108 | sm_21 | **HD Audio** | GF108 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0BEB | GF104 | sm_21 | **HD Audio** | GF104 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0BEE | GF116 | sm_21 | **HD Audio** | GF116 High Definition Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0E08 | GF119 | sm_21 | **HD Audio** | GF119 HDMI Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
| 0E0C | GF114 | sm_21 | **HD Audio** | GF114 HDMI Audio Controller | — | On-board HD Audio function (not a standalone GPU) | — |
