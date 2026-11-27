#! /bin/bash

# exit on error
set -e

PKG=$1
: "${OUT_DIR:?OUT_DIR is not set}"
LOCALREPO="${LOCALREPO:-/tmp/localrepo}"

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
        # add only if it's available (Debian, Raspberry Pi OS or local repo)
        [ "$DEP" = "|" ] && continue
        if apt-cache show $DEP > /dev/null 2>&1; then
            TOINST="$TOINST $DEP"
        fi
    done
fi

if [ "$TOINST" ]; then
    apt-get -y install $TOINST
else
    echo ">>>>> Nothing to be installed"
fi

chmod 755 debian/rules
fakeroot debian/rules binary

# exiting package build folder
popd

ls *.deb > /dev/null 2>&1 || { echo "ERROR: $PKG produced no .deb"; exit 1; }

# Make the new packages visible to the next builds through the local repo
# (no dbgsym). Nothing is installed here: apt installs only what a later
# build asks for in its Build-Depends.
for f in *.deb; do
    case "$f" in
        *-dbgsym_*) ;;
        *) cp "$f" "$LOCALREPO"/ ;;
    esac
done
( cd "$LOCALREPO" && dpkg-scanpackages . /dev/null > Packages )
# Refresh only the local source: no network
apt-get update -qq \
    -o Dir::Etc::sourcelist=sources.list.d/localrepo.list \
    -o Dir::Etc::sourceparts=- \
    -o APT::Get::List-Cleanup=0

# move just compiled packages to the output folder
mv *.deb "$OUT_DIR"/

# clean up
rm -rf $PKGDIR
