# PactSwiftMockServer

[![Build and Test](https://github.com/surpher/PactSwiftMockServer/actions/workflows/build_test.yml/badge.svg)](https://github.com/surpher/PactSwiftMockServer/actions/workflows/build_test.yml)
[![MIT License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE.md)
[![codecov](https://codecov.io/gh/surpher/PactSwiftMockServer/branch/main/graph/badge.svg?token=0LYZVF36I9)](https://codecov.io/gh/surpher/PactSwiftMockServer)

> [!WARNING]
> This repository is under heavy development! There are no guarantees or warranty of any kind!

A wrapper around [`libpact_ffi.a`](https://github.com/pact-foundation/pact-reference/tree/master/rust/pact_ffi) binary and exposed as XCFramework to be primarily used by [`PactSwift`](https://github.com/surpher/PactSwift).

This repository contains the source code, scripts and tools required to generate a [PactSwiftMockServer.xcframework](https://github.com/surpher/PactSwiftMockServerXCFramework) binary package.
It is referenced and set as a dependency in [`PactSwift`](https://github.com/surpher/PactSwift) swift package.

See [LICENSE.md](LICENSE.md) for licensing information.

> [!IMPORTANT]
> The `libpact_ffi.a` binaries for the supported architectures add up to **`>200MB`** with each new built version. Because of this the repository size blew up to unsustainable levels.
>
> Compiling source code found in this repo and artifacts built from submodules into an XCFramework, zipping it up, and shared as a binary target with `checksum` is currently the only way to keep the payload at *`~90MB`* per package resolve.
