IMAGE_INSTALL_append = " \
    pciutils \
    pulseaudio \
    alsa-utils \
    kernel-modules \
    kmscube \
    linux-firmware \
"

IMAGE_INSTALL_remove = " \
    optee-linuxdriver \
    optee-linuxdriver-armtz \
    optee-client \
    libx11-locale \
"

# Use only provided proprietary graphic modules
IMAGE_INSTALL_remove = " \
    packagegroup-graphics-renesas-proprietary \
"

CORE_IMAGE_BASE_INSTALL_remove += "gtk+3-demo clutter-1.0-examples"

populate_vmlinux () {
    find ${STAGING_KERNEL_BUILDDIR} -iname "vmlinux*" -exec mv {} ${DEPLOY_DIR_IMAGE} \; || true
}

IMAGE_POSTPROCESS_COMMAND += "populate_vmlinux; "

IMAGE_FSTYPES += "${@bb.utils.contains('DISTRO_FEATURES', 'qemu_xen', 'ext4', '', d)}"
