import type { AnnouncementConfig } from "../types/config";

export const announcementConfig: AnnouncementConfig = {
	title: "欢迎来到繁星若尘",
	content:
		"记录大规模智算集群稳定性验证、异构计算卡微架构与速率实测、高速互联网络与底层固件排错。",
	closable: true,
	link: {
		enable: true,
		text: "NVIDIA GPU PCI ID 全表 →",
		url: "/posts/nvidia-gpu-pci-device-ids/",
		external: false,
	},
};
