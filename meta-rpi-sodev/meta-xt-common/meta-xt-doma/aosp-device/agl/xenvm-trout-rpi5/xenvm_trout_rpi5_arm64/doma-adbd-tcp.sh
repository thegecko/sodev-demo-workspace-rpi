#!/system/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Pin a stable TCP ADB endpoint for DomD over the internal Xen bridge.

set -u

TAG=doma-adbd-tcp
ADB_PORT=5555

# Keep these in sync with sodev-net.inc. They are literal here because this file
# is consumed by the AOSP build, not BitBake.
SHADOW_BR=br-shadow
SHADOW_ADDR=192.168.10.15/24
ETH1_IF=eth1
ETH1_ADDR=192.168.10.13/24

log() { echo "$TAG: $*"; /system/bin/log -t "$TAG" "$*" 2>/dev/null; :; }

addr_present() {
    /system/bin/ip -4 addr show dev "$1" 2>/dev/null | /system/bin/grep -q " ${2%/*}/"
}

add_addr() {
    iface="$1"
    addr="$2"
    [ -e "/sys/class/net/$iface" ] || return 1
    /system/bin/ip link set "$iface" up 2>/dev/null || true
    if addr_present "$iface" "$addr"; then
        log "$iface already has $addr"
    else
        /system/bin/ip addr add "$addr" dev "$iface" 2>/dev/null \
            && log "$iface static ADB address $addr" \
            || log "WARNING: failed to add $addr to $iface"
    fi
}

# doma_shadow_ap creates br-shadow after it has created the hwsim radios and
# enslaved eth1. This helper also runs from late-init now, before the framework is
# guaranteed to complete boot. Do not only wait for br-shadow here: on hardware eth1
# can appear tens of seconds after late-init, and if Android later stalls before
# sys.boot_completed the boot-completed retry never happens. Wait until either the
# normal bridge or the eth1 recovery path exists, then pin an address and restart adbd.
i=0
if [ "$(/system/bin/getprop persist.vendor.doma.shadow_ap)" != "false" ]; then
    while [ ! -e "/sys/class/net/$SHADOW_BR" ] && [ ! -e "/sys/class/net/$ETH1_IF" ] && [ "$i" -lt 60 ]; do
        /system/bin/sleep 1
        i=$((i + 1))
    done
fi

if [ -e "/sys/class/net/$SHADOW_BR" ]; then
    add_addr "$SHADOW_BR" "$SHADOW_ADDR"
elif [ -e "/sys/class/net/$ETH1_IF" ]; then
    log "$SHADOW_BR absent; using $ETH1_IF fallback"
    add_addr "$ETH1_IF" "$ETH1_ADDR"
else
    log "WARNING: neither $SHADOW_BR nor $ETH1_IF exists; adbd will listen but DomD may not reach it"
fi

/system/bin/setprop ctl.restart adbd
log "requested adbd TCP restart on port $ADB_PORT"
