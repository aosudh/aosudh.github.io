---
title: "NVIDIA Jetson / Tegra 编号与料号全量对照"
published: 2026-06-20
description: "把 Jetson 各代核心板、底板、开发套件的 Pxxxx 编号、SKU 后缀与量产料号一次理清，附设备上自查方法与设备树实证的模组×底板组合。"
image: "/assets/covers/jetson-parts.svg"
category: "资料与随笔"
tags: ["Jetson", "NVIDIA", "速查表"]
pinned: false
draft: false
---

> [!TIP]
> 本页为 **Astro + Mizuki** 自动导入预览版；若需查看原始手写排版（含原版内联 SVG 与附件下载），可访问 [原版 HTML 正文](/legacy-posts/nvidia-jetson-tegra-part-numbers.html)。

玩 Jetson 的人迟早会被那一串 `Pxxxx` 编号搞晕：同一个号既可能是核心板，也可能是底板甚至整机；后面再挂个四位后缀又区分显存和工业级。这篇把**主线 Linux 内核设备树、NVIDIA 官方手册与数据手册、官方下游 BSP、以及厂商量产料号**交叉核对后，整理成一份从 TK1 到 Thor 的完整对照，并给出在设备上自查型号的方法。 

## 先学会读懂一串号

 

Tegra/Jetson 的编号其实有规律，拆开看就不乱了： 

`Pxxxx` 是**板卡设计号（board design ID）**，它本身不区分定位——可能是核心板（SOM）、底板（carrier），也可能是开发套件整机。真正区分配置的是后面那串 `Pxxxx-yyyy`：四位后缀 `yyyy` 是 **SKU**，写在模组 EEPROM 里，用来区分显存容量、工业级、存储介质等。比如 `P3767` 这一个设计号下就挂了五个 SKU（Orin NX 16G/8G、Orin Nano 8G/4G、以及开发套件 SD 卡版）。 

判断「哪个核心板配哪个底板」最硬的依据是设备树文件名，它的命名规则是 `tegra<SoC>-p<底板>-<sku>+p<核心板>-<sku>.dts`。举个真实例子： 

```text
tegra234-p3737-0000+p3701-0004.dts
   │        │            └─ 核心板 P3701-0004 = AGX Orin 32GB
   │        └─ 底板 P3737-0000 = AGX Orin 参考底板
   └─ SoC tegra234 = Orin
```

 

几个 SoC 代号对应到产品代：`tegra210` = Maxwell X1（TX1/Nano）、`tegra186` = Parker（TX2）、`tegra194` = Xavier、`tegra234` = Orin、`tegra264` = Thor。 

跟 P 号并行的还有一套**量产订货料号**：`699-Lxxxxx-yyyy-zzz` 是裸模组，`900-xxxxx` 是带散热的模组，`945-xxxxx` / `900-` 是开发套件整机。另外烧录脚本里会出现 `chipsku`（如 7023、7323），与模组 SKU 一一对应，下面表里一并列出。 

## 在设备上怎么自查

 

拿到一块板子想确认到底是什么型号，最快的几条命令： 

```text
cat /proc/device-tree/nvidia,dtsfilename      # 最直接：含 底板+核心板 组合名
cat /sys/firmware/devicetree/base/model       # 人类可读型号
cat /proc/device-tree/nvidia,boardids         # board id 列表
sudo i2cdump -y <bus> 0x50                     # 直接读模组 EEPROM 的 board SKU
sudo pip install jetson-stats && jtop         # 自动解析以上全部（jtop / jetson_release）
```

 

## 各代核心板（SOM）

 

核心板也就是系统级模组（System-on-Module），是真正承载算力的部分。下面按代分组，含 SKU 后缀、显存、GPU 与标称算力、可订货的量产料号。（算力为官方标称值；标「→」的是 Orin 系列经软件升级后的 Super Mode 数值。）   Tegra264 · Jetson Thor（JetPack 7）        

| PN | 产品 | 显存 | GPU / 算力（标称） | 量产料号 | JetPack |
| --- | --- | --- | --- | --- | --- |
| P3834-0008 | Jetson Thor (T5000) | 128GB LPDDR5X · 256-bit · 273 GB/s | Blackwell 2560 CUDA / 96 Tensor · 14C Neoverse-V3AE · 2070 FP4 / 1035 FP8 TFLOPS · 40–130W · MIG / PVA v3 | 900-13834-0080-000 | JP7 |
| P3834（T4000 SKU） | Jetson Thor (T4000) | 64GB LPDDR5X | 低配版 · 约 1200 TFLOPS（资料仍为初步） | — | JP7 |

    Tegra234 · Jetson AGX Orin（JetPack 5/6）          

| PN | 产品 | 显存 | GPU / 算力（标称） | 量产料号 | chipsku |
| --- | --- | --- | --- | --- | --- |
| P3701-0000 | AGX Orin（早期 / 开发套件 32GB 模组） | 32GB LPDDR5 · 204.8 GB/s | Ampere 1792 CUDA / 56 Tensor | — | 7023 |
| P3701-0004 | AGX Orin 32GB | 32GB LPDDR5 · 204.8 GB/s | 1792 CUDA / 56 Tensor · 200 TOPS (INT8) | — | 7223 |
| P3701-0005 | AGX Orin 64GB | 64GB LPDDR5 · 204.8 GB/s | 2048 CUDA / 64 Tensor · 275 TOPS (INT8 稀疏) · 15–60W | 900-13701-0050-000 | 7023 |
| P3701-0008 | AGX Orin Industrial 64GB | 64GB LPDDR5 + ECC | 2048 CUDA / 64 Tensor · 工业级 -40~85℃ / 10yr · 最高 75W | — | 7023 |

    Tegra234 · Jetson Orin NX / Orin Nano（同一 SO-DIMM 形态）           

| PN | 产品 | 显存 | GPU / 算力（标称） | 量产料号 | chipsku |
| --- | --- | --- | --- | --- | --- |
| P3767-0000 | Orin NX 16GB | 16GB LPDDR5 | Ampere 1024 CUDA / 32 Tensor · 100 → 157 TOPS (Super) · 10–40W | 900-13767-0000-000 | 7323 |
| P3767-0001 | Orin NX 8GB | 8GB LPDDR5 | 1024 CUDA · 70 → 117 TOPS (Super) | — | 7423 |
| P3767-0003 | Orin Nano 8GB | 8GB LPDDR5 | 1024 CUDA · 40 → 67 TOPS (Super) · 7–25W · 带宽 68 → 102 GB/s | — | 7523 |
| P3767-0004 | Orin Nano 4GB | 4GB LPDDR5 | 512 CUDA · 20 → 34 TOPS (Super) | — | 7623 |
| P3767-0005 | Orin Nano 8GB（开发套件 SD 卡版） | 8GB LPDDR5 | 配置同 -0003 · SD 卡启动 · Orin Nano Super 套件用 | — | 7523 |

    Tegra194 · Jetson Xavier（JetPack 4/5）              

| PN | 产品 | 显存 | GPU / 关键规格 | JetPack |
| --- | --- | --- | --- | --- |
| P2888-0001 | AGX Xavier 16GB（「原始」版） | 16GB LPDDR4x | Volta 512 CUDA / 64 Tensor · 约 30 TOPS | JP4/5 |
| P2888-0004 / -0003 | AGX Xavier 32GB | 32GB LPDDR4x | 约 32 TOPS | JP4/5 |
| P2888-0005 | AGX Xavier 64GB | 64GB LPDDR4x | Volta 512 CUDA | JP4/5 |
| P2888-0006 | AGX Xavier 8GB | 8GB LPDDR4x | 低功耗版 | JP4/5 |
| P2888-0008 | AGX Xavier Industrial 32GB | 32GB + ECC | 双 Cortex-R5 锁步 · GPU / DRAM ECC · 10yr | JP4/5 |
| P3668-0000 | Xavier NX（开发套件版，microSD） | 8GB LPDDR4x | Volta 384 CUDA / 48 Tensor · 约 21 TOPS | JP4/5 |
| P3668-0001 | Xavier NX 8GB（eMMC，量产） | 8GB LPDDR4x | 约 21 TOPS | JP4/5 |
| P3668-0003 | Xavier NX 16GB | 16GB LPDDR4x | Volta 384 CUDA | JP4/5 |

    Tegra210 · Jetson TX1 / Nano（JetPack 3/4，均已 EOL）          

| PN | 产品 | 显存 | GPU / 算力 | JetPack |
| --- | --- | --- | --- | --- |
| P2180-1000 | Jetson TX1 | 4GB LPDDR4 | Maxwell 256 CUDA · 约 1 TFLOPS FP16 | JP3/4 (EOL) |
| P3448-0000 | Jetson Nano 4GB（microSD 开发模组） | 4GB LPDDR4 | Maxwell 128 CUDA · 472 GFLOPS FP16 | JP4 (EOL) |
| P3448-0002 | Jetson Nano 4GB 量产（16Gb eMMC） | 4GB LPDDR4 | 同上 | JP4 (EOL) |
| P3448-0003 | Jetson Nano 2GB | 2GB LPDDR4 | Maxwell 128 CUDA | JP4 (EOL) |

    Tegra186 · Jetson TX2（JetPack 4，已 EOL）          

| PN | 产品 | 显存 | GPU / 关键规格 | JetPack |
| --- | --- | --- | --- | --- |
| P3310-1000 | Jetson TX2 | 8GB LPDDR4 | Pascal 256 CUDA · 约 1.33 TFLOPS FP16 | JP4 (EOL) |
| P3489-0888 | Jetson TX2 4GB | 4GB LPDDR4 | Pascal 256 CUDA | JP4 (EOL) |
| P3489-0000 | Jetson TX2i（工业级） | 8GB LPDDR4 + ECC | -40~85℃ / 10yr · 20W | JP4 (EOL) |
| P3636-0001 | Jetson TX2 NX | 4GB LPDDR4 | Pascal 256 CUDA · NX 形态 | JP4 (EOL) |

  

再往前还有 **Jetson TK1**（Tegra124，Kepler 192 CUDA，2GB DDR3L），board id 记为 `R375-0001`，早已退市，这里只作收尾提一句。 

## 底板（Carrier Board）

 

底板提供供电、接口和扩展，核心板插上去才是一台完整设备。同一块底板常常能带多种核心板——这也是 P 号容易让人误解的地方。   NVIDIA 官方参考底板                

| 设计号 | 名称 / 用途 | 适配核心板 | 代 | 备注 |
| --- | --- | --- | --- | --- |
| P4071 | AGX Thor 开发套件参考底板 | P3834 | Thor | 套件标配；官方自定义底板移植模板 |
| P3971 | Thor 参考 / 早期底板 | P3834 | Thor | 见主线内核 tegra264-p3971-0089+p3834-0008 |
| P3737 | AGX Orin 参考底板 | P3701（全 SKU） | Orin | 开发套件底板；工业模组 P3701-0008 亦挂此板 |
| P3740 | AGX Orin 工业 / 服务器参考底板 | P3701-0008 | Orin | tegra234-p3740-0002+p3701-0008 |
| P3768 | Orin Nano / Orin NX 参考底板 | P3767（全 SKU） | Orin | Super 模式需 HV 电源轨 |
| P3509 | Xavier NX / TX2 NX 开发套件底板 | P3668 · P3636 · P3767-0000 | Xavier / Orin | 一板多模组；JP6 BSP 支持挂 Orin NX 16G |
| P2822 | AGX Xavier 底板 | P2888 | Xavier | — |
| P2597 | TX1 / TX2 开发套件底板 | P2180 · P3310 | TX1 / TX2 | 两代共用同款 PCB |
| P3449 | Jetson Nano 开发套件底板 | P3448 | Nano | A02 旧版 / B01 新版（双 CSI） |
| P3541 | Jetson Nano 2GB 套件底板 | P3448-0003 | Nano | — |

  

## 开发套件整机

 

开发套件 = 非量产规格的核心板 + 参考底板，用来开发调试，不可直接用于量产。下表的 945-/900- 是已核到原始出处的量产料号。   Developer Kit 整机              

| 套件 | board id | 量产料号 | 模组 | 底板 |
| --- | --- | --- | --- | --- |
| Jetson AGX Thor Developer Kit | — | 945-14070-0080-000（另 -0085 = Compute Carrier 版） | P3834-0008 (T5000) | P4071 |
| Jetson AGX Orin Developer Kit | P3730-0000 | 见 Download Center | P3701-0000（早期 32G）→ 现 64G | P3737-0000 |
| Jetson Orin Nano (Super) Developer Kit | — | 见 Download Center | P3767-0005 | P3768-0000 |
| Jetson AGX Xavier Developer Kit | P2972-0000 | 945-82972-0040-000 (32G) / -0000-000 (16G) | P2888 | P2822 |
| Jetson Xavier NX Developer Kit | (P3509) | — | P3668-0000 (microSD) | P3509-0000 |
| Jetson Nano Developer Kit | P3450-0000 | 945-13450-0000-100 (B01) / -000 (A02) | P3448 | P3449 |
| Jetson TX2 Developer Kit | P2771-0000 | — | P3310 | P2597 |
| Jetson TX1 Developer Kit | P2371-0000 | — | P2180 | P2597 |

  

## 模组 × 底板：设备树里实证的组合

 

下面这些组合不是推测，而是直接来自主线 Linux 内核 `arch/arm64/boot/dts/nvidia` 的设备树文件名，以及 NVIDIA 官方下游 BSP（OE4T meta-tegra）的机型配置。其中 `P3509-A02` 那条尤其值得注意——它证明 Xavier NX 时代的那块底板，在 JetPack 6 下也能带 Orin NX 16GB 模组。   设备树 / BSP 实证组合                           

| 来源 | DTS / 机型名 | 核心板 | 底板 |
| --- | --- | --- | --- |
| 内核 | tegra210-p2371-0000 / -2180 | P2180 (TX1) | P2597（P2371 套件） |
| 内核 | tegra210-p3450-0000 | P3448 (Nano) | P3449（P3450 套件） |
| 内核 | tegra210-p3541-0000 | P3448-0003 (Nano 2GB) | P3541 |
| 内核 | tegra186-p2771-0000 | P3310 (TX2) | P2597（P2771 套件） |
| 内核 | tegra186-p3509-0000+p3636-0001 | P3636-0001 (TX2 NX) | P3509-0000 |
| 内核 | tegra194-p2972-0000 | P2888 (AGX Xavier) | P2822（P2972 套件） |
| 内核 | tegra194-p3509-0000+p3668-0000 | P3668-0000 (Xavier NX microSD) | P3509-0000 |
| 内核 | tegra194-p3509-0000+p3668-0001 | P3668-0001 (Xavier NX 8GB) | P3509-0000 |
| 内核 | tegra234-p3737-0000+p3701-0000 | P3701-0000 (AGX Orin) | P3737-0000 |
| 内核 | tegra234-p3737-0000+p3701-0008 | P3701-0008 (AGX Orin Ind.) | P3737-0000 |
| 内核 | tegra234-p3740-0002+p3701-0008 | P3701-0008 (AGX Orin Ind.) | P3740-0002（IGX Orin 底板，见下文） |
| 内核 | tegra234-p3768-0000+p3767-0000 | P3767-0000 (Orin NX 16G) | P3768-0000 |
| 内核 | tegra234-p3768-0000+p3767-0005 | P3767-0005 (Orin Nano SD) | P3768-0000 |
| 内核 | tegra264-p3971-0089+p3834-0008 | P3834-0008 (Thor T5000) | P3971-0089 |
| 内核 | tegra264-p4071-0000+p3834-0008 | P3834-0008 (Thor T5000) | P4071-0000 |
| BSP | p3509-a02-p3767-0000 | P3767-0000 (Orin NX 16G) | P3509-A02 ★跨代复用 |
| BSP | p3737-0000-p3701-0004 | P3701-0004 (AGX Orin 32G) | P3737-0000 |
| BSP | p3737-0000-p3701-0005 | P3701-0005 (AGX Orin 64G) | P3737-0000 |
| BSP | p3768-0000-p3767-0001 | P3767-0001 (Orin NX 8G) | P3768-0000 |
| BSP | p3768-0000-p3767-0003 | P3767-0003 (Orin Nano 8G) | P3768-0000 |
| BSP | p3768-0000-p3767-0004 | P3767-0004 (Orin Nano 4G) | P3768-0000 |

  

## 容易混进来的「非 Jetson」Tegra 板

 

搜 P 号时经常会撞上一些同代 Tegra 但根本不是 Jetson 的板子，列出来避免误判：            

| P 号 | SoC | 用途（非 Jetson 产品线） |
| --- | --- | --- |
| P2595 | tegra210 | 任天堂 Switch（Tegra X1）— jetson-stats DB 记为 p2595-0000-A0 |
| P2571 | tegra210 | NVIDIA SHIELD Android TV（Tegra X1） |
| P2530 / P2894 | tegra210 | Tegra X1 参考 / 车载板（tegra210-p2894-0050-a08） |
| P3904 | — | NVIDIA Clara AGX（医疗，Jetson 相邻产品线） |

  

---

 

## 延伸：DRIVE / IGX / Holoscan —— Jetson 之外的同源平台

 

同一颗 Tegra SoC，NVIDIA 还做了三条与 Jetson 并行的产品线：车规的 **DRIVE AGX**、工业医疗的 **IGX**，以及它们承载的 **Holoscan** 软件（前身 Clara AGX / Clara Holoscan）。读它们的号之前，先记三条与 Jetson 不同的规律： 
 
- **只有第一代 DRIVE AGX Xavier / Pegasus（E3550）是 SoC 直焊的整板**（Pegasus 把双 Xavier + 双 Turing GPU 全焊在一块板上，没有可插拔模组）。**从 DRIVE AGX Orin 起又回到「核心板（SOM）＋底板」两段式**，而且模组直接沿用 Jetson 的 `P3701`（Orin）/ `P3834`（Thor）家族，只换 DRIVE 专属 SKU 与底板。 
- **板号前缀不同。**Jetson 全用 `P`；DRIVE 第一代整板用 `E`（E3550），Orin/Thor 的底板改用 `P`（P3710 / P3960）。 
- **量产料号多一个 `940-` 前缀。**原文的 `699-/900-/945-` 都是 Jetson；**DRIVE 与 IGX 的开发套件整机统一是 `940-`**。 
 

**一条贯穿全文的线索：同一颗模组会跨产品线复用。**最典型的是 `P3701` 这颗 Orin 模组——它同时出现在 Jetson AGX Orin（配底板 P3737）、IGX Orin（配 P3740）和 DRIVE AGX Orin（配 P3710）上，只是 SKU、底板与软件栈不同。设备树命名两边不同：Jetson 用「底板＋模组」组合名（`tegra234-p3737-0000+p3701-0000.dts`），DRIVE 把模组放进 include、顶层只用底板名（`tegra234-p3710-0010-a01-linux-driveav-gos.dts`）。Thor 一代同理走两段式（Jetson Thor = P3834 + P4071；DRIVE Thor = Thor 模组 + P3960）。   量产料号前缀速查（在 699-/900-/945- 之外新增 940-）          

| 前缀 | 含义 | 实例 |
| --- | --- | --- |
| 699- | Jetson 裸模组；DRIVE 第一代（E3550）用于整板 | E3550 整板 699-63350-0001-5xx |
| 900- | Jetson 带散热模组 | 900-13701-0050-000（AGX Orin 64G） |
| 945- | Jetson 开发套件整机 | 945-14070-0080-000（Jetson Thor 套件） |
| 940- | **DRIVE / IGX 平台开发套件整机（新）** | DRIVE Orin 940-63710 · DRIVE Thor 940-63960 · IGX Orin 940-23840 · IGX Thor 940-25840 |

  

### DRIVE AGX Xavier / Pegasus（板号 E3550，tegra194）

 

DRIVE 侧的 Xavier 平台板号是 `E3550`，Xavier DevKit 与 Pegasus DevKit 共用同一块板，靠 SKU 区分。已是停更产品（末版 DRIVE OS 5.2.6）。   Tegra194 · DRIVE AGX Xavier / Pegasus（DRIVE OS）              

| 项 | 值 |
| --- | --- |
| 结构 | SoC 直焊整板（DRIVE 唯一一代如此，无可插拔模组） |
| 平台板号 | E3550（双 Xavier 开发板；Xavier DevKit 与 Pegasus DevKit 共用） |
| SKU 区分 | Xavier DevKit = SKU 2000（2× Xavier）；Pegasus DevKit = SKU 2200（2× Xavier + 2× Turing GPU，320 TOPS） |
| 整板料号 | 699-63350-0001-5xx （实物板标签；-500/-501 为修订） |
| 单 Xavier 变体 | P3479（恢复设备仅 x1；E3550 为 x1+x2 双颗） |
| Xavier 计算核 | 烧录目标里以 `p2888-t194` 指代 Xavier CVM |
| 设备树 | `tegra194-e3550-0001-A.dtsi`、显示 `tegra194-display-e3550-0001-b01-A/B.dtsi`（DRIVE OS BSP，t19x/automotive） |
| 末版软件 | DRIVE OS 5.2.6 / DriveWorks 4.0（Xavier/Pegasus XT 已停更） |

  

### DRIVE AGX Orin（P3710 / P3663，tegra234）

 

从这一代起 DRIVE 回到两段式：**P3701 Orin 模组（DRIVE/工业 SKU）+ P3710 底板**，模组与 Jetson AGX Orin、IGX Orin 同族。与 Jetson 的差异在 SKU、SoC 分级、ASIL 安全与软件栈（DRIVE OS vs JetPack），NVIDIA 官方明确「不能拿 Jetson 数据手册当 DRIVE 用」。   Tegra234 · DRIVE AGX Orin            

| 项 | 值 |
| --- | --- |
| 结构 | 核心板（SOM）+ 底板 两段式（模组与 Jetson 同族） |
| 核心板（SOM） | P3701 Orin 模组的 DRIVE/工业 SKU——`P3701-0002`（32GB Micron LPDDR5 + ECC，见 BCT 文件 `tegra234-mb1-bct-p3701-0002-…-ecc`） |
| 底板（carrier） | P3710；板名 p3710-10-a01 / a03 / a04，量产 p3710-10-s05 |
| 整机料号 | 940-63710-0010-100 / 200 / 300（区域版）、-D00 / -C00（修订） |
| 设备树 | `tegra234-p3710-0010-a01-linux-driveav-gos.dts`（顶层只含底板名，模组经 include；非 Jetson 的 +p3701 组合名） |
| 量产单 Orin 板 | P3663（板名 p3663-a01，偏量产/ECU）；P3710 双 Orin、P3663 单 Orin 系据烧录文档推断 |

  

### DRIVE AGX Thor（板号 P3960，tegra264）

 

最新车规平台，2025 下半年量产，同为两段式：**Thor 模组（P3834 家族）+ P3960 底板**。SoC 与 Jetson Thor 同为 Tegra264（14× Neoverse-V3AE + Blackwell）；Jetson Thor 是 P3834 模组 + P4071 底板，DRIVE Thor 则换成 P3960 底板。   Tegra264 · DRIVE AGX Thor（2025 GA）             

| 项 | 值 |
| --- | --- |
| 结构 | 核心板（SOM）+ 底板 两段式 |
| SoC | Tegra264 / T264，14× Arm Neoverse-V3AE + Blackwell GPU（主线内核 Linux 6.17 起支持） |
| 核心板（SOM） | Thor 模组（P3834 家族；Jetson Thor 为 P3834-0008，id 7026）；DRIVE 专属 SKU 未单独查到 |
| 底板（carrier） | P3960（板名 p3960-0010 等） |
| 整机料号 | SKU 10（台架）940-63960-0010-000；SKU 12（车内）940-63960-0012-000 |
| 设备树 | …/t264/automotive/kernel-dts/p3960/ 下 `tegra264-p3960-*.dtsi`（sound / nvscic2c-pcie / pmic 等） |
| 上市 / 出口 | 2025 下半年 GA（9 月发货）；ECCN 4A994 |

  

### Holoscan / Clara AGX 谱系

 

这条线最容易混：**「Holoscan」如今是软件 SDK，它的硬件就是 IGX（见下）；Clara AGX 则是 Xavier 时代的祖先。**改名与换代脉络如下。   从 Clara AGX 到 IGX：改名与换代时间线            

| 时间 | 名称 | 硬件 / 变化 |
| --- | --- | --- |
| 2020 | Clara AGX Developer Kit | Jetson AGX Xavier 模组（P2888）+ Quadro RTX 6000 + ConnectX-6 |
| 2021–22 | Clara Holoscan Developer Kit | Orin + RTX A6000——此名后并入 IGX Orin |
| 2022.03 | Clara Holoscan MGX | 医疗量产平台，Orin Industrial + 选配 dGPU/NIC，10 年支持 |
| 2022.09 | 改名 IGX | 「Clara Holoscan Developer Kit」→「IGX Orin Developer Kit」 |
| 2024.06 | 「Clara Holoscan」→「NVIDIA Holoscan」 | 去掉 Clara，扩到通用传感处理 |
| 2025.10 | IGX Thor | 接班 IGX Orin（≈8× 算力） |

    Clara AGX Developer Kit 规格（官方用户指南 v2.0）              

| 项 | 值 |
| --- | --- |
| 核心板 | AGX Xavier 32GB 模组（P2888 家族；8 核 Carmel） |
| 内存 | 32GB 256-bit LPDDR4x · 136.5 GB/s |
| 独显 dGPU | Quadro RTX 6000（Turing，24GB GDDR6，4608 CUDA / 576 Tensor） |
| 网卡 | ConnectX-6（MT28908；板载 PCIe Switch） |
| 存储 | 250GB 可拆 SSD（SATA M.2） |
| 扩展 | PCIe x8→Xavier、PCIe x8→RTX6000（物理 x16 槽） |
| 电源 / 尺寸 | 750W · 227×149×332 mm |
| 底板设计号 | 官方用户指南未印 Pxxxx；社区型号库（jetson-stats）记作 `P3904` （与上文「非 Jetson」表呼应） |

  

### IGX Orin Developer Kit（P3740 + P3701-0008，tegra234）

 

IGX Orin 直接复用 Jetson AGX Orin Industrial 模组，配 IGX 专用底板 P3740，集成 ConnectX-7 与 BMC。   IGX Orin Developer Kit 规格（用户指南 v1.0 + 产品简介）                  

| 项 | 值 |
| --- | --- |
| 整机料号 | 940-23840-0000-000（Cordless）/ -0001-000（NA/TW/CN/JP）/ -0002-000（EU/UK） |
| 核心板 | 「NVIDIA IGX Orin Industrial Module」= Jetson AGX Orin Industrial 模组 P3701-0008（board id 7023） |
| 底板 | P3740-0002（IGX 专用） |
| iGPU | Ampere 2048 CUDA / 64 Tensor · INT8 up to 248 TOPS |
| CPU | 12 核 Arm Cortex-A78AE |
| 内存 | 64GB 256-bit LPDDR5 · 3200 MHz （用户指南表格误标 LPDDR6，以产品简介为准） |
| 存储 | 500GB NVMe SSD + 64GB eMMC + 64MB QSPI NOR + 8MB 安全 Flash |
| 独显（可选） | RTX A6000（48GB）或 RTX 6000 Ada |
| 集成网卡 | ConnectX-7（32 lane PCIe Gen5 + 集成 Switch，2×100GbE QSFP28） |
| BMC / MCU | Aspeed AST2600（OpenBMC）/ Infineon Aurix TC397 |
| 设备树 / 烧录名 | `tegra234-p3740-0002+p3701-0008.dts`（主线内核）；BSP 烧录目标 `igx-orin-devkit` |
| 电源 / 尺寸 | uATX 最高 850W · 262.7×382.7×151.2 mm |

  

>  

**三重实证「IGX Orin 模组 = P3701-0008」：**① 进恢复模式时主机 `lsusb` 显示 `ID 0955:7023 NVIDIA Corp. APX`——`0955` 是 NVIDIA 的 USB VID，`7023` 正是 AGX Orin Industrial 的 board id；② 主线内核设备树 `tegra234-p3740-0002+p3701-0008`；③ 产品简介规格与 AGX Orin Industrial 64GB 完全吻合。另：其 BMC 主机名是 `mgx-3809`——`mgx` 正是当年 Clara Holoscan **MGX** 的化石。  

### IGX Thor Developer Kit（T7000，2025.10 接班）

   Tegra264 · IGX Thor（Blackwell）           

| 项 | 值 |
| --- | --- |
| 整机料号 | 940-25840-0001-000（与 IGX Orin 的 940-23840 平行） |
| 板 / SoC | IGX T7000 板，Blackwell iGPU（2560 CUDA）+ 14× Neoverse-V3AE |
| 网络 / 独显 | ConnectX-7（QSFP112，2×200GbE / 400GbE）；独显 RTX 6000 PRO Blackwell |
| 算力 | up to 5581 FP4 TFLOPS（≈8× IGX Orin iGPU） |
| 另有 | IGX Thor Developer Kit Mini（T5000） |

  

### 新平台的设备树 / 板号实证

   DRIVE / IGX / Clara 的设备树实证            

| 平台 | DTS / 板名 | 板（及模组） |
| --- | --- | --- |
| DRIVE Xavier/Pegasus | tegra194-e3550-0001-A.dtsi | E3550 整板（SoC 直焊） |
| DRIVE Orin（开发套件） | tegra234-p3710-0010-a01-linux-driveav-gos.dts | 底板 P3710 + 模组 P3701-0002 |
| DRIVE Orin（量产单 Orin） | t234-p3663-a01-*.dts | P3663 |
| DRIVE Thor | tegra264-p3960-*.dtsi | 底板 P3960 + Thor 模组（P3834 家族） |
| IGX Orin | tegra234-p3740-0002+p3701-0008.dts | P3740 + P3701-0008 |
| Clara AGX | tegra194-p2888-0001-p2822-0000（Xavier 基底） | P2888 模组（底板另算） |

  

>  

**本节信息缺口（诚实标注，未编造）：**① DRIVE Xavier/Pegasus 的官方量产 NVPN——只有论坛实物标签 699-63350-0001-5xx，NVIDIA 把精确料号挡在 NVClassification@nvidia.com 之后；② Clara AGX 底板设计号——连官方用户指南都未印（社区记作 P3904）；③ P3663、以及 DRIVE Thor 模组的完整量产料号/SKU 未公开；④「P3710 双 Orin / P3663 单 Orin」系据烧录文档「default Orin A」推断，非数据手册明文；⑤「940- = DRIVE/IGX 整机」前缀系多个料号归纳。  

**本节数据来源：**DRIVE OS《Setting Up the E3550 Platform》与《DRIVE Platform Supported Boards》、NVIDIA DRIVE AGX FAQ、DRIVE AGX Thor / Orin Platform for Developers PDF、IGX Orin Developer Kit Product Brief（2024-12-11）、Holoscan 仓库的 Clara AGX 与 IGX Orin 用户指南（nvidia-holoscan/holoscan-docs）、主线 Linux 内核 IGX Orin 支持补丁（作者 NVIDIA Shubhi Garg）、以及 NVIDIA 开发者论坛 DRIVE / IGX 板块的官方回帖。每条料号均标注「官方／论坛实物／推断」三类证据，未核到一手出处者已显式说明，未编造。 

## 几个容易踩的坑

 

>  

**P 号 ≠ 唯一产品。**Orin NX 与 Orin Nano 共用 P3767；TX1/TX2 共用 P2597 底板；P3509 先后带过 TX2 NX、Xavier NX 和 Orin NX。判型一定要看四位 SKU 后缀，光看 P 号会认错。  

另外几点：`jetson-stats` 的型号库非常好用，但个别标注有出入（比如把 P3701-0002 标成 IGX、Thor 的 CUDA 版本写成 11.0），具体规格还是以 NVIDIA 官方文档为准。主线内核只收录了一部分组合，NVIDIA 下游 L4T 和 meta-tegra 里还有更多工业/参考底板（如 P3740 系列），本文已尽量合并。最后，真正的「长尾」其实是第三方底板——Connect Tech、Auvidea、Seeed 等给同一颗 SOM 配的底板各有自己的 PN，数量远超 NVIDIA 官方底板，做边缘部署选型时这部分才是大头。 

## 数据来源与方法

 

这份对照不是凭记忆写的，而是四类来源交叉核对的结果：**(1)** 主线 Linux 内核 `arch/arm64/boot/dts/nvidia` 目录的设备树文件名（模组×底板组合的最硬证据）；**(2)** NVIDIA Jetson Linux Developer Guide、Jetson FAQ 与各模组数据手册（SKU、chipsku、算力、工业级差异）；**(3)** NVIDIA 官方下游 BSP 层 OE4T meta-tegra 的机型配置（补主线没有的组合）；**(4)** Connect Tech 等厂商的量产料号页（坐实 900-/945- 编号）。表中标「见 Download Center」的量产料号，是没有逐一核到一手出处、未予编造的项；算力列是官方标称值，已注明「标称」。 

如果你手头有带 token 的环境，可以用 GitHub `search/code` 按 SoC 逐代把每个 P 号在内核与 L4T 里的引用做一次真正的全库扫描，会比这里更全；或者直接 clone NVIDIA 的 `Linux_for_Tegra/source`，翻 `hardware/nvidia/platform/` 下的设备树目录树，那是工业/参考底板长尾最完整的地方。
