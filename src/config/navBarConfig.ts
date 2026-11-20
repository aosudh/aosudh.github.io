import type { NavBarConfig } from "../types/config";
import { LinkPreset } from "../types/config";

export const navBarConfig: NavBarConfig = {
	links: [
		LinkPreset.Home,
		LinkPreset.Archive,
		{
			name: "关于",
			url: "/about/",
			icon: "material-symbols:person",
		},
		{
			name: "小红书",
			url: "https://www.xiaohongshu.com/user/profile/60cb6efc000000000101d62b",
			external: true,
			icon: "material-symbols:book-2-outline",
		},
		{
			name: "原版入口",
			url: "/classic.html",
			external: true,
			icon: "material-symbols:history",
		},
		{
			name: "GitHub",
			url: "https://github.com/aosudh",
			external: true,
			icon: "fa7-brands:github",
		},
	],
};
