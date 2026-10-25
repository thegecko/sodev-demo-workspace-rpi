SUMMARY = "Topo CLI release binary"
DESCRIPTION = "Topo discovers, configures, and deploys containerised software to Arm hardware over SSH."
HOMEPAGE = "https://github.com/arm/topo"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e0d54384330ad9d555f164ed84dc5c79"

SRC_URI = " \
    https://artifacts.tools.arm.com/topo/v${PV}/linux/topo_linux_arm64.tar.gz;downloadfilename=topo-${PV}-linux-arm64.tar.gz \
    file://LICENSE \
"
SRC_URI[sha256sum] = "8b8ecb81bb57e72187a71de54a1249e35b1009eb10ba018e8248fa4d1cb1383c"

S = "${UNPACKDIR}"

COMPATIBLE_HOST = "aarch64.*-linux"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/topo ${D}${bindir}/topo
}

FILES:${PN} = "${bindir}/topo"
INSANE_SKIP:${PN} += "already-stripped"
