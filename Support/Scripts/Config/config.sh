#!/usr/bin/env bash
# shellcheck disable=SC2034

# Xcode version to use
# Only care about major and minor
MIN_XCODE_VERSION="16.1"
XCODE_VERSION_MIN_SUGGESTED="16.1"
XCODE_VERSION_MIN_SUPPORTED="16.0"

# Project configuration
CONFIGURATION_FILE="Configurations/Project-Shared.xcconfig"
CHANGE_LOG="CHANGELOG.md"
TAG_MESSAGE_FILE="TAG_MESSAGE_FILE.md"
XCFRAMEWORK_NAME="PactSwiftMockServer.xcframework"

REMOTE_NAME="PactSwiftServer"
RELEASE_REPO_NAME="PactSwiftServer"
DEFAULT_REPO_NAME="PactSwiftMockServer"
REPO_OWNER="surpher"
REMOTE_REPO_BASE="git@github.com:$REPO_OWNER"
