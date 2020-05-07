#!/bin/bash

set -e
set -x

# ref: https://crunchybagel.com/auto-incrementing-build-numbers-in-xcode/

buildNumber=$(date -u "+%Y%m%d%H%M")

updateVersion() {
  local PLIST=$1
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $buildNumber" "$PLIST"  # Version number
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$PLIST"  # Build number
  echo "DateTime for app version number: $buildNumber"
}

for filepath in $(find . -name 'Info.plist' -type f)
do
  echo "Updating ${filepath}"
  updateVersion "$filepath"
done