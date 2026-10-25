SUMMARY = "DomD-side ADB helper for the DomA Android guest"
DESCRIPTION = "Installs the adb client in DomD and a wrapper that targets DomA over the internal Xen management network."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

require recipes-connectivity/sodev-net.inc

SRC_URI = "file://doma-adb"

S = "${UNPACKDIR}"

# meta-openembedded's android-tools package provides the host-side adb client.
RDEPENDS:${PN} = "android-tools"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/doma-adb ${D}${bindir}/doma-adb
    sed -i 's|@XT_DOMA_IP@|${XT_DOMA_IP}|g' ${D}${bindir}/doma-adb
    sed -i 's|@XT_DOMA_WLAN0_IP@|${XT_DOMA_WLAN0_IP}|g' ${D}${bindir}/doma-adb
}

FILES:${PN} = "${bindir}/doma-adb"

COMPATIBLE_MACHINE = "^(raspberrypi4-64|raspberrypi5)$"
