# ubuntu-26.04-server-bootc

Ubuntu 26.04 LTS "Resolute Raccoon" **server** bootc image.
Derives from the minimal base and adds cloud provisioning, networking,
firewall, time sync, and snap support.

```
ghcr.io/ubuntu-bootc/ubuntu-26.04-server-bootc:latest
```

## Image hierarchy

```
docker.io/library/ubuntu:26.04
└── ghcr.io/ubuntu-bootc/ubuntu-26.04-bootc
    ├── ghcr.io/ubuntu-bootc/ubuntu-26.04-server-bootc   ← you are here
    └── ghcr.io/ubuntu-bootc/ubuntu-26.04-desktop-bootc
```

| Image | Description |
|-------|-------------|
| [ubuntu-26.04-bootc](https://github.com/ubuntu-bootc/ubuntu-26.04-bootc) | Minimal base — kernel, bootc, dracut, ssh, podman |
| **[ubuntu-26.04-server-bootc](https://github.com/ubuntu-bootc/ubuntu-26.04-server-bootc)** | This image — server layer on top of the base |
| [ubuntu-26.04-desktop-bootc](https://github.com/ubuntu-bootc/ubuntu-26.04-desktop-bootc) | Desktop layer — GNOME 50, flatpak, ZFS, plymouth |

## What this adds over the base

| Package | Purpose |
|---------|---------|
| `cloud-init` | Provisioning (bare metal, cloud, VM) |
| `netplan.io` | Declarative network configuration |
| `ufw` | Uncomplicated firewall |
| `snapd` | Snap package support |
| `chrony` | NTP time synchronisation |
| `ubuntu-server-minimal` | Ubuntu server metapackage |

Everything from [ubuntu-26.04-bootc](https://github.com/ubuntu-bootc/ubuntu-26.04-bootc)
is also present: kernel 7.0, systemd-boot, dracut initramfs, bootc v1.15.2,
openssh-server, podman, skopeo, sssd, sudo.

## Building locally

```bash
just build
```

## Known issues

- [composefs verity regression on kernel 7.0](https://github.com/ubuntu-bootc/ubuntu-26.04-desktop-bootc/issues/2)
- [sysroot.mount / systemd-gpt-auto-generator quirk](https://github.com/ubuntu-bootc/ubuntu-26.04-desktop-bootc/issues/3)
