#!/bin/sh

#  CreateDiskImage.sh
#  Morphic
#
#  Created by Owen Shaw on 5/29/20.
#  Copyright © 2020 Raising the Floor. All rights reserved.

set -e
set -x

TEMPLATE_NAME="MorphicTemplate.dmg"
MOUNT_PATH="MorphicInstaller"
APP_NAME="${PRODUCT_NAME}.app"
COMPRESSED_TEMPLATE_PATH="${SRCROOT}/Morphic/${TEMPLATE_NAME}.bz2"

cd "${CONFIGURATION_TEMP_DIR}"
rm -rf installer
mkdir installer

bunzip2 -k "${COMPRESSED_TEMPLATE_PATH}" -c > "${TEMPLATE_NAME}"
hdiutil attach "${TEMPLATE_NAME}" -noautoopen -quiet -mountpoint "${MOUNT_PATH}"
ditto "${CONFIGURATION_BUILD_DIR}/${APP_NAME}" "${MOUNT_PATH}/${APP_NAME}"
hdiutil detach "${MOUNT_PATH}" -quiet -force
hdiutil convert "${TEMPLATE_NAME}" -quiet -format UDZO -imagekey -zlib-level=9 -o "${CONFIGURATION_BUILD_DIR}/${PRODUCT_NAME}.dmg"
rm "${TEMPLATE_NAME}"
