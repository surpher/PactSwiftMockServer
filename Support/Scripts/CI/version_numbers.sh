#!/usr/bin/env bash
# shellcheck disable=SC1091

#  PactSwiftMockService
#
#  Created by Marko Justinek on 09/12/24.
#  Copyright © 2024 Marko Justinek. All rights reserved.
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

function latest_tag {
  git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null
}

# Gets the next bumped version number
function generate_version_number {
  # Get parameters
  local version_part="${VERSION_PART:-$1}"
  local description="${DESCRIPTION:-$2}"

  if [[ -z "$version_part" ]]; then
    echo "Usage: $0 {major|minor|patch}"
    exit 1
  fi

  # Get the latest tag from the repository
  local version=
  version=$(latest_tag)

  # Default to v0.0.0 if no tags are found
  if [ -z "$version" ]; then
    version="v0.0.0"
  fi

  # Remove 'v' prefix for easier manipulation
  version=${version#v}

  # Split the version into major, minor, and patch components
  IFS='.' read -r vnum1 vnum2 vnum3 <<< "$version"

  # Determine which part of the version to increment based on the argument
  case $version_part in
    major)
      vnum1=$((vnum1 + 1))
      vnum2=0
      vnum3=0
      ;;
    minor)
      vnum2=$((vnum2 + 1))
      vnum3=0
      ;;
    patch)
      vnum3=$((vnum3 + 1))
      ;;
    *)
      echo "error: Invalid argument: $version_part"
      return 1
      ;;
  esac

  # Construct the new tag
  local new_tag="v$vnum1.$vnum2.$vnum3"

  if [ -n "$description" ]; then
    new_tag="$new_tag - $description"
  fi

  # Check if new_tag alraedy exists
  if [ -z "$(git tag --list "$new_tag")" ]; then
    echo "$new_tag"
    return 0
  else
    die "Tag: $new_tag already exists..."
  fi
}
