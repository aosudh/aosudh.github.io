---
title: "Blackwell-Next CXL DVSEC：代码考据与最终结论"
published: 2026-06-24
description: "全树核查“Blackwell-Next”在 Linux 内核源码里的唯一落地点——nvgrace-gpu 驱动新增的 CXL DVSEC 显存就绪探测路径，证实传输层始终是 NVLink-C2C。"
image: "/assets/covers/blackwell-cxl.svg"
category: "GPU / 算力"
tags: ["NVIDIA", "NVLink", "CXL"]
pinned: false
draft: false
---

> [!TIP]
> 本页为 **Astro + Mizuki** 自动导入预览版；若需查看原始手写排版（含原版内联 SVG 与附件下载），可访问 [原版 HTML 正文](/legacy-posts/blackwell-next-cxl-dvsec.html)。

>  

起点：微信文章提到 NVIDIA "Blackwell-Next"。本文在 GitHub / Linux 内核源码与 LKML 上全量核查了这个词唯一的落地点，梳理相关代码，并就"VR200 是否从 PCIe+C2C 变成 CXL+C2C、提升缓存一致性"给出结论。  

## 一、最终结论（先看这个）

 

**命题：Rubin 时代的 VR200 会从"传统 PCIe + C2C"变成"CXL + C2C"，从而提升缓存一致性。** 

这个命题**方向对、表述错**，错在把两个不同层级的东西混在了一起。   命题逐条评估           

| 子命题 | 评估 |
| --- | --- |
| VR200 从 PCIe+C2C 变成 CXL+C2C | ✗ **概念错位**。CPU↔GPU 一致性主干从 Grace Hopper → Grace Blackwell → Vera Rubin **一直是 NVLink-C2C**，根本没有"PCIe 阶段"可换。PCIe 与 CXL 在 Vera 上是**并存能力**（Vera 同时支持 PCIe6 与 CXL 3.1）。 |
| 因此缓存一致性提升 | ✗ **不能由这段代码推出**。这段代码改的是"显存就绪状态怎么上报"，与"运行时一致性强度"是两回事。 |
| 这段 CXL DVSEC 代码 = 纯 host 端探测 | ✗ **DVSEC 长在 GPU 自己的 PCI 配置空间里**，host 读的是 GPU 暴露的寄存器，这从头到尾就是 CPU↔GPU。 |
| NVIDIA 在向更标准化 / CXL-native 的"设备内存暴露模型"演进 | ✓ 代码 + Vera 支持 CXL 3.1 共同支持的合理解读。 |
| Rubin 一致性确实增强了 | ✓ 但功劳在 **NVLink-C2C 翻倍到 1.8 TB/s**，**不是**这段 CXL DVSEC 探测逻辑。 |

  

### 准确的两层划分

   Grace Blackwell → Blackwell-Next 的两层变化        

| 层 | Grace Blackwell → Blackwell-Next 的变化 |
| --- | --- |
| 一致性**传输 / 带宽** | 仍是 **NVLink-C2C（1.8 TB/s）**。CXL-over-PCIe6 与它差一个量级，不可能替代。 |
| 内存**暴露 / 描述模型** | **从 NVIDIA 私有方案 → CXL HDM 标准化**。GPU 改用标准 CXL DVSEC 结构来描述自己的 HBM 与就绪状态。这才是"一致性相关变化"的真实落点。 |

  

**一句话结论：**这段代码反映的是"GPU 显存的就绪状态 / 内存描述改用 CXL 标准寄存器上报"，是**接口标准化信号**；Rubin 的一致性增强是真的，但来源是 NVLink-C2C 1.8 TB/s，与这段 CXL DVSEC 探测逻辑不是同一回事。所以不是 "PCIe+C2C → CXL+C2C"，而是 **"GPU 内存暴露接口：私有 → CXL 标准化"，传输层 NVLink-C2C 不变**。 

它的现实意义在 **NVLink Fusion 第三方硅互操作、统一内存模型、内存池化语义**，而不是"把已有的 C2C 一致性再调强"。 

---

 

## 二、"Blackwell-Next" 在源码中的唯一落地点

 

全树搜索，"Blackwell-Next" 只出现在**一个文件、一处注释**： 

```text
drivers/vfio/pci/nvgrace-gpu/main.c   (master ~1437 行)
```

 
 
- 目录极简：`main.c` + `Makefile`(3 行) + `Kconfig`(10 行) 
- 模块名 `nvgrace-gpu-vfio-pci`，是 `vfio-pci` 的 variant 驱动 
- 作者：Ankit Agrawal / Aniket Agashe（均 NVIDIA） 
- 用途：把 Grace 系（CPU↔GPU cache-coherent 互联）GPU 的显存以"假 BAR"形式 passthrough 给虚拟机 
 

>  

注意：GitHub 仓库搜索 `blackwell-next` 返回的 3 个结果（`zhiquan0319/blackwell-project`、`abonaidesu-crypto/QuantumCache-CUDA`、`nabe2030/bevformer-blackwell-fp4-fp8`）全是 "Next.js / Next-Generation / next step" 之类的巧合匹配，与代号无关。GitHub Code Search API 需要鉴权，故下述代码均直接从 `raw.githubusercontent.com` 拉取核对。  

---

 

## 三、相关 GitHub PR / Patch（来龙去脉）

 

需要厘清一个**容易混淆的点**：2024–2025 那批标题含 "blackwell" 的系列引入的是 **legacy BAR0 轮询**路径，针对的是 **Grace Blackwell (GB200/GB300)**；而 **"Blackwell-Next" 这个词**是 2026 年 6 月才提交、进入 **Linux 7.2 merge window** 的新改动引入的 **CXL DVSEC 路径**。 

### 3.1 引入 "Blackwell-Next" 的改动（CXL DVSEC 路径，Linux 7.2）

 
 
- Phoronix 报道：[https://www.phoronix.com/news/NVIDIA-Blackwell-Next-VFIO](https://www.phoronix.com/news/NVIDIA-Blackwell-Next-VFIO) 
- 主线驱动文件（已合并）：[https://github.com/torvalds/linux/blob/master/drivers/vfio/pci/nvgrace-gpu/main.c](https://github.com/torvalds/linux/blob/master/drivers/vfio/pci/nvgrace-gpu/main.c) 
 

### 3.2 更早的 "Enable grace blackwell boards" 系列（legacy BAR0 路径，2024–2025）

   "Enable grace blackwell boards" 补丁版本          

| 版本 | LKML / Patchwork 链接 |
| --- | --- |
| v1 (2024-10-06) | [lore.kernel.org/lkml/20241006102722.3991-1-ankita@nvidia.com](https://lore.kernel.org/lkml/20241006102722.3991-1-ankita@nvidia.com/) |
| v4 (2025-01-17) | [lore.kernel.org/kvm/20250117233704.3374-2-ankita@nvidia.com/T/](https://lore.kernel.org/kvm/20250117233704.3374-2-ankita@nvidia.com/T/) |
| v6 (2025-01-24) | [lore.kernel.org/lkml/20250124183102.3976-1-ankita@nvidia.com/T/](https://lore.kernel.org/lkml/20250124183102.3976-1-ankita@nvidia.com/T/) |
| v6 cover (Patchwork) | [patchwork.kernel.org/project/kvm/cover/20250124183102.3976-1-ankita@nvidia.com](https://patchwork.kernel.org/project/kvm/cover/20250124183102.3976-1-ankita@nvidia.com/) |

  

v6 系列 4 个 commit： 
 
- `vfio/nvgrace-gpu: Read dvsec register to determine need for uncached resmem` 
- `vfio/nvgrace-gpu: Expose the blackwell device PF BAR1 to the VM` 
- `vfio/nvgrace-gpu: Check the HBM training and C2C link status` 
- `vfio/nvgrace-gpu: Add GB200 SKU to the devid table` 
 

---

 

## 四、核心机制：两条"设备就绪"探测路径

 

本质：给"GPU 复位 / 上电后，显存是否 ready"的判定**新增一条基于 CXL DVSEC 的路径**，与原有 BAR0 轮询路径并存。靠一个字段分流。 

### 4.1 设备结构体与字段（main.c:59）

 

```text
struct nvgrace_gpu_pci_core_device {
    struct vfio_pci_core_device core_device;
    struct mem_region usemem;       /* VM 可用的 cached 显存 */
    struct mem_region resmem;       /* 末尾切出的 non-cached 区 */
    struct mutex remap_lock;
    void __iomem *bar0_base;
    bool has_mig_hw_bug;
    bool reset_done;                /* GPU 刚被 reset */
    /* CXL Device DVSEC offset; 0 if not present (legacy GB path) */
    int  cxl_dvsec;                 /* ← 关键：分流字段 */
};
```

 

### 4.2 探测发生在 probe()，对象是 GPU 自己（main.c:1336）

 

```text
nvdev->cxl_dvsec = pci_find_dvsec_capability(pdev, PCI_VENDOR_ID_CXL,
                                             PCI_DVSEC_CXL_DEVICE);
```

 

>  

**这是回答"是不是纯 host 端探测"的关键证据：**`pdev` 是**那块 GPU**。`pci_find_dvsec_capability` 在 **GPU 自己的 PCI 配置空间**里找 CXL DVSEC capability。host(Vera) 上的 VFIO 驱动只是去**读 GPU 暴露的寄存器**。 

探测到 CXL DVSEC → 走 Blackwell-Next 路径；探测不到 → 走 legacy Grace Blackwell / Grace Hopper 路径。  

### 4.3 两条路径对比

   Legacy 路径 vs Blackwell-Next 路径           

| 维度 | Legacy 路径 (GH / GB) | Blackwell-Next 路径 |
| --- | --- | --- |
| 判定函数 | `nvgrace_gpu_wait_device_ready_legacy()` | `nvgrace_gpu_wait_device_ready_cxl()` |
| 读取位置 | BAR0 两个寄存器 | **GPU 的 PCI config space → CXL DVSEC** |
| 具体信号 | `C2C_LINK`(0x1498) + `HBM_TRAINING`(0x200BC) 均 == `0xFF` | `MEM_INFO_VALID` + `MEM_ACTIVE` 位 |
| 超时 | 固定 30s | 1s 出 `MEM_INFO_VALID`，再 ~256s 内出 `MEM_ACTIVE` |
| 加锁 | `memory_lock` 锁内轮询 | 锁外轮询（最长 256s），锁内只快速 check |

  

---

 

## 五、Blackwell-Next 专属新增代码块

 

### 5.1 CXL 超时解码 + active 判定（main.c:271–289）

 

```text
/*
 * Decode the 3-bit Memory_Active_Timeout field from CXL DVSEC Range 1 Low
 * (bits 15:13) into milliseconds. Encoding per CXL spec r4.0 sec 8.1.3.8.2:
 * 000b = 1s, 001b = 4s, 010b = 16s, 011b = 64s, 100b = 256s,
 * 101b-111b = reserved (clamped to 256s).
 */
static inline unsigned long cxl_mem_active_timeout_ms(u8 timeout)
{
    return MSEC_PER_SEC << (2 * min_t(u8, timeout, 4));   /* 1/4/16/64/256 s */
}

static inline bool cxl_dvsec_mem_is_active(u32 status)
{
    return (status & PCI_DVSEC_CXL_MEM_INFO_VALID) &&
           (status & PCI_DVSEC_CXL_MEM_ACTIVE);
}
```

 

### 5.2 单次读取 CXL 就绪状态（main.c:291–312）

 

```text
static int nvgrace_gpu_test_device_ready_cxl(struct nvgrace_gpu_pci_core_device *nvdev,
                                             u32 *status)
{
    struct pci_dev *pdev = nvdev->core_device.pdev;
    int cxl_dvsec = nvdev->cxl_dvsec;
    u32 val;

    pci_read_config_dword(pdev,
                          cxl_dvsec + PCI_DVSEC_CXL_RANGE_SIZE_LOW(0),
                          &val);

    if (val == ~0U)
        return -ENODEV;

    if (status)
        *status = val;

    if (cxl_dvsec_mem_is_active(val))
        return 0;

    return -EAGAIN;
}
```

 

### 5.3 两阶段轮询等待（lockless、可被信号打断）（main.c:314–345）

 

```text
/*
 * As per CXL spec r4.0 sec 8.1.3.8.2, MEM_INFO_VALID needs to be set
 * within 1s and MEM_ACTIVE within Memory_Active_Timeout (up to ~256s)
 * after reset and bootup.
 */
static int nvgrace_gpu_wait_device_ready_cxl(struct nvgrace_gpu_pci_core_device *nvdev)
{
    unsigned long deadline = jiffies + msecs_to_jiffies(POLL_QUANTUM_MS);
    bool active_phase = false;
    u32 status;
    int ret;

    for (;;) {
        ret = nvgrace_gpu_test_device_ready_cxl(nvdev, &status);
        if (ret != -EAGAIN)
            return ret;

        if (!active_phase && (status & PCI_DVSEC_CXL_MEM_INFO_VALID)) {
            u8 t = FIELD_GET(PCI_DVSEC_CXL_MEM_ACTIVE_TIMEOUT, status);

            deadline = jiffies +
                       msecs_to_jiffies(cxl_mem_active_timeout_ms(t));
            active_phase = true;
        }

        if (time_after(jiffies, deadline))
            return -ETIME;

        if (schedule_timeout_killable(msecs_to_jiffies(POLL_QUANTUM_MS)))
            return -EINTR;
    }
}
```

 

### 5.4 统一就绪检查：锁内分流（main.c:347–380）

 

```text
/*
 * Since the CXL polling wait could take 256s, it happens outside
 * memory_lock. Only do quick readiness check under the lock. Legacy
 * keeps the in-lock poll.
 */
static int
nvgrace_gpu_check_device_ready(struct nvgrace_gpu_pci_core_device *nvdev)
{
    struct vfio_pci_core_device *vdev = &nvdev->core_device;
    int ret;

    lockdep_assert_held_read(&vdev->memory_lock);

    if (!nvdev->reset_done)
        return 0;
    if (!__vfio_pci_memory_enabled(vdev))
        return -EIO;

    if (nvdev->cxl_dvsec)
        ret = nvgrace_gpu_test_device_ready_cxl(nvdev, NULL);
    else
        ret = nvgrace_gpu_wait_device_ready_legacy(nvdev->bar0_base);
    if (ret)
        return ret;

    nvdev->reset_done = false;
    return 0;
}
```

 

### 5.5 "Blackwell-Next" 注释出现处：probe 期检查（main.c:1259–1317）

 

```text
/*
 * ...（前略：GH/GB 的 HBM training 与 C2C link 检查说明）...
 *
 * On Blackwell-Next systems, memory readiness is determined via the
 * CXL Device DVSEC in PCI config space and does not require BAR0.
 * For the legacy path, ensure BAR0 is enabled before accessing the
 * registers.
 */
static int nvgrace_gpu_probe_check_device_ready(struct nvgrace_gpu_pci_core_device *nvdev)
{
    struct pci_dev *pdev = nvdev->core_device.pdev;
    void __iomem *io;
    int ret;

    /* 最坏 ~256s（vs legacy ~30s），可能阻塞 unbind/sysfs */
    if (nvdev->cxl_dvsec)
        return nvgrace_gpu_wait_device_ready_cxl(nvdev);

    ret = pci_enable_device(pdev);
    if (ret)
        return ret;
    /* ...legacy: 映射 BAR0 后轮询 nvgrace_gpu_wait_device_ready_legacy(io)... */
}
```

 

### 5.6 三处复用 CXL 等待的调用点

 

reset 后首次访问（`reset_done==true && cxl_dvsec`）都会触发 256s 级等待： 
 
- mmap fault 路径 `nvgrace_gpu_vfio_pci_huge_fault()`（main.c:422–438，带 `retry:` 处理 reset race） 
- 读路径 `nvgrace_gpu_read_mem()`（main.c:834–838） 
- 写路径（main.c:974 附近，结构同读） 
 

reset 标志由 PCI error handler 置位： 

```text
static void nvgrace_gpu_vfio_pci_reset_done(struct pci_dev *pdev) {
    /* ... */
    nvdev->reset_done = true;
}
```

 

---

 

## 六、依赖的内核头文件定义

 

CXL 路径用到的宏不在本驱动，而在 UAPI / pci_ids 头文件。 

### 6.1`include/uapi/linux/pci_regs.h`（约 1350–1365）

 

```text
#define PCI_DVSEC_CXL_DEVICE                  0
#define  PCI_DVSEC_CXL_RANGE_SIZE_LOW(i)      (0x1C + (i * 0x10))
#define   PCI_DVSEC_CXL_MEM_INFO_VALID        _BITUL(0)
#define   PCI_DVSEC_CXL_MEM_ACTIVE            _BITUL(1)
#define   PCI_DVSEC_CXL_MEM_ACTIVE_TIMEOUT    __GENMASK(15, 13)
#define   PCI_DVSEC_CXL_MEM_SIZE_LOW          __GENMASK(31, 28)
```

 

>  

这些就是 CXL 1.1 "CXL Range" 设备 DVSEC 寄存器——描述**设备自带内存（HDM, Host-managed Device Memory）**及其就绪状态。`Memory_Active_Timeout` 是 spec 里"复位后多久内存 active"的标准字段。也就是说，**Blackwell-Next GPU 把自己的 HBM 描述成了一段 CXL HDM 范围。**  

### 6.2`include/linux/pci_ids.h`（约 2633）

 

```text
#define PCI_VENDOR_ID_CXL    0x1e98
```

 

>  

vendor ID 用的是 **CXL Consortium (0x1e98)** 而非 NVIDIA——因为这是标准 CXL Device DVSEC，不是 NVIDIA 私有的那个 `GPU_CAP_DVSEC_REGISTER`(ID 3，走 `PCI_VENDOR_ID_NVIDIA`，用于 MIG bug 判定)。  

---

 

## 七、当前已支持的 PCI 设备 ID（还没有 Blackwell-Next）

 

`nvgrace_gpu_vfio_pci_table[]`（main.c:1380）列的全是现有 Grace 硬件： 

```text
static const struct pci_device_id nvgrace_gpu_vfio_pci_table[] = {
    /* GH200 120GB */ { PCI_DRIVER_OVERRIDE_DEVICE_VFIO(PCI_VENDOR_ID_NVIDIA, 0x2342) },
    /* GH200 480GB */ { PCI_DRIVER_OVERRIDE_DEVICE_VFIO(PCI_VENDOR_ID_NVIDIA, 0x2345) },
    /* GH200 SKU   */ { PCI_DRIVER_OVERRIDE_DEVICE_VFIO(PCI_VENDOR_ID_NVIDIA, 0x2348) },
    /* GB200 SKU   */ { PCI_DRIVER_OVERRIDE_DEVICE_VFIO(PCI_VENDOR_ID_NVIDIA, 0x2941) },
    /* GB300 SKU   */ { PCI_DRIVER_OVERRIDE_DEVICE_VFIO(PCI_VENDOR_ID_NVIDIA, 0x31C2) },
    {}
};
```

 

>  

代码路径已就绪，但**真正的 Blackwell-Next device ID 尚未加入**——属于"先把软件框架铺好"。  

---

 

## 八、"Blackwell-Next" 到底指哪一代

 

代号含义本身**模糊**。判读线索矛盾： 
 
- 改动修改的是 `nvgrace-gpu` 驱动 → 这是 **Grace 系**（Grace CPU + Blackwell GPU）；而 Rubin 搭配的是 **Vera** CPU，不是 Grace。 
- NVIDIA 已宣布 Rubin 接替 Blackwell B100/B200 及 Blackwell Ultra B300。 
- 所以到底指 **Blackwell Ultra**、**Rubin**、还是两者之间，**无定论**。多数分析倾向"为下一代数据中心硬件做早期铺垫"。 
- 可以确定：这出现在数据中心 Grace 平台相关的 VFIO 驱动里，**不是消费级 GPU 驱动**，没有依据认为它是 GeForce RTX 60 的代号。 
 

---

 

## 九、VR200 / Vera Rubin 硬件事实（佐证第一节结论）

   VR200 / Vera Rubin 硬件事实          

| 项 | 事实 |
| --- | --- |
| CPU↔GPU 一致性互联 | **NVLink-C2C**，1.8 TB/s（相比上代翻倍），提供 cache-coherent 内存访问 |
| PCIe 的角色 | Rubin 经 C2C 连 Vera，再由 **Vera 经 PCIe6 lane** 连 ConnectX-9 等外设——PCIe 主要用于外设挂载，非一致性主路径 |
| Vera 的接口能力 | **同时支持 PCIe6 与 CXL 3.1**（并存，非替代） |
| NVLink-C2C 可承载的协议 | 支持 **Arm AMBA CHI 或 CXL** 协议——即"C2C vs CXL"在物理层并非二选一，CXL 可作为 C2C 链路上跑的协议 |

  

---

 

## 十、结论一句话复述

 

>  

**不是 "PCIe+C2C → CXL+C2C"，而是 "GPU 内存暴露接口：NVIDIA 私有 → CXL HDM 标准化"。**高带宽一致性传输层始终是 NVLink-C2C（1.8 TB/s），这段 CXL DVSEC 代码改的只是"GPU 显存就绪状态 / 内存描述如何向 host 标准化上报"。Rubin 一致性确有增强，功劳在 NVLink-C2C 翻倍，而非这段探测逻辑。
