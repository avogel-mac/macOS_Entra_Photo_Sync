#!/bin/bash

#############################################################################
# Shellscript      : Script for downloading the profile photo from entraID 
#                    and storing it in macOS as User Photo
# Author           : Andreas Vogel, NEXT Enterprise GmbH
#
# This script has been created to the best of my knowledge and ability. However, I do not assume any liability
# for any damages or losses that may arise from the use of this script.
# Please note that the care of the application in Azure is your responsibility.
# You should ensure that the script meets your requirements and is adjusted accordingly.
# Additionally, please be aware that the endpoints used in the script are currently functional at the time of creation
# and currently only extract the profile picture. Changes to the endpoints are reserved by the provider
# and are subject to change at any time.
#############################################################################

scriptVersion="1.0.0"

# Variables
clientID="$5"
secretValue="$6"
tenantID="$7"
scriptLog="/var/log/it.next.Set_User_Picture.log"
current_user=$(ls -l /dev/console | awk '{ print $3 }')
url="https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token"
data="client_id=$clientID&scope=https://graph.microsoft.com/.default&client_secret=$secretValue&grant_type=client_credentials"
headers=(-H "Content-Type: application/x-www-form-urlencoded")
PictureFolder="/Library/User Pictures/Pictures"
UserPic_tmp="/tmp/${current_user}_photo.jpeg"

# Function for logging
function ScriptLog() {
  echo -e "$(date) | - ${1}" | tee -a "${scriptLog}"
}

# Function for error handling
function handleError() {
  ScriptLog "$1"
  ScriptLog "    End with ERROR [$scriptVersion]"
  ScriptLog "##############################################################"
  exit 1
}

# Initialize Log File
if [[ ! -f "${scriptLog}" ]]; then
  touch "${scriptLog}"
elif [[ $(stat -f%z "${scriptLog}") -gt 10000000 ]]; then
  zipFile="${scriptLog%.log}_$(date +'%Y-%m-%d_%H-%M-%S').zip"
  zip -j "${zipFile}" "${scriptLog}" && rm "${scriptLog}" && touch "${scriptLog}"
  ScriptLog "$(date) - log file too large, has been zipped to ${zipFile}"
fi

# Begin Script
ScriptLog ""
ScriptLog "##############################################################"
ScriptLog "Starting Script to set User Picture [$scriptVersion]"

# Validate inputs
[[ -z "$clientID" || -z "$secretValue" || -z "$tenantID" ]] && handleError "ERROR: Missing required inputs"

# Find User email address
if [[ -d "/Applications/Jamf Connect.app" ]]; then
  ScriptLog "Jamf Connect.app found" 
  ScriptLog "User account was created with jamf connect search the user email address"
  email=$(dscl . read /Users/$current_user dsAttrTypeStandard:NetworkUser | awk '{print $2}')
elif [[ -f "/Library/Managed Preferences/com.microsoft.office.plist" ]]; then
  ScriptLog "com.microsoft.office.plist found"
  email=$(defaults read "/Library/Managed Preferences/com.microsoft.office.plist" EmailAddress)
else
  handleError "Error: Neither Jamf Connect.app nor com.microsoft.office.plist found\nEmail address not found. No image can be searched for the current user from Azure."
fi

[[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]] || handleError "ERROR: No valid e-mail address found"

# Get token from Entra
ScriptLog "Getting the Token"
token=$(curl -s -X POST "${headers[@]}" -d "$data" "$url" | sed -E 's/.*"access_token":"([^"]+)".*/\1/')
[[ -z "$token" ]] && handleError "Failed to obtain token"

# Download profile photo
photoURL="https://graph.microsoft.com/beta/users/$email/photo/\$value"
headers2=(-H "Authorization: Bearer $token")
ScriptLog "getting the Photo [$UserPic_tmp]"

response=$(curl -s --location --request GET "$photoURL" "${headers2[@]}" --write-out "%{http_code}" --silent --output "$UserPic_tmp")
[[ "$response" != "200" ]] && handleError "ERROR HTTP Code: ${response}"

# Ensure PictureFolder exists and copy photo
mkdir -p "$PictureFolder" || handleError "Error when creating the PictureFolder: $PictureFolder"
cp "$UserPic_tmp" "$PictureFolder/${current_user}.jpeg" || handleError "Error copying the image to $PictureFolder/${current_user}.jpeg"
chmod a+rx "$PictureFolder/${current_user}.jpeg" || handleError "Error changing permissions for $PictureFolder/${current_user}.jpeg"

ScriptLog "Delete previous data"

dscl . delete /Users/$current_user JPEGPhoto ||
dscl . delete /Users/$current_user Picture ||
# Update user profile picture
ScriptLog "Set new profile picture"
dscl . create /Users/$current_user Picture "$PictureFolder/${current_user}.jpeg" || handleError "Failed to update user profile picture"

PICIMPORT="$(mktemp /tmp/${current_user}_dsimport.XXXXXX)"
MAPPINGS='0x0A 0x5C 0x3A 0x2C'
ATTRS='dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto'
printf "%s %s \n%s:%s" "${MAPPINGS}" "${ATTRS}" "$current_user" "$PictureFolder/$current_user.jpeg" > "${PICIMPORT}"
/usr/bin/dsimport "${PICIMPORT}" /Local/Default M &&

rm "${PICIMPORT}"

ScriptLog "    End Successfully [$scriptVersion]"
ScriptLog "##############################################################"

exit 0
