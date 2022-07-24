#!/bin/sh


set -e
set -x 

ssh -J tcadmin@simac.local root@test001.local rm -rf "/Applications/XCreds.app"

scp -r -J tcadmin@simac.local "${BUILD_ROOT}"/Release/XCreds.app root@test001.local:/Applications/ 

#ssh -J tcadmin@simac.local root@test001.local reboot || exit 0

ssh -J tcadmin@simac.local root@test001.local /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -r

ssh -J tcadmin@simac.local root@test001.local /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -i

ssh -J tcadmin@simac.local root@test001.local killall -9 SecurityAgent || echo "unable to kill"
