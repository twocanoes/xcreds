#!/bin/sh -x
set -e
#export SKIP_NOTARY=1
PRODUCT_NAME="XCreds"
SCRIPT_FOLDER="$(dirname $0)"
PROJECT_FOLDER="../../"
SRC_PATH="../../"

###########################
source "${SRC_PATH}/../build/bitbucket_creds.sh"
osascript -e 'tell application "DropDMG" to get version'

pushd ../..
agvtool next-version -all

buildNumber=$(agvtool what-version -terse)
popd

temp_folder=$(mktemp -d "/tmp/${PRODUCT_NAME}.XXXXXXXX")
BUILD_FOLDER="${temp_folder}/build"

#buildNumber=$(($buildNumber + 1))


#codesign --verbose --force -o runtime --sign "Developer ID Application: Twocanoes Software, Inc. (UXP6YEHSPW)" "${SRC_PATH}/build_resources/AdditionalPackagesResources/OpenDirectory/Modules/com.twocanoes.sconeod.xpc/Contents/MacOS/dsconfigel"


#codesign --verbose --force -o runtime --sign "Developer ID Application: Twocanoes Software, Inc. (UXP6YEHSPW)" "${SRC_PATH}/build_resources/AdditionalPackagesResources/OpenDirectory/Modules/com.twocanoes.sconeod.xpc"



xcodebuild archive -project "${SRC_PATH}/${PRODUCT_NAME}.xcodeproj" -scheme "${PRODUCT_NAME}" -archivePath  "${temp_folder}/${PRODUCT_NAME}.xcarchive"


xcodebuild -exportArchive -archivePath "${temp_folder}/${PRODUCT_NAME}.xcarchive"  -exportOptionsPlist "${SRC_PATH}/build_resources/exportOptions.plist" -exportPath "${BUILD_FOLDER}" 

#


echo saving symbols
mkdir -p "${PROJECT_FOLDER}/products/symbols/${buildNumber}"


cp -R "${temp_folder}/${PRODUCT_NAME}.xcarchive/dSYMs/" "${PROJECT_FOLDER}/products/symbols/${buildNumber}/"


cp -Rv "${SRC_PATH}/build_resources/" "${BUILD_FOLDER}"

/Users/tperfitt/Documents/Projects/build/build.sh  "${BUILD_FOLDER}" "${temp_folder}" "${PRODUCT_NAME}" "${BUILD_FOLDER}/XCreds.app" "${SCRIPT_FOLDER}/build_post.sh"
