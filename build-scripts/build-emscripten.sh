#!/bin/bash
#
# Build Cataclysm-DDA's SDL3 tiles client for WebAssembly.
#
# The browser workflow installs a current Emscripten SDK and builds the
# SDL3/SDL3_image/SDL3_ttf stack from source.  This script intentionally does
# not build translations, sound, or any native desktop targets.
#
set -exo pipefail

CCACHE=${CCACHE:-0}

command -v emcc >/dev/null
command -v em++ >/dev/null
command -v emcmake >/dev/null
command -v pkg-config >/dev/null

: "${EMSCRIPTEN_SDL_PREFIX:?EMSCRIPTEN_SDL_PREFIX must point at the Emscripten SDL3 install}"

export PKG_CONFIG_PATH="${EMSCRIPTEN_SDL_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CMAKE_PREFIX_PATH="${EMSCRIPTEN_SDL_PREFIX}:${CMAKE_PREFIX_PATH:-}"

pkg-config --atleast-version=3.4.0 sdl3
pkg-config --exists sdl3-image
pkg-config --exists sdl3-ttf
pkg-config --exists freetype2

CXX_PKG_CFLAGS="$(pkg-config --cflags sdl3 sdl3-image sdl3-ttf freetype2 zlib)"
CXX_PKG_LIBS="$(pkg-config --libs sdl3 sdl3-image sdl3-ttf freetype2)"

make -j$(nproc)   NATIVE=emscripten   BACKTRACE=0   TILES=1   SOUND=0   TESTS=0   RUNTESTS=0   RELEASE=1   CCACHE="$CCACHE"   LINTJSON=0   PKG_CONFIG=pkg-config   CXXFLAGS="$CXX_PKG_CFLAGS"   LDFLAGS="$CXX_PKG_LIBS"   cataclysm-tiles.js
