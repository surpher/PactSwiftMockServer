🚨🚨🚨 --- WARNING --- 🚨🚨🚨

Make sure there is a `libpact_mock_server.a` file in each of the subdirectories!
Each of the binaries should contain the slices for required architectures.

The folder structure **MUST** be as follows (case sensitive!):
|- Resources
  |- arm64-ios
  |- x86_64-darwin
  |- x86_64_iOS 

If there are no binaries in these folders, build them using ./Support/build_rust_dependencies script.
