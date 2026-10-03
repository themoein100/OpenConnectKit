# OpenConnectKit

SwiftPM wrapper around a static build of [OpenConnect](https://www.infradead.org/openconnect/) (`libopenconnect` 9.21, LGPL-2.1)
with OpenSSL 3.6.5, for iOS 15+ (device and simulator, arm64). Import it in a Network Extension and use the C API from `openconnect.h`.

```swift
.package(url: "https://github.com/themoein100/OpenConnectKit", from: "9.21.0")
```

Rebuild from source with `build-scripts/build.sh` (needs Xcode, autoconf, automake, libtool, pkgconf). Built without GnuTLS,
stoken, libproxy, GSSAPI, lz4 and PC/SC. Sources: https://gitlab.com/openconnect/openconnect (tag v9.21) and https://github.com/openssl/openssl (tag openssl-3.6.5).

Licensed under LGPL-2.1 (see `LICENSE`); OpenSSL under Apache-2.0.
