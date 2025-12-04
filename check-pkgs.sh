#! /bin/bash

LIST=$( cat pkgs.conf )

pushd indi-3rdparty/

for p in $( ls -d lib* ); do
 if ! grep "^$p" ../pkgs.conf > /dev/null ; then
	echo "'$p' is missing."
 fi
done

for p in $( ls -d indi-* ); do
 if ! grep "^$p" ../pkgs.conf > /dev/null ; then
	echo "'$p' is missing."
 fi
done


