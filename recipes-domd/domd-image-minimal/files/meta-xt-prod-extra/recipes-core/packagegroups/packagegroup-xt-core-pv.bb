SUMMARY = "Para-virtualized components"

LICENSE = "MIT"

inherit packagegroup

RDEPENDS_packagegroup-xt-core-pv = "\
    libxenbe \
    sndbe \
    ${@bb.utils.contains('DISTRO_FEATURES', 'virtio', 'virtio-disk', '', d)} \
"
