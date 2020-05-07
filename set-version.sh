#!/bin/bash

set -e
set -x

# ref: https://crunchybagel.com/auto-incrementing-build-numbers-in-xcode/

NEW_VERSION=${1}

if [[ "$NEW_VERSION" = "" ]]; then
  echo "usage: ./set-version [NEW VERSION]"
  echo "no version provided"
  exit 1
fi

echo "new version: ${NEW_VERSION}"

updateVersion() {
  local PLIST=$1
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $buildNumber" "$PLIST"  # Version number
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$PLIST"  # Build number
}

for filepath in $(find . -name 'Info.plist' -type f)
do
  echo "Updating plist: ${filepath}"
  updateVersion "$filepath"
done