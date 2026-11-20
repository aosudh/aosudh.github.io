import type { ProfileConfig } from "../types/config";

export const profileConfig: ProfileConfig = {
	avatar: "/assets/covers/avatar.jpg",
	name: "繁星若尘",
	bio: "大规模集群稳定性 · 高性能计算 · 高性能网络 · 嵌入式 · 边缘计算",
	typewriter: {
		enable: false,
		speed: 80,
	},
	links: [
		{
			name: "小红书",
			icon: "material-symbols:book-2-outline",
			url: "https://www.xiaohongshu.com/user/profile/60cb6efc000000000101d62b",
		},
		{
			name: "GitHub",
			icon: "fa7-brands:github",
			url: "https://github.com/aosudh",
		},
		{
			name: "Email",
			icon: "material-symbols:mail-outline",
			url: "mailto:2169159625@qq.com",
		},
	],
};
