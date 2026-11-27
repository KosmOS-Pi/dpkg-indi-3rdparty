#!/bin/bash
set -e

# DIAGNOSTICS ONLY: checks whether indi-libcamera needs our patch
# when built against the Raspberry Pi OS libcamera. No .deb is produced.

: "${PIGEN_DIR:?PIGEN_DIR is not set}"
: "${SRC_DIR:?SRC_DIR is not set}"
INDI_VERSION="${INDI_VERSION:-v2.2.5}"
RPI_FILES="$PIGEN_DIR/stage0/00-configure-apt/files"
W=/tmp/diag

# --- Raspberry Pi OS repository (no pinning yet) ---
install -m 644 "$RPI_FILES/raspberrypi-archive-keyring.pgp" /usr/share/keyrings/
sed "s/RELEASE/trixie/g" "$RPI_FILES/raspi.sources" \
  > /etc/apt/sources.list.d/raspi.sources
apt-get update -qq
apt-get install -y -qq --no-install-recommends patchutils cmake build-essential pkg-config

echo "== Simulated install of libcamera-dev + librpicam-app-dev"
apt-get -s install --no-install-recommends libcamera-dev librpicam-app-dev \
  | grep -E '^(Inst|Remv|E:)' || true

# --- Sources: same layout as build-package.sh ---
mkdir -p "$W" && cd "$W"
bash "$SRC_DIR/download.sh" "$INDI_VERSION"
PKG=indi-libcamera
SRC=$W/indi-3rdparty

echo "== Build dependencies of $PKG"
cd "$W"
mk-build-deps -i -r -t "apt-get -y --no-install-recommends" \
  "$SRC/debian/$PKG/control"

echo "== Installed libcamera / rpicam packages"
dpkg-query -W -f='${Package} ${Version}\n' 'libcamera*' 'librpicam*' 'libpisp*' || true

echo "== API names in the installed libcamera headers"
grep -rnE 'PixelArraySize|PixelArrayActiveAreas' /usr/include/libcamera | head -n 10 || true

echo "== API names used by the code"
grep -nE 'PixelArraySize|PixelArrayActiveAreas' "$SRC/$PKG/indi_libcamera.cpp" || true

# --- Patch variants ---
PATCH="$SRC_DIR/patches/04-indi-libcamera.diff"
filterdiff -p1 --include='*CMakeLists.txt' "$PATCH" > "$W/cmake-only.diff"
echo "== cmake-only.diff"
cat "$W/cmake-only.diff"

prepare() {  # prepare <name>
  mkdir -p "$W/$1"
  cp -r "$SRC/$PKG" "$W/$1/$PKG"
  cp -r "$SRC/cmake_modules" "$W/$1/"
  cp -r "$SRC/cmake_modules" "$W/$1/$PKG/"
}

try_build() {  # try_build <name>
  echo "::group::variant $1"
  if ( cd "$W/$1" \
       && cmake -S $PKG -B b -DCMAKE_INSTALL_PREFIX=/usr > cmake.log 2>&1 \
       && cmake --build b -j"$(nproc)" > make.log 2>&1 ); then
    echo "RESULT $1: OK"
  else
    echo "RESULT $1: FAILED"
    grep -hE 'error|Error|CMake Error' "$W/$1"/cmake.log "$W/$1"/make.log 2>/dev/null \
      | head -n 25 || true
  fi
  echo "::endgroup::"
}

prepare A-nopatch
try_build A-nopatch

prepare B-cmake-only
( cd "$W/B-cmake-only" && patch -p1 < "$W/cmake-only.diff" )
try_build B-cmake-only

prepare C-full-patch
( cd "$W/C-full-patch" && patch -p1 < "$PATCH" )
try_build C-full-patch

echo "== Diagnostics only: stopping here"
