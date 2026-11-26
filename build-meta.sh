#! /bin/bash

# exit on error
set -e

DEBCONTROL=indi-3rdparty-all/debian/control

ALLPKGS=$( ls indi-*.deb | egrep -v '.-dbgsym.|.-dbg.' | cut -d_ -f1 )

for p in $ALLPKGS; do
    echo "    $p," >> $DEBCONTROL
done

cat << EOF >> $DEBCONTROL
Description: INDI 3rd party drivers collection.
 This metapackage installs all packages for the available INDI 3rd party
 drivers.
EOF

for p in $ALLPKGS; do
    echo "  * $p" >> $DEBCONTROL
done

# build indi-3rdparty-all meta package
pushd indi-3rdparty-all
dpkg-buildpackage -uc -us -b
popd
