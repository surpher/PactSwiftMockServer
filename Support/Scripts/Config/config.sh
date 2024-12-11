#!/usr/bin/env bash
# shellcheck disable=SC2034

# Xcode version to use
# Only care about major and minor
MIN_XCODE_VERSION="16.1"
XCODE_VERSION_MIN_SUGGESTED="16.1"
XCODE_VERSION_MIN_SUPPORTED="16.0"

# Project configuration
XCPRODUCT_NAME="PactSwiftMockServer"
XCFRAMEWORK_DIR="Framework"
XCFRAMEWORK_LOCATION="Framework"

CONFIGURATION_FILE="Configurations/Project-Shared.xcconfig" # The file where the marketing version is updated before building XCFramework
CHANGE_LOG="CHANGELOG.md" # Self explanatory
TAG_MESSAGE_FILE="TAG_MESSAGE_FILE.tmp" # The temporary file to keep the changes in
XCFRAMEWORK_NAME="$XCPRODUCT_NAME.xcframework" # The name of the XCFramework as it will be shared

REMOTE_NAME="PactSwiftServer" # The name of the locally set git remote
RELEASE_REPO_NAME="PactSwiftServer" # The repo name to which a new release is being pushed
DEFAULT_REPO_NAME="PactSwiftMockServer" # The repo name where the source code is
REPO_OWNER="surpher" # Project owner on GitHub
REMOTE_REPO_BASE="git@github.com:$REPO_OWNER" # The SSH URI to the project owner's space
