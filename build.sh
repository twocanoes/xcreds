#!/bin/bash 

set -e

echo "post to github? (y/N)"
read should_upload
if [ "${should_upload}" = "y" ]; then
   upload=1
echo "uploading to github when done"
fi

carthage update
xcodebuild -resolvePackageDependencies

pushd ./build_resources/buildscripts/

SKIP_DMG=1 ./build.sh

popd
