#!/bin/bash

set -e
set -x

script_path="${0}"
package_path="${1}"
target_path="${2}"
target_volume="${3}"
authrights_path="${target_path}"/Applications/XCreds.app/Contents/Resources/authrights
plugin_path="${target_path}"/Applications/XCreds.app/Contents/Resources/XCredsLoginPlugin.bundle
auth_backup_folder="${target_volume}"/Library/"Application Support"/xcreds
rights_backup_path="${auth_backup_folder}"/rights.bak

if [ -e "${rights_backup_path}" ]; then 
	security authorizationdb write system.login.console < "${rights_backup_path}"
fi

if [ -e  "${target_volume}"/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle ]; then
	rm -rf "${target_volume}"/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle
fi

if [ -e  "${target_volume}"/Applications/XCreds.app ]; then
	rm -rf "${target_volume}"/Applications/XCreds.app
	
fi