#!/bin/bash 

set -e

carthage update
xcodebuild -resolvePackageDependencies

pushd ./build_resources/buildscripts/

SKIP_DMG=1 ./build.sh

popd
