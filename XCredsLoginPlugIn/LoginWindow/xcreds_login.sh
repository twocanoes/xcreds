#!/bin/bash

script_path="$0"
script_folder=$(dirname "${script_path}")
authrights_path="${script_folder}"/authrights
plugin_path="${script_folder}"/XCredsLoginPlugin.bundle
plugin_resources_path="${plugin_path}"/Contents/Resources
overlay_path="${script_folder}"/"XCreds Login Overlay.app"
overlay_resources_path="${overlay_path}"/Contents/Resources
auth_backup_folder=/Library/"Application Support"/xcreds
rights_backup_path="${auth_backup_folder}"/rights.bak
launch_agent_config_name="com.twocanoes.xcreds-overlay.plist"
launch_agent_destination_path="/Library/LaunchAgents/"
launch_agent_source_path="${overlay_resources_path}"/"${launch_agent_config_name}"

autofill_path="${target_path}/Applications/XCreds.app/Contents/Resources/XCreds Login Autofill.app/Contents/PlugIns/XCreds Login Password.appex"


f_install=0
f_remove=0
f_restore=0

remove_rights () {
    "${authrights_path}" -d  "XCredsLoginPlugin:UserSetup,privileged"
    "${authrights_path}" -r  "XCredsLoginPlugin:LoginWindow" "loginwindow:login" > /dev/null
    "${authrights_path}" -d  "XCredsLoginPlugin:PowerControl,privileged"
    "${authrights_path}" -d  "XCredsLoginPlugin:KeychainAdd,privileged"
    "${authrights_path}" -d  "XCredsLoginPlugin:CreateUser,privileged"
    "${authrights_path}" -d  "XCredsLoginPlugin:EnableFDE,privileged"
    "${authrights_path}" -d  "XCredsLoginPlugin:LoginDone"

}
while getopts ":ire" o; do
	case "${o}" in
		i)
			f_install=1
		;;
		r)
			f_remove=1
		;;
        e)
            f_restore=1
        ;;

	esac
done



if [ $(id -u) -ne 0 ]; then
	echo please run with sudo
	exit -1
fi


if [ $f_install -eq 1 ] && [ $f_remove -eq 1 ]; then
	echo "you can't specify both -i and -r"
	exit -1
fi

if [ $f_install -eq 1 ]; then
	
	if [ ! -e  "${auth_backup_folder}" ]; then
		mkdir -p "${auth_backup_folder}"
	fi
	
	if [ ! -e "${rights_backup_path}" ]; then 
		security authorizationdb read system.login.console > "${rights_backup_path}"
		
	fi

    if [ -e "${autofill_path}" ]; then
        /usr/bin/pluginkit -a "${autofill_path}"
    fi
	if [ -e  "${plugin_path}" ]; then
		
		cp -R "${plugin_path}" "${target_volume}"/Library/Security/SecurityAgentPlugins/
		chown -R root:wheel "${target_volume}"/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle
	fi
	
	if [ ! -e "${launch_agent_destination_path}"/"${launch_agent_config_name}" ]; then
	
		cp "${launch_agent_source_path}" "${launch_agent_destination_path}"
	fi
	if [ -e ${authrights_path} ]; then
         remove_rights

        "${authrights_path}" -b "loginwindow:login" "XCredsLoginPlugin:UserSetup,privileged"
        "${authrights_path}" -r "loginwindow:login" "XCredsLoginPlugin:LoginWindow"
        "${authrights_path}" -a  "XCredsLoginPlugin:LoginWindow" "XCredsLoginPlugin:PowerControl,privileged"
        "${authrights_path}" -a  "loginwindow:done" "XCredsLoginPlugin:KeychainAdd,privileged"
        "${authrights_path}" -a  "builtin:login-begin" "XCredsLoginPlugin:CreateUser,privileged"
        "${authrights_path}" -a  "loginwindow:done" "XCredsLoginPlugin:EnableFDE,privileged"
        "${authrights_path}" -a  "loginwindow:done" "XCredsLoginPlugin:LoginDone"

	else
		echo "could not find authrights tool"
		exit -1
	fi

	
elif [ $f_remove -eq 1 ]; then

    remove_rights

	if [ -e  "/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle" ]; then
		rm -rf "/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle"
		
	fi
	
	if [ -e "${launch_agent_destination_path}"/"${launch_agent_config_name}" ]; then
#		/bin/launchctl unload "${launch_agent_destination_path}"/"${launch_agent_config_name}" 
		rm "${launch_agent_destination_path}"/"${launch_agent_config_name}"
	fi
	
	
elif [ $f_restore -eq 1 ]; then
    if [ -e "${rights_backup_path}" ]; then
        security authorizationdb write system.login.console < "${rights_backup_path}"
    else
        echo "no backup found to restore at \"${rights_backup_path}\""
    fi



else 
	echo "you must specify -i (install right), -r (remove right), or -e (restore all rights from backup)."
	exit -1
	
fi
