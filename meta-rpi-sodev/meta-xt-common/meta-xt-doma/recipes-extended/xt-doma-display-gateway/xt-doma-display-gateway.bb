SUMMARY = "Browser display and input gateway for the DomA Android guest"
DESCRIPTION = "Serves a small HTTP UI from DomD for viewing DomA and sending keyboard/mouse input over adb."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://doma-display-gateway \
    file://doma-display-gateway.service \
"

S = "${UNPACKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "doma-display-gateway.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} = " \
    python3-core \
    python3-modules \
    xt-doma-adb \
"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/doma-display-gateway ${D}${bindir}/doma-display-gateway

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/doma-display-gateway.service ${D}${systemd_system_unitdir}/doma-display-gateway.service
}

FILES:${PN} = " \
    ${bindir}/doma-display-gateway \
    ${systemd_system_unitdir}/doma-display-gateway.service \
"

COMPATIBLE_MACHINE = "^(raspberrypi4-64|raspberrypi5)$"
