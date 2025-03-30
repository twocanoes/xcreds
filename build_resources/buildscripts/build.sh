#!/bin/sh 
set -e
#export SKIP_NOTARY=1
PRODUCT_NAME="XCreds"
SCRIPT_FOLDER="$(dirname $0)"
PROJECT_FOLDER="../../"
SRC_PATH="../../"
echo manifest: $update_manifest
echo upload: $upload
###########################

if [ -e "${SRC_PATH}/../build/bitbucket_creds.sh" ] ; then 
	source "${SRC_PATH}/../build/bitbucket_creds.sh"
fi
if [ -e /Applications/DropDMG.app ]; then 
	osascript -e 'tell application "DropDMG" to get version'
fi

pushd ../..


if [ "${1}" == "--force" ] ; then
	echo skipping clean check
else
	
	if output="$(git status --porcelain)" && [ -z "$output" ]; then
		echo "'git status --porcelain' had no errors AND the working directory" \
		"is clean."
	else 
		echo "Working directory has UNCOMMITTED CHANGES."
		exit -1
	fi
fi


agvtool next-version -all

#buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PRODUCT_SETTINGS_PATH}")
buildNumber=$(agvtool what-version -terse)
version=$(xcodebuild -showBuildSettings |grep MARKETING_VERSION|tr -d 'MARKETING_VERSION =')
git tag -a "tag-${version}(${buildNumber})" -m "tag-${version}(${buildNumber})"
git push --tags
./release_notes.sh  > release-notes.md



buildNumber=$(agvtool what-version -terse)
popd

marketing_version=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' "${PROJECT_FOLDER}"/XCreds.xcodeproj/project.pbxproj)

date=$(date)


/usr/libexec/PlistBuddy   -c "Set :pfm_last_modified \"${date}\"" "${PROJECT_FOLDER}/Profile Manifest/com.twocanoes.xcreds.plist"
/usr/libexec/PlistBuddy   -c "Set :pfm_description  \"XCreds ${marketing_version} (${buildNumber}) OAuth Settings\"" "${PROJECT_FOLDER}/Profile Manifest/com.twocanoes.xcreds.plist"

if  [ -n "${update_manifest}" ];  then
	echo "getting current manifest version"
	curr_vers=$(/usr/libexec/PlistBuddy   -c "Print :pfm_version" "${PROJECT_FOLDER}/Profile Manifest/com.twocanoes.xcreds.plist")
	curr_vers=$((${curr_vers}+1))
	echo "setting version to  : ${curr_vers}"
	/usr/libexec/PlistBuddy   -c "Set :pfm_version ${curr_vers}" "${PROJECT_FOLDER}/Profile Manifest/com.twocanoes.xcreds.plist"	
fi

temp_folder=$(mktemp -d "/tmp/${PRODUCT_NAME}.XXXXXXXX")
BUILD_FOLDER="${temp_folder}/build"
pushd "${PROJECT_FOLDER}/Profile Manifest"
./build.py . -o ./jamf/ --overwrite

popd 

xcodebuild archive -project "${SRC_PATH}/${PRODUCT_NAME}.xcodeproj" -scheme "${PRODUCT_NAME}" -archivePath  "${temp_folder}/${PRODUCT_NAME}.xcarchive"


xcodebuild -exportArchive -archivePath "${temp_folder}/${PRODUCT_NAME}.xcarchive"  -exportOptionsPlist "${SRC_PATH}/build_resources/exportOptions.plist" -exportPath "${BUILD_FOLDER}" -allowProvisioningUpdates 


echo saving symbols
mkdir -p "${PROJECT_FOLDER}/products/symbols/${buildNumber}"


cp -R "${temp_folder}/${PRODUCT_NAME}.xcarchive/dSYMs/" "${PROJECT_FOLDER}/products/symbols/${buildNumber}/"


cp -Rv "${SRC_PATH}/build_resources/" "${BUILD_FOLDER}"

echo "output is in ${BUILD_FOLDER}"
if [ -e /Users/tperfitt/Documents/Projects/build/build.sh ] ; then 
	/Users/tperfitt/Documents/Projects/build/build.sh  "${BUILD_FOLDER}" "${temp_folder}" "${PRODUCT_NAME}" "${BUILD_FOLDER}/XCreds.app" "${SCRIPT_FOLDER}/build_post.sh"
fi
