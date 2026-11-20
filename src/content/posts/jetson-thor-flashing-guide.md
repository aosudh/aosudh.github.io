---
title: "Jetson Thor 刷写全流程：原生 Linux、系统配置、第三方载板与 WSL 复盘"
published: 2026-10-22
description: "从 R38.2.1 官方包、目录与 CLI 调用链出发，逐项解释 BCT、设备树、分区与 UEFI，再记录 CES 第三方载板适配和 Windows/WSL 六轮刷写排错。"
image: "/assets/covers/jetson-thor.svg"
category: "嵌入式 / 刷机"
tags: ["Jetson", "Thor", "刷机"]
pinned: false
draft: false
---

> [!TIP]
> 本页为 **Astro + Mizuki** 自动导入预览版；若需查看原始手写排版（含原版内联 SVG 与附件下载），可访问 [原版 HTML 正文](/legacy-posts/jetson-thor-flashing-guide.html)。

这是一份从标准流程开始的 Thor 刷写手册。先完成原生 Linux 上的包准备、镜像生成、写盘与首启，再分析配置，最后进入第三方载板和本次 WSL 调试记录。 

[下载 Word 手册](/assets/downloads/jetson-thor-flashing-guide-r38.2.1.docx) · [下载公开技术附件](/assets/downloads/jetson-thor-technical-supplement.zip) 

公开版使用示例路径与设备标识。技术附件包含清单、命令、补丁和适配脚本；原始机器日志保留于本地证据归档。运行命令前请核对板型、版本与实际路径。 

- 一 原生 Linux 全流程
- 二 各模块配置分析
- 三 第三方载板适配
- 四 本次 WSL 踩坑
 

R38.2.1 第二版 2026年10月22日 公开版 

本手册先给出从空工作目录到正式系统启动的完整原生 Linux 操作，再沿着这条流程解释每一类配置，随后说明第三方载板的改动，最后复盘本次 Windows 和 WSL 刷写。各部分按依赖顺序衔接。 

| 阅读顺序 | 解决的问题 |
| --- | --- |
| 第一部分 A1–A10 原生 Linux 标准流程 | 要准备什么包、目录和工具；每一步在哪运行；内部调用哪些代码；生成什么文件；如何写盘并验收。 |
| 第二部分 B1–B8 逐模块配置分析 | board conf、BCT、设备树、内核、initrd、rootfs、分区、UEFI 各自控制什么，修改后怎样生效。 |
| 第三部分 C1–C4 第三方载板适配 | 硬件差异需要改哪里；CES 包具体覆盖哪些文件；安装与配置修复完成后如何重新走原生 Linux 流程。 |
| 第四部分 D1–D6 本次 WSL 调试复盘 | 原生流程迁移到本机后遇到哪些问题；六轮尝试如何定位、修复并验证；如何复现本机通道。 |

 

### 基准与实际设备

 

第一部分采用 Jetson Linux R38.2.1、原生 Ubuntu 22.04/24.04 主机，以及官方 AGX Thor 开发套件的 P3834-0008 模块和 P4071 载板，boardname 为 jetson-agx-thor-devkit。它用于建立无厂商覆盖的基准流程。实际 CES JAT-001/Y-C28 载板应按第三部分叠加对应 BSP 并改用 CES boardname，不能直接刷官方载板配置。 

第一部分的标准命令依据官方版本文档和本地同版脚本核对；本次设备实际成功刷写发生在第四部分所述的 WSL 与 Windows 混合通道，并未另做一次原生 Linux 实机刷写。手册明确区分标准步骤、源码行为与本次日志实证。 

刷写会改变目标固件、分区与系统数据。开始前核对板型、存储和备份。本次修订仅整理文档与现有证据，没有再次刷写设备。 

## A1 准备输入包和主机工具

 

第一部分 原生 Linux 标准流程 

使用原生 Ubuntu 主机连接 Thor 的刷写 USB。主机负责解包、配置和制作镜像，Thor 运行目标 ARM64 系统。包名 aarch64 指目标架构；本流程使用 x86_64 主机，包内个别静态主机程序实际为 i386 ELF，不能把所有文件都理解为 ARM64 或 x86_64 可执行文件。 

| 必需输入 | 作用与获取位置 |
| --- | --- |
| Jetson_Linux_R38.2.1_aarch64.tbz2 | NVIDIA Driver Package，包含 Linux_for_Tegra 框架、主机刷写工具、内核、设备树、固件和安装材料。 |
| Tegra_Linux_Sample-Root-Filesystem_R38.2.1_aarch64.tbz2 | Ubuntu 24.04 ARM64 基础根文件系统；独立于 Driver Package，需解压到 rootfs/。 |
| 官方工具包内脚本 | tools/l4t_flash_prerequisites.sh 安装主机依赖；apply_binaries.sh --openrm 准备 NVIDIA 系统组件。 |
| 主机环境和基础工具 | Ubuntu 22.04/24.04；tar、bzip2/lbzip2、USB 工具及 prerequisites 解析出的依赖。使用稳定的数据线和供电。 |
| 目标存储与连接 | 官方套件对应的本地 NVMe；刷写 USB 必须接支持 Recovery 的接口。串口用于观察独立于 USB 数据通道的启动日志。 |

 

两份官方包从 JetPack 7.0 下载归档中选择 R38.2.1，不混用其他版本。主机建议至少预留 100 GB 可用空间，还应计入 rootfs、镜像副本和日志；检查实际磁盘余量，不把建议空间当作工具的固定容量常量。 [S01][S02] 

### 哪些材料仅在定制时需要

 

第三方载板 BSP 放到第三部分处理。内核/驱动/设备树源码、交叉工具链、pinmux 表格、UEFI 源码或签名密钥，只在相应定制场景需要；标准预编译包刷写不要求先编译它们。基础系统成功启动也不等于 CUDA、容器和所有外设已完成安装与验收。 

附件“原生流程代码与文件清单”按实际执行阶段列工具、架构、输入输出及来源。包内固件可以是二进制交付，“全部代码梳理”指执行链与所用文件，不意味着这些二进制都有可读源码。 

## A2 建立干净工作目录

 

第一部分 原生 Linux 标准流程 

为官方基准创建新目录，不复用已叠加第三方包的工作树。本例使用当前普通用户的 ~/thor-native/r38.2.1，后续终端沿用下列变量。若切换用户或新开终端，重新设置变量并核对路径。 

主机 Linux 设置路径并检查环境 

```text
export THOR_WORK="$HOME/thor-native/r38.2.1"
export L4T="$THOR_WORK/Linux_for_Tegra"
export BOARD=jetson-agx-thor-devkit
mkdir -p "$THOR_WORK/downloads" "$THOR_WORK/logs"
cd "$THOR_WORK"
uname -m
cat /etc/os-release
df -h "$THOR_WORK"
```

 

目录示意 不要执行为命令 

```text
~/thor-native/r38.2.1/
├─ downloads/                    # 两个官方 .tbz2 原包
├─ logs/                         # 每轮独立日志
└─ Linux_for_Tegra/               # 解包后出现
   ├─ jetson-agx-thor-devkit.conf # 选择模块和载板配置
   ├─ apply_binaries.sh
   ├─ flash.sh
   ├─ l4t_initrd_flash.sh
   ├─ rootfs/                    # 目标系统的主机工作副本
   ├─ kernel/                    # Image、DTB 和内核安装材料
   ├─ nv_tegra/                  # NVIDIA 用户态安装材料
   ├─ bootloader/                # 固件、BCT 与中间结果
   ├─ tools/kernel_flash/        # 生成与刷写入口、分区XML
   │  └─ images/internal/ external/
   └─ unified_flash/             # Thor 传输与写盘工具
      ├─ tools/flashtools/        # 源工具与临时刷写系统
      └─ out/bsp_images/          # 实际刷写包与工具副本
```

 

同一文件可能存在于源目录、生成目录和板上分区。rootfs/ 是待打包目录，system.img 是生成结果，APP 是目标分区；修改前者不会自动修改后两者。bootloader/ 还会保留生成副本，后续必须检查实际消费者使用的路径。 

## A3 解压 BSP 和基础 rootfs

 

第一部分 原生 Linux 标准流程 

将两份 R38.2.1 官方归档放入 $THOR_WORK/downloads 后执行。文件大小可以辅助识别，不能代替可信校验值；保存本地 SHA256 便于之后追踪是否变化。 

主机 Linux 两次解压都应成功后再继续 

```text
cd "$THOR_WORK/downloads"
sha256sum Jetson_Linux_R38.2.1_aarch64.tbz2 \
  Tegra_Linux_Sample-Root-Filesystem_R38.2.1_aarch64.tbz2 \
  > ../logs/input-sha256.txt

sudo apt update
sudo apt install -y bzip2 lbzip2
cd "$THOR_WORK"
sudo tar -xf downloads/Jetson_Linux_R38.2.1_aarch64.tbz2
sudo tar -xpf \
  downloads/Tegra_Linux_Sample-Root-Filesystem_R38.2.1_aarch64.tbz2 \
  -C Linux_for_Tegra/rootfs/
```

 

| 动作 | 输入 | 输出与检查 |
| --- | --- | --- |
| 解压 Driver Package | Jetson_Linux_…tbz2 | 产生完整 Linux_for_Tegra 工具框架；此时不等于已有完整系统。 |
| 解压 sample rootfs | Tegra_Linux_Sample-Root-Filesystem_…tbz2 | 填充 Linux_for_Tegra/rootfs 下的 etc、usr、var 等目标目录。 |
| 保留文件属性 | sudo tar -xpf | 保持系统文件权限和所有权，避免普通用户解压破坏目标系统语义。 |

 

主机 Linux 检查目录位置与目标发行版 

```text
cd "$L4T"
test -f apply_binaries.sh
test -f rootfs/etc/os-release
test -d rootfs/usr
ls -ld rootfs rootfs/etc rootfs/usr
cat rootfs/etc/os-release
```

 

出现 lbzip2: Cannot exec 时先补解压程序；出现 rootfs 为空时回到第二次解压。不要把整个 rootfs 递归 chown 为普通用户来绕过权限错误。整个准备阶段不要求板端已经能启动 Ubuntu。 [S03] 

## A4 安装依赖并完成目标系统内容

 

第一部分 原生 Linux 标准流程 

主机 Linux 按顺序执行 每条成功后再进行下一条 

```text
cd "$L4T"
sudo ./tools/l4t_flash_prerequisites.sh
sudo ./apply_binaries.sh --openrm
```

 

prerequisites 脚本安装刷写主机需要的依赖；apply_binaries 修改的是 rootfs 工作树，将 NVIDIA Debian 包、系统定制和驱动相关内容装入目标系统。Thor 在 R38.2.1 使用 --openrm。它不是刷写命令，也不会自动把系统送入板上 NVMe。 [S02][S03] 

| 执行层 | 相关代码或材料 | 结果 |
| --- | --- | --- |
| 依赖准备 | tools/l4t_flash_prerequisites.sh 及其依赖处理 | 主机拥有生成、签名、打包与刷写需要的工具。 |
| 默认 Debian 安装路径 | apply_binaries.sh → nv_tegra/nv-apply-debs.sh | 把包安装到指定 rootfs，并传递 openrm 选项。 |
| 系统定制 | nv_tools/scripts/nv_customize_rootfs.sh | 调整目标 rootfs 的相关系统内容。 |
| 替代 overlay 路径 | nv_apply_kernel_files.sh 等辅助脚本 | 仅在相应分支被选择时消费，不应把所有分支都说成默认逐一执行。 |

 

主机 Linux 确认目标版本和安装材料 

```text
cat "$L4T/rootfs/etc/nv_tegra_release"
test -d "$L4T/rootfs/lib/modules"
test -f "$L4T/kernel/Image"
ls "$L4T/kernel/dtb" | head
```

 

### 可选的系统定制必须在镜像生成之前完成

 

需要预装软件、修改网络或加入业务文件时，在 rootfs 准备阶段完成，再生成 system.img。通常保留首次开机 OOBE 创建账号即可。无交互部署可查看 tools/l4t_create_default_user.sh --help，按实际账号策略使用；它会改变 rootfs 并跳过 OOBE。该脚本可能打印明文凭据，不把其输出加入共享日志，也不使用统一示例密码。 [S04] 

只有 rootfs 存在且安装成功，下一步生成系统镜像才有意义。此处尚不分析具体 DTB 或 UEFI 参数；第二部分逐项解释它们。 

## A5 连接设备并进入 Force Recovery

 

第一部分 原生 Linux 标准流程 

确认目标是第一部分所用的官方套件配置，并接好 NVMe、稳定供电和刷写 USB。官方 AGX Thor 套件在关机状态下，按住 Force Recovery 按钮，再按下并松开 Power，最后松开 Force Recovery。第三方按钮和接线应遵循其载板说明。进入 RCM 后，主机从 USB 向 BootROM 下载启动材料。 [S03] 

主机 Linux 确认目标处于 Recovery 

```text
lsusb -d 0955:
# Thor Recovery 通常可见 NVIDIA APX 0955:7026
# 同时连接多块设备时，先明确本次目标，不能靠第一项猜测
```

 

### 开始前建立本轮日志目录

 

主机 Linux 后面的生成与刷写日志写入此目录 

```text
export LOGDIR="$THOR_WORK/logs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGDIR"
printf '%s\n' "$L4T" "$BOARD" > "$LOGDIR/context.txt"
uname -a >> "$LOGDIR/context.txt"
lsusb > "$LOGDIR/usb-before.txt"
```

 

| 观察通道 | 用途与记录内容 |
| --- | --- |
| 主机 CLI 日志 | 生成过程、RCM 下载、ADB 写盘、校验、扩容和退出码。 |
| 目标调试串口 | 从 BootROM/MB1/MB2 到 UEFI、临时 Linux、正式 Linux 的第一现场。端口节点按实际设备选择。 |
| 主机 USB 事件 | 记录 APX 消失、重枚举和临时系统接口出现的顺序；可在另一终端观察 journalctl -k -f。 |

 

调试串口的接线、电平与波特率按当前套件说明确认。原生 Linux 下可使用已有串口终端的保存日志功能，正式刷写前先确认它确实在接收数据。 

保持串口跨越整个刷写和首启过程。APX 可枚举只证明下载入口可见，不能证明后续临时系统已经起来，更不能证明系统刷完。 

## A6 先生成完整刷写包

 

第一部分 原生 Linux 标准流程 

本手册主线采用“先生成、再写盘”，便于在写入前检查配置和产物。--no-flash 会生成包后退出，但仍可能读取连接设备的板级信息；按本流程保持 Recovery 可访问，不把它当成无设备离线生成。 

主机 Linux 仅退出码0且生成完成才继续 

```text
cd "$L4T"
set -o pipefail
sudo ./l4t_initrd_flash.sh --no-flash "$BOARD" internal \
  2>&1 | tee "$LOGDIR/generate.log"
rc=${PIPESTATUS[0]}
printf '%s\n' "$rc" > "$LOGDIR/generate-exit-code.txt"
echo "Generate exit code: $rc"
```

 

| 生成动作 | 消费的输入 | 主要输出 |
| --- | --- | --- |
| 展开板型 | <board>.conf、common 配置、板级信息 | 当前目标的文件选择、介质与参数。 |
| 制作启动材料 | BCT、DTB、内核、固件、分区 XML | BCT/签名材料、boot.img、DTB 等分区载荷。 |
| 制作正式系统 | 准备好的 rootfs | system.img 及必要的文件系统内容。 |
| 整理刷写包 | 内部/外部镜像和 unified 工具 | images/internal、images/external、out/bsp_images 下的实际 payload 与工具。 |

 

主机 Linux 核对保存的板型参数与生成目录 

```text
cat tools/kernel_flash/initrdflashparam.txt
cat tools/kernel_flash/images/external/flash.cfg
ls tools/kernel_flash/images/internal/
ls tools/kernel_flash/images/external/
ls unified_flash/out/bsp_images/flash_workspace/flash-images/
test -s unified_flash/out/bsp_images/flash_workspace/rcm-flash/rcm_blob.bin
```

 

核对目标 boardname、外部设备与布局，不只检查文件存在。文件存在可能是旧产物；应以本轮成功生成和本轮配置一致为前提。内部脚本链及每类产物在 A9、A10 进一步对应。 

## A7 执行写盘并判断完成

 

第一部分 原生 Linux 标准流程 

保持原生 Linux 直接拥有刷写 USB，确认设备仍处于 Recovery；若已经离开，则按板卡流程重新进入。沿用 A6 成功生成的包，不在生成与写盘之间改变内核、DTB、BCT、rootfs 或分区配置。 

主机 Linux 真正改写目标存储的步骤 

```text
cd "$L4T"
lsusb -d 0955:
set -o pipefail
sudo ./l4t_initrd_flash.sh --flash-only "$BOARD" internal \
  2>&1 | tee "$LOGDIR/flash.log"
rc=${PIPESTATUS[0]}
printf '%s\n' "$rc" > "$LOGDIR/flash-exit-code.txt"
echo "Flash exit code: $rc"
```

 

| 运行阶段 | 发生什么 | 应观察到什么 |
| --- | --- | --- |
| RCM 下载 | 主机通过 APX 下载组合启动材料 | 目标继续 MB1/MB2/UEFI 等临时启动，USB 发生重枚举。 |
| 临时刷写 Linux | boot_flashing.img 中的系统运行于 RAM | ADB 接口出现；本版 unified 流程通过它传工具和数据。 |
| 目标写盘 | 临时系统执行 wrapper 与 nvdd 等工具，写固件/分区 | 按清单处理 QSPI/NVMe，出现写入与相应检查记录。 |
| 收尾 | 文件系统检查、扩容、sync 和退出 | 工具报告完成，主机退出码 0；随后仍需正式启动验收。 |

 

--flash-only 是复用完整包，不是从上次失败字节处断点续传；它还会读取生成时保存的参数。镜像内容或板型变更后返回 A6 重新生成。原生路径使用 BSP 原始 Linux ADB。 

### 可选的一步入口

 

这是替代路线 不要在上面刷完后再执行一遍 

```text
# 仅在不采用 A6→A7 分阶段路线时使用
sudo ./l4t_initrd_flash.sh "$BOARD" internal
```

 

命令末尾 internal 不等于只写内置 eMMC。官方 Thor NVMe 配置同时选择 QSPI 固件布局与本地 NVMe 根文件系统；最终目标以配置与生成索引为准。 [S04] 

## A8 首次启动与标准验收

 

第一部分 原生 Linux 标准流程 

确认刷写进程完成、写盘和 sync 结束，再观察正常启动。正式启动不按 REC；若工具没有自动进入正常系统，按板卡说明正常重启并持续记录串口。先确认根文件系统真正来自目标存储，再完成 OOBE 创建账号。 

目标 Thor 完成登录后保存结果 

```text
# 以下命令在正式启动后的 Thor 上执行
uname -a
cat /etc/nv_tegra_release
cat /proc/cmdline
findmnt /
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,PARTUUID
df -h /
tr -d '\0' < /proc/device-tree/model
systemctl --failed
```

 

| 验收层次 | 通过条件 |
| --- | --- |
| 主机刷写 | 生成和刷写退出码、目标序列号/板型与日志对应，未忽略失败继续。 |
| 正常启动 | 串口经过正常 UEFI 启动路径；加载正确内核与设备树，未停留在 RCM 或临时 initrd。 |
| 根文件系统 | root= / PARTUUID、findmnt 和 lsblk 相互一致，根分区容量符合设计并可读写。 |
| 用户空间 | 完成 OOBE，登录、必要服务与存储工作正常。 |
| 业务与外设 | 按用途另验 GPU/CUDA、网络、USB、PCIe、相机、串口及其他外设，保存结果。 |

 

临时刷写系统和正式系统可能拥有相同的 uname -r。判断时结合完整内核构建字符串、/proc/cmdline 和根挂载，不只看版本号。主机“刷写成功”也不能替代整板外设验收。 

### 到这里标准操作流程结束

 

A9 和 A10 将上述每一步映射回代码与文件，帮助定位“这一步到底用了哪份输入”。第二部分再解释各配置值；第三方载板适配完成后仍回到同一条准备、生成、写盘、验收主线。 

## A9 完整脚本调用链

 

第一部分 原生 Linux 标准流程 

以下是本版 Thor _UNIFIED_FLASH=1 分支。路径相对 Linux_for_Tegra；示意中的函数由上层自动调用，正常操作只运行 A4、A6、A7 的公开入口，不需要手工逐个执行内部脚本。 

缩略树 ...表示tools/flashtools 完整精确路径见附件调用链 

```text
准备rootfs
  apply_binaries.sh --openrm
    → nv_tegra/nv-apply-debs.sh
    → nv_tools/scripts/nv_customize_rootfs.sh

公开入口 l4t_initrd_flash.sh
  → tools/kernel_flash/l4t_initrd_flash.sh
  → tools/kernel_flash/l4t_initrd_flash_internal.sh
    生成阶段
    → l4t_create_images_for_kernel_flash.sh
      → flash.sh --no-flash --sign
        → bootloader/tegraflash.py
        → tegraflash_impl_t264.py / tegraflash_internal.py
    → unified_flash/.../bootburn/create_bsp_images.py --toolsonly
    → create_l4t_bsp_images.py
    → generate_flash_initrd() / generate_rcmboot_flashingcmd()
    写盘阶段
    → out/bsp_images/tools/flashtools/bootburn/flash_bsp_images.py
    → bootburn_t264_py/flash_bsp_images.py
    → bootburn_thor.BootRCM() → flash/tegrarcm_v2
    → bootburn_lib.FlashImages() → bootburn_adb.py
    → 主机 adb → 目标 /tmp/wr_sh.sh → 目标 /tmp/nvdd
```

 

| 关键内部动作 | 输入和输出 |
| --- | --- |
| nv-apply-debs.sh | 利用QEMU辅助的chroot安装ARM64包到rootfs；这是主机侧准备，不是板上系统已经运行。 |
| flash.sh / tegraflash | 消费conf、BCT、DTB、固件、XML和rootfs；生成签名材料、分区资料与系统/启动镜像。 |
| create_bsp_images.py --toolsonly | 只打包工具副本，不负责把整个rootfs制成system.img。 |
| create_l4t_bsp_images.py | 消费内部/外部flash.idx和flash.cfg，形成FileToFlash.txt与最终payload，另转换RCM材料。 |
| 临时系统生成 | 从预制boot_flashing.img解出内核/initrd，写运行参数并重打包；不是默认重编正式kernel/Image。 |

 

bootburn_t264_py 是目录，不存在 bootburn_t264.py 这个入口文件。写盘阶段执行 generated 工具副本；create_bsp_images.py 与 create_l4t_bsp_images.py 是两个不同脚本。 

## A10 工具 输入文件和产物总表

 

第一部分 原生 Linux 标准流程 

| 文件或代码组 | 执行端或消费者 | 在完整流程中的作用 |
| --- | --- | --- |
| <board>.conf 与 common | 主机脚本读取 | 选择硬件、内核、BCT、DTB、介质及分区布局。 |
| bootloader/generic/BCT 与实际工作副本 | cpp/dtc及Tegra工具 → 目标早期固件 | DTS/DTSI预处理、BCT二进制生成；同时检查同名include。 |
| tegrabct_v2 / tegrahost_v2 / tegraparser_v2 / tegrasign_v3.py | 主机 | 生成BCT、镜像头、分区和签名材料；具体调用按T264分支。 |
| kernel/Image / kernel/dtb / NVIDIA debs / rootfs | 主机生成器 → 正式Thor | 构成正式内核、DTB、驱动/用户态、system.img；mkbootimg组合boot镜像。 |
| uefi_t26x_general.bin 与各协处理器固件 | 生成器打包 → 目标对应固件阶段 | 组成QSPI等引导载荷；它们不是普通Linux用户程序。 |
| flashing_kernel/initramfs/t264/boot_flashing.img | 主机解包重打包 → 目标RAM | 临时刷写内核、initrd、adbd和写盘支持环境；与正式boot.img不同。 |
| tegrarcm_v2 / Linux adb | 主机 | 前者访问BootROM下载入口；后者控制临时Linux，传文件并执行命令。 |
| wr_sh.sh / nvdd / e2fsck / resize2fs / losetup | Thor临时Linux | wrapper返回命令退出码；nvdd实际写盘；文件系统工具执行检查与扩容。 |
| flash.idx / flash.cfg / FileToFlash.txt | 主机调度读取 | 把配置转换成实际分区、输入文件、偏移、大小、resize与校验任务。 |

 

主机并不需要把NVMe挂成自己的USB磁盘来写入。bootburn控制ADB，目标临时系统按FileToFlash执行写盘。大文件传输和整文件MD5是不同步骤，不能从通用成功文本推断所有分区均做了全量回读。 

### 主机依赖脚本的实际包清单

 

本版 l4t_flash_prerequisites.sh 列出 abootimg、binfmt-support、binutils、cpio、cpp、device-tree-compiler、dosfstools、iproute2、iputils-ping、lbzip2、libxml2-utils、netcat-openbsd、nfs-kernel-server、openssl、python3-yaml、python3-usb、qemu-user-static、rsync、sshpass、udev、usbutils、uuid-runtime、whois、xmlstarlet、zstd、zlib1g，并按发行版加入 lz4。安装集合含NFS/SSH组件，不代表本次Thor unified分支实际用它们传镜像。 

附件补全精确脚本/二进制清单、执行端、NVIDIA包目录与输入输出。第三部分附件另收录一份第三方载板生成包的逐项载荷实测样例；某个实例的文件名与偏移不能当作所有板型的固定值。 

## B1 启动与存储 先判断故障属于哪一层

 

第二部分 逐模块配置分析 

本部分以官方 P3834-0008 模块和 P4071-0000 载板、Jetson Linux R38.2.1 为基准。L4T 指全新解压的 ~/thor-native/r38.2.1/Linux_for_Tegra。理解配置时，应沿“输入文件 → 主机工具 → 生成载荷 → 目标启动阶段”追踪，不能只看一个文件名。 

正常启动的依赖关系；协处理器活动并非全部严格串行 

```text
上电 / 复位
  → BootROM、PSC 等安全与早期启动逻辑
  → MB1 / BCT：早期硬件初始化
  → MB2 及相关固件：准备后续启动
  → UEFI → 所选 OS loader → Linux 内核与 initrd
  → 挂载正式 rootfs → systemd → OOBE / 登录
```

 

| 层次 | 主要作用 | 读取或维护的内容 |
| --- | --- | --- |
| 早期引导 | 建立内存、引脚、电源与安全运行环境 | BCT、早期固件、板级信息 |
| UEFI / OS loader | 选择启动设备及加载方式 | UEFI 变量、EFI 入口、内核、DTB、initrd |
| Linux | 探测外设、挂载根分区、运行服务 | 运行时设备树或相应硬件描述、驱动、rootfs |
| QSPI | 保存本配置的引导固件和相关启动材料 | A/B 固件分区、版本和 UEFI 变量等 |
| NVMe | 保存内核相关载荷、EFI 与 Ubuntu 系统 | 分区表、kernel/DTB、ESP、APP 等 |

 

Force Recovery / RCM 是芯片级 USB 下载入口；刷写工具下载并启动的 RAM 临时 Linux 是写盘环境；UEFI 从存储上的 recovery 分区启动又是第三种状态。三者不能仅凭“恢复模式”四个字混为一谈。临时系统能运行不证明正式 APP 已刷好。 [S11] 

官方 devkit 的标准命令同时处理 QSPI-NOR 和 NVMe。rootdev 参数 internal 在 Thor 中可以表示本地 NVMe/UFS 根存储，不等于“只写 eMMC”。具体写什么由板型与分区配置共同决定。 [S03][S04] 

## B2 board.conf 配置选择的总入口

 

第二部分 逐模块配置分析 

CLI 中的板名是配置名，省略 .conf 后缀。官方配置链为 jetson-agx-thor-devkit.conf → p3834-0008-p4071-0000-nvme.conf → t264.conf.common。前者在本版是链接；common 提供默认值，板型文件再覆盖适用于该模块与载板的值。 

| 输入项 | 官方 devkit 的选择 |
| --- | --- |
| DTB_FILE / TBCDTB_FILE | tegra264-p4071-0000+p3834-0008-nv.dtb；分别供 Linux 与 CPU bootloader 配套输入使用 |
| BPFDTB_FILE | tegra264-bpmp-3834-0008-4071-xxxx.dtb |
| PINMUX_CONFIG | tegra264-mb1-bct-pinmux-p3834-xxxx-p4071-0000.dts |
| PMC_CONFIG | tegra264-mb1-bct-padvoltage-p3834-xxxx-p4071-0000.dts |
| MB2_BCT | tegra264-mb2-bct-misc-p3834-xxxx-p4071-0000.dts |
| TBCFILE | bootloader/uefi_t26x_general.bin |
| EXTERNAL_DEVICE | nvme0n1p1；是 Thor 上的目标分区名，不是主机磁盘 |
| EXTERNAL_PT_LAYOUT | tools/kernel_flash/flash_l4t_t264_nvme.xml |

 

这些值由主机侧生成脚本消费，决定 BCT、固件、内核、设备树和分区载荷；它们不是开机后 Linux 会自动重新读取的配置。修改 board.conf 后，应重建相关镜像，再检查生成索引与最终包。仅重跑 --flash-only 不会重新解释所有输入并制作新镜像。 [S04] 

主机：只读找入口，再逐层阅读 common 与后续覆盖 

```text
cd ~/thor-native/r38.2.1/Linux_for_Tegra
readlink -f jetson-agx-thor-devkit.conf
grep -nE 'source|DTB_FILE|TBCDTB_FILE|EXTERNAL_' \
  p3834-0008-p4071-0000-nvme.conf
```

 

不要为了“打印变量”随意 source 整份配置。文件可能包含条件逻辑并依赖 LDK_DIR 等上下文；静态搜索也只能定位定义，最终选择还须由生成日志、flash.cfg 与实际载荷核对。上述官方 conf 值已与本版文件核验；新版本需重新查证。 

## B3 BCT EEPROM 与 pinmux 内核之前就已生效

 

第二部分 逐模块配置分析 

BCT 是早期启动使用的配置表。部分输入采用 DTS/DTSI 语法，但它们不是 Linux 的运行时设备树。board.conf 选择输入，主机工具展开 include、生成二进制表和签名材料，目标的相应早期启动阶段再消费这些产物。 

| 配置类别 | 输入与职责 | 分析重点 |
| --- | --- | --- |
| 内存 / 电源 | SDRAM、PMIC、pad voltage 等配置 | 模块与载板电气条件；不可凭别的型号复制 |
| pinmux / GPIO | 引脚复用、输入输出、电压容限及默认状态 | 原理图、pinmux 表、生成文件与 conf 引用是否一致 |
| MB2 EEPROM | MB2 BCT 中的 CVM/CVB EEPROM 读取参数 | 模块与载板分别对待；读地址、长度和实际硬件 |
| UPHY / 控制器 | PCIe、USB、UFS 等高速资源配置 | lane 分配、控制器模式、固件与设备树是否匹配 |

 

### 分析一个参数要完成四次定位

 

• 先定位 board.conf 选中的输入文件，而不是只搜索一个相似文件名。 

• 再沿 #include 和工具的 include 搜索路径展开；同名副本可能位于 bootloader 根目录和 generic/BCT。 

• 核对实际预处理输出及生成日志，确认改动进入了本次 BCT、RCM 和冷启动材料。 

• 刷写后用目标串口确认对应阶段已经消费新配置；Linux 中的属性不能替代早期阶段证据。 

官方 P4071 基准无需为了刷写而关闭载板 EEPROM。只有确认定制载板没有 EEPROM 时，才按 Thor 适配文档将相应 MB2 的 cvb_eeprom_read_size 设为 0；CVM 是模块 EEPROM，不能一起禁用。此规则是硬件适配条件，不是所有第三方板的固定步骤。 [S05] 

BCT 改动必须重新生成并刷写相应载荷。修改 /boot 下的 Linux DTB、调整 UEFI 启动顺序或跳过主机 EEPROM 检查，都不能自动修复 MB2 实际读取错误。若故障发生在内核出现之前，应先用串口定位最早错误。 

## B4 设备树 输入选择与启动选择是两件事

 

第二部分 逐模块配置分析 

| 对象 | 谁消费 | 不能混淆的内容 |
| --- | --- | --- |
| Linux DTB：DTB_FILE | Linux 驱动与硬件探测 | 不是 MB1/MB2 BCT，也不是 BPMP 的树 |
| CPU bootloader DTB：TBCDTB_FILE | UEFI 相关启动阶段 | 官方基准与 Linux DTB 同源，不表示所有最终字节相同 |
| BPMP DTB：BPFDTB_FILE | BPMP 协处理器固件 | 不能用 Linux DTB 替换 |
| DTBO overlay | 条件匹配后的 UEFI、kernel 或二者 | board_config、sw-modules 等决定适用范围 |

 

生成时，board.conf 决定输入 DTB 与 overlay；工具将它们组合进启动材料、分区载荷和文件系统相关位置。启动时，L4TLauncher 按当前 Boot Mode 和启动项选择内核及 DTB。支持的文件系统启动方式可通过 /boot/extlinux/extlinux.conf 的 FDT 指定文件；未指定或相应文件不可用时按本版规则回退。 [S05][S12] 

因此，主机 kernel/dtb/ 中已替换文件，并不能单独证明系统正在使用它。一个旧的 rootfs FDT 引用可能继续选择文件系统内旧 DTB；也可能仍在使用未重建的分区载荷。运行时树还会接收 overlay 和固件填入的信息。 

属性可不存在；不能只用一个属性或哈希判断全部加载路径 

```text
# 在正式运行的 Thor 上只读检查
tr -d '\0' < /proc/device-tree/model
cat /proc/cmdline
grep -nE 'DEFAULT|LABEL|LINUX|INITRD|FDT|APPEND' \
  /boot/extlinux/extlinux.conf
test ! -r /proc/device-tree/nvidia,dtsfilename || \
  tr -d '\0' < /proc/device-tree/nvidia,dtsfilename
```

 

替换设备树前，明确它属于哪个处理器与阶段、匹配哪个内核和板型，并保留可回退版本。修改输入后重建镜像，结合生成日志、串口 Machine model、启动参数及外设驱动探测验证。仅修改 Linux DTB 不能改变更早的 EEPROM 或 pinmux BCT。 

本文不默认提供 FDTOVERLAYS 可执行模板：必须先核对该版 Thor 的 loader 支持和实际语法。UEFI 文档里的其他平台 camera overlay 文件名也不能直接拿来使用。 

## B5 kernel initrd 与 rootfs 三个不同层次

 

第二部分 逐模块配置分析 

| 对象 | 主机侧内容 / 输入 | 生成和启动作用 |
| --- | --- | --- |
| 正式内核 | kernel/Image；匹配的 modules、固件和 DTB | 生成阶段形成 boot.img 等材料；启动后负责设备驱动和系统调用 |
| 正式 initrd | rootfs/boot/initrd 及生成过程选择的初始化材料 | 在正式根分区挂载前提供早期用户态能力 |
| 正式 rootfs | rootfs/ 中的 Ubuntu、NVIDIA 包、配置与应用 | 制成 APP 载荷；挂载后运行 systemd、桌面与服务 |
| 刷写临时内核 / initrd | unified_flash 的 boot_flashing.img；可由 _FLASHING_KERNEL 选择 | 从 RCM 启动，在 RAM 中提供传输与写盘环境 |

 

apply_binaries.sh --openrm 为准备好的 sample rootfs 安装 NVIDIA 系统内容；镜像生成阶段再组合内核、initrd、DTB 和根文件系统。两步作用不同。改 rootfs 文件夹不会实时修改既有 system.img，更不会实时修改板上 APP。 [S02][S03] 

### 分析一次内核修改

 

先确认 kernel/Image 是期望的版本，再确认 /lib/modules、驱动固件与 ABI 匹配；随后追踪生成工具放入 rootfs/boot 和 boot.img 的实际文件，最后核对 extlinux 或分区启动模式。目标上 uname -a 的完整构建字符串、启动日志和驱动加载结果共同证明实际运行内容。只看 6.8.x 版本号可能分不清两次构建。 

### 分析一次 rootfs 修改

 

先在主机 rootfs 工作树修改文件或安装匹配的 ARM64 软件包，保留正确所有权与权限；再重新生成 APP 载荷并刷写。主机是 x86_64，不能直接把主机的 /usr 或 x86 二进制拷入目标 rootfs。需要 chroot 时应遵循本版提供的工具与模拟执行环境。 

预建目标用户同样属于 rootfs 修改，必须在生成前完成；默认官方 desktop rootfs 也可留到首次 OOBE 创建。基础系统启动成功并不说明所有可选 CUDA、TensorRT、容器和开发组件已经安装。 

正式 kernel/Image 与刷写临时内核是独立输入。正式系统外设能运行，不保证定制后的刷写环境仍有 USB device mode 和目标存储驱动；反过来，临时环境能写盘也不能替代正式系统验收。 [S04] 

## B6 分区 XML 与生成包 确认真正刷入的对象

 

第二部分 逐模块配置分析 

| 输入 / 输出 | 位置或选择 | 职责 |
| --- | --- | --- |
| 冷启动分区布局 | bootloader/flash_l4t_t264_qspi.xml | QSPI 引导材料的分区定义 |
| RCM 布局 | bootloader/flash_l4t_t264_rcmboot.xml | 下载启动所需材料的组织方式 |
| NVMe 分区布局 | tools/kernel_flash/flash_l4t_t264_nvme.xml | 内核、DTB、ESP、APP 等存储布局 |
| 内部 / 外部生成包 | tools/kernel_flash/images/internal/ 与 external/ | 生成后的镜像、参数、flash.cfg / flash.idx 等索引 |
| 实际刷写包 | unified_flash/out/bsp_images/ | 工具副本、RCM 材料和最终 flash-images 载荷 |

 

XML 的分区名、大小、设备类型、文件名及占位变量，由生成阶段展开成实际布局和载荷。不要把源 XML 里某个符号直接当成最终磁盘偏移；应继续查看生成结果。ROOTFSSIZE 控制相关镜像/分区生成设置，不能单凭它断言运行时扩容后的容量。 [S04] 

### 推荐的追踪顺序

 

每一层都回答“哪个文件、给谁、写到哪里” 

```text
board.conf 的布局变量与目标设备
  → 源 XML、rootfs 与启动输入
  → 生成日志、flash.cfg / flash.idx
  → flash-images/FileToFlash.txt 与实际 payload
  → 写盘日志
  → 目标 lsblk、findmnt 和正式启动结果
```

 

文件名相似不代表是同一物：bootloader 中的工作副本、images 下的生成包、unified_flash 输出中的 payload 和板上分区是不同阶段。不要根据 system.img/raw 后缀或文件大小，自行选一个镜像直接 dd 到磁盘。 

--no-flash 用于完成生成而不执行最终写盘；--flash-only 用于复用已存在的匹配包。改布局、rootfs、内核、DTB 或 BCT 后，应重新生成。复用前还要核对保存的 initrdflashparam.txt、板型、输出目录和目标介质；仅改命令行板名不会把旧包变成新硬件的镜像。 

标准完整流程不需要手工决定每个固件的写入顺序。分区级更新、A/B rootfs、加密和 massflash 属于另行设计的工作流，不能随意拼进完整刷写命令。 

## B7 UEFI 设备 加载模式 内核项与 A/B

 

第二部分 逐模块配置分析 

| 选择层 | 决定什么 | 观察或操作入口 |
| --- | --- | --- |
| UEFI Boot#### / BootOrder | 从哪个设备或 EFI 入口开始 | F11 单次选择；Esc → Boot Maintenance Manager → Boot Options → Change Boot Order |
| L4T Boot Mode | 如何加载 OS | Esc → Device Manager → NVIDIA Configuration → L4T Configuration → L4T Boot Mode |
| extlinux DEFAULT / LABEL | 该系统内的哪个内核启动项 | /boot/extlinux/extlinux.conf；仅在消费此文件的加载方式中生效 |
| Bootloader A/B | 使用哪套冗余引导固件 | nvbootctrl 只读查询；不等同于选择 NVMe |
| 可选 rootfs A/B | APP / APP_b 根系统冗余 | 需在生成时显式配置；启用后有与固件槽的配合关系 |

 

L4TDefaultBootMode 的 0/1/2/3 分别表示 GRUB、文件系统中的正常内核/DTB、分区中的正常内核/DTB、分区中的恢复内核/DTB。菜单名称按实际固件确认。恢复内核模式不等于 BootROM 的 USB Force Recovery。 [S12] 

UEFI 固件二进制、TBCDTB_FILE、L4TConfiguration.dtbo、持久 UEFI 变量和 EFI OS loader 是不同对象。DefaultBootPriority 用于刷写后初始默认顺序；它不是每次启动都覆盖用户保存的顺序。要改变现有顺序，应检查当前 NVRAM 和菜单，而不是只修改主机上的 DTBO 后期待目标立刻变化。 

efibootmgr 不存在时可先通过 UEFI 菜单查看 

```text
# 正式 Thor：先只读确认，避免无依据修改活动槽
cat /sys/class/dmi/id/bios_version
sudo nvbootctrl get-current-slot
sudo nvbootctrl dump-slots-info
sudo efibootmgr -v
```

 

Bootloader A/B 默认启用，不代表根文件系统已经具备 APP_b。不要把“BootOrder、内核菜单项、固件槽、根文件系统槽”当成一个开关；也不要反过来声称 rootfs A/B 启用后与固件槽完全独立切换。本文的普通单 APP 主线不要求改活动槽。 [S14] 

## B8 修改之后 重建什么 怎样证明生效

 

第二部分 逐模块配置分析 

| 修改对象 | 需要重建 / 更新 | 目标验证 |
| --- | --- | --- |
| board.conf 或目标介质 | 重新解析配置并生成匹配完整包 | 布局、启动介质、Machine model 与预期一致 |
| MB1/MB2 BCT、pinmux、电压、EEPROM | 预处理与二进制 BCT；相应 RCM / 冷启动材料 | 串口早期初始化、对应引脚/电气行为；不是仅查 Linux DT |
| Linux DTB / overlay | 相关 DTB、overlay、boot 或文件系统载荷 | 确认 loader 选择来源，再核对运行树、驱动探测和外设 |
| BPMP DTB / 固件 | 匹配的协处理器载荷及包 | 对应固件日志、时钟/电源或受影响功能 |
| 正式内核 / modules | 内核、配套模块、initrd 与 rootfs/boot 的一致载荷 | 完整 uname、模块加载、驱动功能与根挂载 |
| rootfs / 预建用户 / 应用 | 重新生成 APP 载荷 | 登录、文件/包版本、服务和应用运行 |
| 分区 XML / ROOTFSSIZE | 分区及镜像生成；先备份可能被重分区的数据 | lsblk、findmnt、df 与文件系统状态 |
| UEFI 固件 / 默认配置 DTBO | 对应引导载荷；区分已有变量和初始默认值 | bios_version、UEFI 菜单、实际启动选择 |
| 目标 extlinux / BootOrder | 按目标当前状态更新启动选择；无需假定改变了底层 BCT | 下一次实际加载的内核、DTB 和介质 |

 

### 一次修改应保存四种证据

 

• 输入证据：修改前后差异、完整路径、版本和文件哈希；同名文件要标明目录。 

• 生成证据：实际选择的配置、预处理结果、生成索引和最终载荷；保存使用的完整命令。 

• 写盘证据：工具退出码、具体写入与检查记录；通用成功文字不能扩大成未执行的校验。 

• 运行证据：正常冷启动、正式根挂载、实际内核/硬件描述以及修改所针对的功能测试。 

只有未改变镜像内容、且已有包仍与目标匹配时，才把 --flash-only 当作节省重新生成时间的重试方式。若仅修改某个生成目录却未同步源输入，下次生成可能覆盖它；若只修改源输入却复用旧包，本次写盘也可能没有包含修改。 

先在官方基准上理解上述链路，再处理第三方适配与特定主机问题。后续部分的案例用于展示如何取证定位，不替代对应硬件与版本的配置验证。 

## C1 第三方载板改变哪些配置

 

第三部分 第三方载板适配 

这一部分采用原生 Ubuntu 主机。先完成第一部分的官方流程理解，再为第三方载板建立独立工作树；不能仅把官方开发板的板名换成一个相似名称。下面以本次 CES Y-C28 / JAT-001、P3834-0008 和 R38.2.1 为实证，其他载板须取得各自厂商适配包。 

| 硬件差异 | 通常涉及的文件或设置 | 需要谁确认 |
| --- | --- | --- |
| 引脚复用与电压 | pinmux、GPIO、pad voltage 的 DTS/DTSI；早期 BCT | 载板厂商按原理图和电气要求提供；用户核对型号与修订 |
| 供电与复位 | PMIC、电源时序、reset、相关 BCT 与设备树 | 厂商确认电源树和启动条件；串口用于定位失败阶段 |
| PCIe USB UFS等连接 | UPHY lane、控制器模式、时钟、Linux DTB；必要时驱动 | 厂商说明实际布线与支持端口；上板验证枚举和功能 |
| EEPROM与板级识别 | board conf、MB2 EEPROM参数、板号与SKU | 厂商说明是否有CVB EEPROM；不能仅凭I2C报错关闭读取 |
| 内核与外设驱动 | Image、DTB、/lib/modules、固件和用户态驱动 | 厂商交付匹配内核/模块ABI；按接口逐项验收 |
| 存储与启动策略 | QSPI/NVMe XML、UEFI配置、启动项和容量 | 厂商确认启动介质；操作者核对目标盘与保留数据 |

 

### 把配置选择和适配责任分开

 

board conf 负责选中已有材料；它不会自动推导载板布线。Linux DTB、BPMP DTB、UEFI DTB 和 MB1/MB2 BCT 分别服务于不同阶段；改 Linux DTB 不能代替早期 EEPROM 或电源配置修复。厂商也可能复用官方板号命名的公共文件，须追踪最终选择和内容。 [S05] 

### 本次包实际交付到哪里

 

CES 包交付 2 个板型配置、10 个启动配置文件、1 个内核和1个Linux DTB；未单独交付完整rootfs、kernel modules文件树或替换UEFI。它能启动，不代表全部外设和模块ABI已经验收；这些边界应保留在交付记录中。 

第三方新树：~/thor-ces/r38.2.1/Linux_for_Tegra。第一部分的官方新树 ~/thor-native/r38.2.1/Linux_for_Tegra 保留独立；本次故障证据树 /home/USER/thor-flash/test/Linux_for_Tegra 只用于案例追溯。 

## C2 CES包的全部文件与安装顺序

 

第三部分 第三方载板适配 

在 ~/thor-ces/r38.2.1 中放入已核对的官方 BSP、Sample Rootfs 和 CES 三个包。按第一部分在该新目录解开 BSP、以 sudo 解开 rootfs、安装主机依赖，再运行 sudo ./apply_binaries.sh --openrm；完成后才叠加下面的厂商文件。不要直接复制本次已改动的工作树作为官方原版。 

CES原包目录清单；不是执行脚本 

```text
ces-Linux_R38.2.1_bsp/
├─ ces-install.sh                 # 安装脚本，另计
└─ Linux_for_Tegra/               # 以下正好14个载荷文件
   ├─ ces-agx-thor-jat-001.conf.common
   ├─ ces-agx-thor-p3834-0008-jat-001-nvme.conf
   ├─ kernel/Image
   ├─ kernel/dtb/ces-agx-thor-jat-001-p3834-0008-nv.dtb
   └─ bootloader/
      ├─ Thor-ces-thor-jat-001-gpio-default.dtsi
      ├─ Thor-ces-thor-jat-001-padvoltage-default.dts
      ├─ Thor-ces-thor-jat-001-padvoltage-default.dtsi
      ├─ Thor-ces-thor-jat-001-pinmux.dts
      ├─ Thor-ces-thor-jat-001-pinmux.dtsi
      ├─ tegra234-mb2-bct-common.dtsi
      └─ generic/BCT/
         ├─ Thor-ces-thor-jat-001-gpio-default.dts
         ├─ Thor-ces-thor-jat-001-padvoltage-default.dts
         ├─ Thor-ces-thor-jat-001-pinmux.dts
         └─ tegra264-mb2-bct-common.dtsi
```

 

仅在上述官方rootfs准备成功后执行厂商安装 

```text
cd ~/thor-ces/r38.2.1
tar -xf ces-Linux_R38.2.1_bsp.tar
cd ces-Linux_R38.2.1_bsp
sudo bash ./ces-install.sh
cd ../Linux_for_Tegra
test -f ces-agx-thor-p3834-0008-jat-001-nvme.conf
test -f kernel/dtb/ces-agx-thor-jat-001-p3834-0008-nv.dtb
```

 

本版 ces-install.sh 用 cp -rf 合并覆盖同级 Linux_for_Tegra，并写入 rootfs/etc/ces/linux_ver.version；不清理目标独有旧文件、不生成 system.img，也不执行刷写。脚本内 apply_binaries 调用被注释，所以不能省略前面的官方准备。用 sudo bash 执行，无须把权限改成777。 

tegra234 文件属于包内实存文件，不代表它在T264流程生效。真正选择的是 tegra264 MB2配置。完整大小、路径及官方包成员关系见附录文件清单。 

本板入口为ces-agx-thor-p3834-0008-jat-001-nvme.conf；它选择CES common、kernel/Image、ces-agx-thor-jat-001-p3834-0008-nv.dtb，以及Thor-ces-thor-jat-001命名的pinmux与padvoltage。QSPI/NVMe布局仍复用本版T264 XML；不能只换DTB却遗漏早期配置。 

## C3 EEPROM配置被同名旧副本遮蔽

 

第三部分 第三方载板适配 

本次第01轮停在MB2：CVB eeprom not found、I2C实例1向0xac读取256字节、Task 0x3e / 0x4f1e050d；尚未进入Linux。证据树在 /home/USER/thor-flash/test/Linux_for_Tegra：厂商源与generic/BCT中CVB已为0，bootloader根目录旧副本仍为0x100。主DTS的相对include先读到根目录同名文件。 

| 文件位置 | 本次观察与用途 |
| --- | --- |
| 厂商包 bootloader/generic/BCT/tegra264-mb2-bct-common.dtsi | 可信的本板交付配置；CVB=0，CVM=0x100 |
| 已安装 bootloader/generic/BCT/同名文件 | 源配置已经正确，单独查看它会遗漏问题 |
| 工作副本 bootloader/tegra264-mb2-bct-common.dtsi | 旧CVB=0x100；实际CPP sibling include命中它 |

 

下列复核针对CES新树已经生成工作副本的情形。全新目录若没有根目录主DTS/旧副本，不要为了套用修复而创建它们；按C4完整生成，并以工具日志的实际cwd与include链复核。若厂商配置或差异不符，不执行后面的同步。 

只读复核；diff发现差异返回1是正常行为，须阅读差异 

```text
cd ~/thor-ces/r38.2.1/Linux_for_Tegra/bootloader
sudo cpp -nostdinc -x assembler-with-cpp \
  -D IN_DTS_CONTEXT -D ENABLE_DCE -D ENABLE_PVA \
  tegra264-mb2-bct-misc-p3834-xxxx-p4071-0000.dts \
  > /tmp/ces-mb2-before.dts
grep -n -E 'cv[mb]_eeprom_read_size' /tmp/ces-mb2-before.dts
cd ..
COMMON=tegra264-mb2-bct-common.dtsi
SRC=../ces-Linux_R38.2.1_bsp/Linux_for_Tegra/bootloader/generic/BCT/$COMMON
sudo cmp "$SRC" "bootloader/generic/BCT/$COMMON"
sudo diff -u "bootloader/$COMMON" "$SRC"
```

 

限定修复条件：厂商源与已安装generic副本一致；CPP确实得到CVB=0x100；diff唯一差异是厂商将CVB读取大小设为0，且CVM仍为0x100。只有三项全部成立，才备份并同步厂商原文件；不使用全局忽略EEPROM或修改其他板的参数。 

仅在限定条件成立后同步；沿用上段当前目录和变量 

```text
BACKUP=../ces-eeprom-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP"
sudo cp -a "bootloader/$COMMON" "$BACKUP/old-common.dtsi"
sudo cp "$SRC" "$BACKUP/vendor-common.dtsi"
cp /tmp/ces-mb2-before.dts "$BACKUP/"
sudo cp -a "$SRC" "bootloader/$COMMON"
```

 

同步后重复CPP复核：应为CVB=0、CVM=0x100，并保存结果；下一步必须完整重新生成和刷写，不用旧包--flash-only。本案第02轮已越过MB2并进入临时Linux，是修复生效的动态证据。 [S05] 

## C4 原生Linux完整刷写与验收

 

第三部分 第三方载板适配 

此流程限定本版CES板型、原生Ubuntu主机和已完成C2准备/C3必要复核的新树。刷写会改写目标QSPI与NVMe；先确认板型、目标盘和备份，按载板说明进入Recovery，确认USB APX枚举，并保持稳定供电和串口日志。 

原生Ubuntu的Bash；首次或修改输入后完整生成并刷写 

```text
cd ~/thor-ces/r38.2.1/Linux_for_Tegra
BOARD=ces-agx-thor-p3834-0008-jat-001-nvme
lsusb -d 0955:7026
set -o pipefail
LOG=../ces-full-$(date +%Y%m%d-%H%M%S).log
sudo ./l4t_initrd_flash.sh "$BOARD" internal 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}
printf 'Flash exit code: %s\n' "$RC"
```

 

internal是这份CES配置的调用约定：board conf同时选择QSPI布局与EXTERNAL_DEVICE=nvme0n1p1。通过展开配置、FileToFlash和实际写盘日志确认目标，不能把internal解释为Ubuntu写入内置eMMC。 

| 发生的改变 | 需要做什么 |
| --- | --- |
| rootfs文件、软件包或账号预置 | 重新生成APP镜像；按本板完整流程刷写 |
| Image、模块、Linux DTB或overlay | 先核对内核/模块/固件匹配，再重建相关镜像与完整包 |
| BCT、pinmux、EEPROM参数、board conf | 复核最终include与配置，再完整生成；不能复用旧启动材料 |
| 分区XML、介质、容量、板型 | 重新确认目标和备份，按新布局完整生成；旧包不适用 |
| 输入未变，仅上次传输失败 | 确认现成包完整、同板同布局后才考虑--flash-only；仍需Recovery |
| 仅临时选择UEFI启动项 | 在UEFI菜单选择并验证；这与重生成DTB/BCT或切换A/B槽不同 |

 

### 把刷写完成与整机验收分开

 

先核对刷写退出码、失败关键句及分区写入结果，再正常启动确认内核、NVMe根分区、Ubuntu用户空间和首次配置。进入OOBE只说明系统已走到该阶段；账号设置、桌面显示、网络、USB、PCIe、GPU和其他外设须分别检查。 

第三方验收还应确认Machine model、实际内核构建、rootfs版本和载板接口与厂商交付一致，保留输入差异、生成索引、串口启动和外设测试记录。本次主机兼容问题与最终实测结果统一放在第四部分。 

## D1 本次环境与六轮尝试时间线

 

第四部分 本次 Windows 和 WSL 调试复盘 

前三部分说明了原生 Linux 流程与载板适配。本次实际环境为 Windows x64、WSL2 Ubuntu-22.04、CES JAT-001/Y-C28、R38.2.1、QSPI + NVMe，调试串口 COM4。BSP 位于 /home/USER/thor-flash/test/Linux_for_Tegra。以下时间均为 2026-10-22 UTC+8。 

| 轮次与时间 | 第一处关键失败 | 处理与结果 |
| --- | --- | --- |
| 01 17:42–17:49 退出1 | MB2 读取 CVB EEPROM 失败，临时 Linux 与 ADB 没有出现 | 第三部分 C3 所述旧 include 遮蔽；同步正确 BCT 后重新生成。此项不是 WSL USB 根因。 |
| 02 17:54–18:03 退出1 | 临时 Linux 已起来，WSL ADB 10 MiB 上传挂起，部分分区已开始写入 | 原生 Windows ADB 对照成功，改为 Windows 数据传输。 |
| 03 18:41 退出1 | RCM reset 后短窗口内设备节点未就绪，OSError 63 | 同一端口等待扩大到30秒，保留节点与路径验证。 |
| 04 18:44–18:45 退出1 | Windows 中转后 wrapper / nvdd 无执行位，报126 | push 后直接恢复 Linux mode；wrapper、上传、MD5和回读验证通过。 |
| 05 18:50–18:52 退出1 | 7100 / WinUSB 枚举正常，但原生 ADB server 未及时识别目标 | 修正专用 server 生命周期和启动顺序；底层触发原因未完全证实。 |
| 06 19:00:50–19:13:07 退出0 | 写盘与扩容完成，热重启仍回 APX | 不按REC断电上电后进入正式系统；NVMe 根挂载、Ubuntu 登录与OOBE有证据。 |

 

准备阶段另出现过 lbzip2 缺失、未用 sudo、sample rootfs 未正确解压，以及 attach 时没有运行中的 WSL2。它们分别对应主机依赖、rootfs 准备与 USB 附加前置，按第一部分的步骤可逐项避免。 

前五轮失败并非同一错误重复发生。必须区分原本的板级配置问题、USB 数据通道问题，以及引入兼容适配后新增的权限和 server 时序问题。 

## D2 WSL USB 的阶段切换与对照证据

 

第四部分 本次 Windows 和 WSL 调试复盘 

| 本次 USB 身份 | 目标所处阶段 | 本机最终方案的归属 |
| --- | --- | --- |
| 0955:7026 APX | Recovery / RCM 下载 | 交给 WSL，Linux 工具完成 RCM。 |
| 0955:7100 ADB | RAM 中的临时刷写 Linux | 留在 Windows，保持 Not shared，由 Windows ADB 接收。 |
| 0955:7020 | 正常系统 USB 复合功能 | 正常开机后的设备身份，不是待刷 APX。 |
| CH340 COM4 | 独立串口 | Windows 采集启动日志，与刷写 USB 分开。 |

 

Windows 本次 BUSID 示例 重新插口后不得盲目照抄 

```text
# Windows PowerShell：先启动并保持 WSL 会话
wsl -d Ubuntu-22.04
# 另一个管理员 PowerShell：先用 list 核对当时 BUSID
usbipd list
# 仅当 2-1 此刻确实为 APX 0955:7026
usbipd bind --busid 2-1
usbipd attach --wsl --busid 2-1 --auto-attach
```

 

bind 保存共享设置，attach 才把当前设备交给 WSL。Persisted 里有 APX 不能证明当前在线；以 Connected 和 WSL 中 lsusb 的即时状态判断。auto-attach 要覆盖 APX 重枚举，但本机最终方案不能把重新出现的 7100 一律交给 WSL。 [S08][S09] 

| 测试 | 实际结果与能支持的结论 |
| --- | --- |
| WSL USBIP 路径 | 多个 ADB / 强制绑定组合的10 MiB上传均约25秒超时；说明当时这条数据路径不稳定。 |
| 同设备 Windows 原生路径 | 完整命令约0.45秒，ADB报告0.247秒 / 40.6 MB/s；MD5与回读通过，目标收发数据能力正常。 |

 

没有定位到具体哪个 filter、内核缺陷或线缆因素必然造成超时。bhound7 / hrdevmon 警告只是线索；不能据此卸载无关驱动，也不能推论所有 WSL 都无法刷 Thor。SDK Manager 的 Windows 支持与本次手工混合适配也不是同一工作流。 [S06][S07] 

## D3 数据通道适配及其引入的问题

 

第四部分 本次 Windows 和 WSL 调试复盘 

本机保留 Linux 镜像生成和 RCM 下载，只把 initrd 阶段的 ADB 数据通道改为 Windows 原生 USB。BSP 的 adb 入口被一个 Python 适配器替换，内部调用 Windows adb.exe；目标布局和固件校验逻辑不因此改变。 

| 改动 | 为什么需要 | 本次验证 |
| --- | --- | --- |
| flash/adb 与 marker | 转换 Linux/Windows路径；.windows-native 选择该模式 | 源和 generated 都安装，内容已核对一致。 |
| 上传后恢复 mode | NTFS中转不能反映 Linux执行位；wrapper不能先执行自己来chmod | 直接 adb shell chmod；wr_sh、nvdd、0600文件和回读均通过。 |
| bootburn_adb.py | 设备归Windows时，WSL lsusb不能作为ADB就绪依据 | 按目标serial执行get-state；无marker保留原Linux分支。 |
| ADB server 生命周期 | WSL interop客户端可能抢先起server，导致主机时序竞争 | 固定 -H127.0.0.1 -P15037；Windows在7100出现后启动，厂商重启分支改为reconnect offline。 |
| bootburn_lib.py | APX reset后设备与节点需要就绪时间 | 同端口等待30秒并验证bus/dev节点，保留后续路径检查。 |

 

第04轮的126错误是使用 Windows 中转后新增的适配问题；不是原始官方 Linux 脚本本身缺少 chmod。第05轮恢复过程中重新建立原生 server 后可见设备，后续生命周期修复成功，但未据此认定唯一的底层驱动原因。 

适配器只覆盖本次实际使用的单文件 push、目录目标 pull 和相关 ADB 选项。它不是通用 adb 的完整实现，不能直接拿去替换其他版本工具。专用15037端口与默认5037分开，避免干扰无关ADB会话。 

临时系统还使用过软件 Force Recovery helper；它依赖具体内核 reboot 处理路径，不作为标准刷机前置。物理 REC 过程仍需按载板说明执行。 

## D4 适配部署与重新生成的边界

 

第四部分 本次 Windows 和 WSL 调试复盘 

附件“补丁与部署/DEPLOY.txt”给出匹配基线、备份、安装 shim、建立 marker、应用两个补丁和核查生成工具的分节命令。当前已修复工作树无需重复安装；归档脚本中的本机路径、端口、serial、BUSID和COM号需迁移时审查。 

| 本机位置或参数 | 已使用的值 |
| --- | --- |
| Windows工作目录 | C:\ThorFlash\work |
| WSL工作目录 | /home/USER/thor-flash/test/Linux_for_Tegra |
| ADB程序 | work/windows-adb/platform-tools/adb.exe，37.0.1 |
| serial / BUSID / COM | THOR_SERIAL / 2-1 / COM4 |
| source工具 | unified_flash/tools/flashtools/ |
| generated工具 | unified_flash/out/bsp_images/tools/flashtools/ |

 

WSL 所有检查通过才继续 不一致先检查生成与部署记录 

```text
cd /home/USER/thor-flash/test/Linux_for_Tegra
src=unified_flash/tools/flashtools
gen=unified_flash/out/bsp_images/tools/flashtools
cmp "$src/flash/adb" "$gen/flash/adb"
cmp "$src/bootburn_t264_py/bootburn_adb.py" \
    "$gen/bootburn_t264_py/bootburn_adb.py"
cmp "$src/bootburn_t264_py/bootburn_lib.py" \
    "$gen/bootburn_t264_py/bootburn_lib.py"
test -f "$src/flash/adb.windows-native"
test -f "$gen/flash/adb.windows-native"
```

 

只改 out 下的工具可能在重建时丢失；只改 source 后直接 --flash-only 则可能仍调用旧 generated 工具。marker 缺失时按 DEPLOY 中的条件分支显式补齐并记录，不假定打包器一定复制额外文件。 

重新生成用 --no-flash，完成后再开 Windows ADB helper 并立即 --flash-only。helper 只等7100出现180秒；不能在耗时的生成开始前就启动它，再期待一直等到写盘。这是复现预防项，不是已证明的本次某轮根因。 

## D5 本机重刷与日志启动顺序

 

第四部分 本次 Windows 和 WSL 调试复盘 

此页仅用于已保留本次适配的工作树，执行会重刷目标。先准备Recovery与WSL的APX通道，确认COM4未被其他终端占用。使用全新日志目录；串口/USB采集均有45分钟上限，旧serial-ready.txt不证明采集仍存活。 

WSL 需要重新生成时先完成此步 再核对D4的工具一致性 

```text
cd /home/USER/thor-flash/test/Linux_for_Tegra
sudo ./l4t_initrd_flash.sh --no-flash \
  ces-agx-thor-p3834-0008-jat-001-nvme internal
```

 

### 在各 Windows PowerShell 窗口设置相同变量

 

Windows 脚本按自身目录寻找ADB 不能从任意附件解压位置直接启动 

```text
$taskRoot = 'C:\ThorFlash'
$py = "$env:USERPROFILE\.cache\codex-runtimes\" +
  'codex-primary-runtime\dependencies\python\python.exe'
$out = Join-Path $taskRoot 'outputs\thor-reflash-YYYYMMDD-HHMMSS'
# 把占位时间换为本轮唯一名称，每个窗口完全一致
New-Item -ItemType Directory -Force -Path $out | Out-Null
```

 

同时保留WSL与APX auto-attach会话 长时间命令各占一个窗口 

```text
# 窗口1：串口采集，确认进程存活且 serial-ready.txt 已生成
& "$taskRoot\work\capture-thor-serial.ps1" -OutputDir $out

# 窗口2：USB状态监视
& $py "$taskRoot\work\monitor-thor-usb.py" $out

# 窗口3：等待7100；启动后立即执行窗口4，不等此命令结束
& $py "$taskRoot\work\start-thor-adb-after-enumeration.py" $out

# 窗口4：从WSL启动实际刷写，复用成功生成的包
& $py "$taskRoot\work\run-thor-flash.py" $out --flash-only
```

 

Windows helper等待7100且Not shared，随后启动15037 server，再等目标ready最长25秒。THOR_ADB_READY只说明数据通道连上；继续观察flash.log、serial.log和最终退出码。写盘完成并验收正式启动后，用stop-capture.flag通知采集退出，并单独停止15037 server。 

完整命令、收尾与迁移配置见附件。未修改镜像内容且包完整时可省略本页生成步骤；改变BCT/DTB/rootfs/布局后不能省略。 

## D6 最终结果与证据边界

 

第四部分 本次 Windows 和 WSL 调试复盘 

| 验收项目 | 本次实际证据 |
| --- | --- |
| 流程完成 | 第06轮退出0，工具耗时约735.68秒；不含前期准备和调试。 |
| 写入清单 | 75条分区任务，引用42个唯一输入文件；BCT在运行时可另组合副本载荷，不等于75个文件或75次独立MD5。 |
| 显式校验 | 日志75条通用成功提示、69条target md5与对应校验记录；APP整镜像MD5回读未独立证实。 |
| APP与文件系统 | 8,911,298,560字节载荷完成分块写入，writer退出成功；e2fsck、resize2fs、sync完成。 |
| 正式启动 | 不按REC断电上电后Direct Boot，CES #61内核，Machine model为CES AGX Thor JAT-001。 |
| 根挂载与用户空间 | NVMe APP ext4读写挂载，扩容为121,397,753个4KiB块；Ubuntu24.04.3登录与NVIDIA OOBE已出现。 |

 

源码中的大文件分支只在指定条件下执行checkMd5，通用成功文字不能单独证明整文件回读校验。因此“刷写完成且能从NVMe正常启动”有证据，“75项全部独立MD5通过”不成立。 

| 第06轮原始日志 LF 物理行 | 对应证据 |
| --- | --- |
| flash.log 24439–24452 | APP末段与writer退出 |
| flash.log 24503–24515 / 24723–24735 | 文件系统检查 |
| flash.log 24747 / 24773 / 24779 | 扩容、成功、END与退出码 |
| serial.log 2689 / 2699 / 2741 | Direct Boot、CES内核、NVMe PARTUUID |
| serial.log 3286 / 3376 / 3614 / 3818 | 根挂载、读写、OOBE、Ubuntu登录 |

 

热重启回APX的底层原因仍未完全证实；正常断电上电成功。未创建用户账号，未完成GPU、网络和全部外设验收；dnsmasq失败未阻止启动，但USB DHCP应另测。日志含回车刷新，引用采用LF物理行而非splitlines的计数。 

公开技术附件提供文件与payload清单、适配脚本、补丁、部署说明及SHA256；完整原始日志保留于本地证据归档。日志行号用于定位本次实测记录。 

## 参考资料与附件阅读顺序

 

本手册固定Jetson Linux R38.2.1。官方资料于2026年10月22日核对；具体脚本路径、配置和运行时差异来自本地同版文件及已有日志。先读主文档四部分，再按需要查下列附件。 

| 附件 | 使用方式 |
| --- | --- |
| 标准流程代码与文件清单 | 结合A9/A10看完整调用链、输入输出、主机/目标执行端及依赖包。 |
| 配置盘点与厂商文件 | 结合B/C部分看官方选择与本次CES覆盖，避免混用源目录、生成副本和实际目标。 |
| 本次75项写入任务表 | CES实测索引与运行时映射；不是重新生成的官方devkit默认结果。 |
| 补丁与部署和适配脚本 | 仅用于第四部分本机兼容方案；按DEPLOY逐项核对，不能整包直接执行。 |
| 六轮复盘与证据索引 | 公开附件提供复盘与证据定位；完整原始日志保留本地，日志引用采用LF物理行。 |

 

S01 [JetPack 7.0 下载归档](https://developer.nvidia.com/embedded/jetpack/downloads/archive-7.0) 

S02 [R38.2.1 Release Notes](https://docs.nvidia.com/jetson/archives/r38.2.1/ReleaseNotes/Jetson_Linux_Release_Notes_r38.2.1.pdf) 

S03 [R38.2.1 Quick Start](https://docs.nvidia.com/jetson/archives/r38.2.1/DeveloperGuide/IN/QuickStart.html) 

S04 [Flashing Support Jetson Thor](https://docs.nvidia.com/jetson/archives/r38.2.1/DeveloperGuide/SD/FlashingSupportJetsonThor.html) 

S05 [Jetson Thor Adaptation and Bring Up](https://docs.nvidia.com/jetson/archives/r38.2.1/DeveloperGuide/HR/JetsonModuleAdaptationAndBringUp/JetsonThorAdaptationBringUp.html) 

S06 [SDK Manager Windows Direct Flash](https://docs.nvidia.com/sdk-manager/install-with-sdkm-jetson-direct-flash/index.html) 

S07 [SDK Manager WSL Systems](https://docs.nvidia.com/sdk-manager/wsl-systems/index.html) 

S08 [Microsoft WSL USB](https://learn.microsoft.com/en-us/windows/wsl/connect-usb) 

S09 [usbipd win WSL Support](https://github.com/dorssel/usbipd-win/wiki/WSL-support) 

S10 [Google Platform Tools](https://developer.android.com/tools/releases/platform-tools) 

S11 [Jetson Thor Boot Flow](https://docs.nvidia.com/jetson/archives/r38.2.1/DeveloperGuide/AR/BootArchitecture/JetsonThorBootFlow.html) 

S12 [UEFI Adaptation](https://docs.nvidia.com/jetson/archives/r38.2.1/DeveloperGuide/SD/Bootloader/UEFI.html) 

S14 [Update and Redundancy](https://docs.nvidia.com/jetson/archives/r38.2.1/DeveloperGuide/SD/Bootloader/UpdateAndRedundancy.html) 

部分官方页面仍含旧平台示例，主机版本以R38.2.1发布说明为准；T234/Orin板名、XML和寄存器示例不能直接套用Thor。第三方载板按对应硬件和厂商版本核对。标准流程、源码说明和本次实证在文中分别标明。 

返回顶部
