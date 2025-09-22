#! /bin/bash

# exit on error
set -e

#git clone --revision=v2.1.5 --depth 50 https://github.com/indilib/indi-3rdparty.git
git clone --branch=v2.1.5 --depth 1 https://github.com/indilib/indi-3rdparty.git
pushd indi-3rdparty

BUILD=../

LIBS=$( ls -d lib* )
DRVS=$( ls -d indi* )

mkdir -p $BUILD

for lib in $LIBS; do
    [ -d $BUILD/deb-$lib ] && rm -rf $BUILD/deb-$lib
    mkdir $BUILD/deb-$lib
    cp -r $lib $BUILD/deb-$lib
    cp -r debian/$lib $BUILD/deb-$lib/debian
    cp -r cmake_modules $BUILD/deb-$lib/
    pushd $BUILD/deb-$lib
    #dpkg-buildpackage -uc -us -b || { echo "Failed building $lib."; exit 1; }
    chmod 755 debian/rules
    fakeroot debian/rules binary
    popd
    pushd $BUILD
    sudo dpkg -i ${lib}_*.deb
    popd
done

for drv in $DRVS; do
    [ -d $BUILD/deb-$drv ] && rm -rf $BUILD/deb-$drv
    mkdir $BUILD/deb-$drv
    cp -r $drv $BUILD/deb-$drv
    cp -r debian/$drv $BUILD/deb-$drv/debian
    cp -r cmake_modules $BUILD/deb-$drv/
    pushd $BUILD/deb-$drv
    #dpkg-buildpackage -uc -us -b || { echo "Failed building $lib."; exit 1; }
    chmod 755 debian/rules
    fakeroot debian/rules binary
    popd
done

popd #indi-3rdparty

# move packages outside
mv *.deb ../

