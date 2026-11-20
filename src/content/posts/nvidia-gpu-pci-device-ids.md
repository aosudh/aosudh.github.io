---
title: "NVIDIA PCI Device ID 全量对照：Fermi → Rubin × Grace / Vera × NVSwitch"
published: 2026-06-24
updated: 2026-11-20
description: "全网最全一手实证 NVIDIA PCI Device ID 图谱（共 1149 项）：整合 pci.ids v2026.11.19、NVIDIA open-gpu-kernel-modules 620.73.04、gpu-admin-tools、DCGM、edk2-nvidia 与 Linux 主线源码，完整覆盖 11 代 CUDA GPU（Fermi → Rubin，1026 项）、Grace TH500 / Vera TB500 / Tegra SoC（40 项）、NVSwitch LR10/LS10（33 项）与 15B3 集群互联（NVLink-6/7/8 Switch · ConnectX-6~11 · BlueField-1~4，50 项）。"
image: "/assets/covers/nvidia-pci-ids.svg"
category: "资料与随笔"
tags: ["NVIDIA", "PCIe", "Rubin", "Blackwell", "Grace", "Vera", "NVSwitch", "速查表"]
pinned: true
draft: false
---

> [!TIP]
> **2026-11-20 超级扩充版（354 项 → 1149 项）**：除实时同步 `pci.ids v2026.11.19` 与 `open-gpu-kernel-modules 620.73.04` 外，本次深度挖掘了 **`NVIDIA/gpu-admin-tools`**、**`NVIDIA/DCGM`**、**`NVIDIA/edk2-nvidia`** 与 **`torvalds/linux`** 源码树，将范围从 Ampere → Rubin 全面扩展至 **11 代 CUDA GPU（Fermi → Rubin）**，并补全 **Grace（`TH500`）与 Vera（`TB500`）CPU Root Port**、**NVSwitch 全量 33 个 ID**，以及已迁入 `15B3` 的 **NVLink-6/7/8 Switch · ConnectX-10/11 NVLink-C2C · BlueField-4**。
>
> 如需使用 **实时关键词过滤 + 架构快捷筛选 + 1520px 吸顶宽表**，推荐直接打开：[原版实时搜索宽表页（1149 条）](/legacy-posts/nvidia-gpu-pci-device-ids.html)；本文所有表格亦支持右上角 **「⤢ 宽屏展开表格」**。

📊 **原始数据下载**：[下载最新全量多表 Excel（.xlsx · 16 个工作表 · 1149 个 PCI ID · 135 KB）](/assets/files/nvidia-gpu-pci-ids-ampere-to-rubin.xlsx)

> [!NOTE]
> **本次扩大搜索的 6 项硬核一手发现（`pci.ids` 尚未收录或未标明的关键情报）**
> 1. **Grace CPU（`TH500`）6 个隐藏 PCI ID 与 Vera CPU（`TB500`）5 个 Root Port 实锤**：`open-gpu-kernel-modules` 的 `nvcst.h` 直接定义了 Grace **`22B1 / 22B2 / 22B3 / 22B4 / 22B8 / 22B9`**（均未进入 `pci.ids`）与 Vera **`2F95–2F99`**（`CS_NVIDIA_TB500`，与 Grace 共享 I/O Coherent + PCIe Atomics 配置），同时确认 **`2F88` = `T256 (N1)` 客户端 Arm SoC**、**`3400` = `T268`**、**`22D1` = `T254`**。
> 2. **NVIDIA PCI Device ID Bit-6（`+0x40`）硬件分配规律**：从 `NVIDIA/edk2-nvidia`（`TH500GpuDxe/efihand/DriverBinding.c`）源码实锤——数据中心单芯的 `+0x00~0x3F` 段用于 **Endpoint（PCIe/SXM）**，`+0x41~0x7F` 段用于 **Self-Hosted（Grace/Vera C2C）**；并首次确认 **`GB120` 在 TH500 上的预留段为 `3341–337F`**、**`GR100` Endpoint 段为 `3000–303F`**。
> 3. **Rubin 子系统与 DCGM Profile 落锤**：CUDA 13.5 确认 **`sm_107`（CC 10.7）**；`gpu-admin-tools` 揭示 **`3002:2277`** 为非 C2C SXM、**`3041:221A`**（`VR NVL72`，已入 `open-gpu 620.73.04` ✓）与 **`307E:221A`** 为 GR100 C2C+SXM、**`30FF:221B/221C`** 为 GR102 C2C+SXM；DCGM 已收录 `3041 / 307E / 307F`。
> 4. **NVSwitch 从 `10DE` 迁入 `15B3` 的分水岭**：`open-gpu nvswitch.c` 定义了 **LR10（17 个 ID：`1AE8, 1AF0–1AFF`）** 与 **LS10 "Laguna"（16 个 ID：`22A0–22AF`）**，而 `pci.ids v2026.11.19` 显示 **NVLink-6 / 7 / 8 Switch（`15B3:D2F8 / D2FA / D2FC`）** 已正式并入 Mellanox/NVIDIA Networking `15B3` 交换芯片段位！
> 5. **Linux 主线 `drivers/pci/quirks.c` 实锤两个新硬件段**：**`10DE:2E00–2E3F`（GB20B / Spark / N1X 全段）** 与 **`15B3:2101`（ConnectX-10 NVLink-C2C）** 均需强制启用 PCIe ATS，用于无标准 CXL 配置空间下发起类 `CXL.cache` 一致性操作。
> 6. **Hopper / Blackwell 隐藏 ID 与 DCGM 内部代号补完**：`gpu-admin-tools` 补出未入 `pci.ids` 的 **`2309`（H20）**，并将 `2343 / 2345` 正式转正为 **GH200**；DCGM `diag-skus.yaml` 补齐了 **`GB300 NVL Bianca (1399W)` / `Galaxy (1299W)`**、**`RTX 6000D LC (249W)`**、**`Scout H100`**、**`SkinnyJoe`** 与 11 代老卡（K80/M60/P100/V100/T4）官方诊断基线。

## 一、总览、架构 × SM × Hex 段位与 Bit-6 分配规律

### 1.1 全站收录总量分布（1149 项）

- **`10DE` CUDA GPU（11 代全量 · Fermi → Rubin）**：**1026 项**（其中 `open-gpu-kernel-modules 620.73.04` 官方支持 **299 项**，覆盖 Turing → Rubin）
  - 新一代（按最新倒序）：**Rubin** `10` · **Blackwell / Ultra** `91` · **Hopper** `29` · **Ada** `69` · **Ampere** `146`
  - 经典历代：**Turing** `124`（开放驱动起点）· **Volta** `21` · **Pascal** `113` · **Maxwell** `91` · **Kepler** `197` · **Fermi** `135`
- **`10DE` Grace（`TH500`）· Vera（`TB500`）· Tegra / Thor / N1 CPU & SoC**：**40 项**（Grace 6 + Vera 5 + Tegra/Thor/Spark/N1 29）
- **`10DE` NVSwitch（Gen2 LR10 + Gen3 LS10）**：**33 项**（LR10 17 + LS10 16）
- **`15B3` 集群互联与新一代 NVLink Switch**：**50 项**（NVLink-6/7/8 Switch · ConnectX-6~11 · BlueField-1~4 · Quantum / Spectrum）

### 1.2 全架构 × SM / Compute Capability × PCI Hex 段位速查

| 架构 | 芯片 | SM | CC | PCI Hex 段位（10DE） | 代表产品 | 关键特性 / 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| Rubin (DC) | GR100 / GR102 | sm_107 | 10.7 | 3000–307F (GR100) / 3080–30FF (GR102) | VR NVL72 (3041), PCIe Faber (3021), R100/R200 | CUDA 13.4/13.5 GA (sm_107a/107f); 328 KB SMEM; HBM4, NVLink 6; open-gpu 620.x |
| Blackwell (Spark/N1X) | GB10 / GB20B | sm_121 | 12.1 | 2E00–2E3F (Linux quirks ATS) | DGX Spark (GB10), RTX Spark N1X (5120/6144-core) | sm_121a; 强制 PCIe ATS 模拟 CXL.cache |
| Blackwell (Consumer/Pro) | GB202/203/205/206/207 | sm_120 | 12.0 | 2B80–2DFF, 2F00–2F7F | RTX 50 / 5070 SUPER, RTX PRO 6000/5500/5000 | mma.sync (非 tcgen05); FP4/FP6; 另有 GB20C SDM |
| Blackwell (Thor/T268) | GB10B (T264 / T268) | sm_110 | 11.0 | 2B00 (T264), 3400 (T268) | Jetson AGX Thor, DRIVE Thor, T268 | CUDA 13.0 由 sm_101 改名; 另有 GB10C |
| Blackwell Ultra (DC) | GB110 / GB112 / GB120 | sm_103 | 10.3 | 3180–327F, 3300–337F | B300 (3182), GB300 Bianca/Galaxy (31C2), GB300-252 (31C3) | sm_103a/103f; 1400W 级; edk2 确认 GB120 段 3341–337F |
| Blackwell (DC) | GB100 / GB102 | sm_100 | 10.0 | 2900–297F (GB100) / 2980–29FF (GB102) | B100, B200, GB200 NVL72 (2941) | TMEM, tcgen05, 2-SM MMA; sm_100a/100f |
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

### 1.3 数据中心 GPU Bit-6（`+0x40`）Endpoint vs Self-Hosted 分配规律

从 `NVIDIA/edk2-nvidia`（`Silicon/NVIDIA/Server/TH500/Drivers/TH500GpuDxe/efihand/DriverBinding.c`）与 `NVIDIA/gpu-admin-tools`（`gpu/devid_chips.py`）提取的硬件级分段规则——拿到一个陌生 `10DE:xxxx`，只看低字节是否 `>= 0x40`（或 `>= 0xC0`）就能秒判它属于传统 PCIe/SXM 卡还是 **Grace / Vera C2C 超级芯片**：

| 芯片家族 | Recovery / 保留 | Endpoint 段（+0x00，PCIe/SXM） | Self-Hosted 段（+0x40，Grace/Vera C2C） | 源码实证 | 典型实例 |
| --- | --- | --- | --- | --- | --- |
| GH100 (Hopper) | 0x2300 (Recovery) | 0x2301 – 0x233F | 0x2341 – 0x237F | edk2-nvidia TH500GpuDxe | 2330 H100 SXM (EP) vs 2342/2345/2348 GH200 (SH) |
| GB100 (Blackwell) | 0x2900 (Reserved A) | 0x2901 – 0x293F | 0x2941 – 0x297F | edk2-nvidia TH500GpuDxe | 2901 B200 (EP) vs 2941/297E GB200 (TH500 SH) |
| GB102 (Blackwell) | 0x2980 (Reserved A) | 0x2981 – 0x29BF | 0x29C1 – 0x29FF | edk2-nvidia TH500GpuDxe | 29BB/29BC (EP) vs 29C1–29FF (TH500 SH) |
| GB110 (Blackwell Ultra) | 0x3180 (Reserved A) | 0x3181 – 0x31BF (特例 31A1=SH) | 0x31C1 – 0x31FF (+ 31A1) | edk2-nvidia TH500GpuDxe | 3182 B300 (EP) vs 31C2/31C3 GB300 & 31A1 MaxQ (SH) |
| GB120 (Blackwell Ultra) | 0x3300 / 0x3340 | 0x3301 – 0x333F | 0x3341 – 0x337F | edk2-nvidia TH500GpuDxe | edk2 明确预留 TH500+GB120 SH 段 3341–337F |
| GR100 (Rubin) | 0x3000 (Reserved A) | 0x3000 – 0x303F | 0x3041 – 0x307F | edk2 + gpu-admin-tools | 3002 SXM / 3021 PCIe Faber (EP) vs 3041 VR NVL72 / 307E / 307F (Vera SH) |
| GR102 (Rubin) | 0x3080 (Reserved A) | 0x3081 – 0x30BF | 0x30C1 – 0x30FF | gpu-admin-tools | 30C0 Reserved B / 30FF [221B/221C] C2C+SXM (Vera SH) |

## 二、Grace（TH500）· Vera（TB500）· Tegra / Thor / N1 CPU & SoC（40 个 `10DE` ID）

本节汇总 NVIDIA 自研 Arm 数据中心 CPU（**Grace `TH500`**、**Vera `TB500`**）以及边缘/客户端 Arm SoC（**Thor `T264`**、**`T268`**、**`T256 (N1)`**、**`T254`**、**GB10**、**Orin `T234`**、**Xavier `T194`**、**Parker `T186`**、**X1 `T210`**）在 PCIe 总线上暴露的 Root Port / Bridge 设备 ID。其中 **Grace 全部 6 个 ID（`22B1–22B4, 22B8–22B9`）目前尚未收录进 `pci.ids`**，直接提取自 `NVIDIA/open-gpu-kernel-modules` 的 `src/nvidia/arch/nvalloc/common/inc/nvcst.h`。

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

### Grace / Vera 非 PCI 关键硬件标识（Linux 主线 `nvidia_cspmu.c` & `edk2-nvidia`）

Grace（`Tegra241 / TH500`，Neoverse V2 核心）与 Vera（`TB500`，自研 Olympus 核心 + 不对称 SMT + OCP Caliptra Root of Trust）的片上互联与性能计数器并非全挂在 PCI 配置空间，而是通过 **ACPI / Arm CoreSight PMU（CSPMU）** 与 **SMMUv3 CMDQV（`tegra241-cmdqv.c`）** 暴露（`edk2-nvidia` `Dsdt_TH500.asl` 亦含 `NVDA2006` 等 ACPI HID）：

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

## 三、NVSwitch（`10DE` 全量 33 项）与 `15B3` 集群互联家族（50 项）

### 3.1 `10DE` NVSwitch Gen2（LR10 / LimeRock）与 Gen3（LS10 / Laguna）全量表

`pci.ids` 仅收录了最常见的 `1AF1` 与 `22A3` 两条，但 `NVIDIA/open-gpu-kernel-modules` 的 `src/common/nvswitch/kernel/nvswitch.c` 完整定义了全部 **33 个** PCI Device ID（含 LS10 的管理端点、Function 0 PCI-PCI Bridge 与 Function 1 NTB）：

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

### 3.2 `15B3` 配套高速互联核心表（NVLink-6/7/8 Switch · ConnectX-6~11 · BlueField-1~4 · Quantum / Spectrum）

在大规模 Grace/Blackwell/Vera Rubin 集群的 `lspci` 中，除 `10DE` 外还会密集出现 **`15B3`（Mellanox / NVIDIA Networking）** 设备——特别值得注意的是，**从 NVLink-6 Switch（Vera Rubin）起，机架级 NVLink 交换芯片的 PCI ID 已正式并入 `15B3:D2F8/D2FA/D2FC`**，而 **ConnectX-10/11（`15B3:2101/2102`）** 更是直接原生支持 **NVLink-C2C**：

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

## 四、Rubin（10 个 ID · sm_107 / CC 10.7）

截至 **2026-11-20**，结合 `pci.ids v2026.11.19`、`NVIDIA/open-gpu-kernel-modules 620.73.04`、`NVIDIA/gpu-admin-tools`、`NVIDIA/edk2-nvidia`、`NVIDIA/DCGM` 与 **CUDA 13.5 GA** 官方文档，Rubin 已从半年前的 2 个占位 ID 扩充至 **10 个**，且多条底层实锤均已落地：

- **官方 Compute Capability = `sm_107`（CC 10.7，含 `sm_107a` / `sm_107f`）**：每 SM 共享内存扩至 328 KB、引入 TMA 细粒度同步与增强型 `tcgen05.mma` 仿真 FP64，Windows 端放弃传统 TCC 模式。
- **Endpoint vs Self-Hosted 分段清晰**：`edk2-nvidia` 确认 `3000–303F` 为 GR100 Endpoint（含 `3002` subsys `2277` 非 C2C SXM、`3021` `PCIe Faber`），`3041–307F` 为 Vera+Rubin Self-Hosted C2C（含首个进入开放驱动 `620.73.04` 的 **`3041` `NVIDIA VR NVL72`**、`307E` 与 `307F` 均已进入 DCGM 诊断 profile）；GR102 的 **`30FF`**（subsys `221B/221C`）也在 `gpu-admin-tools` 标明 `has_c2c + is_sxm`。
- **内核驱动架构已实装**：`open-gpu` 已合入 `arch/rubin/kern_gpu_gr100.c`（20× CE、8× Graphics、FSP/SPDM/TDISP、`VR-BM` 许可位、`kbifDoCxlReset_GR100` CXL 复位 HAL）与 `kern_gpu_gr102.c`。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3000 | GR100 | sm_107 | GPU | GR100 [Reserved Dev ID A] | — | GR100 Endpoint Reserved A (edk2: 3000–303F = GR100 Endpoint; open-gpu arch/rubin/kern_gpu_gr100.c) | — |
| 3002 | GR100 | sm_107 | GPU | GR100 | — | GR100 Endpoint SXM (non-C2C); gat: SXM (subsys 2277) | — |
| 3021 | GR100 | sm_107 | GPU | GR100 [PCIe Faber] | GR100 PCIe (Faber) (社区) | Rubin GR100 PCIe form-factor / platform codename 'Faber' (in 3000–303F Endpoint range) | — |
| 3040 | GR100 | sm_107 | GPU | GR100 [Reserved Dev ID B] | — | GR100 Self-Hosted Reserved B (3040–307F = Vera+Rubin C2C Self-Hosted range) | — |
| 3041 | GR100 | sm_107 | GPU | GR100 [VR NVL72] | NVIDIA VR NVL72 | Vera Rubin NVL72; first shipping Rubin SKU in open-gpu 620.73.04; gat: C2C+SXM (subsys 221A); DCGM Rubin profile | ✓ |
| 307E | GR100 | sm_107 | GPU | GR100 | — | GR100 Vera+Rubin C2C variant; gat: C2C+SXM (subsys 221A); DCGM Rubin profile | — |
| 307F | GR100 | sm_107 | GPU | GR100 | — | GR100 Vera+Rubin Self-Hosted variant; DCGM Rubin profile | — |
| 3080 | GR102 | sm_107 | GPU | GR102 [Reserved Dev ID A] | — | GR102 Endpoint Reserved A (open-gpu arch/rubin/kern_gpu_gr102.c) | — |
| 30C0 | GR102 | sm_107 | GPU | GR102 [Reserved Dev ID B] | — | GR102 Self-Hosted Reserved B — GR100 package = 2× GR102 dies | — |
| 30FF | GR102 | sm_107 | GPU | GR102 | — | GR102 Vera+Rubin C2C variant; gat: C2C+SXM (subsys 221B/221C) | — |

### Rubin 架构与路线图速览（2026-11）

| 代号 / 维度 | 定位与最新状态（2026-11） |
| --- | --- |
| **GR100（7 IDs）** | Rubin 数据中心旗舰双芯封装：`3041`（`NVIDIA VR NVL72`，`subsys 221A`，open-gpu 620.73.04 ✓ / DCGM ✓）、`307E`（`221A` C2C / DCGM ✓）、`307F`（DCGM ✓）、`3021`（`PCIe Faber`）、`3002`（`2277` SXM 非 C2C）、`3000/3040`（Reserved A/B） |
| **GR102（3 IDs）** | Rubin 基础硅片（GR100 = 2× GR102）：`3080/30C0`（Reserved A/B）、`30FF`（`subsys 221B/221C`，C2C+SXM），驱动落地 `arch/rubin/kern_gpu_gr102.c` |
| **GR150 / GR20x / GR21x** | 后续量产数据中心 die（GR150，CoWoP/SXM8，~2027）、消费级 Rubin（GR20x）与 Rubin CPX 长上下文 Prefill 加速器（GR21x，GDDR7），PCI ID 尚未公开 |
| **Vera CPU（TB500）** | 自研 Olympus 核心 + 不对称 SMT + Caliptra RoT；PCIe Root Port `10DE:2F95–2F99`；通过 NVLink-C2C + PCI-SIG CXL DVSEC 与 Rubin 耦合 |
| **Compute Capability** | **`sm_107`（CC 10.7，含 `sm_107a` / `sm_107f`）** —— CUDA 13.4 预览 / **CUDA 13.5 GA**；328 KB SMEM、TMA 细粒度同步、`tcgen05.mma` 仿真 FP64，Windows 弃用 TCC |
| **互联与交换** | 288 GB HBM4（13–22 TB/s）；NVLink 6（3.6 TB/s）配套 **`15B3:D2F8` NVLink-6 Switch**、**ConnectX-9（`15B3:1025`）** 与 **BlueField-4（`15B3:A2DD–A2DF`）** |

## 五、Blackwell & Blackwell Ultra（91 个 ID · sm_100 / 103 / 110 / 120 / 121）

一个代号、五个 SM，叠加 **DCGM / gpu-admin-tools / edk2-nvidia / Linux quirks.c** 交叉实证后细节全部打通：

- **数据中心 GB100 / GB102（`sm_100`）**：`2901` / `2909` / `290A`（B200），`2941`（GB200，DCGM 1199W，Linux `nvgrace-gpu` VFIO 白名单），`297E`（`subsys 2046` C2C+SXM），`2924/2925`（PCIe 样片），`29F1`（GB102 SXM）。
- **Blackwell Ultra GB110 / GB112 / GB120（`sm_103`）**：`3182`（B300 SXM6 AC 1099W），`3183/3184`（B300 SXM `22F2/22F3`），`31A1`（GB300 MaxQ 1199W C2C），`31C2`（**GB300 NVL Bianca 1399W** / **Galaxy `[20E5]` 1299W**，`nvgrace-gpu` 白名单），`31C3`（**GB300-252** 252 GB HBM3e），`3224/323E`（GB112 SXM `215F`），`3340`（`edk2-nvidia` 确认 `3341–337F` 为 `TH500+GB120`）。
- **Thor / T268（`sm_110`）**：`2B00`（`CS_NVIDIA_T264` Thor iGPU）、`3400`（`nvcst.h` 实锤为 `CS_NVIDIA_T268` Tegra RP iGPU）；`open-gpu rmconfig.h` 还出现了 `GB10C` 与 `GB20C`（SDM iGPU）。
- **消费 / 专业工作站 GB202–GB207（`sm_120`）**：含新增 **RTX PRO 5500 Blackwell（`2BBD` 84GB ECC ✓）**、GB203 **RTX 5070（`2C09` ✓）**、首个 **RTX 5070 SUPER（`2F02`）**、DCGM 实证的 **RTX PRO 6000 Max-Q（`2BB4` 代号 `Galaxy TS2`）** 与 **RTX 6000D LC（`2BB9:2279` 249W）**。
- **DGX Spark / RTX Spark N1X（`sm_121` · GB10 / GB20B）**：Linux 主线 `drivers/pci/quirks.c` 明确规定 **`0x2E00–0x2E3F` 全段强制启用 PCIe ATS 以发出类 `CXL.cache` 一致性操作**；含 `2E03/2E06/2E13` 三款 N1X 开放驱动 ID 与 `2E12` GB10。（对应的 PCIe Root Port / Bridge ID 归入第二章 Grace/Vera/Tegra 表。）

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 子系统 / 功耗 / 驱动注解 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2900 | GB100 | sm_100 | GPU | GB100 [Reserved Dev ID A] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 2901 | GB100 | sm_100 | GPU | GB100 [B200] | NVIDIA B200 | DCGM: B200 DevId 20da [20DA] 850W; B200 DevId 1999 [1999] 1000W; B200 DevId 199B10DE [199B] 999W；gat: SXM (subsys 1999/199B/199D/20DA) | ✓ |
| 2909 | GB100 | sm_100 | GPU | GB100 [HGX B200 168GB] | NVIDIA B200 | DCGM: HGX B200 168GB 1000W | ✓ |
| 290A | GB100 | sm_100 | GPU | GB100 [B200] | B200 (GB100 variant) (社区) | Datacenter B200 variant (confirmed B200 in gpu-admin-tools & pci.ids v2026.11.19) | — |
| 2920 | GB100 | sm_100 | GPU | GB100 [TS4 / B100] | B100 (TS4 sample) (社区) | DCGM: TS4 700W; B100 DevId 197f [197F] 850W；gat: SXM (subsys 197F/20DE) | — |
| 2924 | GB100 | sm_100 | GPU | GB100 | — | GB100 PCIe sample/variant; gat: PCIe (subsys 18B6/20D4) | — |
| 2925 | GB100 | sm_100 | GPU | GB100 | — | GB100 PCIe sample/variant; gat: PCIe (subsys 18B7) | — |
| 293D | GB100 | sm_100 | GPU | GB100 | — | GB100 PCIe/SXM variant; gat: PCIe+SXM (subsys 18B6/197F/1999) | — |
| 2940 | GB100 | sm_100 | GPU | GB100 [Reserved Dev ID B] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 2941 | GB100 | sm_100 | GPU | GB100 [HGX GB200] | NVIDIA GB200 | Grace+Blackwell GB200 (edk2: TH500+GB100 2941–297F); Linux nvgrace-gpu VFIO (0x2941); gat: C2C+SXM; DCGM 1199W | ✓ |
| 297E | GB100 | sm_100 | GPU | GB100 | — | TH500+GB100 Self-Hosted C2C variant; gat: C2C+SXM (subsys 2046) | — |
| 2980 | GB102 | sm_100 | GPU | GB102 [Reserved Dev ID A] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 29BB | GB102 | sm_100 | GPU | GB102 [DRIVE P2021] | NVIDIA DRIVE P2021 | DCGM: P2021 50W | ✓ |
| 29BC | GB102 | sm_100 | GPU | GB102 [B100] | B100 (GB102 variant) (社区) | DCGM: B100 350W；gat: C2C+SXM+PCIe (subsys 1997/1998/1985/2045) | — |
| 29C0 | GB102 | sm_100 | GPU | GB102 [Reserved Dev ID B] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 29F1 | GB102 | sm_100 | GPU | GB102 | — | GB102 SXM variant; gat: SXM (subsys 20DC) | — |
| 3180 | GB110 | sm_103 | GPU | GB110 [Reserved Dev ID A] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 3182 | GB110 | sm_103 | GPU | GB110 [B300 SXM6 AC] | NVIDIA B300 SXM6 AC | B300 SXM6 AC; gat: SXM (subsys 20E5/20E6/220C); DCGM B300 1099W | ✓ |
| 3183 | GB110 | sm_103 | GPU | GB110 | — | GB110 B300 SXM variant; gat: SXM (subsys 22F2) | — |
| 3184 | GB110 | sm_103 | GPU | GB110 | — | GB110 B300 SXM variant; gat: SXM (subsys 22F3) | — |
| 31A1 | GB110 | sm_103 | GPU | GB110 [GB300 MaxQ] | GB300 Max-Q (社区) | GB300 Max-Q (edk2: TH500+GB110 special ID); gat: C2C+SXM (subsys 2274); DCGM 1199W | — |
| 31C0 | GB110 | sm_103 | GPU | GB110 [Reserved Dev ID B] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 31C2 | GB110 | sm_103 | GPU | GB110 [GB300] | NVIDIA GB300 | Grace+GB300 NVL (edk2: 31C1–31FF); Linux nvgrace-gpu VFIO (0x31C2); DCGM Bianca 1399W / Galaxy [20E5] 1299W | ✓ |
| 31C3 | GB110 | sm_103 | GPU | GB110 [GB300-252] | NVIDIA GB300 / NVIDIA GB300-252 | GB300-252 (252 GB HBM3e, DGX Station GB300 class); gat: C2C+SXM (subsys 23AB) | ✓ |
| 31FE | GB110 | sm_103 | GPU | GB110 | — | GB110 SXM variant; gat: SXM (subsys 20E5) | — |
| 3200 | GB112 | sm_103 | GPU | GB112 | — | Blackwell-Ultra (B300/GB300 class) internal/sample variant — no public SKU | — |
| 3224 | GB112 | sm_103 | GPU | GB112 | — | GB112 SXM variant; gat: SXM (subsys 215F) | — |
| 323E | GB112 | sm_103 | GPU | GB112 | — | GB112 SXM variant; gat: SXM (subsys 215F) | — |
| 3340 | GB120 | sm_103 | GPU | GB120 | — | GB120 Reserved (edk2: TH500+GB120 Self-Hosted range = 3341–337F) | — |
| 2B00 | GB10B | sm_110 | GPU | GB10B [Jetson AGX Thor] | — | Jetson AGX Thor iGPU (CS_NVIDIA_T264 in open-gpu nvcst.h) | — |
| 3400 | GB10B | sm_110 | GPU | GB10B [Tegra RP iGPU] | Tegra RP iGPU (GB10B) (社区) | T268 Tegra RP iGPU (CS_NVIDIA_T268 in open-gpu nvcst.h; GB10B in pci.ids) | — |
| 2B85 | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090] | NVIDIA GeForce RTX 5090 |  | ✓ |
| 2B87 | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090 D] | NVIDIA GeForce RTX 5090 D |  | ✓ |
| 2B8C | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090 D V2] | NVIDIA GeForce RTX 5090 D v2 |  | ✓ |
| 2BB1 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Workstation Edition] | NVIDIA RTX PRO 6000 Blackwell Workstation Edition |  | ✓ |
| 2BB2 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000D Blackwell Workstation Edition] | — |  | — |
| 2BB3 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 5000 Blackwell / RTX PRO 5000 72GB Blackwell] | NVIDIA RTX PRO 5000 Blackwell / NVIDIA RTX PRO 5000 72GB Blackwell | DCGM: rtx5000 349W | ✓ |
| 2BB4 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Max-Q Workstation Edition] | NVIDIA RTX PRO 6000 Blackwell Max-Q Workstation Edition | RTX PRO 6000 Max-Q Workstation; DCGM codename 'Galaxy TS2' 299W | ✓ |
| 2BB5 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Server Edition] | NVIDIA RTX PRO 6000 Blackwell Server Edition | RTX PRO 6000 Server Edition; DCGM PG153 SKU 210 600W | ✓ |
| 2BB9 | GB202 | sm_120 | GPU | GB202GL [RTX 6000D] | NVIDIA RTX 6000D | RTX 6000D China SKU (DCGM 600W / RTX6000D LC [2279] 249W) | ✓ |
| 2BBC | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000D Blackwell Max-Q Workstation Edition] | — |  | — |
| 2BBD | GB202 | sm_120 | GPU | GB202GL [RTX PRO 5500 Blackwell Workstation Edition] | NVIDIA RTX PRO 5500 Blackwell Workstation Edition | RTX PRO 5500 Blackwell Workstation (84 GB GDDR7 ECC); added in open-gpu 620.x | ✓ |
| 2C02 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5080] | NVIDIA GeForce RTX 5080 |  | ✓ |
| 2C05 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5070 Ti] | NVIDIA GeForce RTX 5070 Ti |  | ✓ |
| 2C09 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5070] | NVIDIA GeForce RTX 5070 | GB203-based RTX 5070 SKU alongside GB205 (2F04); in open-gpu README | ✓ |
| 2C18 | GB203 | sm_120 | GPU | GB203M / GN22 [GeForce RTX 5090 Max-Q / Mobile] | NVIDIA GeForce RTX 5090 Laptop GPU |  | ✓ |
| 2C19 | GB203 | sm_120 | GPU | GB203M / GN22 [GeForce RTX 5080 Max-Q / Mobile] | NVIDIA GeForce RTX 5080 Laptop GPU |  | ✓ |
| 2C2C | GB203 | sm_120 | GPU | GB6-256(N22W-ES-A1) | GN22 Mobile/Workstation 256-bit ES-A1 (社区) | GB203 range (2Cxx) engineering sample — N22W-ES-A1 | — |
| 2C31 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4500 Blackwell] | NVIDIA RTX PRO 4500 Blackwell |  | ✓ |
| 2C33 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4000 Blackwell SFF Edition] | NVIDIA RTX PRO 4000 Blackwell SFF Edition |  | ✓ |
| 2C34 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4000 Blackwell] | NVIDIA RTX PRO 4000 Blackwell |  | ✓ |
| 2C38 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 5000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 5000 Blackwell Generation Laptop GPU |  | ✓ |
| 2C39 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 4000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 4000 Blackwell Generation Laptop GPU |  | ✓ |
| 2C3A | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4500 Blackwell Server Edition] | NVIDIA RTX PRO 4500 Blackwell Server Edition | DCGM: GB203 164W | ✓ |
| 2C58 | GB203 | sm_120 | GPU | GB203M / GN22-X11 [GeForce RTX 5090 Max-Q / Mobile] | NVIDIA GeForce RTX 5090 Laptop GPU |  | ✓ |
| 2C59 | GB203 | sm_120 | GPU | GB203M / GN22-X9 [GeForce RTX 5080 Max-Q / Mobile] | NVIDIA GeForce RTX 5080 Laptop GPU |  | ✓ |
| 2C77 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 5000 Blackwell Embedded GPU] | NVIDIA RTX PRO 5000 Blackwell Embedded GPU |  | ✓ |
| 2C79 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 4000 Blackwell Embedded GPU] | NVIDIA RTX PRO 4000 Blackwell Embedded GPU |  | ✓ |
| 2D04 | GB206 | sm_120 | GPU | GB206 [GeForce RTX 5060 Ti] | NVIDIA GeForce RTX 5060 Ti |  | ✓ |
| 2D05 | GB206 | sm_120 | GPU | GB206 [GeForce RTX 5060] | NVIDIA GeForce RTX 5060 |  | ✓ |
| 2D18 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5070 Max-Q / Mobile] | NVIDIA GeForce RTX 5070 Laptop GPU |  | ✓ |
| 2D19 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5060 Max-Q / Mobile] | NVIDIA GeForce RTX 5060 Laptop GPU |  | ✓ |
| 2D2C | GB206 | sm_120 | GPU | GB6-128 (N22Y-ES-A1) | GN22 Mobile/Workstation 128-bit ES-A1 (社区) | GB206 range (2Dxx) engineering sample — N22Y-ES-A1 | — |
| 2D30 | GB206 | sm_120 | GPU | GB206GL [RTX PRO 2000 Blackwell] | NVIDIA RTX PRO 2000 Blackwell |  | ✓ |
| 2D39 | GB206 | sm_120 | GPU | GB206GLM [RTX PRO 2000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 2000 Blackwell Generation Laptop GPU |  | ✓ |
| 2D58 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5070 Max-Q / Mobile] | NVIDIA GeForce RTX 5070 Laptop GPU |  | ✓ |
| 2D59 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5060 Max-Q / Mobile] | NVIDIA GeForce RTX 5060 Laptop GPU |  | ✓ |
| 2D79 | GB206 | sm_120 | GPU | GB206GLM [RTX PRO 2000 Blackwell Embedded GPU] | NVIDIA RTX PRO 2000 Blackwell Embedded GPU |  | ✓ |
| 2D83 | GB207 | sm_120 | GPU | GB207 [GeForce RTX 5050] | NVIDIA GeForce RTX 5050 |  | ✓ |
| 2D98 | GB207 | sm_120 | GPU | GB207M [GeForce RTX 5050 Max-Q / Mobile] | NVIDIA GeForce RTX 5050 Laptop GPU |  | ✓ |
| 2DB8 | GB207 | sm_120 | GPU | GB207GLM [RTX PRO 1000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 1000 Blackwell Generation Laptop GPU |  | ✓ |
| 2DB9 | GB207 | sm_120 | GPU | GB207GLM [RTX PRO 500 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 500 Blackwell Generation Laptop GPU |  | ✓ |
| 2DD8 | GB207 | sm_120 | GPU | GB207M [GeForce RTX 5050 Max-Q / Mobile] | NVIDIA GeForce RTX 5050 Laptop GPU |  | ✓ |
| 2DF9 | GB207 | sm_120 | GPU | GB207GLM [RTX PRO 500 Blackwell Embedded GPU] | NVIDIA RTX PRO 500 Blackwell Embedded GPU |  | ✓ |
| 2F02 | GB205 | sm_120 | GPU | GB205 [GeForce RTX 5070 SUPER] | GeForce RTX 5070 SUPER (社区) | First RTX 50 SUPER PCI ID surfaced in pci.ids (v2026.11.19) | — |
| 2F04 | GB205 | sm_120 | GPU | GB205 [GeForce RTX 5070] | NVIDIA GeForce RTX 5070 |  | ✓ |
| 2F06 | GB205 | sm_120 | GPU | GB205 [GeForce RTX 5060] | NVIDIA GeForce RTX 5060 |  | ✓ |
| 2F18 | GB205 | sm_120 | GPU | GB205M [GeForce RTX 5070 Ti Mobile] | NVIDIA GeForce RTX 5070 Ti Laptop GPU |  | ✓ |
| 2F38 | GB205 | sm_120 | GPU | GB205GLM [RTX PRO 3000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 3000 Blackwell Generation Laptop GPU |  | ✓ |
| 2F58 | GB205 | sm_120 | GPU | GB205M [GeForce RTX 5070 Ti Mobile] | NVIDIA GeForce RTX 5070 Ti Laptop GPU |  | ✓ |
| 22E8 | GB202 | sm_120 | **HD Audio** | GB202 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22E9 | GB203 | sm_120 | **HD Audio** | GB203 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22EB | GB206 | sm_120 | **HD Audio** | GB206 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22EC | GB207 | sm_120 | **HD Audio** | GB207 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 2F80 | GB205 | sm_120 | **HD Audio** | GB205 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 2E02 | GB20B | sm_121 | GPU | GB20B [JMJWOA-Generic-GPU] | — | GB20B / Spark N1X pre-prod ID (Linux quirks.c: 2E00–2E3F requires PCIe ATS for CXL.cache) | — |
| 2E03 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (6144-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (6144-core Blackwell RTX GPU) | Graduated from JMJWOA-Generic-GPU into open-gpu; Linux quirks.c ATS range 2E00–2E3F | ✓ |
| 2E06 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (5120-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (5120-core Blackwell RTX GPU) | Client Arm+Blackwell N1X SoC (5120 CUDA cores); Linux quirks.c ATS range 2E00–2E3F | ✓ |
| 2E12 | GB10 | sm_121 | GPU | GB20B [GB10] | NVIDIA GB10 | DGX Spark GB10 (GB20B die); Linux quirks.c ATS range 2E00–2E3F | ✓ |
| 2E13 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (6144-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (6144-core Blackwell RTX GPU) | Client Arm+Blackwell N1X SoC (6144 CUDA cores); Linux quirks.c ATS range 2E00–2E3F | ✓ |
| 2E2A | GB20B | sm_121 | GPU | GB20B [JMJWOA-Generic-GPU] | — |  | — |

## 六、Hopper（29 个 ID · sm_90）

**GH100** 单芯片家族（含 `gpu-admin-tools` 独家收录、尚未入 `pci.ids` 的 **`2309` H20**；LS10 NVSwitch 全部 16 个 ID 归入第三章）。经 `gpu-admin-tools` 与 `DCGM` 交叉验证：`2343` / `2345` 均正式确认为 **GH200**（`has_c2c + is_sxm`），`2342` / `2345` / `2348` 位于 Linux 主线 `nvgrace-gpu` VFIO 白名单；DCGM 亦披露了内部代号 **`Scout`（`2337/2339`）**、**`SkinnyJoe`（`237F/2342`）** 与 **`PG502`（`2336/2338`）**。

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

## 七、Ada Lovelace（69 个 ID · sm_89）

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

## 八、Ampere（146 个 ID · sm_80 / 86）

数据中心 **GA100**（`sm_80`，A100 / A800 / A30 / AX800 / CMP 170HX）与消费/专业卡 **GA102–GA107**（`sm_86`，RTX 30 系 / RTX A 系 / A40 / A10 / A16 / A2），含 5 个 HD Audio。（LR10 NVSwitch 全部 17 个 ID 归入第三章，Orin T234 PCIe Root Port 归入第二章。）

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

**GV100** 单芯片（`sm_70`；Jetson AGX Xavier 嵌入式 `GV11B` 为 `sm_72`，其 PCIe RC 归入第二章）。虽不在开放内核模块支持列表内（仅闭源 R580 及之前分支支持），但在存量集群中 **V100 SXM2 16GB/32GB（`1DB0/1DB1`）**、**V100 PCIe 16GB/32GB（`1DB4/1DB6`）**、**V100S（`1DF6`）** 与 **DGX-1V / DGX Station（`1DBD/1DB2`）** 依然极常见。

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

## 十、Linux 主线内核、PCI-SIG 与多源核对方法论

### 关键内核与规范实证

- **Linux `nvgrace-gpu` + PCI-SIG CXL DVSEC**：主线 `drivers/vfio/pci/nvgrace-gpu/main.c` 明确收录 5 个一致性内存 VFIO ID（`2342` / `2345` / `2348` / `2941` / `31C2`），并通过 PCI-SIG CXL DVSEC（`PCI_VENDOR_ID_CXL`）探测 Blackwell-Next / Rubin 显存就绪状态（物理层仍为 NVLink-C2C，接口走向 CXL 标准化，详见本站 [Blackwell-Next CXL DVSEC 考据](/posts/blackwell-next-cxl-dvsec/)）。
- **Linux `drivers/pci/quirks.c` 的两处 CXL.cache / ATS 特例**：`quirk_nvidia_gpu_ats_required()` 强制对 **`10DE:2E00–2E3F`（GB20B / Spark / N1X）** 与 **`15B3:2101`（ConnectX-10 NVLink-C2C）** 开启 PCIe ATS，注释明确说明这些设备不暴露标准 CXL 配置空间但会发出类似 `CXL.cache` 的一致性事务。
- **Linux Rust 驱动 `nova-core`**：主线 `drivers/gpu/nova-core/gpu.rs` 已定义 `GA100–GA107`、`GH100`、`AD102–AD107`、`GB100/102`、`GB202–GB207`，并留下关键注释——*`Somewhere in the Rubin timeframe, boot0 will no longer have space to add new GPU IDs.`*
- **Open GPU `rmconfig.h` 芯片枚举**：R620（`620.73.04`）已内置 `TU102–TU117`、`GA100–GA107`、`AD102–AD107`、`GH100`、`GB100/102/10B/10C/110/112`、`GB202–GB207/GB20B/GB20C`、`GR100/GR102`、`T234D/T238D/T264D`。

### 七大一手数据源

1. **`pciutils/pciids`（`pci.ids v2026.11.19`）**：全量 `10DE`（1,997 条）与 `15B3`（235 条）超集。
2. **`NVIDIA/open-gpu-kernel-modules`（`620.73.04`，2026-11-18）**：`README.md` 全部 843 行 / 299 唯一 ID、`nvcst.h`（Grace `TH500` / Vera `TB500` / `T256 N1` / `T268`）、`nvswitch.c`（LR10/LS10 共 33 ID）、`rmconfig.h`、`arch/rubin/` 与 `arch/blackwell/`。
3. **`NVIDIA/gpu-admin-tools`（`main`）**：`devid_chips.py`、`devid_names.py`（补出 `2309` H20 与 `2343/2345` GH200）、`devid_properties.py`（子系统级 `is_sxm`/`is_pcie`/`has_c2c`，覆盖 Hopper → Rubin）。
4. **`NVIDIA/DCGM`（`master` / `v4.7.0`）**：`nvvs/diag-skus.yaml.in`（137 个数据中心 SKU 功耗与内部板卡代号）与 Rubin `3041 / 307E / 307F` 诊断支持说明。
5. **`NVIDIA/edk2-nvidia`（`main`）**：`TH500GpuDxe/efihand/DriverBinding.c`（Endpoint vs Self-Hosted Bit-6 分配规则与 `GB120 3341–337F`）、`Dsdt_TH500.asl`。
6. **`torvalds/linux` 主线源码**：`nvgrace-gpu/main.c`、`nova-core/gpu.rs`、`drivers/pci/quirks.c`、`drivers/perf/arm_cspmu/nvidia_cspmu.c`、`tegra241-cmdqv.c`、`nouveau/nvkm/engine/device/base.c`。
7. **NVIDIA CUDA 13.4 / 13.5 官方文档**：确认 Vera Rubin `sm_107`（CC 10.7）及历代 SM 映射。

> [!NOTE]
> **最终汇总统计（2026-11-20）**：本文与配套 Excel 共收录 **1149** 条一手实证 PCI Device ID —— 其中 `10DE` CUDA GPU（Fermi → Rubin 11 代）**1026** 条（开放驱动 `620.73.04` 官方收录 **299** 条）、`10DE` Grace/Vera/Tegra CPU & SoC **40** 条、`10DE` NVSwitch **33** 条、`15B3` 配套高速互联与 NVLink-6/7/8 Switch **50** 条。

