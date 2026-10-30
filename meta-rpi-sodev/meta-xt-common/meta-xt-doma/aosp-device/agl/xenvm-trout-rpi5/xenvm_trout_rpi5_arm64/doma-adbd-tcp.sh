#!/system/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Pin a stable TCP ADB endpoint for DomD over the internal Xen bridge.

set -u

TAG=doma-adbd-tcp
ADB_PORT=5555
WAIT_SECS="${DOMA_ADBD_NET_WAIT_SECS:-300}"

# Keep these in sync with sodev-net.inc. They are literal here because this file
# is consumed by the AOSP build, not BitBake.
SHADOW_BR=br-shadow
SHADOW_ADDR=192.168.10.15/24
ETH1_IF=eth1
ETH1_ADDR=192.168.10.13/24
DOMD_ADDR=192.168.10.10
MGMT_SUBNET=192.168.10.0/24

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

prefer_mgmt_route() {
    iface="$1"
    src="$2"
    /system/bin/ip route replace "$DOMD_ADDR/32" dev "$iface" src "${src%/*}" table main 2>/dev/null || true
    /system/bin/ip rule show | /system/bin/grep -q "to $MGMT_SUBNET lookup main" \
        || /system/bin/ip rule add to "$MGMT_SUBNET" lookup main pref 50 2>/dev/null \
        || true
    /system/bin/ip route flush cache 2>/dev/null || true
}

# doma_shadow_ap creates br-shadow after it has created the hwsim radios and
# enslaved eth1. This helper also runs from late-init now, before the framework is
# guaranteed to complete boot. Do not only wait for br-shadow here: on hardware eth1
# can appear minutes after late-init, and if Android later stalls before
# sys.boot_completed the boot-completed retry never happens. Wait until either the
# normal bridge or the eth1 recovery path exists, then pin addresses and restart adbd.
i=0
if [ "$(/system/bin/getprop persist.vendor.doma.shadow_ap)" != "false" ]; then
    while [ ! -e "/sys/class/net/$SHADOW_BR" ] && [ ! -e "/sys/class/net/$ETH1_IF" ] && [ "$i" -lt "$WAIT_SECS" ]; do
        /system/bin/sleep 1
        i=$((i + 1))
    done
fi

added=0
restarted=0
if [ -e "/sys/class/net/$ETH1_IF" ]; then
    # Always keep the direct management fallback pinned. If the shadow bridge is
    # absent, broken, or created after Android has already given up DHCP, DomD can
    # still reach ADB on 192.168.10.13.
    add_addr "$ETH1_IF" "$ETH1_ADDR"
    prefer_mgmt_route "$ETH1_IF" "$ETH1_ADDR"
    added=1
    /system/bin/setprop ctl.restart adbd
    restarted=1
    log "requested adbd TCP restart on $ETH1_IF fallback"
fi

if [ "$(/system/bin/getprop persist.vendor.doma.shadow_ap)" != "false" ] && [ ! -e "/sys/class/net/$SHADOW_BR" ]; then
    # eth1 can appear before doma_shadow_ap has created br-shadow and enslaved it.
    # Keep waiting for the normal shadow bridge even after the fallback is usable;
    # if Android stalls before sys.boot_completed, this oneshot may be our only
    # chance to publish the stable 192.168.10.15 ADB endpoint.
    while [ ! -e "/sys/class/net/$SHADOW_BR" ] && [ "$i" -lt "$WAIT_SECS" ]; do
        /system/bin/sleep 1
        i=$((i + 1))
    done
fi

if [ -e "/sys/class/net/$SHADOW_BR" ]; then
    # If eth1 was used as the early fallback and is now a bridge port, keep the
    # management addresses on the bridge only. Duplicate .13 on both the bridge
    # and its port can confuse ARP/reachability on DomD.
    if [ -e "/sys/class/net/$ETH1_IF/master" ]; then
        /system/bin/ip addr del "$ETH1_ADDR" dev "$ETH1_IF" 2>/dev/null || true
    fi
    add_addr "$SHADOW_BR" "$ETH1_ADDR"
    add_addr "$SHADOW_BR" "$SHADOW_ADDR"
    prefer_mgmt_route "$SHADOW_BR" "$ETH1_ADDR"
    added=1
    /system/bin/setprop ctl.restart adbd
    restarted=1
    log "requested adbd TCP restart on $SHADOW_BR"
elif [ "$added" -eq 1 ]; then
    log "$SHADOW_BR absent; using $ETH1_IF fallback"
else
    log "WARNING: neither $SHADOW_BR nor $ETH1_IF exists; adbd will listen but DomD may not reach it"
fi

if [ "$restarted" -eq 0 ]; then
    /system/bin/setprop ctl.restart adbd
    log "requested adbd TCP restart on port $ADB_PORT"
fi
