# Nauka Images

Pre-built OS images for the [Nauka](https://github.com/sifrah/nauka) cloud platform.

## Available images

| Image | Arch | Size | Description |
|---|---|---|---|
| `ubuntu-24.04` | amd64 | ~180MB | Ubuntu 24.04 LTS with SSH, networking tools |

## Usage

```bash
# Pull an image on a Nauka node
nauka vm image pull ubuntu-24.04

# Create a VM with that image
nauka vm create web-1 --image ubuntu-24.04 ...
```

## Building images locally

```bash
cd images/ubuntu-24.04
sudo ./build.sh
# Creates ubuntu-24.04-amd64.tar.gz
```

## Image contents

Each image includes:
- Base OS (minimal install)
- `openssh-server` (with root login enabled, pubkey auth)
- `iproute2`, `iputils-ping`, `net-tools`
- SSH host keys pre-generated
- `/run/sshd` directory created
