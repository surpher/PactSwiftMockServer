# Handling libpact_mock_server.a binaries

## 🚨🚨🚨 --- WARNING --- 🚨🚨🚨

Make sure there is a `libpact_ffi.a` file in each of the subdirectories!
Each of the binaries should contain the slices for required architectures.

If you're missing any when trying to build/run/test from source, see `./Support/build_rust_dependencies` script.

The folder structure **MUST** be as follows (case sensitive!):
|- Resources
  |- arm64-ios
  |- x86_64-darwin
  |- x86_64_iOS

If there are no binaries in these folders, build them using ./Support/build_rust_dependencies script.

## Upgrading libpact_ffi.a

These fat libraries are fat AF! Github has a filesize limit of 100MB which means pretty much any of our fat libraries will be rejected unless we'd use Git-LFS.  
Unfortunately LFS is not free even for open source projects. In order to still allow us to test this project on CI, make sure you only commit the single slices for x86_64 architecture.

Once the CI runners move to M1 machinges, we might reconsider and replace with arm64 slices.

Until then... This is it, or more scripts, pre-commit hooks, whatnots... This is an open source project with only one person working on it so it will remain like this for a while longer 🤷‍♂️.
