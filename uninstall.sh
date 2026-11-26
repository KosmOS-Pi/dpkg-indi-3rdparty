#! /bin/bash

# get packages list
PKGLIST=$( cat pkgs.conf | egrep -v '^#' )

for PKG in $PKGLIST; do
    if [ "${PKG::3}" = "lib" ]; then
        apt-get -y purge $PKG
    fi
done

