#!/bin/bash
source bin/common.sh
# get atom id of the by atom name
# mandatory arguments
ARGUMENTS=(roleName env)
inputs "$@"
if [ "$?" -gt "0" ] 
then 
	return 255;
fi
source bin/queryRole.sh name=$roleName
source bin/queryEnvironment.sh name=$envName classification="*"

_saveRoleId=$roleId
_saveEnvId=$envId
ARGUMENTS=(roleId envId)
JSON_FILE=json/queryEnvironmentRole.json
unset roleAttachmentId
URL=$baseURL/EnvironmentRole/query
id=result[0].id
exportVariable=roleAttachmentId
createJSON
callAPI
clean

if [ "$ERROR" -gt "0" ]
then
   return 255;
fi
export envId="${_saveEnvId}"
export roleId="${_saveRoleId}"
