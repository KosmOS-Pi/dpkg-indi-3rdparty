#! /bin/bash

# exit on error
set -e

: "${OUT_DIR:?OUT_DIR is not set}"
: "${INDI_VERSION:?INDI_VERSION is not set}"
HERE=$(cd "$(dirname "$0")" && pwd)

# Work on a copy: the tracked debian/control is never modified.
W=$(mktemp -d)
cp -r "$HERE/indi-3rdparty-all" "$W/"
META=$W/indi-3rdparty-all
CONTROL=$META/debian/control

ALLPKGS=$( ls "$OUT_DIR"/indi-*.deb | xargs -n1 basename \
           | grep -Ev -- '-dbgsym_|-dbg_' | cut -d_ -f1 | sort -u )
[ -n "$ALLPKGS" ] || { echo "ERROR: no indi-*.deb in $OUT_DIR"; exit 1; }

for p in $ALLPKGS; do
    echo "    $p," >> "$CONTROL"
done

cat << EOF >> "$CONTROL"
Description: INDI 3rd party drivers collection.
 This metapackage installs all packages for the available INDI 3rd party
 drivers.
EOF

for p in $ALLPKGS; do
    echo "  * $p" >> "$CONTROL"
done

bash "$HERE/set-version.sh" indi-3rdparty-all "$META/debian/changelog" --meta

# build indi-3rdparty-all meta package
pushd "$META"
dpkg-buildpackage -uc -us -b
popd

mv "$W"/indi-3rdparty-all_*.deb "$OUT_DIR"/
rm -rf "$W"
