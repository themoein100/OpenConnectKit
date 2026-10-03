#!/bin/bash
# Builds OpenSSL + libopenconnect (static) for iOS device and simulator and packs openconnect.xcframework.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/src"
OUT="$ROOT/out"
MIN_IOS=15.0
JOBS=$(sysctl -n hw.ncpu)
export PATH="/opt/homebrew/bin:/opt/homebrew/opt/libtool/libexec/gnubin:$PATH"

# slice name | sdk | clang arch | configure host | openssl target
SLICES=(
  "ios-arm64|iphoneos|arm64|aarch64-apple-darwin|ios64-xcrun"
  "ios-sim-arm64|iphonesimulator|arm64|aarch64-apple-darwin|iossimulator-xcrun"
)

build_slice() {
  IFS='|' read -r NAME SDK ARCH HOST OSSL_TARGET <<<"$1"
  local SDKPATH; SDKPATH="$(xcrun --sdk "$SDK" --show-sdk-path)"
  local PREFIX="$OUT/$NAME"
  local MINFLAG="-miphoneos-version-min=$MIN_IOS"
  [ "$SDK" = "iphonesimulator" ] && MINFLAG="-mios-simulator-version-min=$MIN_IOS"
  mkdir -p "$PREFIX"

  echo "=== [$NAME] OpenSSL"
  if [ ! -f "$PREFIX/lib/libssl.a" ]; then
    rm -rf "$ROOT/build/openssl-$NAME"; mkdir -p "$ROOT/build"
    cp -R "$SRC/openssl" "$ROOT/build/openssl-$NAME"
    ( cd "$ROOT/build/openssl-$NAME"
      export CROSS_TOP="$(xcrun --sdk "$SDK" --show-sdk-platform-path)/Developer"
      export CROSS_SDK="$(basename "$SDKPATH")"
      ./Configure "$OSSL_TARGET" no-shared no-tests no-apps no-docs no-dso no-async no-ui-console \
        "$MINFLAG" --prefix="$PREFIX" --openssldir="$PREFIX/ssl" >/dev/null
      make -j"$JOBS" build_libs >/dev/null
      make install_dev >/dev/null )
  fi

  echo "=== [$NAME] libopenconnect"
  local BUILD="$ROOT/build/openconnect-$NAME"
  rm -rf "$BUILD"; mkdir -p "$BUILD"
  cp -R "$SRC/openconnect/." "$BUILD/"
  ( cd "$BUILD"
    [ -f configure ] || ./autogen.sh >/dev/null
    export CC="$(xcrun --sdk "$SDK" -f clang)"
    export CFLAGS="-arch $ARCH -isysroot $SDKPATH $MINFLAG -O2 -fPIC -I$PREFIX/include -Wno-error -Wno-implicit-function-declaration"
    export LDFLAGS="-arch $ARCH -isysroot $SDKPATH $MINFLAG -L$PREFIX/lib"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export OPENSSL_CFLAGS="-I$PREFIX/include" OPENSSL_LIBS="-L$PREFIX/lib -lssl -lcrypto"
    export LIBXML2_CFLAGS="-I$SDKPATH/usr/include/libxml2" LIBXML2_LIBS="-lxml2"
    export ZLIB_CFLAGS="" ZLIB_LIBS="-lz"
    ./configure --host="$HOST" --prefix="$PREFIX" --disable-shared --enable-static \
      --without-gnutls --with-openssl="$PREFIX/lib" --disable-nls --disable-docs \
      --without-stoken --without-libpskc --without-libproxy --without-gssapi \
      --without-libpcsclite --without-lz4 --without-system-cafile --without-java \
      --with-vpnc-script=/usr/bin/true --disable-dsa-tests >/dev/null
    make -j"$JOBS" libopenconnect.la >/dev/null
    mkdir -p "$PREFIX/lib" "$PREFIX/include"
    cp .libs/libopenconnect.a "$PREFIX/lib/"
    cp openconnect.h "$PREFIX/include/" )
}

for slice in "${SLICES[@]}"; do build_slice "$slice"; done

echo "=== xcframework"
rm -rf "$OUT/openconnect.xcframework" "$OUT/headers"
mkdir -p "$OUT/headers"
cp "$OUT/ios-arm64/include/openconnect.h" "$OUT/headers/"
cat > "$OUT/headers/module.modulemap" <<'EOF'
module COpenConnect {
    header "openconnect.h"
    export *
}
EOF
# One fat static archive per slice: libopenconnect + OpenSSL.
for slice in "${SLICES[@]}"; do
  NAME="${slice%%|*}"
  /usr/bin/libtool -static -o "$OUT/$NAME/libopenconnect-all.a" \
    "$OUT/$NAME/lib/libopenconnect.a" "$OUT/$NAME/lib/libssl.a" "$OUT/$NAME/lib/libcrypto.a"
done
xcodebuild -create-xcframework \
  -library "$OUT/ios-arm64/libopenconnect-all.a" -headers "$OUT/headers" \
  -library "$OUT/ios-sim-arm64/libopenconnect-all.a" -headers "$OUT/headers" \
  -output "$OUT/openconnect.xcframework"
echo "done: $OUT/openconnect.xcframework"
