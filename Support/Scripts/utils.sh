#!/usr/bin/env bash
# shellcheck disable=SC2034

#  PactSwiftMockService
#
#  Created by Marko Justinek on 24/4/24.
#  Copyright © 2021 Marko Justinek. All rights reserved.
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
#  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
#  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

set -euo pipefail

function executeCommand {
  if [ $# -eq 0 ]; then
    echo -e "No command provided"
    exit 1
  else
    COMMAND="$1"
    printf "🤖 Executing:\n   '%s'\n" "$COMMAND"
    eval "$COMMAND"
  fi
}

function folderExists {
  if [ ! -d "$1" ]; then
    echo false
  else
    echo true
  fi
}

function fileExists {
  if [ ! -f "$1" ]; then
    echo false
  else
    echo true
  fi
}

# Xcode version number
# Only care about major and minor
MIN_XCODE_VERSION="16.1"
XCODE_VERSION_MIN_SUGGESTED="16.1"
XCODE_VERSION_MIN_SUPPORTED="16.0"

function __check_xcode_version_number {
  local major=${1:-0}
  local minor=${2:-0}

  local suggested_major="${XCODE_VERSION_MIN_SUGGESTED%.*}"
  local min_supported_major="${XCODE_VERSION_MIN_SUPPORTED%.*}"
  local min_supported_minor="${XCODE_VERSION_MIN_SUPPORTED##*.}"

  return $(( (major >= suggested_major) || (major == min_supported_major && minor >= min_supported_minor) ))
}

# Checks for Xcode and it's version.
# Exits with non-zero if not found or version is not supported.
function check_xcode() {
  if ! xcode_version="$(xcodebuild -version | sed -n '1s/^Xcode \([0-9.]*\)$/\1/p')"; then
    echo 'Failed to get Xcode version' 1>&2
    exit 1
  elif __check_xcode_version_number ${xcode_version//./ }; then # not double quoting to pass two parameters
    echo "Xcode version '$xcode_version' not supported, version $MIN_XCODE_VERSION or above is required" 1>&2;
    exit 1
  fi
}

#########
# Text

# Colour variables using ANSI escape codes
# usage: echo "This is ${RED}red${RESET} text."
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
LIGHT_BLUE="\033[38;2;173;216;230m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NOCOLOR="\033[0m" # Reset color

BOLD="\033[1m"
REGULAR="\033[0m"
