# Provides a pristine dpkg/apt database to restore in the system stage.
FROM docker.io/library/ubuntu:26.04 AS dpkg-state

# Copy build scripts into build context
FROM scratch AS ctx
COPY shared/ /shared

# ── Bootc builder ─────────────────────────────────────────────────────────────
FROM docker.io/library/ubuntu:26.04 AS builder

RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root --mount=type=tmpfs,dst=/boot \
    apt-get update -y && \
    apt-get install -y \
        build-essential \
        curl \
        git \
        go-md2man \
        libostree-dev \
        libzstd-dev \
        make \
        ostree \
        pkgconf && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

ENV CARGO_HOME=/tmp/rust
ENV RUSTUP_HOME=/tmp/rust
WORKDIR /home/build
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" | sh -s -- --profile minimal -y && \
    sh -c ". ${RUSTUP_HOME}/env ; /ctx/shared/build.sh"

# ── System stage ──────────────────────────────────────────────────────────────
FROM docker.io/library/ubuntu:26.04 AS system

# Copy bootc binary from builder
COPY --from=builder /output/ /

ENV DEBIAN_FRONTEND=noninteractive

# Install bootc runtime dependencies

# Restore the dpkg/apt database from the pristine ubuntu:26.04 stage.
# The bootc-rootfs.sh step (later) will wipe /var; apt-get will not
# work without a valid dpkg status and the supporting directory tree.
COPY --from=dpkg-state /var/lib/dpkg /var/lib/dpkg
RUN mkdir -p /var/cache/apt/archives/partial /var/lib/apt/lists/partial /var/log/apt

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
