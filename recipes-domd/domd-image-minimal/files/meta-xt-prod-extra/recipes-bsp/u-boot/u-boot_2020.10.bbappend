FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append = " \
    file://0001-Enable-BOOTSTAGE-for-RCAR3.patch \
    file://0001-Toggle-LED6-on-kernel-start.patch \
"