# sodev-net.inc — single source of truth for the RPi5 Xen cockpit DomD network
# topology (management hostname, IP addresses, MACs, DHCP range).
#
# Consumers `require` this file and derive their shipped config from these vars,
# so each address/MAC lives in exactly one place:
#   - xen-network        : DomD eth0 (.network), Dom0<->DomD vif (.network),
#                          domd-flatbridge-up (xenbr0 address + uplink gateway)
#   - dnsmasq (bbappend) : DHCP range + static guest leases
#   - dom0-domd-vif      : Dom0 end of the point-to-point vif (bring-up script)
#
# One consumer is deliberately outside that set: meta-rpi-sodev-devel's
# domu-network runs in a different bitbake instance, which does not include
# meta-xt-driver-domain and therefore cannot `require` this file. Its
# 20-eth0.network repeats the DomU address and the DomD gateway literally and has
# to be kept in step by hand -- see the note in domu-network_0.1.bb. Changing a
# value here means checking that file too.
#
# These are HW-proven values. Do NOT change them casually: a wrong value
# silently breaks the 2-screen demo (SSH / guests / HDMI). In particular the
# xenbr0 bridge MUST stay addressless in the .network files — .10.10 is assigned
# LATE by the flatbridge script, never via a .network Address=.
#
# Two segments:
#   - Flat L2 management subnet 192.168.10.0/24 (DomD xenbr0 .10, guests, PC).
#   - Dom0<->DomD point-to-point vif 192.168.0.0/24 (Dom0 .1, DomD netfront .11).
#
# NOTE: bitbake has no inline comments — a trailing `# ...` on an assignment line
# is a parse error ("unparsed line"), so every annotation below is on its own line.

# --- management identity ---
SODEV_NET_MANAGEMENT_HOSTNAME ??= "basecamp-net"

# --- flat L2 management subnet (192.168.10.0/24) ---
XT_NET_FLAT_SUBNET  ??= "192.168.10.0/24"
# DomD xenbr0 (assigned LATE by flatbridge; also DomD eth0 gateway)
XT_DOMD_XENBR0_IP   ??= "192.168.10.10"
# DomD RP1 eth0 (boot-time, NOT bridged)
XT_DOMD_ETH0_IP     ??= "192.168.10.11"
# Uplink gateway DomD points its default route at once xenbr0 is up. In the demo
# setup this is the PC on the flat segment; it is what gives DomD (and, through
# it, the guests) a route off the RPi5.
XT_PC_UPLINK_GW_IP  ??= "192.168.10.1"
# DomU static lease
XT_DOMU_IP          ??= "192.168.10.12"
# DomA eth1 (ADB deployment from DomD) static lease.
# Never answered while the shadow AP runs: that service enslaves eth1 into
# br-shadow at sys.boot_completed, a bridge port holds no L3 address, and DomA
# therefore never completes DHCP on eth1 -- dnsmasq logs DHCPOFFER 192.168.10.13
# with no ACK. It stays correct for a build without the shadow AP. DomA's wlan0
# reservation is XT_DOMA_WLAN0_IP below.
XT_DOMA_IP          ??= "192.168.10.13"
# DomA eth0 static lease. Never answered either: eth0 is renamed to buried_eth0
# for minradio, so nothing asks for this MAC.
XT_DOMA_ETH0_IP     ??= "192.168.10.14"
# DomA wlan0 (hwsim station joined to the in-guest shadow AP). Outside the DHCP
# range on purpose, so a range change cannot move it: measured on the PC (netns,
# real dnsmasq 2.90), an unreserved station lands on a range address that MOVES
# when the range moves (.175 for .100-.200, .112 for .100-.150, .135 for
# .120-.200). DomA gets this address only when the MAC its station uses is on
# the dhcp-host line, i.e. when XT_DOMA_WLAN0_MAC below is set; by default it
# takes a range address.
XT_DOMA_WLAN0_IP    ??= "192.168.10.15"
XT_DHCP_RANGE_START ??= "192.168.10.100"
XT_DHCP_RANGE_END   ??= "192.168.10.200"

# --- Dom0<->DomD point-to-point vif subnet (192.168.0.0/24) ---
XT_NET_P2P_SUBNET ??= "192.168.0.0/24"
# Dom0 end of the vif
XT_DOM0_VIF_IP    ??= "192.168.0.1"
# DomD xen-netfront end of the vif
XT_DOMD_VIF_IP    ??= "192.168.0.11"

# --- guest MAC addresses (also fixed in /etc/xen/domX.cfg, shipped by
# xt-xen-cfg-*; those cfgs remain the authoritative NIC definition — these
# mirror them for the dnsmasq static leases) ---
XT_DOMU_MAC      ??= "08:00:27:ff:cb:c2"
# DomA eth1 (management / adb)
XT_DOMA_MAC      ??= "08:00:27:ff:cb:cf"
# DomA eth0
XT_DOMA_ETH0_MAC ??= "08:00:27:ff:cb:ce"
# DomA wlan0. The AAOS product also pins this address on br-shadow at boot for
# ADB deployment from DomD, so ADB does not depend on DHCP. The dnsmasq lease is
# still useful for normal DHCP operation when DomD's DHCP server is active. The
# AAOS product overlay disables connected-MAC randomization for this lab image,
# so the hwsim radio-0 perm_addr is the normal reservation key.
# XT_DOMA_WLAN0_MAC remains as an optional extra key for local experiments that
# re-enable randomization; dnsmasq accepts several MACs on one dhcp-host line
# (verified: both resolve to .15, an unrelated MAC still gets a range address).
# The dnsmasq bbappend drops this optional value when it is empty, so an unset
# value cannot produce a config dnsmasq refuses to parse.
XT_DOMA_WLAN0_MAC      ??= ""
# hwsim radio-0 perm_addr. mac80211_create_radios builds it as
# 02:<prefix hi>:<prefix lo>:00:<idx>:00 from ro.boot.wifi_mac_prefix=5554
# (0x15B2), so radio 0 is 02:15:b2:00:00:00.
XT_DOMA_WLAN0_PERM_MAC ??= "02:15:b2:00:00:00"
