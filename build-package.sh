#! /bin/bash

# exit on error
set -e

PKG=$1

[ -z "$PKG" ] && {
    echo "ERROR: missing package name"
    exit 1
}

echo "############################ $PKG ##############################"
PKGDIR=build-$PKG
[ -d $PKGDIR ] && rm -rf $PKGDIR

# Prepare folders
mkdir $PKGDIR
cp -r $PKG $PKGDIR
cp -r debian/$PKG $PKGDIR/debian
cp -r cmake_modules $PKGDIR
cp -r cmake_modules $PKGDIR/$PKG/

# entering package build folder
pushd $PKGDIR

# checking build dependencies
TOINST=''
echo ">>>>> Checking deps for $PKG"
if [ -f debian/control ]; then
    for DEP in $( dpkg-checkbuilddeps debian/control 2>&1 | cut -d: -f4 ); do
        # add only if it's available
        [ "$DEP" = "|" ] && continue
        if apt-cache show $DEP > /dev/null 2>&1; then
            TOINST="$TOINST $DEP"
        fi
    done
fi

if [ "$TOINST" ]; then
    sudo apt-get -y install $TOINST
else
    echo ">>>>> Nothing to be installed"
fi

#dpkg-buildpackage -uc -us -b || { echo "Failed building $lib."; exit 1; }
chmod 755 debian/rules
fakeroot debian/rules binary

# exiting package build folder
popd

if [ "$2" = "install" ]; then
    sudo dpkg -i *.deb || sudo apt-get -f install -y
fi

#move just compiled packages to parent dir
mv *.deb ../

# clean up
rm -rf $PKGDIR
