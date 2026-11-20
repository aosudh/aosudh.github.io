---
title: "NVIDIA GPU PCI Device ID 全量对照：Ampere → Rubin"
published: 2026-06-24
updated: 2026-11-20
description: "把 lspci 里的 10DE:xxxx 翻译成芯片 / 架构 / 产品：基于 2026-11 最新 pci.ids、NVIDIA open-gpu-kernel-modules 620.73.04、Linux 主线驱动与 CUDA 13.5 文档，全量更新 Ampere → Rubin 共 354 个 PCI Device ID（含首批 10 个 Rubin ID、sm_107 确认、RTX PRO 5500 / RTX Spark N1X / RTX 5070 SUPER）。"
image: "/assets/covers/nvidia-pci-ids.svg"
category: "资料与随笔"
tags: ["NVIDIA", "PCIe", "Rubin", "Blackwell", "速查表"]
pinned: true
draft: false
---

> [!TIP]
> 本文已于 **2026-11-20** 依据最新上游数据全量同步（`pci.ids v2026.11.19`、`NVIDIA/open-gpu-kernel-modules 620.73.04`、Linux 主线 `nvgrace-gpu` / `nova-core`、CUDA 13.4/13.5 官方文档）。如需使用原版 1520px 宽表 + 实时搜索框页面，也可访问 [原版 HTML 速查页](/legacy-posts/nvidia-gpu-pci-device-ids.html)。

把 `lspci` 里那串 `10de:xxxx` 翻译成「到底是哪颗芯片、哪代架构、哪个产品」。本文整理了从 Ampere 到 Rubin 共 **354 个** NVIDIA GPU PCI device ID，交叉核对 `pci.ids`、`NVIDIA/open-gpu-kernel-modules` README 与内核源码、Linux 主线驱动（`nvgrace-gpu` / `nova-core` / `nouveau`）及 CUDA 13.5 官方文档，逐条标注芯片、SM / Compute Capability、功能、官方与社区产品名，以及是否在开放驱动列表内。

📊 **原始数据下载**：[下载最新完整表格（.xlsx · 9 个工作表 · 354 个 device ID · 59 KB）](/assets/files/nvidia-gpu-pci-ids-ampere-to-rubin.xlsx)

> [!NOTE]
> **2026-11-20 重点更新（对比 06-24 首版 332 项 → 现 354 项，+22 新增 / 4 条转正更新）**
> - **Rubin 架构正式落地（2 → 10 项）**：CUDA 13.4/13.5 官方文档已确认 **Vera Rubin 的 Compute Capability 为 `sm_107`（CC 10.7，非此前猜测的 `sm_13x`）**；**`10DE:3041`（`GR100 [VR NVL72]`，子系统 `10DE:221A`）** 已正式进入 `NVIDIA/open-gpu-kernel-modules 620.73.04`，源码树 `arch/rubin/` 已落地 `kern_gpu_gr100.c` 与 `kern_gpu_gr102.c`；`pci.ids` 新增 `3021`（`GR100 [PCIe Faber]`）等 8 个 Rubin ID。
> - **Blackwell 阵营扩充（84 → 96 项）**：新增 **RTX PRO 5500 Blackwell（`2BBD`，84 GB ECC，开放驱动 ✓）**、GB203 版 **RTX 5070（`2C09` ✓）**、首个 **RTX 5070 SUPER（`2F02`，GB205）**、**RTX Spark N1X** 全系（`2E03` 从 `JMJWOA-Generic-GPU` 正式转正，新增 `2E06` 5120-core / `2E13` 6144-core ✓）、**GB300-252（`31C3` 252 GB HBM3e ✓）**、Thor `3400`（`GB10B [Tegra RP iGPU]`）以及 `2C2C` / `2D2C`（GN22 工程样片）。
> - **Ada 补全（67 → 69 项）**：`pci.ids` 补入未发售的 `2682`（AD102 RTX 4090 Ti）与 `2687`（AD102 RTX 4080 变体）。
> - **Linux 主线 & PCI-SIG 交叉印证**：补充了 Linux 主线 `drivers/vfio/pci/nvgrace-gpu/main.c`（5 个 Grace 一致性显存 VFIO ID 与 PCI-SIG CXL DVSEC 探测路径）及 Rust 新驱动 `drivers/gpu/nova-core/gpu.rs` 的芯片枚举现状。

## 一、为什么需要这张表

`lspci -nn` 只会告诉你 `10de:3041` 或 `10de:2901` 这种 `vendor:device` 组合——`10de` 是 NVIDIA，后面四位才是具体设备。但要从这四位 hex 反推「这是哪颗 die、属于哪代架构、对应哪款上市产品」，并不直观：同一颗 die 会派生出一堆 device ID（裸卡、HGX 模组、中国特供 SKU、CSP 内部变体、保留/未发布 ID），而且同一段 ID 空间里还混着 **板载 HD Audio、NVSwitch、Bridge/Root** 等非 GPU 功能。这张表把这些全部摊开、逐条对应。

数据来自 **`pci.ids`（v2026.11.19）** 与 **`NVIDIA/open-gpu-kernel-modules`（R620 / 620.73.04）** 两个上游一手源合并，再用 Linux 主线内核（`nvgrace-gpu` / `nova-core` / `nouveau`）、CUDA 13.5 官方文档与社区数据库交叉核对（详见文末「数据来源与方法」）。总量分布：

- **Ampere**：150 个（`sm_80` / `86` / `87`）
- **Ada Lovelace**：69 个（`sm_89`）
- **Hopper**：29 个（`sm_90`）
- **Blackwell**：96 个（`sm_100` / `103` / `110` / `120` / `121`）
- **Rubin**：10 个（`GR100` / `GR102`，官方 **`sm_107` / CC 10.7**）

## 二、怎么读这张表

每代一张表，列含义如下：

- **ID**：device ID 的低四位 hex（完整写法是 `10DE:<ID>`）。
- **芯片 / SM**：物理 die 代号（如 `GB202`、`GR100`）与其 SM 架构等级；SM 与 Compute Capability 一一对应，速查见下表。
- **功能**：绝大多数是 `GPU`；**加粗**的是同一 ID 空间里的非 GPU 功能（HD Audio / NVSwitch / Bridge-Root）。
- **pci.ids 名称**：来自 `pci.ids` 的完整名（含方括号变体），**恒有值**，是最稳的描述字段。
- **产品名（官方 / 社区）**：优先取 NVIDIA 开放内核模块 README 里的权威营销名；该列没有时退而取社区/第三方数据库的名字并标注 `(社区)`（置信度低于官方）；都没有则为 `—`。
- **说明 / 推断**：用于保留 / 内部 / 中国 SKU / Rubin 条目与 Linux 主线驱动注解；`[ES 工程样品]` 表示工程样片 ID。
- **开放驱动**：`✓` = 在 NVIDIA 开放内核模块（`620.73.04`）的设备列表里；`—` = 只在 `pci.ids`、不在开放驱动列表（多为中国特供 SKU、数据中心内部变体、保留或未发售 ID）。

### 架构 × SM / Compute Capability 速查

| 架构 | 芯片 | SM | Compute Capability | 代表产品 | 备注 |
| --- | --- | --- | --- | --- | --- |
| Ampere | GA100 | sm_80 | 8.0 | A100, A30, A100X, A30X, CMP 170HX | HBM2e datacenter; FP64 |
| Ampere | GA102/103/104/106/107 | sm_86 | 8.6 | RTX 30 series, RTX A-series, A40/A10/A16 | 2x FP32/SM vs sm_80 |
| Ampere | GA10B (Orin) | sm_87 | 8.7 | Jetson AGX Orin, DRIVE Orin | Tegra/automotive iGPU only |
| Ada Lovelace | AD102/103/104/106/107 | sm_89 | 8.9 | RTX 40 series, RTX 6000 Ada, L40/L40S/L4/L20 | FP8 Transformer Engine |
| Hopper | GH100 | sm_90 | 9.0 | H100, H200, H800, H20, H20-3e, GH200 | WGMMA, TMA; sm_90a for CUTLASS |
| Blackwell (DC) | GB100 / GB102 | sm_100 | 10.0 | B100, B200, GB200 NVL72 | TMEM, tcgen05, 2-SM MMA; sm_100a/100f |
| Blackwell Ultra (DC) | GB110 / GB112 / GB120 | sm_103 | 10.3 | B300, GB300 NVL72, GB300-252 | sm_103a/103f; same 10.x family as sm_100 |
| Blackwell (Thor) | Thor T5000 (GB10B) | sm_110 | 11.0 | Jetson AGX Thor, DRIVE Thor | Renamed from sm_101 in CUDA 13.0; robotics SoC |
| Blackwell (consumer) | GB202/203/205/206/207 | sm_120 | 12.0 | RTX 50 / 50 SUPER, RTX PRO 6000 / 5500 / 5000 | mma.sync (Ampere-style), NOT tcgen05; FP4/FP6 |
| Blackwell (Spark) | GB10 / GB20B | sm_121 | 12.1 | DGX Spark, GB10, RTX Spark N1X (5120/6144-core) | sm_121a; ISA distinct from datacenter sm_100 |
| Rubin (DC) | GR100 / GR102 | sm_107 | 10.7 | VR NVL72 (3041), GR100 PCIe Faber (3021), R100/R200 | CUDA 13.4/13.5 GA (sm_107a/107f); 328 KB SMEM; HBM4, NVLink 6; open-gpu 620.x |

## 三、Ampere（150 个 ID · sm_80 / 86 / 87）

包含数据中心 **GA100**（sm_80，A100 / A30 / CMP 170HX）、消费与专业卡 **GA102–GA107**（sm_86，RTX 30 系 / RTX A 系 / A40 / A10 / A16）以及 **GA10B / Orin**（sm_87，Jetson AGX Orin / DRIVE Orin）；含 5 个 HD Audio、1 个 NVSwitch、2 个 Bridge/Root。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 推断 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1AF1 | GA100 | sm_80 | **NVSwitch** | GA100 [A100 NVSwitch] | — | On-board / on-system NVSwitch fabric switch (not a GPU die) | — |
| 2080 | GA100 | sm_80 | GPU | GA100 | — | GA100 (A100-class) internal/CSP variant — no public SKU mapping | — |
| 2081 | GA100 | sm_80 | GPU | GA100 | — | GA100 (A100-class) internal/CSP variant — no public SKU mapping | — |
| 2082 | GA100 | sm_80 | GPU | GA100 [CMP 170HX] | CMP 170HX (crypto-mining) (社区) |  | — |
| 20B0 | GA100 | sm_80 | GPU | GA100 [A100 SXM4 40GB] | NVIDIA A100-PG509-200 / NVIDIA A100-SXM4-40GB |  | ✓ |
| 20B1 | GA100 | sm_80 | GPU | GA100 [A100 PCIe 40GB] | — |  | — |
| 20B2 | GA100 | sm_80 | GPU | GA100 [A100 SXM4 80GB] | NVIDIA A100-SXM4-80GB / NVIDIA PG509-210 |  | ✓ |
| 20B3 | GA100 | sm_80 | GPU | GA100 [A100-SXM-64GB] | NVIDIA A100-SXM-64GB |  | ✓ |
| 20B4 | GA100 | sm_80 | GPU | GA100 | — | GA100 (A100-class) internal/CSP variant — no public SKU mapping | — |
| 20B5 | GA100 | sm_80 | GPU | GA100 [A100 PCIe 80GB] | NVIDIA A100 80GB PCIe |  | ✓ |
| 20B6 | GA100 | sm_80 | GPU | GA100GL [PG506-232] | NVIDIA PG506-232 |  | ✓ |
| 20B7 | GA100 | sm_80 | GPU | GA100GL [A30 PCIe] | NVIDIA A30 |  | ✓ |
| 20B8 | GA100 | sm_80 | GPU | GA100 [A100X] | A100X (converged w/ BlueField-3) (社区) |  | — |
| 20B9 | GA100 | sm_80 | GPU | GA100 [A30X] | A30X (converged w/ BlueField-3) (社区) |  | — |
| 20BB | GA100 | sm_80 | GPU | GA100 [DRIVE A100 PROD] | DRIVE A100 (automotive) (社区) |  | — |
| 20BD | GA100 | sm_80 | GPU | GA100 [A800 SXM4 40GB] | NVIDIA A800-SXM4-40GB |  | ✓ |
| 20BE | GA100 | sm_80 | GPU | GA100 [GRID A100A] | GRID A100A (vGPU) (社区) |  | — |
| 20BF | GA100 | sm_80 | GPU | GA100 [GRID A100B] | GRID A100B (vGPU) (社区) |  | — |
| 20C0 | GA100 | sm_80 | GPU | GA100 [Initial DevID] | — |  | — |
| 20C2 | GA100 | sm_80 | GPU | GA100 [CMP 170HX] | — |  | — |
| 20F0 | GA100 | sm_80 | GPU | GA100 [A100-PG506-207] | A100 (PG506-207 SKU) (社区) |  | — |
| 20F1 | GA100 | sm_80 | GPU | GA100 [A100 PCIe 40GB] | NVIDIA A100-PCIE-40GB |  | ✓ |
| 20F2 | GA100 | sm_80 | GPU | GA100 [A100-PG506-217] | A100 (PG506-217 SKU) (社区) |  | — |
| 20F3 | GA100 | sm_80 | GPU | GA100 [A800-SXM4-80GB] | NVIDIA A800-SXM4-80GB |  | ✓ |
| 20F5 | GA100 | sm_80 | GPU | GA100 [A800 80GB PCIe] | NVIDIA A800 80GB PCIe / NVIDIA A800 80GB PCIe LC |  | ✓ |
| 20F6 | GA100 | sm_80 | GPU | GA100 [A800 40GB PCIe] | NVIDIA A800 40GB Active |  | ✓ |
| 20FD | GA100 | sm_80 | GPU | GA100 [AX800 Converged Accelerator] | NVIDIA AX800 |  | ✓ |
| 20FE | GA100 | sm_80 | GPU | GA100 [INT SKU] | — |  | — |
| 20FF | GA100 | sm_80 | GPU | GA100 | — | GA100 (A100-class) internal/CSP variant — no public SKU mapping | — |
| 1AEF | GA102 | sm_86 | **HD Audio** | GA102 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 228B | GA104 | sm_86 | **HD Audio** | GA104 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 228E | GA106 | sm_86 | **HD Audio** | GA106 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 2291 | GA107 | sm_86 | **HD Audio** | GA107 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
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
| 2230 | GA102 | sm_86 | GPU | GA102GL [RTX A6000] | NVIDIA RTX A6000 |  | ✓ |
| 2231 | GA102 | sm_86 | GPU | GA102GL [RTX A5000] | NVIDIA RTX A5000 |  | ✓ |
| 2232 | GA102 | sm_86 | GPU | GA102GL [RTX A4500] | NVIDIA RTX A4500 |  | ✓ |
| 2233 | GA102 | sm_86 | GPU | GA102GL [RTX A5500] | NVIDIA RTX A5500 |  | ✓ |
| 2235 | GA102 | sm_86 | GPU | GA102GL [A40] | NVIDIA A40 |  | ✓ |
| 2236 | GA102 | sm_86 | GPU | GA102GL [A10] | NVIDIA A10 |  | ✓ |
| 2237 | GA102 | sm_86 | GPU | GA102GL [A10G] | NVIDIA A10G |  | ✓ |
| 2238 | GA102 | sm_86 | GPU | GA102GL [A10M] | NVIDIA A10M |  | ✓ |
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
| 249C | GA104 | sm_86 | GPU | GA104M [GeForce RTX 3080 Mobile / Max-Q 8GB/16GB] | NVIDIA GeForce RTX 3060 Laptop GPU / NVIDIA GeForce RTX 3080 Laptop GPU |  | ✓ |
| 249D | GA104 | sm_86 | GPU | GA104M [GeForce RTX 3070 Mobile / Max-Q] | NVIDIA GeForce RTX 3070 Laptop GPU |  | ✓ |
| 249F | GA104 | sm_86 | GPU | GA104M | — | Internal/engineering variant — no public marketing name | — |
| 24A0 | GA104 | sm_86 | GPU | GA104 [Geforce RTX 3070 Ti Laptop GPU] | NVIDIA GeForce RTX 3060 Laptop GPU / NVIDIA GeForce RTX 3070 Ti Laptop GPU |  | ✓ |
| 24A4 | GA104 | sm_86 | GPU | GA104M | — | Internal/engineering variant — no public marketing name | — |
| 24AC | GA104 | sm_86 | GPU | GA104 [GeForce RTX 30x0 Engineering Sample] | — | [ES 工程样品] | — |
| 24AD | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3060 Engineering Sample] | — | [ES 工程样品] | — |
| 24AF | GA104 | sm_86 | GPU | GA104 [GeForce RTX 3070 Engineering Sample] | — | [ES 工程样品] | — |
| 24B0 | GA104 | sm_86 | GPU | GA104GL [RTX A4000] | NVIDIA RTX A4000 |  | ✓ |
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
| 2531 | GA106 | sm_86 | GPU | GA106 [RTX A2000] | NVIDIA RTX A2000 |  | ✓ |
| 2544 | GA106 | sm_86 | GPU | GA106 [GeForce RTX 3060] | NVIDIA GeForce RTX 3060 |  | ✓ |
| 2560 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3060 Mobile / Max-Q] | NVIDIA GeForce RTX 3060 Laptop GPU |  | ✓ |
| 2561 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3060 Laptop GPU] | — |  | — |
| 2563 | GA106 | sm_86 | GPU | GA106M [GeForce RTX 3050 Ti Mobile / Max-Q] | NVIDIA GeForce RTX 3050 Ti Laptop GPU |  | ✓ |
| 2571 | GA106 | sm_86 | GPU | GA106 [RTX A2000 12GB] | NVIDIA RTX A2000 12GB |  | ✓ |
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
| 25B6 | GA107 | sm_86 | GPU | GA107GL [A2 / A16] | NVIDIA A16 / NVIDIA A2 |  | ✓ |
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
| 229A | GA10B(Orin) | sm_87 | **Bridge/Root** | Orin PCIe x8 Root Complex | — | PCIe bridge / root-port function on the GPU board or host SoC (not a standalone product) | — |
| 229C | GA10B(Orin) | sm_87 | **Bridge/Root** | Orin PCIe x4/x8 Endpoint/Root Complex | — | PCIe bridge / root-port function on the GPU board or host SoC (not a standalone product) | — |
| 229E | GA10B(Orin) | sm_87 | **Bridge/Root** | Orin PCIe x1 Root Complex | — | PCIe bridge / root-port function on the GPU board or host SoC (not a standalone product) | — |

## 四、Ada Lovelace（69 个 ID · sm_89）

**AD102–AD107**（统一 sm_89，首代 FP8 Transformer Engine）：RTX 40 系桌面与移动卡、RTX 6000/5000/4000 Ada 专业卡、以及数据中心 L40 / L40S / L4 / L20；含 5 个 HD Audio。本次同步从 `pci.ids` 补入 `2682`（未发售 AD102 RTX 4090 Ti）与 `2687`（AD102 RTX 4080 变体）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 推断 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 22BA | AD102 | sm_89 | **HD Audio** | AD102 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22BB | AD103 | sm_89 | **HD Audio** | AD103 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22BC | AD104 | sm_89 | **HD Audio** | AD104 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22BD | AD106 | sm_89 | **HD Audio** | AD106M High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22BE | AD107 | sm_89 | **HD Audio** | AD107 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 2681 | AD102 | sm_89 | GPU | AD102 [RTX TITAN Ada] | — |  | — |
| 2682 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4090 Ti] | GeForce RTX 4090 Ti (未发售 / 样片) (社区) | [ES 工程样品] Unreleased AD102 flagship SKU added to pci.ids (v2026.11.19) | — |
| 2684 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4090] | NVIDIA GeForce RTX 4090 |  | ✓ |
| 2685 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4090 D] | NVIDIA GeForce RTX 4090 D |  | ✓ |
| 2687 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4080] | GeForce RTX 4080 (AD102 变体) (社区) | AD102-based RTX 4080 variant recorded in pci.ids (v2026.11.19) | — |
| 2689 | AD102 | sm_89 | GPU | AD102 [GeForce RTX 4070 Ti SUPER] | NVIDIA GeForce RTX 4070 Ti SUPER |  | ✓ |
| 26AF | AD102 | sm_89 | GPU | AD102 [PG137] | — |  | — |
| 26B1 | AD102 | sm_89 | GPU | AD102GL [RTX 6000 Ada Generation] | NVIDIA RTX 6000 Ada Generation |  | ✓ |
| 26B2 | AD102 | sm_89 | GPU | AD102GL [RTX 5000 Ada Generation] | NVIDIA RTX 5000 Ada Generation |  | ✓ |
| 26B3 | AD102 | sm_89 | GPU | AD102GL [RTX 5880 Ada Generation] | NVIDIA RTX 5880 Ada Generation |  | ✓ |
| 26B5 | AD102 | sm_89 | GPU | AD102GL [L40] | NVIDIA L40 |  | ✓ |
| 26B7 | AD102 | sm_89 | GPU | AD102GL [L20] | — |  | — |
| 26B8 | AD102 | sm_89 | GPU | AD102GL [L40G] | — |  | — |
| 26B9 | AD102 | sm_89 | GPU | AD102GL [L40S] | NVIDIA L40S |  | ✓ |
| 26BA | AD102 | sm_89 | GPU | AD102GL [L20] | NVIDIA L20 |  | ✓ |
| 26BB | AD102 | sm_89 | GPU | AD102GL [L30] | — |  | — |
| 26F5 | AD102 | sm_89 | GPU | AD102GL [L40 CNX] | — |  | — |
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
| 27B6 | AD104 | sm_89 | GPU | AD104GL [L2] | NVIDIA L2 |  | ✓ |
| 27B7 | AD104 | sm_89 | GPU | AD104GL [L16] | — |  | — |
| 27B8 | AD104 | sm_89 | GPU | AD104GL [L4] | NVIDIA L4 |  | ✓ |
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
| 28B0 | AD107 | sm_89 | GPU | AD107GL [RTX 2000 / 2000E Ada Generation] | NVIDIA RTX 2000 Ada Generation / NVIDIA RTX 2000E Ada Generation |  | ✓ |
| 28B8 | AD107 | sm_89 | GPU | AD107GLM [RTX 2000 Ada Generation Laptop GPU] | NVIDIA RTX 2000 Ada Generation Laptop GPU |  | ✓ |
| 28B9 | AD107 | sm_89 | GPU | AD107GLM [RTX 1000 Ada Generation Laptop GPU] | NVIDIA RTX 1000 Ada Generation Laptop GPU |  | ✓ |
| 28BA | AD107 | sm_89 | GPU | AD107GLM [RTX 500 Ada Generation Laptop GPU] | NVIDIA RTX 500 Ada Generation Laptop GPU |  | ✓ |
| 28BB | AD107 | sm_89 | GPU | AD107GLM [RTX 500 Ada Generation Laptop GPU] | NVIDIA RTX 500 Ada Generation Laptop GPU |  | ✓ |
| 28E0 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 4060 Max-Q / Mobile] | NVIDIA GeForce RTX 4060 Laptop GPU |  | ✓ |
| 28E1 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 4050 Max-Q / Mobile] | NVIDIA GeForce RTX 4050 Laptop GPU |  | ✓ |
| 28E3 | AD107 | sm_89 | GPU | AD107M [GeForce RTX 3050 A Laptop GPU] | NVIDIA GeForce RTX 3050 A Laptop GPU |  | ✓ |
| 28F8 | AD107 | sm_89 | GPU | AD107GLM [RTX 2000 Ada Generation Embedded GPU] | NVIDIA RTX 2000 Ada Generation Embedded GPU |  | ✓ |

## 五、Hopper（29 个 ID · sm_90）

**GH100** 单芯片（sm_90，含 CUTLASS 用的 `sm_90a` 变体）：H100 / H200 / GH200，以及中国特供的 H800 / H20 / H20-3e / H20 NVL16；含 1 个 NVSwitch。其中 `2342`、`2345`、`2348` 三个 GH200 ID 同时位于 Linux 主线 `drivers/vfio/pci/nvgrace-gpu/main.c` VFIO 驱动白名单中。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 推断 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 22A3 | GH100 | sm_90 | **NVSwitch** | GH100 [H100 NVSwitch] | — | On-board / on-system NVSwitch fabric switch (not a GPU die) | — |
| 2302 | GH100 | sm_90 | GPU | GH100 | — | GH100 internal/CSP variant — no public SKU mapping | — |
| 230C | GH100 | sm_90 | GPU | GH100 [H20 NVL16] | H20 NVL16 (China SKU) (社区) |  | — |
| 230E | GH100 | sm_90 | GPU | GH100 [H20 NVL16] | NVIDIA H20 NVL16 |  | ✓ |
| 2313 | GH100 | sm_90 | GPU | GH100 [H100 CNX] | H100 CNX (Converged Accelerator) (社区) |  | — |
| 2321 | GH100 | sm_90 | GPU | GH100 [H100L 94GB] | NVIDIA H100 NVL |  | ✓ |
| 2322 | GH100 | sm_90 | GPU | GH100 [H800 PCIe] | NVIDIA H800 PCIe |  | ✓ |
| 2324 | GH100 | sm_90 | GPU | GH100 [H800] | NVIDIA H800 |  | ✓ |
| 2328 | GH100 | sm_90 | GPU | GH100 [H20B] | H20B (China SKU) (社区) |  | — |
| 2329 | GH100 | sm_90 | GPU | GH100 [H20] | NVIDIA H20 |  | ✓ |
| 232C | GH100 | sm_90 | GPU | GH100 [H20 HBM3e] | NVIDIA H20-3e |  | ✓ |
| 2330 | GH100 | sm_90 | GPU | GH100 [H100 SXM5 80GB] | NVIDIA H100 80GB HBM3 |  | ✓ |
| 2331 | GH100 | sm_90 | GPU | GH100 [H100 PCIe] | NVIDIA H100 PCIe |  | ✓ |
| 2335 | GH100 | sm_90 | GPU | GH100 [H200 SXM 141GB] | NVIDIA H200 |  | ✓ |
| 2336 | GH100 | sm_90 | GPU | GH100 [H100] | H100 (PCIe variant, TPU-listed) (社区) |  | — |
| 2337 | GH100 | sm_90 | GPU | GH100 [H100 SXM5 64GB] | H100 SXM5 64GB (TPU-listed) (社区) |  | — |
| 2338 | GH100 | sm_90 | GPU | GH100 [H100 SXM5 96GB] | H100 SXM5 96GB (TPU-listed) (社区) |  | — |
| 2339 | GH100 | sm_90 | GPU | GH100 [H100 SXM5 94GB] | NVIDIA H100 |  | ✓ |
| 233A | GH100 | sm_90 | GPU | GH100 [H800L 94GB] | NVIDIA H800 NVL |  | ✓ |
| 233B | GH100 | sm_90 | GPU | GH100 [H200 NVL] | NVIDIA H200 NVL |  | ✓ |
| 233D | GH100 | sm_90 | GPU | GH100 [H100 96GB] | H100 96GB (TPU-listed) (社区) |  | — |
| 2342 | GH100 | sm_90 | GPU | GH100 [GH200 120GB / 480GB] | NVIDIA GH200 120GB / NVIDIA GH200 480GB | In Linux mainline nvgrace-gpu VFIO PCI table (0x2342) | ✓ |
| 2343 | GH100 | sm_90 | GPU | GH100 | — | GH100 internal/CSP variant — no public SKU mapping | — |
| 2345 | GH100 | sm_90 | GPU | GH100 [GH100-88K-A1] | — | In Linux mainline nvgrace-gpu VFIO PCI table (0x2345) | — |
| 2348 | GH100 | sm_90 | GPU | GH100 [GH200 144G HBM3e] | NVIDIA GH200 144G HBM3e | In Linux mainline nvgrace-gpu VFIO PCI table (0x2348) | ✓ |
| 237E | GH100 | sm_90 | GPU | GH100 [H100 GH3] | — |  | — |
| 237F | GH100 | sm_90 | GPU | GH100 [Skinny Joe] | — |  | — |
| 23B0 | GH100 | sm_90 | GPU | GH100 | — | GH100 internal/CSP variant — no public SKU mapping | — |
| 23F0 | GH100 | sm_90 | GPU | GH100 | — | GH100 internal/CSP variant — no public SKU mapping | — |

## 六、Blackwell（96 个 ID · sm_100 / 103 / 110 / 120 / 121）

一个代号、五个 SM——这是 Blackwell 最容易混的地方：

- **数据中心 GB100 / GB102**（`sm_100`，B100 / B200 / GB200 NVL72；`2941` 在 Linux `nvgrace-gpu` 白名单内）
- **Blackwell Ultra GB110 / 112 / 120**（`sm_103`，B300 / GB300 NVL72 / `GB300-252` 252 GB HBM3e；`31C2` 在 Linux `nvgrace-gpu` 白名单内）
- **Thor 机器人 SoC**（`sm_110`，CUDA 13.0 起由 `sm_101` 正式改名，新增 `3400` `GB10B [Tegra RP iGPU]`）
- **消费 / 工作站 GB202–GB207**（`sm_120`，RTX 50 / RTX 5070 SUPER `2F02` / RTX PRO 6000 & 5500 `2BBD`；注意走 Ampere 式 `mma.sync` 而非 `tcgen05`）
- **DGX Spark / N1X（GB10 / GB20B）**（`sm_121`，新增与转正 `2E03` / `2E06` / `2E13` 三款 **RTX Spark N1X** 开放驱动 ID；另 `open-gpu-kernel-modules` 已出现 `arch/blackwell/kern_gpu_gb20c.c`）

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 推断 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2900 | GB100 | sm_100 | GPU | GB100 [Reserved Dev ID A] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 2901 | GB100 | sm_100 | GPU | GB100 [B200] | NVIDIA B200 |  | ✓ |
| 2909 | GB100 | sm_100 | GPU | GB100 [HGX B200 168GB] | NVIDIA B200 |  | ✓ |
| 290A | GB100 | sm_100 | GPU | GB100 [B200] | B200 (GB100 variant) (社区) | Datacenter Blackwell B200 variant added to pci.ids (v2026.11.19) | — |
| 2920 | GB100 | sm_100 | GPU | GB100 [TS4 / B100] | B100 (TS4 sample) (社区) |  | — |
| 2924 | GB100 | sm_100 | GPU | GB100 | — | Datacenter Blackwell internal/sample variant — no public SKU | — |
| 2925 | GB100 | sm_100 | GPU | GB100 | — | Datacenter Blackwell internal/sample variant — no public SKU | — |
| 293D | GB100 | sm_100 | GPU | GB100 | — | Datacenter Blackwell internal/sample variant — no public SKU | — |
| 2940 | GB100 | sm_100 | GPU | GB100 [Reserved Dev ID B] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 2941 | GB100 | sm_100 | GPU | GB100 [HGX GB200] | NVIDIA GB200 | In Linux mainline nvgrace-gpu VFIO PCI table (0x2941) | ✓ |
| 297E | GB100 | sm_100 | GPU | GB100 | — | Datacenter Blackwell internal/sample variant — no public SKU | — |
| 2980 | GB102 | sm_100 | GPU | GB102 [Reserved Dev ID A] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 29BB | GB102 | sm_100 | GPU | GB102 [DRIVE P2021] | NVIDIA DRIVE P2021 |  | ✓ |
| 29BC | GB102 | sm_100 | GPU | GB102 [B100] | B100 (GB102 variant) (社区) |  | — |
| 29C0 | GB102 | sm_100 | GPU | GB102 [Reserved Dev ID B] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 29F1 | GB102 | sm_100 | GPU | GB102 | — | Datacenter Blackwell internal/sample variant — no public SKU | — |
| 3180 | GB110 | sm_103 | GPU | GB110 [Reserved Dev ID A] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 3182 | GB110 | sm_103 | GPU | GB110 [B300 SXM6 AC] | NVIDIA B300 SXM6 AC |  | ✓ |
| 3183 | GB110 | sm_103 | GPU | GB110 | — | Blackwell-Ultra (B300/GB300 class) internal/sample variant — no public SKU | — |
| 3184 | GB110 | sm_103 | GPU | GB110 | — | Blackwell-Ultra (B300/GB300 class) internal/sample variant — no public SKU | — |
| 31A1 | GB110 | sm_103 | GPU | GB110 [GB300 MaxQ] | GB300 Max-Q (社区) |  | — |
| 31C0 | GB110 | sm_103 | GPU | GB110 [Reserved Dev ID B] | — | Reserved/internal dev ID — not publicly mapped to a shipping product | — |
| 31C2 | GB110 | sm_103 | GPU | GB110 [GB300] | NVIDIA GB300 | In Linux mainline nvgrace-gpu VFIO PCI table (0x31C2) | ✓ |
| 31C3 | GB110 | sm_103 | GPU | GB110 [GB300-252] | NVIDIA GB300 / NVIDIA GB300-252 | Includes 252 GB HBM3e variant (subsys 10DE:23AB, DGX Station GB300 class) | ✓ |
| 31FE | GB110 | sm_103 | GPU | GB110 | — | Blackwell-Ultra (B300/GB300 class) internal/sample variant — no public SKU | — |
| 3200 | GB112 | sm_103 | GPU | GB112 | — | Blackwell-Ultra (B300/GB300 class) internal/sample variant — no public SKU | — |
| 3224 | GB112 | sm_103 | GPU | GB112 | — | Blackwell-Ultra (B300/GB300 class) internal/sample variant — no public SKU | — |
| 323E | GB112 | sm_103 | GPU | GB112 | — | Blackwell-Ultra (B300/GB300 class) internal/sample variant — no public SKU | — |
| 3340 | GB120 | sm_103 | GPU | GB120 | — | Blackwell-Ultra (B300/GB300 class) internal/sample variant — no public SKU | — |
| 22D8 | THOR | sm_110 | **Bridge/Root** | THOR Processor PCI Express Root Port | — | PCIe bridge / root-port function on the GPU board or host SoC (not a standalone product) | — |
| 22E6 | THOR | sm_110 | **Bridge/Root** | THOR Processor PCI Express x16 Controller | — | PCIe bridge / root-port function on the GPU board or host SoC (not a standalone product) | — |
| 2B00 | THOR | sm_110 | GPU | GB10B [Jetson AGX Thor] | — |  | — |
| 3400 | THOR | sm_110 | GPU | GB10B [Tegra RP iGPU] | Tegra RP iGPU (GB10B) (社区) | GB10B / Tegra Root-Port iGPU entry in pci.ids (v2026.11.19) | — |
| 22E8 | GB202 | sm_120 | **HD Audio** | GB202 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22E9 | GB203 | sm_120 | **HD Audio** | GB203 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22EB | GB206 | sm_120 | **HD Audio** | GB206 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 22EC | GB207 | sm_120 | **HD Audio** | GB207 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 2F80 | GB205 | sm_120 | **HD Audio** | GB205 High Definition Audio Controller | — | On-board HD Audio function of the GPU board (not a standalone product) | — |
| 2B85 | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090] | NVIDIA GeForce RTX 5090 |  | ✓ |
| 2B87 | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090 D] | NVIDIA GeForce RTX 5090 D |  | ✓ |
| 2B8C | GB202 | sm_120 | GPU | GB202 [GeForce RTX 5090 D V2] | NVIDIA GeForce RTX 5090 D v2 |  | ✓ |
| 2BB1 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Workstation Edition] | NVIDIA RTX PRO 6000 Blackwell Workstation Edition |  | ✓ |
| 2BB2 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000D Blackwell Workstation Edition] | — |  | — |
| 2BB3 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 5000 Blackwell / RTX PRO 5000 72GB Blackwell] | NVIDIA RTX PRO 5000 72GB Blackwell / NVIDIA RTX PRO 5000 Blackwell |  | ✓ |
| 2BB4 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Max-Q Workstation Edition] | NVIDIA RTX PRO 6000 Blackwell Max-Q Workstation Edition |  | ✓ |
| 2BB5 | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000 Blackwell Server Edition] | NVIDIA RTX PRO 6000 Blackwell Server Edition |  | ✓ |
| 2BB9 | GB202 | sm_120 | GPU | GB202GL [RTX 6000D] | NVIDIA RTX 6000D |  | ✓ |
| 2BBC | GB202 | sm_120 | GPU | GB202GL [RTX PRO 6000D Blackwell Max-Q Workstation Edition] | — |  | — |
| 2BBD | GB202 | sm_120 | GPU | GB202GL [RTX PRO 5500 Blackwell Workstation Edition] | NVIDIA RTX PRO 5500 Blackwell Workstation Edition | 84 GB GDDR7 ECC workstation GPU; added in open-gpu-kernel-modules 620.x | ✓ |
| 2C02 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5080] | NVIDIA GeForce RTX 5080 |  | ✓ |
| 2C05 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5070 Ti] | NVIDIA GeForce RTX 5070 Ti |  | ✓ |
| 2C09 | GB203 | sm_120 | GPU | GB203 [GeForce RTX 5070] | NVIDIA GeForce RTX 5070 | GB203-based RTX 5070 SKU alongside GB205 (2F04); in open-gpu README | ✓ |
| 2C18 | GB203 | sm_120 | GPU | GB203M / GN22 [GeForce RTX 5090 Max-Q / Mobile] | NVIDIA GeForce RTX 5090 Laptop GPU |  | ✓ |
| 2C19 | GB203 | sm_120 | GPU | GB203M / GN22 [GeForce RTX 5080 Max-Q / Mobile] | NVIDIA GeForce RTX 5080 Laptop GPU |  | ✓ |
| 2C2C | GB203 | sm_120 | GPU | GB6-256(N22W-ES-A1) | GN22 Mobile/Workstation 256-bit ES-A1 (社区) | [ES 工程样品] GB203 range (2Cxx) engineering sample — N22W-ES-A1 | — |
| 2C31 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4500 Blackwell] | NVIDIA RTX PRO 4500 Blackwell |  | ✓ |
| 2C33 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4000 Blackwell SFF Edition] | NVIDIA RTX PRO 4000 Blackwell SFF Edition |  | ✓ |
| 2C34 | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4000 Blackwell] | NVIDIA RTX PRO 4000 Blackwell |  | ✓ |
| 2C38 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 5000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 5000 Blackwell Generation Laptop GPU |  | ✓ |
| 2C39 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 4000 Blackwell Generation Laptop GPU] | NVIDIA RTX PRO 4000 Blackwell Generation Laptop GPU |  | ✓ |
| 2C3A | GB203 | sm_120 | GPU | GB203GL [RTX PRO 4500 Blackwell Server Edition] | NVIDIA RTX PRO 4500 Blackwell Server Edition |  | ✓ |
| 2C58 | GB203 | sm_120 | GPU | GB203M / GN22-X11 [GeForce RTX 5090 Max-Q / Mobile] | NVIDIA GeForce RTX 5090 Laptop GPU |  | ✓ |
| 2C59 | GB203 | sm_120 | GPU | GB203M / GN22-X9 [GeForce RTX 5080 Max-Q / Mobile] | NVIDIA GeForce RTX 5080 Laptop GPU |  | ✓ |
| 2C77 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 5000 Blackwell Embedded GPU] | NVIDIA RTX PRO 5000 Blackwell Embedded GPU |  | ✓ |
| 2C79 | GB203 | sm_120 | GPU | GB203GLM [RTX PRO 4000 Blackwell Embedded GPU] | NVIDIA RTX PRO 4000 Blackwell Embedded GPU |  | ✓ |
| 2D04 | GB206 | sm_120 | GPU | GB206 [GeForce RTX 5060 Ti] | NVIDIA GeForce RTX 5060 Ti |  | ✓ |
| 2D05 | GB206 | sm_120 | GPU | GB206 [GeForce RTX 5060] | NVIDIA GeForce RTX 5060 |  | ✓ |
| 2D18 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5070 Max-Q / Mobile] | NVIDIA GeForce RTX 5070 Laptop GPU |  | ✓ |
| 2D19 | GB206 | sm_120 | GPU | GB206M [GeForce RTX 5060 Max-Q / Mobile] | NVIDIA GeForce RTX 5060 Laptop GPU |  | ✓ |
| 2D2C | GB206 | sm_120 | GPU | GB6-128 (N22Y-ES-A1) | GN22 Mobile/Workstation 128-bit ES-A1 (社区) | [ES 工程样品] GB206 range (2Dxx) engineering sample — N22Y-ES-A1 | — |
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
| 22CE | GB10 | sm_121 | **Bridge/Root** | GB10 GEN5 X4 PCIe host | — | PCIe bridge / root-port function on the GPU board or host SoC (not a standalone product) | — |
| 22D0 | GB10 | sm_121 | **Bridge/Root** | GB10 GEN4 X1 PCIe host | — | PCIe bridge / root-port function on the GPU board or host SoC (not a standalone product) | — |
| 22D1 | GB20 | sm_121 | **Bridge/Root** | GB20B PCI bridge | — | PCIe bridge / root-port function on the GPU board or host SoC (not a standalone product) | — |
| 2E02 | GB20B | sm_121 | GPU | GB20B [JMJWOA-Generic-GPU] | — | GB20B / Spark N1X family internal/generic pre-prod ID | — |
| 2E03 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (6144-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (6144-core Blackwell RTX GPU) | Graduated from JMJWOA-Generic-GPU into open-gpu-kernel-modules | ✓ |
| 2E06 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (5120-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (5120-core Blackwell RTX GPU) | Client Arm+Blackwell SoC (5120 CUDA cores); in open-gpu-kernel-modules | ✓ |
| 2E12 | GB10 | sm_121 | GPU | GB20B [GB10] | NVIDIA GB10 |  | ✓ |
| 2E13 | GB20B | sm_121 | GPU | GB20B [RTX Spark N1X (6144-core Blackwell RTX GPU)] | NVIDIA RTX Spark N1X (6144-core Blackwell RTX GPU) | Client Arm+Blackwell SoC (6144 CUDA cores); in open-gpu-kernel-modules | ✓ |
| 2E2A | GB20 | sm_121 | GPU | GB20B [JMJWOA-Generic-GPU] | — |  | — |

## 七、Rubin（10 个 ID · sm_107 / CC 10.7）

截至 **2026-11-20**，Rubin 已从半年前的 2 个占位 ID 扩充至 **10 个** PCI Device ID，且三件关键事实已经落锤：

1. **官方 Compute Capability 为 `sm_107`（CC 10.7）**：CUDA 13.4 预览、**CUDA 13.5 GA** 官方文档与 MathDx / Tile IR 均已确认 Vera Rubin 对应 `sm_107`（含 `sm_107a` / `sm_107f`），每 SM 共享内存上限放宽至 328 KB、引入 TMA 细粒度同步与增强型 `tcgen05.mma` 仿真 FP64，且 Windows 端起正式放弃传统 TCC 模式。
2. **首款量产 SKU 已进入开放内核驱动**：`10DE:3041`（`GR100 [VR NVL72]`，子系统 `10DE:221A`）已正式出现在 `NVIDIA/open-gpu-kernel-modules` **620.73.04**（2026-11-18）支持列表中；驱动源码 `src/nvidia/src/kernel/gpu/arch/rubin/` 已落地 `kern_gpu_gr100.c` 与 `kern_gpu_gr102.c`。
3. **PCIe 形态代号浮现**：`pci.ids v2026.11.19` 新增 `10DE:3021`（`GR100 [PCIe Faber]`），同时明确了 `3000/3040`（GR100 Reserved A/B）与 `3080/30C0`（GR102 Reserved A/B）。

| ID | 芯片 | SM | 功能 | pci.ids 名称 | 产品名（官方 / 社区） | 说明 / 推断 | 开放驱动 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3000 | GR100 | sm_107 | GPU | GR100 [Reserved Dev ID A] | — | Reserved/internal Rubin GR100 dev ID A (open-gpu arch/rubin/kern_gpu_gr100.c) | — |
| 3002 | GR100 | sm_107 | GPU | GR100 | — | Rubin GR100 internal/sample variant — no public SKU mapping | — |
| 3021 | GR100 | sm_107 | GPU | GR100 [PCIe Faber] | GR100 PCIe (Faber) (社区) | Rubin GR100 PCIe form-factor / platform codename 'Faber' in pci.ids | — |
| 3040 | GR100 | sm_107 | GPU | GR100 [Reserved Dev ID B] | — | Reserved/internal Rubin GR100 dev ID B (updated from bare GR100) | — |
| 3041 | GR100 | sm_107 | GPU | GR100 [VR NVL72] | NVIDIA VR NVL72 | Vera Rubin NVL72 (subsys 10DE:221A); first shipping Rubin SKU in open-gpu 620.x | ✓ |
| 307E | GR100 | sm_107 | GPU | GR100 | — | Rubin GR100 internal/sample variant — no public SKU mapping | — |
| 307F | GR100 | sm_107 | GPU | GR100 | — | Rubin GR100 internal/sample variant — no public SKU mapping | — |
| 3080 | GR102 | sm_107 | GPU | GR102 [Reserved Dev ID A] | — | Reserved/internal Rubin GR102 dev ID A (open-gpu arch/rubin/kern_gpu_gr102.c) | — |
| 30C0 | GR102 | sm_107 | GPU | GR102 [Reserved Dev ID B] | — | Reserved/internal Rubin GR102 dev ID B — GR100 package = 2x GR102 dies | — |
| 30FF | GR102 | sm_107 | GPU | GR102 | — | Rubin GR102 internal/sample variant — no public SKU mapping | — |

### Rubin 架构与路线图速览（2026-11）

| 代号 / 维度 | 定位与最新状态（2026-11） |
| --- | --- |
| GR100 (7 IDs) | Rubin 数据中心旗舰双芯封装（`3041` = **NVIDIA VR NVL72** 已入开放驱动 620.x；`3021` = **PCIe Faber**；`3000/3040` = Reserved A/B） |
| GR102 (3 IDs) | Rubin 基础硅片（GR100 封装由 2× GR102 组成；`3080/30C0` = Reserved A/B，见 `arch/rubin/kern_gpu_gr102.c`） |
| GR150 | 后续量产数据中心 die（CoWoP, SXM8），约 2027 |
| GR20x / GR21x | 客户端消费级 Rubin（GR20x）与 Rubin CPX 长上下文 prefill 加速器（GR21x），PCI ID 尚未公开 |
| VR200 / VR NVL72 | Vera CPU + Rubin GPU 机架级整机（72 GPU 封装），PCI-SIG CXL DVSEC 显存就绪探测 + NVLink-C2C |
| Compute Capability | **`sm_107`（CC 10.7，含 `sm_107a` / `sm_107f`）** —— CUDA 13.4 预览、**CUDA 13.5 GA**；每 SM 共享内存上限扩至 328 KB、TMA 细粒度同步、`tcgen05.mma` 仿真 FP64，Windows 端不再支持传统 TCC 模式 |
| 显存 / 互联 | 288 GB HBM4，13–22 TB/s 每 GPU；NVLink 6（3.6 TB/s） |

## 八、Linux 主线驱动、PCI-SIG 与周边 ID 补充

除上述 GPU 列表外，2026 年下半年上游 Linux 内核与 PCI-SIG 侧有几条直接影响硬件识别与虚拟化的关键动向：

- **Linux `nvgrace-gpu` 与 PCI-SIG CXL DVSEC**：主线 `drivers/vfio/pci/nvgrace-gpu/main.c` 明确收录 5 个一致性内存 VFIO 设备 ID（`2342`、`2345`、`2348`、`2941`、`31C2`），并通过 **PCI-SIG CXL DVSEC**（`pci_find_dvsec_capability(pdev, PCI_VENDOR_ID_CXL, ...)`）探测 Blackwell-Next / Rubin 显存就绪状态（物理传输层仍是 NVLink-C2C，接口走向 CXL 标准化，详见本站 [Blackwell-Next CXL DVSEC 考据](/posts/blackwell-next-cxl-dvsec/)）。
- **Linux Rust 新驱动 `nova-core`**：主线 `drivers/gpu/nova-core/gpu.rs` 已定义 `GA100–GA107`、`GH100`、`AD102–AD107`、`GB100/102` 与 `GB202–GB207` 芯片枚举；源码注释还特别留下一条关于 Rubin 硬件 ID 空间的线索——*`Somewhere in the Rubin timeframe, boot0 will no longer have space to add new GPU IDs.`*
- **同期出现但未计入 354 项主表的周边 ID**：`pci.ids v2026.11.19` 同期新增了 `2F88`（`T256`）、`2F95–2F99`（`TB500 RP x16 / x8 / x4 / x2 / x1`）以及 `200A`（`NPU`）、`2296`（`Tegra PCIe Endpoint Virtual Network`），属于下一代 Tegra 平台根端口/非独立 GPU 功能，故未混入 Ampere → Rubin 主表统计。

## 九、数据来源与方法

这张表由上游一手源码自动比对合并，再用多源交叉核对：

1. **`pciutils/pciids` — `pci.ids`（v2026.11.19）**：全量 `10DE` 设备超集（共 1,997 条），提供全部新增的 Rubin（10 项）、RTX 5070 SUPER（`2F02`）、RTX PRO 5500（`2BBD`）、RTX Spark N1X 与 AD102 变体。
2. **`NVIDIA/open-gpu-kernel-modules`（620.73.04，2026-11-18）**：`README.md` 全部 843 条产品行（299 个唯一 Device ID，含子系统级）提供官方营销名；`src/nvidia/src/kernel/gpu/arch/` 核验 `rubin/kern_gpu_gr100.c`、`kern_gpu_gr102.c` 与 `blackwell/kern_gpu_gb20c.c`。
3. **Linux 主线内核（`torvalds/linux`）**：`drivers/vfio/pci/nvgrace-gpu/main.c`、`drivers/gpu/nova-core/gpu.rs` 与 `nouveau`（`nvkm`）交叉印证芯片代号、VFIO 白名单与 CXL DVSEC 探测。
4. **NVIDIA CUDA 13.4 / 13.5 官方文档**：确认 Rubin Compute Capability 为 `sm_107`（CC 10.7）及 Thor `sm_110`、Blackwell Ultra `sm_103`、Spark `sm_121`。
5. **TechPowerUp GPU DB / DeviceHunt / 厂商规格页**：补充未入开放驱动列表的数据中心/中国特供/样片 ID 社区名称。

> [!NOTE]
> **检索统计（2026-11-20）**：主表共 **354** 条（其中 GPU **330** 条，其余为 HD Audio / Bridge-Root / NVSwitch），开放驱动官方收录 **218** 条，`pci.ids` 含方括号名 **295** 条，社区补名 **26** 条。官方名取自 NVIDIA 开放内核模块 README（权威），`—` 表示不在开放驱动列表中。
