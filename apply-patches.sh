#! /bin/bash

set -e

# apply our patches
echo '>>> Applying patches...'
for PATCH in ../patches/*.diff; do
    echo "      - $PATCH"
    patch -p1 < $PATCH
done

