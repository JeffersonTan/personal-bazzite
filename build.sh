#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# rpm-ostree install screen
rpm-ostree install zoxide
rpm-ostree install nodejs
rpm-ostree install dnf-plugins-core
rpm-ostree install hplip
rpm-ostree install hplip-common
rpm-ostree install hplip-gui
rpm-ostree install hplip-libs

# this would install a package from rpmfusion
# rpm-ostree install vlc

#### Example for enabling a System Unit File

systemctl enable podman.socket

# Install CoolerControl
wget -c https://copr.fedorainfracloud.org/coprs/codifryed/CoolerControl/repo/fedora-40/codifryed-CoolerControl-fedora-40.repo && mv "codifryed-CoolerControl-fedora-40.repo" "/etc/yum.repos.d/_copr_codifryed-CoolerControl-fedora-40.repo"
rpm-ostree install coolercontrol

### Install Windscribe
echo "Installing Windscribe VPN"

PACKAGE_NAME="Windscribe"
PACKAGE_OPT_NAME="windscribe"
UNPACK_PATH="/tmp/${PACKAGE_NAME}"
OPT_PATH="/usr/lib/${PACKAGE_OPT_NAME}"

mkdir -p /var/opt

curl -Lo windscribe.rpm https://windscribe.com/install/desktop/linux_rpm_x64
rpm-ostree install windscribe.rpm

mv "/opt/$PACKAGE_OPT_NAME" "$OPT_PATH"

ln -s "${OPT_PATH}/Windscribe" /usr/bin

# Register path symlink
# We do this via tmpfiles.d so that it is created by the live system.
# use \x20 for whitespace as spec.
cat >/usr/lib/tmpfiles.d/windscribe.conf <<EOF
L  /opt/windscribe /usr/lib/windscribe
EOF

# Enable systemd unit(s)
systemctl enable windscribe-helper
systemctl enable coolercontrold

### Install HP drivers
echo "Installing HP bullcrap"

rpm-ostree install /tmp/hplip-plugin-latest-1.x86_64.rpm
