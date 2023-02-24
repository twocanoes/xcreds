	#!/bin/bash +x 

set -x
SECURITY_PLUGIN_PATH="/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle"

if [ "${1}" ]; then
REMOTE_MAC=$1
else 
REMOTE_MAC="test.local"
fi
echo running ssh
ssh "root@${REMOTE_MAC}" rm -rf  "${SECURITY_PLUGIN_PATH}"

echo copying files
scp -r "${BUILD_ROOT}/Release/XCredsLoginPlugin.bundle" "root@${REMOTE_MAC}":"${SECURITY_PLUGIN_PATH}" 

ssh "root@${REMOTE_MAC}" killall -9 SecurityAgent

exit 0
