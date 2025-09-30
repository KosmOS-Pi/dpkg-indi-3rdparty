#! /bin/bash

set -e

[ -z "$1" ] && { echo "ERROR: missing version"; exit 1; }

git clone --branch=$1 --depth 1 https://github.com/indilib/indi-3rdparty.git
