#!/bin/bash
# Railway entrypoint for NodeBB.
#
# Order matters: everything that could let a stranger claim the forum has to be
# done before any process binds a port. NodeBB's stock deployment path on Railway
# is the opposite — the container starts with no config, NodeBB serves its web
# installer, and whoever loads the public URL first becomes the administrator.
set -euo pipefail

NODEBB_UID=1001
NODEBB_GID=1001
DATA_DIR="${NODEBB_DATA_DIR:-/data}"
CONFIG_DIR="${CONFIG_DIR:-/opt/config}"
CONFIG="$CONFIG_DIR/config.json"
MARKER="$DATA_DIR/config/.railway-setup-complete"

die() { echo "[railway] $1" >&2; exit 1; }

[ -n "${NODEBB_ADMIN_PASSWORD:-}" ] || die "NODEBB_ADMIN_PASSWORD is required. Refusing to start with no administrator password."
[ -n "${NODEBB_URL:-}" ] || die "NODEBB_URL is required."

export NODEBB_DB=postgres
# setpriv keeps the environment, so HOME would still be root's and npm would try to
# use a cache directory this uid cannot write.
export HOME=/usr/src/app
export npm_config_cache="${NODEBB_DATA_DIR:-/data}/npm-cache"
export NODEBB_ADMIN_USERNAME="${NODEBB_ADMIN_USERNAME:-admin}"
export NODEBB_ADMIN_EMAIL="${NODEBB_ADMIN_EMAIL:-admin@example.com}"

# Railway mounts the volume owned by uid 0 while the image runs as uid 1001.
mkdir -p "$DATA_DIR/config" "$DATA_DIR/build" "$DATA_DIR/uploads" "$DATA_DIR/npm-cache"
chown -R "$NODEBB_UID:$NODEBB_GID" "$DATA_DIR"

rm -rf "$CONFIG_DIR"
ln -sfn "$DATA_DIR/config" "$CONFIG_DIR"
rm -rf /usr/src/app/build /usr/src/app/public/uploads
ln -sfn "$DATA_DIR/build" /usr/src/app/build
ln -sfn "$DATA_DIR/uploads" /usr/src/app/public/uploads

# config.json is written with a JSON encoder, never with a shell.
node /railway/write-config.js "$CONFIG"
chown "$NODEBB_UID:$NODEBB_GID" "$CONFIG"

as_nodebb() {
	setpriv --reuid="$NODEBB_UID" --regid="$NODEBB_GID" --clear-groups "$@"
}

cd /usr/src/app

if [ ! -f "$MARKER" ]; then
	echo "[railway] first boot: installing NodeBB non-interactively"
	as_nodebb ./nodebb setup --config="$CONFIG"
	as_nodebb touch "$MARKER"
else
	echo "[railway] re-applying the administrator password"
	as_nodebb ./nodebb user reset 1 -p "$NODEBB_ADMIN_PASSWORD" --config="$CONFIG"
fi

exec setpriv --reuid="$NODEBB_UID" --regid="$NODEBB_GID" --clear-groups /usr/local/bin/entrypoint.sh "$@"
