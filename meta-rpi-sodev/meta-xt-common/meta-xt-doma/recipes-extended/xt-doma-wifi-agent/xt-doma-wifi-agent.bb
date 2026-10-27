SUMMARY = "DomD-side agent for DomA's shadow-AP Wi-Fi"
DESCRIPTION = "\
    DomD owns the only real radio on the board. DomA does not get it -- its \
    devices are qemu device models, and its wlan0 has to be one that \
    WifiService manages -- so DomA simulates its radios with mac80211_hwsim \
    and beacons the SSIDs this agent reports, while this agent performs the \
    real association. \
\
    Transport: a qemu virtio-serial chardev, /run/android_vm_virtconsole5 (DomA sees \
    /dev/hvc4, because a virtconsole takes an hvc node). doma.cfg creates \
    five virtconsoles and one virtserialport, and this agent takes virts5. \
    Chosen over vsock and TCP because it needs no IP and no routing rules -- \
    DomA's policy routing sends unmarked traffic out a different interface. \
    This side is the client; qemu listens. \
\
    wpa_supplicant is driven directly over its control socket (AF_UNIX/SOCK_DGRAM at \
    /run/wpa_supplicant/wlan0). The shared DomD supplicant package owns the socket and \
    DHCP action service; this recipe only owns the DomA relay agent. \
\
    NOTE: a passphrase typed on the AAOS screen crosses this channel in the clear. A \
    shadow AP cannot learn a PSK from a 4-way handshake -- only a MIC crosses the air -- \
    so on-screen entry and a real association cannot both hold without forwarding it. \
    Lab use only. \
\
    The guest half is the AAOS device: init.xenvm-hwsim.rc plus \
    /vendor/bin/doma-shadow-ap and /vendor/bin/doma-wifi-relay. For the Pi 5 that is \
    meta-xt-doma/aosp-device/agl/xenvm-trout-rpi5, staged by stage-aosp-device.sh; \
    the Pi 4 takes its device from the manifest instead (device/sodev/xenvm-cf)."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://domd_wifi_agent.py \
    file://domd-wifi-agent.service \
"

S = "${UNPACKDIR}"

inherit systemd

# The supplicant/control-socket setup is provided by xt-domd-wifi-supplicant when
# DomD owns the real radio. DOM0_OS=linux keeps the radio in Dom0 and image
# packaging avoids this agent entirely.
SYSTEMD_SERVICE:${PN} = "domd-wifi-agent.service"
SYSTEMD_AUTO_ENABLE = "enable"

# python3 for the agent, with python3-io for its socket module; the common DomD
# supplicant package owns wpa_supplicant and the wlan0 DHCP action service.
RDEPENDS:${PN} = "python3-core python3-io python3-json ${@'' if d.getVar('DOM0_OS') == 'linux' else 'xt-domd-wifi-supplicant'}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/domd_wifi_agent.py ${D}${bindir}/domd_wifi_agent.py
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/domd-wifi-agent.service ${D}${systemd_system_unitdir}/domd-wifi-agent.service
}

FILES:${PN} = " \
    ${bindir}/domd_wifi_agent.py \
    ${systemd_system_unitdir}/domd-wifi-agent.service \
"


# Both boards give DomD the onboard Wi-Fi and use the same doma.cfg chardev, so
# allow both rather than gating and re-widening in a bbappend the way
# xt-aaos-host-services had to.
COMPATIBLE_MACHINE = "^(raspberrypi4-64|raspberrypi5)$"
