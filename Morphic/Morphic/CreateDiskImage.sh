#!/bin/sh

#  CreateDiskImage.sh
#  Morphic
#
#  Created by Owen Shaw on 5/29/20.
#  Copyright © 2020 Raising the Floor. All rights reserved.

echo "---- Running CreateDiskImage.sh -----"

TEMPLATE_NAME="MorphicTemplate.dmg"
MOUNT_PATH="MorphicInstaller"
APP_NAME="${PRODUCT_NAME}.app"
COMPRESSED_TEMPLATE_PATH="${SRCROOT}/Morphic/${TEMPLATE_NAME}.bz2"
TEMP_FOLDER="Morhpic.DiskImage.build"

cd "${CONFIGURATION_TEMP_DIR}"
rm -rf "${TEMP_FOLDER}"
mkdir "${TEMP_FOLDER}" && echo "[dmg] Created folder ${CONFIGURATION_TEMP_DIR}/${TEMP_FOLDER}" || exit
cd "${TEMP_FOLDER}" && echo "[dmg] Working in folder ${TEMP_FOLDER}" || exit

bunzip2 -k "${COMPRESSED_TEMPLATE_PATH}" -c > "${TEMPLATE_NAME}" && echo "[dmg] unzipped ${TEMPLATE_NAME}" || exit
hdiutil attach "${TEMPLATE_NAME}" -noautoopen -quiet -mountpoint "${MOUNT_PATH}" && echo "[dmg] mounted ${TEMPLATE_NAME} to ${MOUNT_PATH}" || exit
ditto "${CONFIGURATION_BUILD_DIR}/${APP_NAME}" "${MOUNT_PATH}/${APP_NAME}" && echo "[dmg] copied ${APP_NAME} to ${MOUNT_PATH}" || exit
hdiutil detach "${MOUNT_PATH}" -quiet -force && echo "[dmg] unmounted ${MOUNT_PATH}" || exit
rm -f "${CONFIGURATION_BUILD_DIR}/${PRODUCT_NAME}.dmg"

# This outputs to the Morphic root in the git repo structure, rather than DerivedData
hdiutil convert "${TEMPLATE_NAME}" -quiet -format UDZO -imagekey -zlib-level=9 -o "${SRCROOT}/${PRODUCT_NAME}.dmg" && echo "[dmg] created ${SRCROOT}/${PRODUCT_NAME}.dmg" || exit
cd ..
rm -rf "${TEMP_FOLDER}" && echo "[dmg] cleaned up ${TEMP_FOLDER}" || exit
echo "[dmg] done"
