import type { SiteConfig } from "../types/config";

// 定义站点语言
const SITE_LANG = "zh_CN"; // 语言代码，例如：'en', 'zh_CN', 'ja' 等。

export const siteConfig: SiteConfig = {
	title: "繁星若尘",
	subtitle: "硬件实测与底层技术笔记",
	siteURL: "https://aosudh.github.io/", // 请替换为你的站点URL，以斜杠结尾
	siteStartDate: "2026-06-18", // 站点开始运行日期，用于站点统计组件计算运行天数
	timeZone: "Asia/Shanghai", // 文章日期使用的 IANA 时区，可改为 Asia/Tokyo、Europe/Berlin 等

	lang: SITE_LANG,

	themeColor: {
		hue: 222, // 主题色的默认色相，范围从 0 到 360
		fixed: false, // 对访问者隐藏主题色选择器
	},

	// 特色页面开关配置
	featurePages: {
		anime: false,
		diary: false,
		friends: false,
		projects: false,
		skills: false,
		timeline: false,
		albums: false,
		devices: false,
		aiTools: false,
	},

	// 顶栏标题配置
	navbarTitle: {
		mode: "text-icon",
		text: "繁星若尘",
		icon: "/assets/covers/avatar.jpg",
		logo: "/assets/covers/avatar.jpg",
	},

	pageScaling: {
		enable: false,
		targetWidth: 2000,
	},

	font: {
		mode: "system",
	},

	bangumi: {
		userId: "your-bangumi-id", // 在此处设置你的Bangumi用户ID，可以设置为 "sai" 测试
		fetchOnDev: false, // 是否在开发环境下获取 Bangumi 数据（默认 false），获取前先执行 pnpm build 构建 json 文件
	},

	bilibili: {
		vmid: "your-bilibili-vmid", // 在此处设置你的Bilibili用户ID (uid)，例如 "1129280784"
		fetchOnDev: false, // 是否在开发环境下获取 Bilibili 数据（默认 false）
		coverMirror: "", // 封面图片镜像源（可选，如果需要使用镜像源，例如 "https://images.weserv.nl/?url="）
		useWebp: true, // 是否使用WebP格式（默认 true）

		// bilibili 观看进度配置说明(可选，如需配置仔细阅读):
		// 1. 本地开发：请在 .env 文件中填写 BILI_SESSDATA=your_SESSDATA
		// 2. 远程构建：请在 GitHub 仓库 Settings -> Secrets 中添加 BILI_SESSDATA
		// 注意：SESSDATA 为账号凭证，为防止泄露，切记不可使用硬编码。
		// 安全提示：如 SESSDATA 已泄露，请打开 B站手机端 —— 我的 —— 设置 —— 安全隐私 —— 登陆设备管理 —— 一键退登，销毁已泄露的账号凭证
	},

	anime: {
		mode: "local", // 番剧页面模式："bangumi" 使用Bangumi API，"local" 使用本地配置，"bilibili" 使用Bilibili API
	},

	// 日记页面 Memos API 地址，留空则使用静态数据
	diaryApiUrl: "",

	// 文章列表布局配置
	postListLayout: {
		// 默认布局模式："list" 列表模式（单列布局），"grid" 网格模式（双列布局）
		// 注意：如果侧边栏配置启用了"both"双侧边栏，则无法使用文章列表"grid"网格（双列）布局
		defaultMode: "list",
		// 是否启用布局切换功能
		enable: true,
		// 是否允许用户切换布局
		allowSwitch: true,
		// 文章列表页分类导航条配置
		categoryBar: {
			enable: true, // 是否在文章列表页显示分类导航条
		},
	},

	// 文章页超宽屏布局配置
	// 在 2K/4K 视口下扩展文章容器、侧栏与正文阅读轨道；1920px 以下不生效。
	// 与 pageScaling 互不影响：断点按 CSS 视口判断，且 pageScaling 在 2000px 以上是空操作。
	ultrawidePostLayout: {
		enable: true, // 访客未手动切换时的初始状态
		allowSwitch: true, // 是否在设置面板中显示开关
	},

	// 标签样式配置
	tagStyle: {
		// 是否使用新样式（悬停高亮样式）还是旧样式（外框常亮样式）
		useNewStyle: false,
	},

	// 壁纸模式配置
	wallpaperMode: {
		// 默认壁纸模式：banner=顶部横幅，fullscreen=全屏壁纸，none=无壁纸
		defaultMode: "banner",
		// 整体布局方案切换按钮显示设置（默认："desktop"）
		// "off" = 不显示
		// "mobile" = 仅在移动端显示
		// "desktop" = 仅在桌面端显示
		// "both" = 在所有设备上显示
		showModeSwitchOnMobile: "both",
	},

	banner: {
		src: {
			desktop: ["/assets/covers/banner-starfield.jpg"],
			mobile: ["/assets/covers/banner-starfield.jpg"],
		},

		position: "center",

		carousel: {
			enable: false,
			interval: 5,
			switchable: false,
		},

		waves: {
			enable: true,
			performanceMode: false,
			mobileDisable: false,
			switchable: true,
		},

		imageApi: {
			enable: false,
			url: "",
		},

		homeText: {
			enable: true,
			title: "繁星若尘",
			switchable: true,

			subtitle: [
				"在硅片与光缆之间，追寻系统的底层真相。",
				"从 PCIe BAR0 到 100G SONiC，每一份实测都可复现。",
				"仰望繁星，亦俯察寄存器与二进制微尘。",
				"GPU 架构实测 · 交换机适配 · 固件底层修复",
				"自在飞花轻似梦，无边丝雨细如愁。",
			],
			typewriter: {
				enable: true,
				speed: 90,
				deleteSpeed: 45,
				pauseTime: 2200,
			},
		},

		credit: {
			enable: false,
			text: "",
			url: "",
		},

		navbar: {
			transparentMode: "semifull",
		},
	},
	toc: {
		enable: true,
		mobileTop: true,
		desktopSidebar: true,
		floating: true,
		depth: 2,
		useJapaneseBadge: false,
	},
	showCoverInContent: false,
	generateOgImages: false,
	favicon: [
		{
			src: "/assets/covers/favicon.svg",
		},
	],

	showLastModified: true, // 控制"上次编辑"卡片显示的开关
	pageProgressBar: {
		enable: true, // 启用页面顶部进度条
		height: 3, // 进度条高度 3px
		duration: 6000, // 动画时长 6s
	},

	thirdPartyAnalytics: {
		enable: false, // 是否启用第三方统计（Microsoft Clarity），默认关闭，启用可能影响 Lighthouse 评分
		clarityId: "", // Clarity 项目 ID
	},
	// 卡片样式配置
	card: {
		border: true, // 开启卡片边框和微阴影，让卡片更有立体感
		followTheme: false, // 卡片背景跟随主题色相
	},
	// 图片优化配置
	imageOptimization: {
		formats: "webp", // 图片输出格式："avif"、"webp" 或 "both"（avif+webp，最优质量但构建更慢）
		quality: 85, // 图片质量，推荐 70-85
		noReferrerDomains: [
			// 需要添加 referrerpolicy="no-referrer" 的域名（支持通配符）
			"*.hdslb.com", // Bilibili CDN
		],
	},
};

export { SITE_LANG };
