#! /bin/bash

# exit on error
set -e

BLACKLIST=

[ -f blacklist.lst ] && BLACKLIST=$( cat blacklist.lst )

#git clone --revision=v2.1.5 --depth 50 https://github.com/indilib/indi-3rdparty.git
git clone --branch=v2.1.5 --depth 1 https://github.com/indilib/indi-3rdparty.git
pushd indi-3rdparty

[ -f ../patch.diff ] && patch -p1 < ../patch.diff

BUILD=../

LIBS=$( ls -d lib* )
DRVS=$( ls -d indi* )

mkdir -p $BUILD

for lib in $LIBS; do
    for b in $BLACKLIST; do
        [ "$b" = "$lib" ] && continue 2 #skip blacklisted lib
    done
    [ -d $BUILD/deb-$lib ] && rm -rf $BUILD/deb-$lib
    mkdir $BUILD/deb-$lib
    cp -r $lib $BUILD/deb-$lib
    cp -r debian/$lib $BUILD/deb-$lib/debian
    cp -r cmake_modules $BUILD/deb-$lib/
    cp -r cmake_modules $BUILD/deb-$lib/$lib/
    pushd $BUILD/deb-$lib
    #dpkg-buildpackage -uc -us -b || { echo "Failed building $lib."; exit 1; }
    chmod 755 debian/rules
    fakeroot debian/rules binary
    popd
    pushd $BUILD
    sudo dpkg -i *.deb || sudo apt -f install -y
    mv *.deb ../ #move just compiled packages to dest
    popd
done

for drv in $DRVS; do
    for b in $BLACKLIST; do
        [ "$b" = "$drv" ] && continue 2 #skip blacklisted drv
    done
    [ -d $BUILD/deb-$drv ] && rm -rf $BUILD/deb-$drv
    mkdir $BUILD/deb-$drv
    cp -r $drv $BUILD/deb-$drv
    cp -r debian/$drv $BUILD/deb-$drv/debian
    cp -r cmake_modules $BUILD/deb-$drv/
    cp -r cmake_modules $BUILD/deb-$drv/$drv/
    pushd $BUILD/deb-$drv
    #dpkg-buildpackage -uc -us -b || { echo "Failed building $lib."; exit 1; }
    chmod 755 debian/rules
    fakeroot debian/rules binary
    popd
    pushd $BUILD
    mv *.deb ../ #move just compiled packages to dest
    popd
done

popd #indi-3rdparty
