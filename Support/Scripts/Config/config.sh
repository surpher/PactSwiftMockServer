#!/usr/bin/env bash
# shellcheck disable=SC2034

# Xcode version to use
# Only care about major and minor
MIN_XCODE_VERSION="16.1"
XCODE_VERSION_MIN_SUGGESTED="16.1"
XCODE_VERSION_MIN_SUPPORTED="16.0"

IPHONEOS_DEPLOYMENT_TARGET=13.0
MACOSX_DEPLOYMENT_TARGET=12.0

LIBPACT_FFI_VERSION_FILE="libpact_ffi.version"

# Project configuration
XCPRODUCT_NAME="PactSwiftMockServer"
XCFRAMEWORK_LOCATION="Framework"

CONFIGURATION_FILE="Configurations/Project-Shared.xcconfig" # The file where the marketing version is updated before building XCFramework
CHANGE_LOG="CHANGELOG.md" # Self explanatory
TAG_MESSAGE_FILE="TAG_MESSAGE_FILE.tmp" # The temporary file to keep the changes in
XCFRAMEWORK_NAME="$XCPRODUCT_NAME" # The name of the XCFramework as it will be shared
XCFRAMEWORK_EXTENSION="xcframework" # The extension of the XCFramework
XCFRAMEWORK_CHECKSUM_EXTENSION="zip.checksum" # The extension of the checksum file

SUBMODULE_XCFRAMEWORK="XCFramework" # The name of the submodule that contains and hosts the XCFramework release

REPO_OWNER="surpher" # Project owner on GitHub
RELEASE_REPO_NAME="PactSwiftMockServerXCFramework" # The repo name to which a new release is being pushed
REMOTE_REPO_BASE="git@github.com:$REPO_OWNER" # The SSH URI to the project owner's space

XCFRAMEWORK_URL_TEMPLATE="https://github.com/${REPO_OWNER}/${RELEASE_REPO_NAME}/releases/download/___VERSION_TAG___/PactSwiftMockServer-___VERSION_TAG___.xcframework.zip" # The template for the URL to the XCFramework
