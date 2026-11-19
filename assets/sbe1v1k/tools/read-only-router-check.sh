#!/bin/sh
# Read-only status collection for the reviewed QWRT schema. No writes/reloads.
# Does not print MACs, passwords, ART/LICENSE hashes, serials or host keys.
set -u
printf '%s\n' '--- Version ---'
uname -r
if [ -r /etc/openwrt_release ]; then
    grep -E '^(DISTRIB_ID|DISTRIB_RELEASE|DISTRIB_REVISION|DISTRIB_TARGET)=' /etc/openwrt_release
fi
printf '%s\n' '--- Boot arguments (allowlisted fields only) ---'
awk '{ for (i=1; i<=NF; i++) if ($i == "rootwait" ||
    $i ~ /^root=\/dev\/mmcblk[0-9]+p[0-9]+$/ ||
    $i ~ /^console=tty[A-Za-z0-9]+,[0-9]+[neo][0-9]+$/ ||
    $i ~ /^rootfstype=(ext4|squashfs|f2fs)$/ ||
    $i ~ /^(fstools_ignore_partname|fstools_partname_fallback_scan|cnss2\.enable_mlo_support)=[01]$/ ||
    $i ~ /^(loglevel|panic)=[0-9]+$/) print $i }' /proc/cmdline
printf '%s\n' '--- Overlay ---'
awk '$2 == "/overlay" {
    source=$1; if (source !~ /^\/dev\/mmcblk[0-9]+p[0-9]+$/) source="[other source omitted]";
    access="unknown"; n=split($4,opts,","); for (i=1;i<=n;i++) if (opts[i]=="rw" || opts[i]=="ro") access=opts[i];
    print "device=" source, "type=" $3, "access=" access
}' /proc/mounts
df -h /overlay 2>/dev/null | awk 'NR == 2 { print "size=" $2, "used=" $3, "available=" $4, "use=" $5 }'
printf '%s\n' '--- Ethernet links ---'
for port in eth0 eth1 eth2 eth3; do
    carrier=$(cat "/sys/class/net/$port/carrier" 2>/dev/null) || carrier=unavailable
    speed=$(cat "/sys/class/net/$port/speed" 2>/dev/null) || speed=unavailable
    printf '%s carrier=%s speed_mbps=%s\n' "$port" "$carrier" "$speed"
done
printf '%s\n' '--- AP state (SSIDs are user-visible names) ---'
for radio in 0 1 2; do
    printf 'ath%s\n' "$radio"
    if status=$(hostapd_cli -p "/var/run/hostapd-wifi$radio" -i "ath$radio" status 2>/dev/null); then
        printf '%s\n' "$status" | awk '/^(state|freq|ssid\[0\])=/'
    else
        printf '%s\n' 'state=unavailable'
    fi
done
