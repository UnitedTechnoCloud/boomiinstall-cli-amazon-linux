#!/bin/bash
source bin/common.sh
# get atom id of the by atom name
# mandatory arguments
ARGUMENTS=(roleNames env)
inputs "$@"
if [ "$?" -gt "0" ] 
then 
	return 255;
fi

_saveEnv="${env}"
IFS=',' ; for roleName in $(echo "$roleNames");
do
	
	roleName=$(echo "${roleName}" | xargs )
	_saveRoleName="${roleName}"
	env="${_saveEnv}"
	source bin/queryEnvironmentRole.sh 
	if [ -z "${roleAttachmentId}" ] || [ "" == "${roleAttachmentId}" ] || [ null == "${roleAttachmentId}" ] || [ "null" == "${roleAttachmentId}" ]
	then
		JSON_FILE=json/createEnvironmentRole.json
		ARGUMENTS=(roleId envId)
		URL=$baseURL/EnvironmentRole/
		id=id	
		exportVariable=roleAttachmentId
		createJSON
 		callAPI
	else
		echoi "Role $_saveRoleName is already attached to $_saveEnv."	
	fi
done	
	
clean
if [ "$ERROR" -gt "0" ]
then
   return 255;
fi
