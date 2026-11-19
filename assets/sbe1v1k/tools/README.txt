SBE1V1K QWRT 公开审计附件（2026-11-19）

inspect_and_patch.py 仅使用 Python 3 标准库。可直接在 Windows Python 中运行，不需要 Linux、WSL、第三方包或网络。
它仅读取本地普通文件；patch-loader 只创建指定的本地 ITB 文件，不访问路由器，不执行固件，不写原始磁盘或分区。
拒绝 UNC/设备路径、符号链接输入输出、错误大小/哈希及不同内容的已有输出。相同正确输出可重复核验但不重写。

使用方式（在自行保存原文件的目录执行）：
  python inspect_and_patch.py inspect-firmware QWRT-R26.05.01-ipq95xx-generic-spectrum_sbe1v1k-squashfs-sysupgrade.bin
  python inspect_and_patch.py patch-loader sbe1v1k-chainloader.itb sbe1v1k-chainloader-260922-p29.itb

build_low_launcher.py 是独立的标准库工具，不需要上面的 Python 文件或其他私有模块。
用本地原版 859-byte FIT 制作已经验证的 863-byte 低地址 launcher：
  python build_low_launcher.py rtq7300t_boot_auto_upgrade_fw.img rtq7300t_boot_auto_upgrade_fw-44000000.img
原版 SHA256：498bc402dc720bd7cd93ffc400fbbd308d64785e950a8a5bc54ae72896a09bba
目标 SHA256：999775118abefc7c8b798ff85f8bf1826ce84c94e777b8582cfea983d3776125
它重新序列化 script 的 data 与对应 SHA256，自动更新 FDT 长度/偏移，保留 RTQ7300T 标记及其他属性，复核两个内嵌 SHA256。
输出脚本只有一行：
  setenv serverip 172.16.252.252; tftpboot 0x44000000 initramfs.itb && bootm 0x44000000
这里不只是更换暂存地址，还使用 && 使 bootm 仅在 tftpboot 成功后执行；没有 saveenv 或 eMMC 写入命令。
本工具不会下载、传输或执行 launcher，不会启动 TFTP/DHCP 服务，也不附带原版或修改版二进制。
相同正确输出只核验不重写，不同现有文件拒绝覆盖，输入原件不会被修改。
即使 launcher 只把第二级引导加载到 RAM，之后若继续启动 Linux，Linux 仍可能写入配置区；不能把整个后续启动过程称为只读。

严格适用范围：
1. QWRT 固件必须是 119685913 字节，SHA256：
   0a033c708675c68e1765661ace2d6a03d902b35b1d62e88f1a4cae9fa8c7dd64
2. 作者原版 260922 ITB 必须是 804036 字节，SHA256：
   6e83ca577933585e5140ee80a08d40bc75872bf08375c9b3d7ffeab23f431347
3. 只生成本文已审核的 custom-p29 ITB，SHA256：
   8a7b5911001dd34b0cedbeda000e7ac0f096599b7b1b0ef21c9c147f982a6359
4. 定制文件将 U-Boot 载荷中的 fstools_ignore_partname=1 改为 0，并更新对应 FIT SHA1。
   工具检查全部内嵌 hash、唯一目标字符串、结构/属性不变及精确的 21 字节差异，最后锁定输出 SHA256。
   不适用于其他引导版本、其他 rootfs/GPT 布局或尚未确认健康独立 p29 ext4 的系统。
5. inspect-firmware 不把 tar 解压到文件系统；只在内存中核对四个成员及 kernel/root 长度和 SHA256。
   通过此工具不等于设备适配、备份、安装或启动验证通过。此附件没有刷写子命令。

read-only-router-check.sh 是在路由器 shell 中执行的只读诊断脚本，Windows 可以通过已有 SSH 连接运行。
只读版本、允许公开的启动参数、overlay、四个网口 carrier/speed 和三个 AP 的 state/freq/SSID。
不会设置配置、reload、reboot、下载固件或写分区；不打印 MAC、密码、ART/LICENSE 哈希、序列号或主机密钥。
SSID 会按要求输出，分享日志前仍应检查 SSID 是否包含自己的姓名或其他个人信息。
适配的是本文 QWRT 的 wifi0/ath0、wifi1/ath1、wifi2/ath2 schema；其他固件可能显示 unavailable。

公开数据边界：附件只包含通用镜像哈希和本地审计代码，没有设备身份、许可证、校准数据或实际 Wi-Fi 凭据。
命令的正常 JSON 与处理过的错误信息不带输入/输出绝对路径。不要连同私有备份、原始配置或 private-replay 目录一起发布。
QWRT 本体来自本次用户提供文件，尚无与该哈希一一对应的已验证作者发布页；工具不提供其下载来源。
定制 ITB 不是作者未经修改的官方发布包。

来源：
https://github.com/OneNAS-space/Askey_Spectrum_SBE1V1K/blob/main/README_SBE1V1K_en.md
https://github.com/YYH2913/http-uboot/releases/tag/sbe1v1k_260922
https://github.com/YYH2913/http-uboot/blob/4702852be0dde91dd8e352d1857bb420fae054a1/board/qualcomm/sbe1v1k-chainloader/sbe1v1k-chainloader.c
https://github.com/openwrt/uci/blob/415f9e48/cli.c

Windows 临时官方下载代理（官方 OpenWrt / APK 阶段）
------------------------------------------------
openwrt_download_proxy.py 是独立的 Python 3 标准库程序。只有显式启动时才监听网络，
不会在导入时启动服务，不写状态文件，不读取本地凭据，也不访问路由器。
它固定监听 Windows 127.0.0.1:18080，只允许 downloads.openwrt.org 的 HTTPS/443。
支持 uclient-fetch 使用的绝对 HTTPS URL GET/HEAD，也支持 CONNECT。
GET/HEAD 上游使用默认 TLS 证书和主机名验证；CONNECT 保留客户端与官方服务器的端到端 TLS，
证书验证由下载客户端负责。没有禁用证书检查或软件源签名验证。
代理不自动跟随重定向；客户端重新请求时仍必须通过同一域名和端口限制。

这部分不同于上面的离线审计工具：启动后会按请求访问官方网络，但不会写路由器配置或分区。
以下 apk 命令只适用于本文官方 OpenWrt 阶段，不要直接用于后续采用 opkg 的 QWRT。
使用前应确认当前软件源与运行系统匹配，不把历史 SNAPSHOT 的软件包版本与新源混装。

1. Windows PowerShell 窗口 A，在本文件所在目录前台启动：
     python openwrt_download_proxy.py
   不需要管理员权限；只绑定回环地址，无需向局域网开放该代理端口。

2. Windows PowerShell 窗口 B，建立到已核验路由器的反向转发：
     ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -R 127.0.0.1:18080:127.0.0.1:18080 root@192.168.1.1
   保持该窗口运行。使用已有的本台主机密钥信任记录；多台机器复用同一地址时要分别核验身份。
   转发只在路由器 127.0.0.1 上监听，不向路由器 LAN/WAN 开放代理。

3. 另开一个路由器 SSH 会话，设置仅本会话生效的小写代理环境变量：
     export http_proxy=http://127.0.0.1:18080
     export https_proxy=http://127.0.0.1:18080
     apk update
     apk --simulate add luci-ssl luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn
   确认索引更新成功并审阅模拟安装事务，无错误后运行实际安装：
     apk add luci-ssl luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn
   然后核对 uhttpd 服务和 LuCI 登录页。不要关闭软件源签名检查来绕过安装错误。

4. 完成后清理：
   - 在上述路由器会话执行：unset http_proxy https_proxy
   - 在 Windows 窗口 B 按 Ctrl+C，关闭 SSH 反向转发。
   - 在 Windows 窗口 A 按 Ctrl+C，关闭代理；无需删除任何状态文件。
   - 即使没有手动停止，代理也会在启动 20 分钟后退出并关闭监听及活动连接。
     超时退出不会代替关闭窗口 B：SSH 进程及其远端转发仍需单独 Ctrl+C 停止。
   - 如果下载期间达到 20 分钟期限，请检查 apk 的结果；可重新启动代理继续需要的下载，
     不要把中断误认为安装成功，更不需要因此重新刷机。

本公开副本的核验范围：语法、域名/协议/端口拒绝、GET/HEAD 路由与 CONNECT 目标限制的离线模拟。
它基于本次已使用的代理实现整理；整理时未重新访问外网、连接路由器或做在线下载测试。
