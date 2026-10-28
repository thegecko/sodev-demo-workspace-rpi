# SPDX-License-Identifier: Apache-2.0
# DomU debug-image package set (static-IP + ssh network drop-in + Topo target
# runtime). The deployed DomU in the RPi5 stack boots a core-image-weston ext4
# rootfs from SD partition 3, not the rpi5-image-domu-gfx initramfs; keep the
# packages Topo checks for here too.
#
# Gated on the DomU MACHINE (virtio-armv8-xt). This .inc is required from the
# images-domu/ core-image-minimal.bbappend / core-image-weston.bbappend, which
# land on the GENERIC core-image-* recipes. bitbake applies a .bbappend to its
# target recipe regardless of the layer subdir it lives in, so without a gate the
# DomD build (MACHINE=raspberrypi5) would also pull in this DomU-only drop-in
# (cross-contamination). The MACHINE override makes it inert unless the DomU
# machine is active; the DomD-side install (images/, gated on raspberrypi5) is
# inert here, and vice versa.
IMAGE_INSTALL:append:virtio-armv8-xt = " domu-network docker-moby util-linux-lscpu"

ROOTFS_POSTPROCESS_COMMAND:append:virtio-armv8-xt = " enable_domu_docker; "

enable_domu_docker() {
    unit="${IMAGE_ROOTFS}${systemd_system_unitdir}/docker.service"
    wants="${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants"

    if [ ! -e "$unit" ]; then
        bbfatal "docker.service was not installed into the DomU rootfs"
    fi

    install -d "$wants"
    ln -sf "${systemd_system_unitdir}/docker.service" "$wants/docker.service"
}
