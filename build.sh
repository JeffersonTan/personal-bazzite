#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"


### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
rpm-ostree install screen

# this would install a package from rpmfusion
# rpm-ostree install vlc

#### Example for enabling a System Unit File

systemctl enable podman.socket

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

### Install HP drivers
echo "Installing HP bullcrap"

HPLIP_VERSION="3.23.12"

# mkdir /tmp/hplip
# curl -Lo "hplip-${HPLIP_VERSION}.tar.gz" "https://sourceforge.net/projects/hplip/files/hplip/${HPLIP_VERSION}/hplip-${HPLIP_VERSION}.tar.gz/download" && \
# 	mv hplip-${HPLIP_VERSION}.tar.gz /tmp/ && \
# 	tar -z -x --no-same-owner --no-same-permissions -f /tmp/hplip-${HPLIP_VERSION}.tar.gz -C /tmp/hplip --strip-components=1
# cp -r /tmp/hplip/prnt/ /usr/share/hplip/ && \
# 	rm -r /tmp/hplip

# All of that above was a dead end.

# Prepare build directory
cd /tmp/
mkdir rpmbuild
mkdir rpmbuild/BUILD
mkdir rpmbuild/BUILDROOT
mkdir -p rpmbuild/RPMS/x86_64
mkdir rpmbuild/SOURCES
mkdir rpmbuild/SPECS
mkdir rpmbuild/SRPMS

# Download the .spec for building an RPM
git clone 'https://gitlab.com/greysector/rpms/hplip-plugin.git' && \
mv hplip-plugin/hplip-plugin.spec rpmbuild/SPECS/
mv hplip-plugin/* rpmbuild/SOURCES/

# Download HP's plugins and move it to SOURCES
curl -Lo hplip-${HPLIP_VERSION}-plugin.run https://developers.hp.com/sites/default/files/hplip-${HPLIP_VERSION}-plugin.run
curl -Lo hplip-${HPLIP_VERSION}-plugin.run.asc https://developers.hp.com/sites/default/files/hplip-${HPLIP_VERSION}-plugin.run.asc
mv hplip-${HPLIP_VERSION}-plugin.* rpmbuild/SOURCES/

# Time to build
echo "Building hplip-plugin RPM"
cd rpmbuild
rpmbuild -bb SPECS/hplip-plugin.spec