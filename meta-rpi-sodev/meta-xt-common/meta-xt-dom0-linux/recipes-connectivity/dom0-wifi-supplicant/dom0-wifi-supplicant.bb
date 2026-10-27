SUMMARY = "Linux Dom0 Wi-Fi supplicant and DHCP integration"
DESCRIPTION = "Runs wpa_supplicant and DHCP for the real Raspberry Pi Wi-Fi radio when Linux Dom0 owns wlan0."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://wpa_supplicant-wlan0.conf \
    file://dom0-wpa-supplicant.service \
    file://dom0-wifi-dhcp.service \
    file://dom0-wifi-dhcp-action \
"

S = "${UNPACKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "dom0-wpa-supplicant.service dom0-wifi-dhcp.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} = "busybox-udhcpc wpa-supplicant wpa-supplicant-cli"

do_install() {
    install -d ${D}${sysconfdir}
    install -m 0600 ${UNPACKDIR}/wpa_supplicant-wlan0.conf ${D}${sysconfdir}/wpa_supplicant-wlan0.conf

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/dom0-wpa-supplicant.service ${D}${systemd_system_unitdir}/dom0-wpa-supplicant.service
    install -m 0644 ${UNPACKDIR}/dom0-wifi-dhcp.service ${D}${systemd_system_unitdir}/dom0-wifi-dhcp.service

    install -d ${D}${libexecdir}
    install -m 0755 ${UNPACKDIR}/dom0-wifi-dhcp-action ${D}${libexecdir}/dom0-wifi-dhcp-action
}

FILES:${PN} = " \
    ${sysconfdir}/wpa_supplicant-wlan0.conf \
    ${systemd_system_unitdir}/dom0-wpa-supplicant.service \
    ${systemd_system_unitdir}/dom0-wifi-dhcp.service \
    ${libexecdir}/dom0-wifi-dhcp-action \
"

CONFFILES:${PN} = "${sysconfdir}/wpa_supplicant-wlan0.conf"
COMPATIBLE_MACHINE = "^raspberrypi5$"
