#!/bin/bash +x 
set -e
SECURITY_PLUGIN_PATH="/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle"
ssh root@sign.local rm -rf  "${SECURITY_PLUGIN_PATH}"
scp -r "${BUILD_ROOT}/Debug/XCredsLoginPlugin.bundle" root@sign.local:"${SECURITY_PLUGIN_PATH}"
ssh root@sign.local killall -9 SecurityAgent

exit 0