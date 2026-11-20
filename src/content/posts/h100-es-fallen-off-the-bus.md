---
title: "我与 H100 885 ES 的激情斗法"
published: 2026-07-06
description: "一块 GH100 ES（10de:233f）突然从 nvidia-smi 消失，BAR0 MMIO 一读就报 I/O error 与 fallen off the bus。六回合排查后揪出 pci=nocrs,realloc=on 真凶。"
image: "/assets/covers/h100-es-bar0.svg"
category: "GPU / 算力"
tags: ["H100", "PCIe", "NVIDIA"]
pinned: false
draft: false
---

> [!TIP]
> 本页为 **Astro + Mizuki** 自动导入预览版；若需查看原始手写排版（含原版内联 SVG 与附件下载），可访问 [原版 HTML 正文](/legacy-posts/h100-es-fallen-off-the-bus.html)。

手上这块 H100 是工程样品（ES），没有零售名分：PCI ID `10de:233f`，在公开 pci.ids 里查无此人——我之前整理的[《NVIDIA GPU PCI Device ID 全量对照》](/posts/nvidia-gpu-pci-device-ids.html)里也没有它，ES 专属 ID 本来就不进公开名单。`nvidia-smi` 里它只肯自称 **NVIDIA Graphics Device**，开源内核驱动要打开 `OpenRmEnableUnsupportedGpus=1` 才肯伺候，NVLink 还得手动关掉。这种卡从第一天起就走在“非官方支持”的钢丝上。 

然后某一天，它从 `nvidia-smi` 里消失了。 

这篇是这场斗法的完整记录：六个回合的复活手段轮番上阵、全部无效，最后靠一行内核引导参数一击定胜负。剧透：**真凶不是驱动、不是 CUDA、也不是卡坏了，是 `pci=nocrs,realloc=on`**——内核被这行参数指使着无视 ACPI 上报的 host bridge 窗口、自作主张重排了 GPU 的 BAR，把 MMIO 摆成了黑洞。改回 `pci=use_crs,realloc=off`，卡当场复活。 

## 对局双方

          

| 主板 | Supermicro H13SSL-N |
| --- | --- |
| 系统 / 内核 | Ubuntu 24.04，`6.17.0-35-generic` |
| 驱动 | NVIDIA 开源内核模块 `595.71.05` |
| GPU | Hopper GH100 ES，`0000:41:00.0` |
| PCI ID | `10de:233f`（subsystem `10de:16c1`） |
| 料号 / VBIOS | `233F-885-A1` / `96.00.74.00.01` |

 

安装的 NVIDIA 软件栈： 

```text
nvidia-driver-595-open
nvidia-kernel-source-595-open
nvidia-utils-595
linux-modules-nvidia-595-open-6.17.0-35-generic
```

 

Secure Boot 提前排除嫌疑： 

```text
SecureBoot disabled
Platform is in Setup Mode
```

 

ES 身份需要的前置设定（它们不是本次问题的原因，而是这块卡能工作的前提）： 

```text
OpenRmEnableUnsupportedGpus: 1
NvLinkDisable: 1
```

 

持久化的 modprobe 配置，修复完成后长这样： 

```text
options nvidia NVreg_NvLinkDisable=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var
options nvidia_drm modeset=1
blacklist nouveau
blacklist lbm-nouveau
blacklist nova
blacklist nova_core
alias nouveau off
alias lbm-nouveau off
alias nova off
alias nova_core off
```

 

## 发病现场：五个信号指向同一层

 

第一现场，`nvidia-smi` 与驱动彻底失联： 

```text
$ nvidia-smi -L
NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver.
Make sure that the latest NVIDIA driver is installed and running.
```

 

但 `lspci` 还看得见它： 

```text
$ lspci -Dnn | rg -i 'nvidia|3d controller|vga|display'
0000:41:00.0 3D controller [0302]: NVIDIA Corporation Device [10de:233f] (rev a1)
0000:c6:00.0 VGA compatible controller [0300]: ASPEED Technology, Inc. ASPEED Graphics Family [1a03:2000] (rev 52)
```

 

内核日志里，驱动在反复碰壁： 

```text
NVRM: The NVIDIA GPU 0000:41:00.0
NVRM: (PCI ID: 10de:233f) installed in this system has
NVRM: fallen off the bus and is not responding to commands.
nvidia 0000:41:00.0: probe with driver nvidia failed with error -1
NVRM: The NVIDIA probe routine failed for 1 device(s).
NVRM: None of the NVIDIA devices were initialized.
```

 

链路甚至训练在满血 Gen5 x16： 

```text
current_link_speed = 32.0 GT/s PCIe
current_link_width = 16
```

 

而最有信息量的一条证据：**PCI config 空间读得好好的，BAR0 的 MMIO 一读就报 I/O error**： 

```text
$ od -A x -t x4 -N 64 /sys/bus/pci/devices/0000:41:00.0/resource0
000000
od: '/sys/bus/pci/devices/0000:41:00.0/resource0': Input/output error
```

 

把五个信号摆到一起看： 
 
- PCI config 读正常； 
- PCIe 链路在 Gen5 x16； 
- NVIDIA 驱动初始化失败； 
- BAR0 MMIO 读失败； 
- 内核报 “fallen off the bus”。 
 

这个组合非常挑人：config 事务由 root complex 按 BDF 直接寻址，不依赖 MMIO 窗口；而 BAR 访问走的是普通内存事务，要求 host bridge 沿途每一级都正确 decode 这个地址。“config 通、MMIO 死”意味着问题不在 CUDA、不在用户态、大概率也不在链路本身，而在 **PCI 资源路由 / endpoint MMIO decode / 电源与槽位状态 / GPU 内部卡死**这一层。后面的六个回合，全部围绕这个判断展开。 

## 六个回合的无用功（但不白打）

 

### 回合一：先让战场安静下来

 

失联的设备会引来 udev 和 `nvidia-persistenced` 的反复 probe，日志刷屏，reset 的效果也没法干净地观察。先止噪： 

```text
systemctl stop nvidia-persistenced.service nvidia-cdi-refresh.service || true
udevadm control --stop-exec-queue
modprobe -r nvidia_uvm nvidia_drm nvidia_modeset nvidia || true
```

 

udev 还会反复重放 NVIDIA 规则，于是再压一层运行时 modprobe guard： 

```text
/run/modprobe.d/zz-disable-nvidia-until-reboot.conf
```

 

```text
install nvidia /bin/false
install nvidia-modeset /bin/false
install nvidia-drm /bin/false
install nvidia-uvm /bin/false
```

 

注意它放在 `/run` 下——重启自动消失，只是诊断期间的临时手段，不属于持久修复的一部分。 

### 回合二：FLR（函数级复位）

 

设备声称支持两种复位方式： 

```text
$ cat /sys/bus/pci/devices/0000:41:00.0/reset_method
flr bus
```

 

先来 FLR： 

```text
printf 1 > /sys/bus/pci/devices/0000:41:00.0/enable
printf 1 > /sys/bus/pci/devices/0000:41:00.0/reset
```

 

结果：链路还在 Gen5 x16，BAR0 还是 I/O error，probe 还是失败。 

### 回合三：secondary bus reset

 

总线 41 上只挂了这一个 endpoint，可以放心做下游总线复位： 

```text
printf 'bus\n' > /sys/bus/pci/devices/0000:41:00.0/reset_method
printf 1 > /sys/bus/pci/devices/0000:41:00.0/reset
printf 'flr bus\n' > /sys/bus/pci/devices/0000:41:00.0/reset_method
```

 

链路重训练成功——然后一切照旧。 

### 回合四：remove + rescan

 

把 PCI function 整个摘掉再重新扫描： 

```text
printf 1 > /sys/bus/pci/devices/0000:41:00.0/remove
printf 1 > /sys/bus/pci/rescan
```

 

设备在 `41:00.0` 原位归来，内核重建了 BAR 分配，BAR0 依然 I/O error。这一轮还附赠了新报错——连 DOE mailbox 都复位不动： 

```text
pci 0000:41:00.0: DOE: [2c8] ABORT timed out
pci 0000:41:00.0: DOE: [2c8] failed to reset mailbox with abort command : -5
pci 0000:41:00.0: DOE: [2c8] failed to create mailbox: -5
```

 

设备对这些管理面的操作一概爱答不理。 

### 回合五：把 BAR2 从 128 GB 砍到 64 MB

 

这块卡支持 Resizable BAR： 

```text
BAR 2: current size: 128GB, supported: 64MB ... 128GB
```

 

怀疑 128 GB 的巨型 BAR 摆不下，先砍到最小试试。`resource2_resize` 写入的是以 MB 为单位的 log2 值：6 → 2⁶ = 64 MB，17 → 2¹⁷ MB = 128 GB： 

```text
printf 0 > /sys/bus/pci/devices/0000:41:00.0/enable
printf 6 > /sys/bus/pci/devices/0000:41:00.0/resource2_resize
```

 

再配合驱动侧关掉 BAR resize 探一次： 

```text
modprobe nvidia NVreg_OpenRmEnableUnsupportedGpus=1 NVreg_EnableResizableBar=0
```

 

resize 机械上成功了，该失败的照样失败：probe 挂、BAR0 依旧 I/O error。试完把 BAR2 恢复回 128 GB： 

```text
printf 17 > /sys/bus/pci/devices/0000:41:00.0/resource2_resize
```

 

### 回合六：modprobe 旗子全家桶

 

```text
modprobe nvidia NVreg_OpenRmEnableUnsupportedGpus=1
modprobe nvidia NVreg_OpenRmEnableUnsupportedGpus=1 NVreg_EnableResizableBar=0
modprobe nvidia NVreg_OpenRmEnableUnsupportedGpus=1 NVreg_EnableResizableBar=0 NVreg_IgnoreMMIOCheck=1
```

 

连 `NVreg_IgnoreMMIOCheck=1` 都压不住。在旧引导策略下没有任何一种组合能救活它，失败形态从头到尾高度一致——**这是更低层的 PCI/MMIO 映射问题**。 

战况小结：           

| 回合 | 手段 | 链路 | BAR0 读 | 驱动 probe |
| --- | --- | --- | --- | --- |
| 一 | 停服务 / 卸模块 / modprobe guard | — | — | —（只为止噪） |
| 二 | FLR | Gen5 x16 | I/O error | 失败 |
| 三 | Secondary bus reset | 重训练成功 | I/O error | 失败 |
| 四 | remove + rescan | 重新枚举成功 | I/O error | 失败（附赠 DOE 报错） |
| 五 | BAR2 128 GB → 64 MB | 正常 | I/O error | 失败 |
| 六 | modprobe 旗子全家桶 | 正常 | I/O error | 失败 |

 

## 真凶浮出水面：pci=nocrs,realloc=on

 

回头审引导参数。这台机器的旧 boot line 带着： 

```text
pci=nocrs,realloc=on
```

 

而内核日志里其实早就留了自白书： 

```text
PCI: Ignoring host bridge windows from ACPI; if necessary, use "pci=use_crs" and report a bug
PCI: Using E820 reservations for host bridge windows
```

 

两个参数拆开看：`nocrs` 让内核无视 ACPI `_CRS` 上报的 host bridge 资源窗口，退回用 E820 保留表去猜；`realloc=on` 进一步允许内核把固件分好的 BAR 全部重排。在这块主板 + 这块卡的组合上，后果就是 GPU 的 BAR 被挪到了一个“枚举看起来正常、链路也在，但 MMIO 实际不被可靠 decode”的位置——于是就有了前面那组诡异的症状。 

固件本来把话说得很清楚。ACPI 给 root bus `40` 上报的资源里，有一个巨大的高位 MMIO 窗口： 

```text
pci_bus 0000:40: root bus resource [mem 0x28081000000-0x38080ffffff window]
```

 

H100 的三个 BAR 天然就住在这个窗口里： 

```text
pci 0000:41:00.0: BAR 0 [mem 0x38002000000-0x38002ffffff 64bit pref]
pci 0000:41:00.0: BAR 2 [mem 0x36000000000-0x37fffffffff 64bit pref]
pci 0000:41:00.0: BAR 4 [mem 0x38000000000-0x38001ffffff 64bit pref]
```

 

BAR0 是 16 MB 寄存器区，BAR2 是 128 GB 显存映射（对应后文 BAR1 Memory 的 131072 MiB），BAR4 是 32 MB。让内核尊重 ACPI 窗口之后，驱动一次初始化成功。两种策略下的差别画出来是这样： 

## 终局：一行参数定胜负

 

编辑 `/etc/default/grub`。改前： 

```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=nocrs,realloc=on iommu=pt"
```

 

改后： 

```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=use_crs,realloc=off iommu=pt"
```

 

重新生成 GRUB 配置并重启： 

```text
update-grub
systemctl reboot
```

 

重启后确认生效的引导行： 

```text
$ cat /proc/cmdline
BOOT_IMAGE=/boot/vmlinuz-6.17.0-35-generic root=UUID=1b66de5d-62ff-4e45-b5c1-c127818b6c5b ro quiet splash pci=use_crs,realloc=off iommu=pt vt.handoff=7
```

 

## 战后验尸

 

`lspci`：驱动上桩，三个 BAR 各就各位，链路满血： 

```text
$ lspci -Dnnvv -s 0000:41:00.0
0000:41:00.0 3D controller [0302]: NVIDIA Corporation Device [10de:233f] (rev a1)
    Kernel driver in use: nvidia
    Region 0: Memory at 38002000000 (64-bit, prefetchable) [size=16M]
    Region 2: Memory at 36000000000 (64-bit, prefetchable) [size=128G]
    Region 4: Memory at 38000000000 (64-bit, prefetchable) [size=32M]
    LnkSta: Speed 32GT/s, Width x16
```

 

设备节点齐了： 

```text
$ ls -l /dev/nvidia0 /dev/nvidiactl /dev/nvidia-uvm
```

 

驱动侧的登记信息： 

```text
$ cat /proc/driver/nvidia/gpus/0000:41:00.0/information
Model:           Unknown
GPU UUID:        GPU-ef59d941-6b8d-2e65-026a-580067da9fcd
Video BIOS:      96.00.74.00.01
Bus Type:        PCIe
Bus Location:    0000:41:00.0
Device Minor:    0
GPU Firmware:    595.71.05
GPU Excluded:    No
```

 

`Model: Unknown` 不用慌——ES 的 PCI ID 本来就不在驱动的花名册里。重要的信号是：UUID 在、minor `0` 在、`GPU Excluded: No`。然后是久违的问候： 

```text
$ nvidia-smi -L
GPU 0: NVIDIA Graphics Device (UUID: GPU-ef59d941-6b8d-2e65-026a-580067da9fcd)
```

 

一条命令看齐健康指标： 

```text
$ nvidia-smi --query-gpu=index,name,uuid,pci.bus_id,driver_version,memory.total,pstate,temperature.gpu,power.draw,power.limit,ecc.mode.current --format=csv
index, name, uuid, pci.bus_id, driver_version, memory.total [MiB], pstate, temperature.gpu, power.draw [W], power.limit [W], ecc.mode.current
0, NVIDIA Graphics Device, GPU-ef59d941-6b8d-2e65-026a-580067da9fcd, 00000000:41:00.0, 595.71.05, 81559 MiB, P0, 29, 86.62 W, 700.00 W, Enabled
```

 

81559 MiB 显存、P0、29 ℃、86 W / 上限 700 W、ECC 开启。显存与 ECC 细查（`nvidia-smi -q -d MEMORY` / `-d ECC`）： 

```text
FB Memory Usage
    Total:    81559 MiB
    Reserved: 478 MiB
    Used:     14 MiB
    Free:     81068 MiB
BAR1 Memory Usage
    Total:    131072 MiB
```

 

```text
ECC Mode
    Current: Enabled
    Pending: Enabled
Volatile ECC Errors:
    SRAM Correctable: 0
    SRAM Uncorrectable Parity: 0
    SRAM Uncorrectable SEC-DED: 0
    DRAM Correctable: 0
    DRAM Uncorrectable: 0
```

 

BAR1 的 131072 MiB = 128 GB，正是回合五折腾过的那个 BAR2 映射，如今安安稳稳。内核日志也干净了： 

```text
nvidia 0000:41:00.0: enabling device (0000 -> 0002)
NVRM: loading NVIDIA UNIX Open Kernel Module for x86_64 595.71.05
nvidia-modeset: Loading NVIDIA UNIX Open Kernel Mode Setting Driver for x86_64 595.71.05
[drm] [nvidia-drm] [GPU ID 0x00004100] Loading driver
[drm] Initialized nvidia-drm 0.0.0 for 0000:41:00.0 on minor 2
```

 

没有 “fallen off the bus”、没有 Xid、没有致命 NVRM 报错。下面这两条 DRM 消息对无头计算卡无害，属正常现象： 

```text
nvidia 0000:41:00.0: [drm] No compatible format found
nvidia 0000:41:00.0: [drm] Cannot find any crtc or sizes
```

 

## 备忘与告诫

 
 
- 本次结论的前提是单卡在位（只有 `0000:41:00.0` 一个 NVIDIA endpoint）。若装两块 ES 而 `lspci` 只见其一，那是另一类枚举 / 供电 / 槽位问题，别直接套用本文。 
- ES 卡在 `nvidia-smi` 里显示为 `NVIDIA Graphics Device` 而非零售名 H100，属预期行为。 
- VBIOS 为 `96.00.74.00.01`，料号 `233F-885-A1`，最终工作驱动为开源内核模块 `595.71.05`。 
- **最重要的持久设定是内核 PCI 资源策略。**除非有独立的平台级理由、且改完重新验证过 GPU，否则不要把 `pci=nocrs,realloc=on` 加回来。 
 

## 复发自查清单

 

同样症状再次出现时，按顺序过一遍： 
 
- 确认当前引导行，应包含 `pci=use_crs,realloc=off iommu=pt`： 

```text
cat /proc/cmdline
```

 
- 确认 PCI 设备还在： 

```text
lspci -Dnn | rg -i 'nvidia|3d controller'
```

 
- 确认驱动绑定，期望指向 `/sys/bus/pci/drivers/nvidia`： 

```text
readlink -f /sys/bus/pci/devices/0000:41:00.0/driver
```

 
- 确认设备节点： 

```text
ls -l /dev/nvidia0 /dev/nvidiactl /dev/nvidia-uvm
```

 
- 确认 `nvidia-smi`： 

```text
nvidia-smi -L
nvidia-smi --query-gpu=index,name,uuid,pci.bus_id,driver_version,memory.total,ecc.mode.current --format=csv
```

 
- 若 `nvidia-smi` 再次失联，先收集现场： 

```text
dmesg -T | rg -i 'nvrm|nvidia|xid|41:00|fallen off|aer|bar|doe'
lspci -Dnnvv -s 0000:41:00.0
cat /sys/bus/pci/devices/0000:41:00.0/resource
cat /proc/driver/nvidia/version
```

 
- 不要上来就动 CUDA 软件包。这次的故障从头到尾不在 CUDA 用户态，而在 PCI 资源 / MMIO 路由。 
 

最后一句话总结这场斗法：**链路在 ≠ MMIO 通，config 可读 ≠ 卡还活着。**当 `nvidia-smi` 失联、`lspci` 却看得见、BAR 一读就 I/O error 时，别急着重装驱动、更别动 CUDA——低头看一眼 `/proc/cmdline`。斗了六个回合才发现，对面站着的从来不是这块卡，它也是受害者；真正的对手，是引导参数里那七个字符：`nocrs`。
