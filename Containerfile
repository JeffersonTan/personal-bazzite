## 1. BUILD ARGS
# These allow changing the produced image by passing different build args to adjust
# the source from which your image is built.
# Build args can be provided on the commandline when building locally with:
#   podman build -f Containerfile --build-arg FEDORA_VERSION=40 -t local-image

# SOURCE_IMAGE arg can be anything from ublue upstream which matches your desired version:
# See list here: https://github.com/orgs/ublue-os/packages?repo_name=main
# - "silverblue"
# - "kinoite"
# - "sericea"
# - "onyx"
# - "lazurite"
# - "vauxite"
# - "base"
#
#  "aurora", "bazzite", "bluefin" or "ucore" may also be used but have different suffixes.
ARG SOURCE_IMAGE="bazzite"

## SOURCE_SUFFIX arg should include a hyphen and the appropriate suffix name
# These examples all work for silverblue/kinoite/sericea/onyx/lazurite/vauxite/base
# - "-main"
# - "-nvidia"
# - "-asus"
# - "-asus-nvidia"
# - "-surface"
# - "-surface-nvidia"
#
# aurora, bazzite and bluefin each have unique suffixes. Please check the specific image.
# ucore has the following possible suffixes
# - stable
# - stable-nvidia
# - stable-zfs
# - stable-nvidia-zfs
# - (and the above with testing rather than stable)
ARG SOURCE_SUFFIX="-gnome"

## SOURCE_TAG arg must be a version built for the specific image: eg, 39, 40, gts, latest
ARG SOURCE_TAG="latest"

# Build HP plugin
FROM fedora-minimal:38 as builder

# Install build tools
RUN dnf5 install -y git rpmdevtools crudini

# Prepare build directory
RUN rpmdev-setuptree && \

    # Download the .spec for building an RPM
    git clone 'https://gitlab.com/greysector/rpms/hplip-plugin.git' && \
    mv hplip-plugin/hplip-plugin.spec /root/rpmbuild/SPECS/ && \
    mv hplip-plugin/* /root/rpmbuild/SOURCES/ && \
 
    # Download HP's plugins and move it to SOURCES
    HPLIP_VERSION=`grep -Eo '[0-9]\.[0-9].\.[0-9]' /root/rpmbuild/SPECS/hplip-plugin.spec | head -1` && \
    curl -Lo hplip-${HPLIP_VERSION}-plugin.run https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-${HPLIP_VERSION}-plugin.run && \
    curl -Lo hplip-${HPLIP_VERSION}-plugin.run.asc https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-${HPLIP_VERSION}-plugin.run.asc && \
    mv hplip-${HPLIP_VERSION}-plugin.* /root/rpmbuild/SOURCES/

RUN echo "Building hplip-plugin RPM" && \
    cd /root/rpmbuild && \

    # Confirm that the file exists
    ls -lh /root/rpmbuild/SPECS/hplip-plugin.spec && \
    rpmbuild -bb /root/rpmbuild/SPECS/hplip-plugin.spec

RUN ls /root/rpmbuild/RPMS/x86_64/hplip-plugin-*-1.x86_64.rpm && \
    HPLIP_VERSION=`ls /root/rpmbuild/RPMS/x86_64/hplip-plugin-*-1.x86_64.rpm | grep -Eo '[0-9]\.[0-9].\.[0-9]'` && \
    mv /root/rpmbuild/RPMS/x86_64/hplip-plugin-${HPLIP_VERSION}-1.x86_64.rpm /root/rpmbuild/RPMS/x86_64/hplip-plugin-latest-1.x86_64.rpm

### 2. SOURCE IMAGE
## this is a standard Containerfile FROM using the build ARGs above to select the right upstream image
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}
ENV OS_VERSION=41

# Copy build artifact
# ARG HPLIP_VERSION="3.24.4" # HPLIP version that's used
COPY --from=builder /root/rpmbuild/RPMS/x86_64/hplip-plugin-latest-1.x86_64.rpm /tmp

### 3. MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

COPY build.sh /root/build.sh

RUN mkdir -p /var/lib/alternatives && \
    /root/build.sh && \
    ostree container commit
## NOTES:
# - /var/lib/alternatives is required to prevent failure with some RPM installs
# - All RUN commands must end with ostree container commit
#   see: https://coreos.github.io/rpm-ostree/container/#using-ostree-container-commit
