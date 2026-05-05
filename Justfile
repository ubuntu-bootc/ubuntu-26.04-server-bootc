image_name     := env("IMAGE_NAME",     "ubuntu-26.04-server-bootc")
image_tag      := env("IMAGE_TAG",      "latest")
image_registry := env("IMAGE_REGISTRY", "ghcr.io/hanthor")
container_runtime := env("CONTAINER_RUNTIME", "podman")
sudo_cmd       := env("SUDO_CMD", "sudo")

# Build the server bootc image
build:
    {{sudo_cmd}} {{container_runtime}} build \
        ${PODMAN_EXTRA_ARGS:-} \
        -f Containerfile \
        -t "{{image_name}}:{{image_tag}}" \
        --label "org.opencontainers.image.source=https://github.com/ubuntu-bootc/ubuntu-26.04-server-bootc" \
        --label "org.opencontainers.image.description=Ubuntu 26.04 server bootc image" \
        .

clean:
    {{sudo_cmd}} {{container_runtime}} rmi "{{image_name}}:{{image_tag}}" 2>/dev/null || true

# Image structure tests
test-structure:
    {{sudo_cmd}} {{container_runtime}} run --rm \
        --security-opt label=disable \
        --security-opt seccomp=unconfined \
        "{{image_name}}:{{image_tag}}" \
        /bin/bash -c ' \
            set -euo pipefail; \
            echo "--- binary checks ---"; \
            for b in bootc cloud-init netplan ufw chronyc snap; do \
                command -v "$b" > /dev/null && echo "OK: $b" || { echo "MISSING: $b"; exit 1; }; \
            done; \
            echo "--- bootc layout ---"; \
            [[ -L /home ]] && echo "OK: /home -> var/home"; \
            echo "--- bootc lint ---"; \
            bootc container lint; \
            echo "ALL CHECKS PASSED"; \
        '
