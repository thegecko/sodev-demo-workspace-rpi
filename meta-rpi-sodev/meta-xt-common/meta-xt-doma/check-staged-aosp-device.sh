#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Verify that the AOSP checkout contains the board device tree staged from this
# layer, and force moulin's Android component dirty when that staged content
# changes. stage-aosp-device.sh mutates the repo checkout outside ninja's graph;
# without this, `ninja doma` can consider its stamp up to date and keep shipping
# old vendor.img/super.img content after only meta-xt-doma/aosp-device changed.
set -eu

ROOT="${1:-}"
BOARD="${2:-}"
PRODUCT_DEVICE="${3:-}"
CLEAN_TARGET="${4:-}"

if [ -z "$ROOT" ] || [ -z "$BOARD" ] || [ -z "$PRODUCT_DEVICE" ]; then
	echo "usage: $0 <AOSP_ROOT> <rpi5|rpi4> <product-device> [ninja-clean-target]" >&2
	exit 1
fi
[ -d "$ROOT/.repo" ] || { echo "ERROR: $ROOT is not a repo checkout." >&2; exit 1; }

hash_tree() {
	# Paths are repo-controlled/staged source paths and should not contain newlines, but
	# use NUL delimiters anyway so this remains safe for arbitrary filenames.
	find "$@" -type f -print0 \
		| sort -z \
		| xargs -0 sha256sum \
		| sha256sum \
		| awk '{print $1}'
}

case "$BOARD" in
rpi5)
	PATHS="device/agl/xenvm-trout-rpi5 device/agl/common device/agl/doma-common"
	for d in $PATHS; do
		[ -d "$ROOT/$d" ] || { echo "ERROR: staged AOSP device dir missing: $ROOT/$d" >&2; exit 1; }
	done
	SHADOW="$ROOT/device/agl/xenvm-trout-rpi5/xenvm_trout_rpi5_arm64/doma-shadow-ap.sh"
	ADBD="$ROOT/device/agl/xenvm-trout-rpi5/xenvm_trout_rpi5_arm64/doma-adbd-tcp.sh"
	for f in "$SHADOW" "$ADBD"; do
		[ -f "$f" ] || { echo "ERROR: staged AOSP device file missing: $f" >&2; exit 1; }
	done
	# These are the route/address fixes required for DomD -> DomA ADB/screencap on rpi5.
	# If this fails, the AOSP checkout is stale even if source mode is selected.
	grep -q 'MGMT_ADDR=.*192[.]168[.]10[.]13/24' "$SHADOW" \
		|| { echo "ERROR: $SHADOW is missing the br-shadow management address fix." >&2; exit 1; }
	grep -q 'ip rule add to.*MGMT_SUBNET.*lookup main' "$SHADOW" \
		|| { echo "ERROR: $SHADOW is missing the management subnet policy-route fix." >&2; exit 1; }
	grep -q 'prefer_mgmt_route' "$ADBD" \
		|| { echo "ERROR: $ADBD is missing the management route fallback." >&2; exit 1; }
	;;
rpi4)
	PATHS="device/sodev/xenvm-cf"
	[ -d "$ROOT/device/sodev/xenvm-cf" ] \
		|| { echo "ERROR: rpi4 AOSP device missing: $ROOT/device/sodev/xenvm-cf" >&2; exit 1; }
	;;
*)
	echo "ERROR: unknown board '$BOARD' (expected rpi5 or rpi4)." >&2
	exit 1
	;;
esac

STAMP_DIR="$ROOT/out/target/product/$PRODUCT_DEVICE"
STAMP="$STAMP_DIR/.xt-staged-aosp-device.sha256"
mkdir -p "$STAMP_DIR"

# shellcheck disable=SC2086 # PATHS is intentionally a space-separated list of fixed paths.
new=$(cd "$ROOT" && hash_tree $PATHS)
old=""
[ -f "$STAMP" ] && old=$(cat "$STAMP" 2>/dev/null || true)

if [ "$new" != "$old" ]; then
	echo ">> staged AOSP device content changed; invalidating Android component '${CLEAN_TARGET:-none}'"
	if [ -n "$CLEAN_TARGET" ]; then
		# This script is called from the workspace root after `ninja fetch-*`, so build.ninja
		# exists here. Failure to clean should not hide the actual Android build diagnostic.
		ninja -t clean "$CLEAN_TARGET" >/dev/null 2>&1 || true
	fi
	printf '%s\n' "$new" > "$STAMP"
else
	echo ">> staged AOSP device content unchanged"
fi
