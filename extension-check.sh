#!/usr/bin/env bash 
#################################################################
#	FILE:  check-extension.sh 				#
#	USAGE: check-extension <item>				#
#	AUTHOR: @RDY73 						#
#	VERSION: 0.1 						#
#	CREATE: 20/6/26 					#
#	NOTES: A function  to detect what a version item it 	#	
#################################################################

if command -v chmod 2>/dev/null; then 
	sudo chmod +x ./extension-check.sh 
fi
extension-func(){

	local prompt
	prompt=$(sudo -nv 2>&1)
	if [[ $? -ne 0 ]]; then
		if echo $prompt | grep -q "^sudo"; then 
			echo "Script needs sudo. Enter password"
			sudo touch /var/run/extension-check.pid
		else
			echo "you need sudo."
		fi
	fi
	
	if [[ $# -ne 1 ]]; then 
		echo "need at least one volume"
		return 1
	fi	
	local thing=${1}
	if [[ -f "$thing" ]]; then 
		echo "Thing is a file."
	elif [[ -d "$thing" ]]; then 
		echo "Thing is a folder."
	elif [[ -n "$thing" ]]; then 
		echo "Thing is a string"
	fi	
}

extension-func "/etc/"
extension-func "/etc/passwd"
extension-func "/etc/passwd"
extension-func "test"
