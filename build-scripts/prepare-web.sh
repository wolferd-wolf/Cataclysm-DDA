#!/bin/bash
set -exo pipefail

rm -rf web_bundle

BUNDLE_DIR=web_bundle
DATA_DIR=$BUNDLE_DIR/data
mkdir -p $DATA_DIR
cp -R data/{core,font,fontdata.json,json,mods,names,raw,motd,credits,title} $DATA_DIR/
cp -R gfx $BUNDLE_DIR/

# Remove .DS_Store files.
find web_bundle -name ".DS_Store" -type f -exec rm {} \;

# Remove obsolete mods.
echo "Removing obsolete mods..."
for MOD_DIR in $DATA_DIR/mods/*/ ; do
    if jq -e '.[] | select(.type == "MOD_INFO") | .obsolete' "$MOD_DIR/modinfo.json" >/dev/null; then
        echo "$MOD_DIR is obsolete, excluding from web_bundle..."
        rm -rf $MOD_DIR
    fi
done

echo "Removing MA mod..."
rm -rf $DATA_DIR/mods/MA
echo "Removing Ultica_iso tileset..."
rm -rf $BUNDLE_DIR/gfx/Ultica_iso

$EMSDK/upstream/emscripten/tools/file_packager cataclysm-tiles.data --js-output=cataclysm-tiles.data.js --no-node --preload "$BUNDLE_DIR""@/" --lz4

# The manually generated package loader must be part of the main Emscripten
# JS output.  This is the same arrangement used by emcc --preload-file and
# avoids racing two async script tags.  The loader starts the data fetch first;
# the LZ4 runtime from cataclysm-tiles.js is available when the fetch completes.
cat cataclysm-tiles.data.js cataclysm-tiles.js > cataclysm-tiles.js.tmp
mv cataclysm-tiles.js.tmp cataclysm-tiles.js

mkdir -p build/
cp \
  build-data/web/index.html \
  cataclysm-tiles.{data,js,wasm} \
  data/font/Terminus.ttf \
  build
cp data/cataicon.ico build/favicon.ico
