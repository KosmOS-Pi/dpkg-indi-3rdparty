#!/bin/bash
set -e

: "${PIGEN_DIR:?PIGEN_DIR is not set}"
: "${SRC_DIR:?SRC_DIR is not set}"
: "${OUT_DIR:?OUT_DIR is not set}"
INDI_VERSION="${INDI_VERSION:-v2.2.5}"
# PKGS="libfli indi-fli"   # test only: build just these packages
RPI_FILES="$PIGEN_DIR/stage0/00-configure-apt/files"
export LOCALREPO=/tmp/localrepo

# --- Raspberry Pi OS repository (needed by indi-libcamera) ---
install -m 644 "$RPI_FILES/raspberrypi-archive-keyring.pgp" /usr/share/keyrings/
sed "s/RELEASE/trixie/g" "$RPI_FILES/raspi.sources" \
  > /etc/apt/sources.list.d/raspi.sources

# Low priority for everything from Raspberry Pi OS, normal priority only for
# the camera stack: the other build dependencies keep coming from Debian.
cat > /etc/apt/preferences.d/raspi.pref <<'EOF'
Package: *
Pin: origin archive.raspberrypi.com
Pin-Priority: 100

Package: libcamera* librpicam-app* libpisp*
Pin: origin archive.raspberrypi.com
Pin-Priority: 500
EOF

# --- Local repository: packages built here, visible to later builds ---
mkdir -p "$LOCALREPO"
chmod 755 "$LOCALREPO"
: > "$LOCALREPO/Packages"
echo "deb [trusted=yes] file:$LOCALREPO ./" > /etc/apt/sources.list.d/localrepo.list

apt-get update
echo "== Check pinning"
apt-cache policy libcamera-dev librpicam-app-dev libpisp1

# Tools used by the INDI build scripts but not declared in the control files.
apt-get install -y --no-install-recommends pkg-config

# --- Sources and patches ---
cd "$SRC_DIR"
./download.sh "$INDI_VERSION"

PKGLIST="${PKGS:-$(grep -Ev '^#' pkgs.conf)}"

pushd indi-3rdparty
../apply-patches.sh

# Order matters: libraries first (pkgs.conf), then drivers. A library is
# installed in the build environment only if a later package needs it.
for PKG in $PKGLIST; do
    ../build-package.sh "$PKG"
done
popd

echo "== Installed lib packages from the local repo"
dpkg-query -W -f='${Package} ${Version}\n' | grep -E 'lib' | grep -E '2\.[0-9]' || true

# indi-3rdparty-all (build-meta.sh): not handled yet.
