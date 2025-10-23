#! /bin/bash

for FLD in $( ls -d debian/indi-* ); do
    PKG=$( basename $FLD )
    TMP=$( cat $FLD/changelog | head -n1 | grep -E -o '\(.+\)' )
    VER=${TMP:1:-1}
    if [ -z "$1" ]; then
        cat $FLD/changelog | sed "s/($VER)/(2:$VER-1)/" > $FLD/changelog.new
        mv $FLD/changelog.new $FLD/changelog
    else
        echo $PKG  $VER
    fi
done

for FLD in $( ls -d debian/lib* ); do
    PKG=$( basename $FLD )
    TMP=$( cat $FLD/changelog | head -n1 | grep -E -o '\(.+\)' )
    VER=${TMP:1:-1}
    if [ -z "$1" ]; then
        cat $FLD/changelog | sed "s/($VER)/($VER-1)/" > $FLD/changelog.new
        mv $FLD/changelog.new $FLD/changelog
    else
        echo $PKG  $VER
    fi
done
