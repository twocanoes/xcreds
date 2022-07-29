#!/bin/sh


set -e
set -x 
a=123
BUILD_DIR="/tmp/xcreds"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"


agvtool bump
xcodebuild  -scheme "XCreds"  -configuration "Release" -derivedDataPath  "${DERIVED_DATA_DIR}"

ssh  root@simac.local 'bash -c "if [ -e "/Applications/XCreds.app" ] ; then echo removing; rm -rf "/Applications/XCreds.app"; fi"'

scp -r "${DERIVED_DATA_DIR}"/Build/Products/Release/XCreds.app root@simac.local:/Applications/ 

#ssh -J tcadmin@simac.local root@test001.local reboot || exit 0

ssh root@simac.local /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -r

ssh  root@simac.local /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -i

ssh  root@simac.local killall -9 SecurityAgent || echo "unable to kill"
#ssh root@simac.local reboot
