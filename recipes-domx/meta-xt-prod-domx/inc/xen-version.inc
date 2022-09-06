
################################################################################
# Following inc file defines XEN version and needed glue info to get it
# built with the current yocto version
################################################################################
require recipes-extended/xen/xen-4.17-dunfell.inc

SRC_URI = "git://github.com/0wn3r/xen.git;protocol=https;branch=xen-4.17rc"
