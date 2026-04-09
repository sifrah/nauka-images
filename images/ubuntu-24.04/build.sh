#!/usr/bin/env bash
# Build Ubuntu 24.04 Nauka image
# Requires: debootstrap, root privileges
set -euo pipefail

ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
IMAGE_NAME="ubuntu-24.04-${ARCH}"
ROOTFS=$(mktemp -d)

echo "Building ${IMAGE_NAME}..."

# 1. Bootstrap minimal Ubuntu
debootstrap --variant=minbase --arch=${ARCH} noble "${ROOTFS}" http://archive.ubuntu.com/ubuntu

# 2. Install essential packages
chroot "${ROOTFS}" apt-get install -y --no-install-recommends \
    openssh-server \
    iproute2 \
    iputils-ping \
    net-tools \
    passwd \
    ca-certificates \
    curl

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
