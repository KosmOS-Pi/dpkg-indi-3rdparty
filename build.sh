#! /bin/bash

# exit on error
set -e

./download.sh v2.1.6.2

# get packages list
PKGLIST=$( cat pkgs.conf | egrep -v '^#' )

# enter source folder
pushd indi-3rdparty

# Call script to apply patches
../apply-patches.sh

# build (and install if libs)
for PKG in $PKGLIST; do
    TOINST=
    [ "${PKG::3}" = "lib" ] && TOINST=install
    ../build-package.sh $PKG $TOINST
done

popd #indi-3rdparty

# build indi-3rdparty-all meta package
pushd indi-3rdparty-all
dpkg-buildpackage -uc -us -b
popd

# move packages to dest
mv *.deb ../

