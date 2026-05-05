# Provides a pristine dpkg/apt database to restore in the system stage.
FROM docker.io/library/ubuntu:26.04 AS dpkg-state

# Ubuntu 26.04 server image — derives from the minimal bootc base.
FROM ghcr.io/hanthor/ubuntu-26.04-bootc:latest AS system

ENV DEBIAN_FRONTEND=noninteractive

# Restore the dpkg/apt database from the pristine ubuntu:26.04 stage.
# The base image ran bootc-rootfs.sh which wiped /var; apt-get will not
# work without a valid dpkg status and the supporting directory tree.
COPY --from=dpkg-state /var/lib/dpkg /var/lib/dpkg
RUN mkdir -p /var/cache/apt/archives/partial /var/lib/apt/lists/partial /var/log/apt

# Bring bootc-rootfs.sh into the build context so we can re-run it.
FROM scratch AS ctx
COPY shared/ /shared

FROM system

# Server packages: provisioning, networking, firewall, time sync, snaps.
RUN --mount=type=tmpfs,dst=/tmp \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        chrony \
        cloud-init \
        netplan.io \
        snapd \
        ubuntu-server-minimal \
        ufw && \
    # kdump-tools (pulled in by ubuntu-server-minimal) fails postinst without dbus;
    # remove it — crash dumps are not useful in a bootc image context.
    apt-get remove -y kdump-tools 2>/dev/null || true && \
    systemctl enable --root / chrony.service ufw.service && \
    # cloud-init units may not register until first boot; ignore if missing
    systemctl enable --root / \
        cloud-init.service \
        cloud-init-local.service \
        cloud-config.service \
        cloud-final.service 2>/dev/null || true && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Re-run bootc-rootfs.sh to wipe /var (packages above wrote dpkg/apt state
# into /var; bootc requires /var to be empty in the image).
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/shared/bootc-rootfs.sh

# Clean up runtime directories left by post-install scripts.
RUN find /run -mindepth 1 -maxdepth 1 ! -name 'secrets' -exec rm -rf {} + ; \
    rm -rf /tmp/*

RUN bootc container lint
