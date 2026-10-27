SUMMARY = "DomD guest display backend selector"
DESCRIPTION = "Selects QEMU's Wayland/SDL or EGL headless display backend based on DomD DRM connector state."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://xt-guest-display-mode"
S = "${UNPACKDIR}"

RDEPENDS:${PN} = "xen-tools-xenstore"

do_install() {
    install -d ${D}${libexecdir}
    install -m 0755 ${UNPACKDIR}/xt-guest-display-mode ${D}${libexecdir}/xt-guest-display-mode
}

FILES:${PN} = "${libexecdir}/xt-guest-display-mode"
