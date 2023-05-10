#!/bin/sh


set -e
set -x 
a=123
BUILD_DIR="/tmp/xcreds"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"
if [ "${1}" ]; then
REMOTE_MAC=$1
else 
REMOTE_MAC="test.local"
fi

agvtool bump
xcodebuild  -scheme "XCreds"  -configuration "Release" -derivedDataPath  "${DERIVED_DATA_DIR}"

ssh  root@"${REMOTE_MAC}" 'bash -c "if [ -e "/Applications/XCreds.app" ] ; then echo removing; rm -rf "/Applications/XCreds.app"; fi"'

if [ -e /tmp/xcreds/xcreds.zip ]; then
	rm /tmp/xcreds/xcreds.zip
fi

pushd /tmp/xcreds/DerivedData/Build/Products/Release/
zip -r /tmp/xcreds/xcreds.zip XCreds.app
popd 

ssh  root@"${REMOTE_MAC}" 'bash -c "if [ -e "/tmp/xcreds.zip" ] ; then echo removing; rm -rf "/tmp/xcreds.zip"; fi"'

scp -Cr /tmp/xcreds/xcreds.zip root@"${REMOTE_MAC}":/tmp/xcreds.zip


ssh root@"${REMOTE_MAC}" unzip /tmp/xcreds.zip -d /Applications
#scp -r /tmp/xcreds/DerivedData/Build/Products/Release/XCreds.app root@"${REMOTE_MAC}":/Applications
ssh root@"${REMOTE_MAC}" /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -r

ssh  root@"${REMOTE_MAC}" /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -i

#ssh  root@"${REMOTE_MAC}" killall -9 SecurityAgent || echo "unable to kill"
ssh root@"${REMOTE_MAC}" reboot
