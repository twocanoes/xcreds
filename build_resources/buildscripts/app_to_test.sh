#!/bin/sh 
set -e
#export SKIP_NOTARY=1
PRODUCT_NAME="XCreds"
SCRIPT_FOLDER="$(dirname $0)"
PROJECT_FOLDER="../.."
SRC_PATH="../../"
REMOTE_MAC="test.local"
echo manifest: $update_manifest
echo upload: $upload
###########################


pushd ../../
carthage update
xcodebuild -resolvePackageDependencies



buildNumber=$(agvtool what-version -terse)
version=$(xcodebuild -showBuildSettings |grep MARKETING_VERSION|tr -d 'MARKETING_VERSION =')


buildNumber=$(agvtool what-version -terse)
popd
marketing_version=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' "${PROJECT_FOLDER}"/XCreds.xcodeproj/project.pbxproj)

date=$(date)



temp_folder=$(mktemp -d "/tmp/${PRODUCT_NAME}.XXXXXXXX")
BUILD_FOLDER="${temp_folder}/build"


xcodebuild archive -project "${SRC_PATH}/${PRODUCT_NAME}.xcodeproj" -scheme "${PRODUCT_NAME}" -archivePath  "${temp_folder}/${PRODUCT_NAME}.xcarchive"


xcodebuild -exportArchive -archivePath "${temp_folder}/${PRODUCT_NAME}.xcarchive"  -exportOptionsPlist "${SRC_PATH}/build_resources/exportOptions.plist" -exportPath "${BUILD_FOLDER}" -allowProvisioningUpdates 

pushd "${BUILD_FOLDER}"
if [ ! -e /tmp/xcreds ]; then 
	mkdir /tmp/xcreds
fi
zip -r /tmp/xcreds/xcreds.zip XCreds.app
popd 
ssh  root@"${REMOTE_MAC}" 'bash -c "if [ -e "/Applications/XCreds.app" ] ; then echo removing; rm -rf "/Applications/XCreds.app"; fi"'


ssh  root@"${REMOTE_MAC}" 'bash -c "if [ -e "/tmp/xcreds.zip" ] ; then echo removing; rm -rf "/tmp/xcreds.zip"; fi"'

scp -Cr /tmp/xcreds/xcreds.zip root@"${REMOTE_MAC}":/tmp/xcreds.zip


ssh root@"${REMOTE_MAC}" unzip /tmp/xcreds.zip -d /Applications



echo "output is in $:{BUILD_FOLDER}"
