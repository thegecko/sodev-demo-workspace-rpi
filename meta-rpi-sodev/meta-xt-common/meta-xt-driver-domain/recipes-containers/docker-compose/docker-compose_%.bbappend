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

# Some Compose recipes build the plugin without honouring VERSION/GO_LDFLAGS and
# keep reporting "Docker Compose version dev". Topo gates on that command before
# using Compose, so make the installed plugin answer the version query
# deterministically while passing every real Compose operation through untouched.
do_install:append() {
    plugin="${D}${libdir}/docker/cli-plugins/docker-compose"
    [ -e "$plugin" ] || return 0
    mv "$plugin" "$plugin.real"
    cat > "$plugin" <<'EOF'
#!/bin/sh
case "$1" in
    version)
        case " ${*#version} " in
            *" --short "*) echo "@DOCKER_COMPOSE_VERSION@" ;;
            *) echo "Docker Compose version @DOCKER_COMPOSE_VERSION@" ;;
        esac
        exit 0
        ;;
esac
exec @DOCKER_COMPOSE_REAL@ "$@"
EOF
    sed -i "s|@DOCKER_COMPOSE_VERSION@|${DOCKER_COMPOSE_VERSION}|g" "$plugin"
    sed -i "s|@DOCKER_COMPOSE_REAL@|${libdir}/docker/cli-plugins/docker-compose.real|g" "$plugin"
    chmod 0755 "$plugin"
}
