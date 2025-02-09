FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend := "${THISDIR}/../../recipes-domx:"

python __anonymous () {
    product_name = d.getVar('XT_PRODUCT_NAME', True)
    folder_name = product_name.replace("-", "_")
    d.setVar('XT_MANIFEST_FOLDER', folder_name)

    if d.getVar('XT_USE_VIS_SERVER', True) and not d.getVar("AOS_VIS_PACKAGE_DIR", True):
        d.appendVar("XT_QUIRK_BB_ADD_LAYER", " meta-aos")

    if product_name == "prod-devel-src": 
        if d.getVar('XT_RCAR_EVAPROPRIETARY_DIR'):
            bb.warn("Ingore XT_RCAR_EVAPROPRIETARY_DIR={} for {}".format(d.getVar('XT_RCAR_EVAPROPRIETARY_DIR'), d.getVar('XT_PRODUCT_NAME')))
            d.delVar("XT_RCAR_EVAPROPRIETARY_DIR")
}

SRC_URI = " \
    repo://github.com/0wn3r/manifests;protocol=https;branch=master;manifest=${XT_MANIFEST_FOLDER}/domd.xml;scmdata=keep \
"

XT_QUIRK_UNPACK_SRC_URI += " \
    file://meta-xt-prod-extra;subdir=repo \
    file://meta-xt-prod-domx;subdir=repo \
"

XT_QUIRK_BB_ADD_LAYER += " \
    meta-xt-prod-extra \
    meta-xt-prod-domx \
"

################################################################################
# Renesas R-Car H3ULCB ES3.0 8GB Kingfisher
################################################################################
XT_QUIRK_BB_ADD_LAYER_append_h3ulcb-4x2g-kf = " \
    meta-rcar/meta-rcar-gen3-adas \
"

configure_versions_kingfisher() {
    local local_conf="${S}/build/conf/local.conf"

    cd ${S}
    #FIXME: patch ADAS: do not use network setup as we provide our own
    base_add_conf_value ${local_conf} BBMASK "meta-rcar-gen3-adas/recipes-core/systemd"
    base_add_conf_value ${local_conf} BBMASK "meta-rcar-gen3-adas/recipes-bsp/optee"
    # Remove development tools from the image
    base_add_conf_value ${local_conf} IMAGE_INSTALL_remove " strace eglibc-utils ldd rsync gdbserver dropbear opkg git subversion nano cmake vim"
    base_add_conf_value ${local_conf} DISTRO_FEATURES_remove " opencv-sdk"
    # Do not enable surroundview which cannot be used
    base_add_conf_value ${local_conf} DISTRO_FEATURES_remove " surroundview"
    base_update_conf_value ${local_conf} PACKAGECONFIG_remove_pn-libcxx "unwind"

    # Remove the following if we use prebuilt EVA proprietary "graphics" packages
    if [ ! -z ${XT_RCAR_EVAPROPRIETARY_DIR} ];then
        base_update_conf_value ${local_conf} PACKAGECONFIG_remove_pn-cairo " egl glesv2"
    fi
}

python do_configure_append_h3ulcb-4x2g-kf() {
    bb.build.exec_func("configure_versions_kingfisher", d)
}

XT_BB_IMAGE_TARGET = "core-image-minimal"

# Dom0 is a generic ARMv8 machine w/o machine overrides,
# but still needs to know which system we are building,
# e.g. Salvator-X M3 or H3, for instance
# So, we provide machine overrides from this build the domain.
# The same is true for Android build.
addtask domd_install_machine_overrides after do_configure before do_compile
python do_domd_install_machine_overrides() {
    bb.debug(1, "Installing machine overrides")

    d.setVar('XT_BB_CMDLINE', "-f domd-install-machine-overrides")
    bb.build.exec_func("build_yocto_exec_bitbake", d)
}

################################################################################
# Renesas R-Car
################################################################################

XT_QUIRK_PATCH_SRC_URI_rcar = "\
    file://0001-rcar-gen3-arm-trusted-firmware-Allow-to-add-more-bui.patch;patchdir=meta-renesas \
    file://0001-copyscript-Set-GFX-Library-List-to-empty-string.patch;patchdir=meta-renesas \
    file://0001-recipes-kernel-Load-multimedia-related-modules-autom.patch;patchdir=meta-renesas \
    file://0001-armtf-Clarify-check-for-the-h3ulcb-based-machines-in.patch;patchdir=meta-renesas \
    file://0001-Update-meta-rcar-for-Yv510.patch;patchdir=meta-renesas \
    file://0001-0002-meta-renesas-gstreamer-change-git-protocol-at-h.patch;patchdir=meta-rcar \
    file://0001-gstreamer1.0-plugins-good-change-git-protocol-at-htt.patch;patchdir=meta-renesas \
    file://0001-gstreamer1.0-plugins-bad-change-git-protcol-at-https.patch;patchdir=meta-renesas \
    file://0001-Remove-Utest.patch;patchdir=meta-rcar \
"

XT_QUIRK_PATCH_SRC_URI_append_h3ulcb-4x2g-kf = "\
    file://0001-armtf-Add-missing-ADDITIONAL_ATFW_OPT-in-do_ipl_opt_.patch;patchdir=meta-rcar \
"

XT_BB_LOCAL_CONF_FILE_rcar = "meta-xt-prod-extra/doc/local.conf.rcar-domd-image-weston"
XT_BB_LAYERS_FILE_rcar = "meta-xt-prod-extra/doc/bblayers.conf.rcar-domd-image-weston"


# In order to copy proprietary "graphics" packages,
# XT_RCAR_EVAPROPRIETARY_DIR variable under [local_conf] section in
# the configuration file should point to the real packages location.
configure_versions_rcar() {
    local local_conf="${S}/build/conf/local.conf"

    cd ${S}
    base_add_conf_value ${local_conf} BBMASK "meta-xt-images-vgpu/recipes-graphics/gles-module/"
    base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-extra/recipes-graphics/gles-module/"
    base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-extra/recipes-graphics/rcar-proprietary-graphic/"
    base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-vgpu/recipes-graphics/gles-module/"
    base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-vgpu/recipes-graphics/wayland/"
    base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-vgpu/recipes-kernel/kernel-module-gles/"
    base_add_conf_value ${local_conf} BBMASK "meta-xt-images-vgpu/recipes-kernel/kernel-module-gles/"
    base_add_conf_value ${local_conf} BBMASK "meta-renesas/meta-rcar-gen3/recipes-kernel/kernel-module-gles/"
    base_add_conf_value ${local_conf} BBMASK "meta-renesas/meta-rcar-gen3/recipes-graphics/gles-module/"

    # HACK: force ipk instead of rpm b/c it makes troubles to PVR UM build otherwise
    base_update_conf_value ${local_conf} PACKAGE_CLASSES "package_ipk"

    # FIXME: normally bitbake fails with error if there are bbappends w/o recipes
    # which is the case for agl-demo-platform's recipe-platform while building
    # agl-image-weston: due to AGL's Yocto configuration recipe-platform is only
    # added to bblayers if building agl-demo-platform, thus making bitbake to
    # fail if this recipe is absent. Workaround this by allowing bbappends without
    # corresponding recipies.
    base_update_conf_value ${local_conf} BB_DANGLINGAPPENDS_WARNONLY "yes"

    # override console specified by default by the meta-rcar-gen3
    # to be hypervisor's one
    base_update_conf_value ${local_conf} SERIAL_CONSOLES "115200;hvc0"


    # set default timezone to Las Vegas
    base_update_conf_value ${local_conf} DEFAULT_TIMEZONE "US/Pacific"

    base_update_conf_value ${local_conf} XT_GUESTS_INSTALL "${XT_GUESTS_INSTALL}"

    # DomU based product doesn't need ivi-shell
    if echo "${XT_GUESTS_INSTALL}" | grep -qi "domu";then
        base_set_conf_value ${local_conf} DISTRO_FEATURES_remove "ivi-shell"
    fi

    if [ -n "${XT_USE_VIS_SERVER}" ]; then
        base_set_conf_value ${local_conf} DISTRO_FEATURES_append " vis"
        if [ ! -z "${AOS_VIS_PLUGINS}" ];then
            base_update_conf_value ${local_conf} AOS_VIS_PLUGINS "${AOS_VIS_PLUGINS}"
        fi
    else
        # Mask bbappend to avoid warning "No recipes available for"
        base_add_conf_value ${local_conf} BBMASK "meta-xt-prod-extra/recipes-aos/aos-vis/"
    fi

    # Disable shared link for GO packages
    base_set_conf_value ${local_conf} GO_LINKSHARED ""

    if [ -n "${XT_USE_VIS_SERVER}" ]; then
        if [ ! -z "${AOS_VIS_PACKAGE_DIR}" ];then
            base_update_conf_value ${local_conf} AOS_VIS_PACKAGE_DIR "${AOS_VIS_PACKAGE_DIR}"
        fi
    fi

    # Only Kingfisher variants have WiFi and bluetooth
    if echo "${MACHINEOVERRIDES}" | grep -qiv "kingfisher"; then
        base_add_conf_value ${local_conf} DISTRO_FEATURES_remove "wifi bluetooth"

        # We have netevent_%.bbappend that modifies
        # meta-rcar-gen3-adas/recipes-support/netevent/netevent_git.bb
        # and is intended to be used for Kingfisher only.
        # For other boards we need to mask our bbappend to avoid
        # warning "No recipes available for".
        base_add_conf_value ${local_conf} BBMASK "recipes-support/netevent"
    fi

    if [ ! -z "${XT_COMMON_DISTRO_FEATURES_APPEND}" ]; then
        base_set_conf_value ${local_conf} DISTRO_FEATURES_append " ${XT_COMMON_DISTRO_FEATURES_APPEND}"
    fi

    base_update_conf_value ${local_conf} XT_RCAR_PROPRIETARY_MULTIMEDIA_DIR "${XT_RCAR_PROPRIETARY_MULTIMEDIA_DIR}"
}

# In order to copy proprietary "multimedia" packages,
# XT_RCAR_PROPRIETARY_MULTIMEDIA_DIR variable under [local_conf] section in
# the configuration file should point to the real packages location.
copy_rcar_proprietary_multimedia() {
    local local_conf="${S}/build/conf/local.conf"

    if [ ! -z ${XT_RCAR_PROPRIETARY_MULTIMEDIA_DIR} ];then
        # Populate meta-renesas with proprietary software packages
        # (according to the https://elinux.org/R-Car/Boards/Yocto-Gen3)
        cd ${S}/meta-renesas
        sh meta-rcar-gen3/docs/sample/copyscript/copy_evaproprietary_softwares.sh -f ${XT_RCAR_PROPRIETARY_MULTIMEDIA_DIR}
    fi
}

python do_configure_append_rcar() {
    bb.build.exec_func("configure_versions_rcar", d)
    bb.build.exec_func("copy_rcar_proprietary_multimedia", d)
}

do_install_append () {
    local LAYERDIR=${TOPDIR}/../meta-xt-prod-devel
    find ${LAYERDIR}/doc -iname "u-boot-env*" -exec cp -f {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt \; || true
    find ${LAYERDIR}/doc -iname "mk_sdcard_image.sh" -exec cp -f {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt \; \
    -exec cp -f {} ${DEPLOY_DIR} \; || true
    if [ -n "${XT_USE_VIS_SERVER}" ]; then
        find ${DEPLOY_DIR}/${PN}/ipk/aarch64 -iname "aos-vis_git*" -exec cp -f {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt \; && \
        find ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt -iname "aos-vis_git*" -exec ln -sfr {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt/aos-vis \; || true
    fi
}
