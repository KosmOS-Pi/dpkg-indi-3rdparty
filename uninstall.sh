#! /bin/bash

# get packages list
PKGLIST=$( cat pkgs.conf | egrep -v '^#' )

# build (and install if libs)
for PKG in $PKGLIST; do
    TOINST=
    [ "${PKG::3}" = "lib" ] && TOINST=install
    ../build-package.sh $PKG $TOINST
done

