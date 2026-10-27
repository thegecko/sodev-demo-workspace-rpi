# SPDX-License-Identifier: MIT

# Topo checks `docker compose version` and requires >= 2.21.0. The Compose v2
# binary built by the upstream recipe on this image reported `Docker Compose
# version dev`, which Topo parsed as older than the minimum even though the plugin
# itself ran. Make the version metadata deterministic without changing Docker
# daemon packaging.
DOCKER_COMPOSE_VERSION ??= "${@'v' + (d.getVar('PV') or '2.21.0').split('+')[0].lstrip('v')}"

# Covers recipes that build through the upstream Makefile.
EXTRA_OEMAKE:append = " VERSION=${DOCKER_COMPOSE_VERSION}"

# Covers recipes that use go.bbclass/go-mod directly.
GO_LDFLAGS:append = " -X github.com/docker/compose/v2/internal.Version=${DOCKER_COMPOSE_VERSION}"

# Belt-and-braces fallback for recipes that neither pass VERSION nor GO_LDFLAGS
# through to the final `go build`: Compose keeps the development default as a Go
# variable initialised to "dev".
do_configure:append() {
    if grep -Rqs 'Version[[:space:]]*=[[:space:]]*"dev"' ${S}; then
        grep -Rsl 'Version[[:space:]]*=[[:space:]]*"dev"' ${S} \
            | xargs sed -i "s/Version[[:space:]]*=[[:space:]]*\"dev\"/Version = \"${DOCKER_COMPOSE_VERSION}\"/"
    fi
}
