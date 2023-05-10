#!/bin/bash

set -e
set -x


script_path="${0}"
package_path="${1}"
target_path="${2}"
target_volume="${3}"
xcreds_login_script="${target_path}"/Applications/XCreds.app/Contents/Resources/xcreds_login.sh
plugin_path="${target_path}"/Applications/XCreds.app/Contents/Resources/XCredsLoginPlugin.bundle
auth_backup_folder="${target_path}"/Library/"Application Support"/xcreds
rights_backup_path="${auth_backup_folder}"/rights.bak


if [ ! -e  "${auth_backup_folder}" ]; then
	mkdir -p "${auth_backup_folder}"
fi

if [ ! -e "${rights_backup_path}" ]; then 
	security authorizationdb read system.login.console > "${rights_backup_path}"

fi

if [ -e  "${plugin_path}" ]; then
	
	if [ -e "${target_volume}"/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle ]; then
		rm -rf "${target_volume}"/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle
	fi
	cp -R "${plugin_path}" "${target_volume}"/Library/Security/SecurityAgentPlugins/
	chown -R root:wheel "${target_volume}"/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle
fi

if [ -e ${xcreds_login_script} ]; then
	"${xcreds_login_script}" -i 

else
	echo "could not find xcreds_login_script tool"
	exit -1
fi
