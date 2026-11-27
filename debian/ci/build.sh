#!/bin/bash
set -e

: "${PIGEN_DIR:?PIGEN_DIR is not set}"
: "${SRC_DIR:?SRC_DIR is not set}"
: "${OUT_DIR:?OUT_DIR is not set}"
INDI_VERSION="${INDI_VERSION:-v2.2.5}"
PKGS="indi-libcamera"   # test only: build just these packages
RPI_FILES="$PIGEN_DIR/stage0/00-configure-apt/files"

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

apt-get update
apt-get install -y --no-install-recommends pkg-config

echo "== Check pinning"
apt-cache policy libcamera-dev librpicam-app-dev libpisp1
apt-get -s install --no-install-recommends libcamera-dev librpicam-app-dev \
  | grep -E '^(Inst|Remv|E:)' || true

# --- Sources and patches ---
cd "$SRC_DIR"
./download.sh "$INDI_VERSION"

PKGLIST="${PKGS:-$(grep -Ev '^#' pkgs.conf)}"

pushd indi-3rdparty
../apply-patches.sh

for PKG in $PKGLIST; do
    TOINST=
    [ "${PKG::3}" = "lib" ] && TOINST=install
    ../build-package.sh "$PKG" $TOINST
done
popd

# indi-3rdparty-all (build-meta.sh): not handled yet, see next step.
