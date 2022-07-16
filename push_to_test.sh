#!/bin/bash +x 

set -x
SECURITY_PLUGIN_PATH="/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle"

echo running ssh
ssh -J tcadmin@simac.local root@test001.local rm -rf  "${SECURITY_PLUGIN_PATH}"

echo copying files
scp -r -J tcadmin@simac.local "${BUILD_ROOT}/Release/XCredsLoginPlugin.bundle" root@test001.local:"${SECURITY_PLUGIN_PATH}" 

ssh -J tcadmin@simac.local root@test001.local killall -9 SecurityAgent

exit 0
