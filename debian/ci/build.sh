#!/bin/bash
set -e

# Raspberry Pi OS repository: needed by indi-libcamera (librpicam-app-dev).
: "${PIGEN_DIR:?PIGEN_DIR is not set}"
RPI_FILES="$PIGEN_DIR/stage0/00-configure-apt/files"

install -m 644 "$RPI_FILES/raspberrypi-archive-keyring.pgp" /usr/share/keyrings/
sed "s/RELEASE/trixie/g" "$RPI_FILES/raspi.sources" \
  > /etc/apt/sources.list.d/raspi.sources
echo "== raspi.sources"
cat /etc/apt/sources.list.d/raspi.sources

apt-get update

echo "== apt-cache policy"
apt-cache policy librpicam-app-dev libcamera-dev libcamera0.5

echo "== Simulated install of librpicam-app-dev (nothing is installed)"
apt-get -s install --no-install-recommends librpicam-app-dev \
  | grep -E '^(Inst|Remv|E:)' || true

echo "== Diagnostics only: stopping here"

