#!/bin/sh -x
set -e
#export SKIP_NOTARY=1
PRODUCT_NAME="XCreds"
SCRIPT_FOLDER="$(dirname $0)"
PROJECT_FOLDER="../../"
SRC_PATH="../../"

###########################

if [ -e "${SRC_PATH}/../build/bitbucket_creds.sh" ] ; then 
	source "${SRC_PATH}/../build/bitbucket_creds.sh"
fi
if [ -e /Applications/DropDMG.app ]; then 
	osascript -e 'tell application "DropDMG" to get version'
fi

pushd ../..
agvtool next-version -all

buildNumber=$(agvtool what-version -terse)
popd

marketing_version=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' "${PROJECT_FOLDER}"/XCreds.xcodeproj/project.pbxproj)

/usr/libexec/PlistBuddy   -c "Set :pfm_version ${buildNumber}" "${PROJECT_FOLDER}/Profile Manifest/com.twocanoes.xcreds.plist"

/usr/libexec/PlistBuddy   -c "Set :pfm_description  \"XCreds ${marketing_version} (${buildNumber}) OAuth Settings\"" "${PROJECT_FOLDER}/Profile Manifest/com.twocanoes.xcreds.plist"


temp_folder=$(mktemp -d "/tmp/${PRODUCT_NAME}.XXXXXXXX")
BUILD_FOLDER="${temp_folder}/build"


xcodebuild archive -project "${SRC_PATH}/${PRODUCT_NAME}.xcodeproj" -scheme "${PRODUCT_NAME}" -archivePath  "${temp_folder}/${PRODUCT_NAME}.xcarchive"


xcodebuild -exportArchive -archivePath "${temp_folder}/${PRODUCT_NAME}.xcarchive"  -exportOptionsPlist "${SRC_PATH}/build_resources/exportOptions.plist" -exportPath "${BUILD_FOLDER}" 


echo saving symbols
mkdir -p "${PROJECT_FOLDER}/products/symbols/${buildNumber}"


cp -R "${temp_folder}/${PRODUCT_NAME}.xcarchive/dSYMs/" "${PROJECT_FOLDER}/products/symbols/${buildNumber}/"


cp -Rv "${SRC_PATH}/build_resources/" "${BUILD_FOLDER}"

echo "output is in ${BUILD_FOLDER}"
if [ -e /Users/tperfitt/Documents/Projects/build/build.sh ] ; then 
	/Users/tperfitt/Documents/Projects/build/build.sh  "${BUILD_FOLDER}" "${temp_folder}" "${PRODUCT_NAME}" "${BUILD_FOLDER}/XCreds.app" "${SCRIPT_FOLDER}/build_post.sh"
fi
