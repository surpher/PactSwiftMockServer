# CHANGELOG

## 1.0.0 - v1.0.0

* d08c413 - chore: Change to use updated package API
* 6995bb2 - tech: Update MockServer to be an actor
* 2cf3ec4 - docs: Add doc file references to Xcode project
* 883b8ee - tech: Set min iOS target to 14.0 & macOS to 11.0

## 0.4.4 - v0.4.4

* 7728901 - chore: Upgrade Pact FFI Library to 0.3.15 (Marko Justinek)
* 9ec0d7d - chore: Submodule sync (Marko Justinek)

## 0.4.2 - v0.4.2

* caaccda - Upgrade libpact_ffi to v0.3.11 (Marko Justinek)

## 0.4.1 - v0.4.1

* a580bdd - ci: Cancel build with new push (Marko Justinek)
* dc550f9 - fix: Conditional for unsupported import (Marko Justinek)

## 0.4.0 - v0.4.0

* 19c2c5e - ci: Skip building rust binaries if in cache (Marko Justinek)
* 2b3ce0e - docs: Update README [skip ci] (Marko Justinek)
* 54c6077 - ci: Updates to rust script for pact-reference submodule (Marko Justinek)
* 53fa385 - tech: Updates build rust dependencies for submodule (Marko Justinek)
* 644c9bb - tech: Adds pact-reference as submodule (Marko Justinek)
* 89e6501 - ci: Join workflows into one (Marko Justinek)
* dec6c33 - ci: Add Package.resolved to repo (Marko Justinek)
* 6449c75 - ci: Improvements to pipelines (Marko Justinek)
* dea0f7c - tech: Removes the PactSwiftToolbox dependency (#4) (Marko Justinek)
* cdc61c4 - chore: Adds project-level copyright template (Marko Justinek)

## 0.3.8 - v0.3.8

* 1012993 - bugfix: Invert merge flag (Marko Justinek)

## 0.3.7 - v0.3.7

* bcfc657 - tech: Adds more logging information when writing contract (Marko Justinek)

## 0.3.6 - v0.3.6

* df4932d - upgrade: libpact_ffi-v0.3.2 (Marko Justinek)
* 8bb44b5 - feat: Merge interactions with existing Pact contract (Marko Justinek)

## 0.3.5 - v0.3.5

* d03409c - Upgrade to pact-rust v0.2.3 (Marko Justinek)
* d932b02 - v0.3.5 (Marko Justinek)
* e0dac45 - chore: Refactor release script (Marko Justinek)
* 5f007f5 - chore: Recompiles pact_ffi-0.2.3 into XCFramework binaries (Marko Justinek)
* 523584a - chore: Refactor the build_xcframwork script (Marko Justinek)
* 84cb880 - chore: Refactor the release script (Marko Justinek)
* 75b6d8f - v0.3.5 (Marko Justinek)
* 464406a - tech: Add a check for Xcode version when building XCFramework (Marko Justinek)

## 0.3.4 - v0.3.4

* fa4e952 - chore: Recompiles pact_ffi for v0.0.3 with swiftlang-1205.0.28.2 clang-1205.0.19.57 (Marko Justinek)

## 0.3.3 - v0.3.3

* a0c50de - chore: Recompiles pact_ffi for v0.0.3 (Marko Justinek)
* 27fc482 - doco: Add description for tag in build_rust_dependencies script (Marko Justinek)

## 0.3.2 - v0.3.2

* 3eed423 - chore: Rebuild XCFramework (Marko Justinek)
* c22e5e6 - feat: Initialize with directory path (Marko Justinek)

## 0.3.1 - v0.3.1

* 367764f - fix: Returns a valid port on Linux (Marko Justinek)

## 0.3.0 - v0.3.0

* 0e81924 - chore: Upgrade libpact_ffi to v0.0.2 (Marko Justinek)
* 0ee3d6e - tech: Add a reusable build_test script (Marko Justinek)
* aabac43 - chore: Support scripts include license header (Marko Justinek)
* 9e773bb - refactor: Protocolize ProviderVerifier (Marko Justinek)
* e1edc69 - refactor: Move the Verifier models out into PactSwift (Marko Justinek)
* e067ea5 - feat: Adds more verification options (Marko Justinek)
* 3c195ec - refactor: Namespacing provider verification options (Marko Justinek)
* 27f3650 - feature: MVP for provider verification (Marko Justinek)
* d48746a - feature: Base Verifier interface and models (Marko Justinek)
* d29a1b0 - tech: SwiftLint source files (Marko Justinek)
* 9579223 - tech: Limit the CI builds to a set of branches (Marko Justinek)
* 0a8c00b - refactor: Clean up MockServer a bit (Marko Justinek)

## 0.2.5 - v0.2.5

* accd74e - fix: Writing Pact that includes strings with escape characters (Marko Justinek)

## 0.2.4 - v0.2.4

* 073d2db - fix: Use same unusedPort api (Marko Justinek)
* 57ee570 - feat: Initializes on random port (Marko Justinek)

## 0.2.3 - v0.2.3

* 73622c6 - feat: Each test runs on own port (Marko Justinek)
* 0734852 - refactor: Shutdown mock server on verify (Marko Justinek)

## 0.2.2 - Bugfix

* 1394ff8 - fix: Defines a port at MockServer init (Marko Justinek)

## 0.2.1 - Linux support

* 904a874 - chore: Update dependency verisons (Marko Justinek)
* 8a70a40 - chore: Revert dependency name change (Marko Justinek)
* 8b7338a - chore: Rename PactMockSerer to PactFFI (Marko Justinek)
* 2bc2b5d - chore: Update package dependencies (Marko Justinek)
* e2735e2 - chore: Clean up gitignore a bit (Marko Justinek)
* c926aa5 - chore: Update default socketAddress to 127.0.0.1 (Marko Justinek)
* 3e8199d - fix: Remove port definition (Marko Justinek)
* ca33d93 - chore: Updates Package to expose PactSwiftMockServerLinux (Marko Justinek)
* 0234fdd - tech: Add a release script (Marko Justinek)
* f5d7f76 - chore: Update gitignore file (Marko Justinek)
* cb47a66 - fix: Update lib search paths (Marko Justinek)
* 0718e0e - chore: Add blank changelog file (Marko Justinek)
* db37819 - tech: Update carthage script (Marko Justinek)
