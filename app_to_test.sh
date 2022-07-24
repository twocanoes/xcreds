#!/bin/sh


set -e
set -x 
a=123
BUILD_DIR="/tmp/xcreds"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"


agvtool bump
xcodebuild  -scheme "XCreds"  -configuration "Release" -derivedDataPath  "${DERIVED_DATA_DIR}"

ssh -J tcadmin@simac.local root@test001.local 'bash -c "if [ -e "/Applications/XCreds.app" ] ; then echo removing; rm -rf "/Applications/XCreds.app"; fi"'

scp -r -J tcadmin@simac.local "${DERIVED_DATA_DIR}"/Build/Products/Release/XCreds.app root@test001.local:/Applications/ 

#ssh -J tcadmin@simac.local root@test001.local reboot || exit 0

ssh -J tcadmin@simac.local root@test001.local /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -r

ssh -J tcadmin@simac.local root@test001.local /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -i

ssh -J tcadmin@simac.local root@test001.local killall -9 SecurityAgent || echo "unable to kill"
