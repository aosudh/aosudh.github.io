# 关于繁星若尘（aosudh）

长期深耕 **AI 算力基础设施** 与 **底层异构硬件系统工程**，专注于大规模多机多卡智算集群的稳定性验证、计算卡微架构极限速率表征、高速互联网络（RDMA / NVLink / PCIe P2P / 100G–800G 交换）与固件级排错。

## 核心研究与工程实践

### 01 · 大规模智算集群稳定性与可靠性工程
围绕多机多卡智算集群的上线验收与长周期稳定性测试，构建从单卡满载烤机（Burn-in）、功耗与热节流监控到跨节点集合通信压测的端到端验收基线；深度定位 PCIe 链路降级、BAR0 MMIO 访问异常、GPU 掉卡（Fallen off the bus）、TMA / mbarrier 挂死与静默性能抖动等生产级疑难故障。

### 02 · 异构计算卡微架构剖析与极限速率实测
覆盖 NVIDIA Hopper / Blackwell / Rubin、DGX Spark、Jetson Thor 及国产算力卡（MTT S5000）的真实算力墙、显存带宽与发射占空比表征；结合 DCGM 硬件计数器、Nsight Compute 与底层 CUTLASS / CUDA 内核追踪，量化多精度矩阵算力（FP32 / TF32 / FP16 / FP8 / NVFP4）、特供 SKU 限速机制与端到端推理吞吐收益。

### 03 · 高速互联拓扑与数据中心交换网络
深挖 GPU↔GPU PCIe P2P、GPUDirect RDMA（DMA-BUF / nvidia-peermem）、NVLink-C2C 与 MTLink 互联带宽瓶颈，以及多卡 NCCL / MCCL AllReduce 通信效率；涵盖白盒与品牌 100G/400G 交换机（HPE / Celestica / Mellanox SN2100）的 SONiC / Onyx / ONIE 平台适配、端口拆分验证与带外运维体系。

### 04 · 底层固件逆向、恢复与硬件图谱库
涉及 ConnectX-7/8/9 网卡固件二进制与 PSID 谱系逆向、CH347 / MTUSB / FS5 双份 NV_DATA 闪存级救砖、OpenRM / GSP-RM 驱动栈源码消融，以及 Jetson 载板设备树与嵌入式启动链排错；持续维护 332 项 NVIDIA GPU PCI Device ID（Ampere → Rubin）与 Jetson/Tegra 模组料号全量对照表。

## 主页与联系

- **小红书**：[繁星若尘的小红书主页](https://www.xiaohongshu.com/user/profile/60cb6efc000000000101d62b)
- **GitHub**：[@aosudh](https://github.com/aosudh)
- **邮箱**：`2169159625@qq.com`
