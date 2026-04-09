#!/usr/bin/env bash
# Build Debian 12 Nauka image
# Requires: debootstrap, root privileges
set -euo pipefail

ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
IMAGE_NAME="debian-12-container-${ARCH}"
ROOTFS=$(mktemp -d)

echo "Building ${IMAGE_NAME}..."

# 1. Bootstrap minimal Debian
debootstrap --variant=minbase --arch=${ARCH} bookworm "${ROOTFS}" http://deb.debian.org/debian

# 2. Install essential packages
chroot "${ROOTFS}" apt-get install -y --no-install-recommends \
    openssh-server \
    iproute2 \
    iputils-ping \
    net-tools \
    passwd \
    ca-certificates \
    curl

# 2b. Install tini (static binary for zombie reaping)
TINI_VERSION="v0.19.0"
curl -fsSL "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${ARCH}" \
    -o "${ROOTFS}/usr/bin/tini"
chmod +x "${ROOTFS}/usr/bin/tini"

# 3. Configure SSH
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

# 4. Set default root password (locked — SSH key only)
chroot "${ROOTFS}" passwd -l root

# 5. Clean up apt cache
chroot "${ROOTFS}" apt-get clean
rm -rf "${ROOTFS}/var/lib/apt/lists/"*

# 6. Create tarball
echo "Creating ${IMAGE_NAME}.tar.gz..."
tar -czf "${IMAGE_NAME}.tar.gz" -C "${ROOTFS}" .

# Cleanup
rm -rf "${ROOTFS}"

SIZE=$(du -h "${IMAGE_NAME}.tar.gz" | cut -f1)
echo "Done: ${IMAGE_NAME}.tar.gz (${SIZE})"
