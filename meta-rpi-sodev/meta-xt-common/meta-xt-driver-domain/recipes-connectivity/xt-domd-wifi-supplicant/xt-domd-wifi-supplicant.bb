SUMMARY = "DomD Wi-Fi supplicant and DHCP integration"
DESCRIPTION = "Runs wpa_supplicant for DomD's real wlan0 and starts DHCP when the device-console app or another client associates it with an AP."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://wpa_supplicant-wlan0.conf \
    file://domd-wpa-supplicant.service \
    file://domd-wifi-dhcp.service \
    file://domd-wifi-dhcp-action \
"

S = "${UNPACKDIR}"

inherit systemd

require recipes-connectivity/sodev-net.inc

SYSTEMD_SERVICE:${PN} = "domd-wpa-supplicant.service domd-wifi-dhcp.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} = "busybox-udhcpc wpa-supplicant wpa-supplicant-cli"

do_install() {
    install -d ${D}${sysconfdir}
    install -m 0600 ${UNPACKDIR}/wpa_supplicant-wlan0.conf ${D}${sysconfdir}/wpa_supplicant-wlan0.conf

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/domd-wpa-supplicant.service ${D}${systemd_system_unitdir}/domd-wpa-supplicant.service
    install -m 0644 ${UNPACKDIR}/domd-wifi-dhcp.service ${D}${systemd_system_unitdir}/domd-wifi-dhcp.service

    install -d ${D}${libexecdir}
    install -m 0755 ${UNPACKDIR}/domd-wifi-dhcp-action ${D}${libexecdir}/domd-wifi-dhcp-action
    sed -i 's|@SODEV_MANAGEMENT_HOSTNAME@|${SODEV_NET_MANAGEMENT_HOSTNAME}|g' \
        ${D}${libexecdir}/domd-wifi-dhcp-action
}

FILES:${PN} = " \
    ${sysconfdir}/wpa_supplicant-wlan0.conf \
    ${systemd_system_unitdir}/domd-wpa-supplicant.service \
    ${systemd_system_unitdir}/domd-wifi-dhcp.service \
    ${libexecdir}/domd-wifi-dhcp-action \
"

CONFFILES:${PN} = "${sysconfdir}/wpa_supplicant-wlan0.conf"
COMPATIBLE_MACHINE = "^(raspberrypi4-64|raspberrypi5)$"
