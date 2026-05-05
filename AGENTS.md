# AGENTS.md — ubuntu-26.04-server-bootc

## What this repo is

Ubuntu 26.04 LTS **server** bootc image. Derives from
[hanthor/ubuntu-26.04-bootc](https://github.com/ubuntu-bootc/ubuntu-26.04-bootc)
(the minimal base — kernel, systemd-boot, dracut, bootc, openssh, podman).
This layer adds server-specific packages only.

```
ubuntu:26.04
└── ubuntu-26.04-bootc          (kernel, bootc, dracut, ssh, podman)
    └── ubuntu-26.04-server-bootc  ← this repo
```

Published to: `ghcr.io/ubuntu-bootc/ubuntu-26.04-server-bootc:latest`

## What this adds over the base

| Package | Purpose |
|---------|---------|
| `cloud-init` | Provisioning (bare metal, cloud, VM) |
| `netplan.io` | Declarative network configuration |
| `ufw` | Uncomplicated firewall |
| `snapd` | Snap package support |
| `chrony` | NTP time synchronisation |
| `ubuntu-server-minimal` | Ubuntu server metapackage |

## Repository map

```
Containerfile          FROM ghcr.io/ubuntu-bootc/ubuntu-26.04-bootc:latest + server pkgs
Justfile               build, test-structure
shared/
  bootc-rootfs.sh      Re-run after apt to wipe /var (inherited from base)
.github/workflows/
  build.yaml           CI: build + push to GHCR
```

## Critical: bootc-rootfs.sh must re-run

The base image runs `bootc-rootfs.sh` which wipes `/var`. When this image
installs packages, `apt` writes back into `/var` (dpkg database, etc.).
`bootc-rootfs.sh` is therefore re-run at the end of this Containerfile to
wipe `/var` again before the final image is committed.

## Deriving from this image

```dockerfile
FROM ghcr.io/ubuntu-bootc/ubuntu-26.04-server-bootc:latest

RUN apt-get update && apt-get install -y my-server-package && apt-get clean
# Re-run bootc-rootfs.sh after any apt installs that write to /var
```
