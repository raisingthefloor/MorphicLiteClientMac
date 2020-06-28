#!/bin/bash

BRANCH="${BRANCH}"
BRANCH_NAME="${BRANCH_NAME}"

if [[ "${BRANCH_NAME}" == "master" ]]; then
  echo "detected master build. will sign"
elif [[ "${BRANCH}" == *"staging/"* ]]; then
  echo "detected staging build. will sign"
elif [[ "${BRANCH}" == *"release/"* ]]; then
  echo "detected release build. will sign"
else
  echo "detected PR build. Will not sign"
  exit 0
fi

USERNAME="${USERNAME}"
APP_PASSWORD="${APP_PASSWORD}"
SIGNING_IDENTITY="${SIGNING_IDENTITY}"
BUNDLE_ID="com.raisingthefloor.MorphicClient.dmg"
DMG_PATH="./Morphic/Morphic.dmg"

exitWithErr()
{
  echo "$1"
  exit 1
}

# Parse the status field from output.
parseStatus()
{
  echo "$1" | awk -F ': ' '/Status:/ { print $2; }'
}

# Parse the RequestUUID field from output
parseRequestUuid()
{
  echo "$1" | awk '/RequestUUID/ { print $NF; }'
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
if [[ "$SIGNING_IDENTITY" == "" ]]; then
  exitWithErr "SIGNING_IDENTITY env var must be provided"
fi

set -e
set -x

codesign --timestamp \
  --sign "${SIGNING_IDENTITY}" \
   "${DMG_PATH}"

# this will return a “RequestUUID”...which is used as a command-line argument for polling
NOTARIZE_REQUST=$(xcrun altool --notarize-app \
  --primary-bundle-id "${BUNDLE_ID}" \
  --username "${USERNAME}" \
  --password "${APP_PASSWORD}" \
  --file "${DMG_PATH}")

echo "${NOTARIZE_REQUST}"

REQUEST_UUID=$(parseRequestUuid "${NOTARIZE_REQUST}")
if [[ "${REQUEST_UUID}" == "" ]]; then
  exitWithErr "failed to parse request_UUID"
fi

# Poll for completion

REQUEST_STATUS="in progress"
while [[ "$REQUEST_STATUS" == "in progress" ]]; do
  echo "Polling for completion of notarization request"
  sleep 20
  NOTARY_INFO=$(xcrun altool \
    --notarization-info ${REQUEST_UUID} \
    --username "${USERNAME}" \
    --password "${APP_PASSWORD}")

  REQUEST_STATUS=$(parseStatus "${NOTARY_INFO}")
  REQUEST_STATUS=$(toLower "$REQUEST_STATUS")

  echo "current status: ${REQUEST_STATUS}"
done

echo "Final notarization status:"
echo "${NOTARY_INFO}"

if [[ "$REQUEST_STATUS" != "success" ]]; then
  exitWithErr "failed to get notarization. Status is not 'success'"
fi

echo "stapling notarization to dmg"
xcrun stapler staple "${DMG_PATH}"

echo "successfully stapled DMG"