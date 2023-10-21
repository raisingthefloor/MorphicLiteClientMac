#!/bin/bash

# see: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
# see: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
# see: https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool

BRANCH="${BRANCH}"
BRANCH_NAME="${BRANCH_NAME}"

if [[ "${BRANCH_NAME}" == "master" ]]; then
  echo "detected master build. will notarize"
elif [[ "${BRANCH}" == *"staging/"* ]]; then
  echo "detected staging build. will notarize"
elif [[ "${BRANCH}" == *"release/"* ]]; then
  echo "detected release build. will notarize"
else
  echo "detected PR build. Will not notarize"
  exit 0
fi

USERNAME="${USERNAME}"
APP_PASSWORD="${APP_PASSWORD}"
TEAM_ID="${TEAM_ID}"
SIGNING_IDENTITY="${SIGNING_IDENTITY}"
BUNDLE_ID="${BUNDLE_ID}"
DMG_PATH="${DMG_PATH}"
PKG_PATH="${PKG_PATH}"

if [[ "$DMG_PATH" != "" ]]; then
  FILE_PATH=${DMG_PATH}
else 
  FILE_PATH=${PKG_PATH}
fi

exitWithErr()
{
  echo "$1"
  exit 1
}

# Parse the status field from output.
parseStatus()
{
  echo "$1" | awk -F "status: " '{ print $NF; }' | tail -1 | tr -d "[:space:]"
}

# Parse the RequestUUID field from output
parseRequestUuid()
{
  echo "$1" | awk '/id/ { print $NF; }' | tail -1  | tr -d "[:space:]"
}

toLower()
{
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

if [[ "$USERNAME" == "" ]]; then
  exitWithErr "USERNAME env var must be provided"
fi
if [[ "$APP_PASSWORD" == "" ]]; then
  exitWithErr "APP_PASSWORD env var must be provided"
fi

if [[ "$DMG_PATH" != "" && "$SIGNING_IDENTITY" == "" ]]; then
  exitWithErr "SIGNING_IDENTITY env var must be provided for DMG files"
fi

set -e
set -x

if [[ "$SIGNING_IDENTITY" != "" ]]; then
  codesign --timestamp \
    --sign "${SIGNING_IDENTITY}" \
     "${FILE_PATH}"
fi

# this will wait until the submission has completed and will return the result of the submission
NOTARIZE_RESPONSE=$(xcrun notarytool submit \
  --apple-id "${USERNAME}" \
  --team-id "${TEAM_ID}" \
  --password "${APP_PASSWORD}" \
  --wait "${FILE_PATH}")

#echo "${NOTARIZE_RESPONSE}"

REQUEST_UUID=$(parseRequestUuid "${NOTARIZE_RESPONSE}")
if [[ "${REQUEST_UUID}" == "" ]]; then
  exitWithErr "failed to parse request_UUID"
fi

REQUEST_STATUS=$(parseStatus "${NOTARIZE_RESPONSE}")
REQUEST_STATUS=$(toLower "$REQUEST_STATUS")

echo "Final notarization status:"
echo "${REQUEST_STATUS}"

if [[ "$REQUEST_STATUS" != "accepted" ]]; then
  exitWithErr "failed to get notarization. Status is not 'accepted'"
fi

echo "fetching the notary log"
NOTARY_LOG=$(xcrun notarytool log \
  --apple-id "${USERNAME}" \
  --team-id "${TEAM_ID}" \
  --password "${APP_PASSWORD}" \
  ${REQUEST_UUID})

#echo "${NOTARY_LOG}"

echo "stapling notarization to file"
xcrun stapler staple "${FILE_PATH}"

echo "successfully stapled notarization to file"
