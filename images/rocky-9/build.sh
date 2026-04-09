#!/usr/bin/env bash
# Build Rocky Linux 9 Nauka image
# Requires: dnf, root privileges
set -euo pipefail

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64) ARCH_NAME="amd64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    *) ARCH_NAME="${ARCH}" ;;
esac

IMAGE_NAME="rocky-9-container-${ARCH_NAME}"
ROOTFS=$(mktemp -d)

echo "Building ${IMAGE_NAME}..."

# 1. Bootstrap minimal Rocky Linux
dnf --installroot="${ROOTFS}" --releasever=9 \
    --repo=baseos --repo=appstream \
    --setopt=install_weak_deps=False \
    install -y \
    rocky-release \
    coreutils \
    bash \
    openssh-server \
    iproute \
    iputils \
    net-tools \
    passwd \
    ca-certificates \
    curl \
    rootfiles

# 2. Configure SSH
mkdir -p "${ROOTFS}/etc/ssh/sshd_config.d"
cat > "${ROOTFS}/etc/ssh/sshd_config.d/nauka.conf" << 'EOF'
PermitRootLogin yes
PasswordAuthentication no
PubkeyAuthentication yes
EOF

# Generate host keys
chroot "${ROOTFS}" ssh-keygen -A

# Create required runtime directories
mkdir -p "${ROOTFS}/run/sshd"
mkdir -p "${ROOTFS}/root/.ssh"
chmod 700 "${ROOTFS}/root/.ssh"

# 3. Set default root password (locked — SSH key only)
chroot "${ROOTFS}" passwd -l root

# 4. Clean up
dnf --installroot="${ROOTFS}" clean all
rm -rf "${ROOTFS}/var/cache/dnf/"*

# 5. Create tarball
echo "Creating ${IMAGE_NAME}.tar.gz..."
tar -czf "${IMAGE_NAME}.tar.gz" -C "${ROOTFS}" .

# Cleanup
rm -rf "${ROOTFS}"

SIZE=$(du -h "${IMAGE_NAME}.tar.gz" | cut -f1)
echo "Done: ${IMAGE_NAME}.tar.gz (${SIZE})"
