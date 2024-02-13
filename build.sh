#!/bin/bash 

set -e

echo "post to github? (y/N)"
read should_upload
if [ "${should_upload}" = "y" ]; then
   export upload=1
   echo "uploading to github when done"
fi


echo "updated manifest version? (y/N)"
read should_update_manifest
if [ "${should_update_manifest}" = "y" ]; then
   export update_manifest=1
   echo "updating manifest"
fi


carthage update
xcodebuild -resolvePackageDependencies

pushd ./build_resources/buildscripts/

SKIP_DMG=1 ./build.sh

popd
