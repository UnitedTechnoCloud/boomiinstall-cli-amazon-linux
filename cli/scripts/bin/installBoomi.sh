#!/bin/bash
source bin/common.sh
INSTALL_DIR="${installDir}"
JRE_HOME="${jreHome}"
JAVA_HOME="${javaHome}"
TMP_DIR="${tmpDir}"
WORK_DIR="${workDir}"
unset ATOM_HOME
if [[ "$atomType" = "ATOM" ]]
	then
		# install atom on the local drive 
		ATOM_HOME=${INSTALL_DIR}/Atom_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi
			
		source bin/installerToken.sh atomType=${atomType}
		./bin/installAtom.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"
		if [ ! -z "${env}" ]; 
		then
			source bin/createEnvAndAttachRoleAndAtom.sh env="${env}" classification=${classification} atomName="${atomName}" roleNames="${roleNames}" purgeHistoryDays="${purgeHistoryDays}" forceRestartTime="${forceRestartMin}"
		else
			source bin/updateAtom.sh atomId=${atomId} purgeHistoryDays="${purgeHistoryDays}" forceRestartTime=${forceRestartTime}
		fi
		source bin/updateSharedServer.sh atomName="${atomName}" overrideUrl=true url="${sharedWebURL}" apiType="${apiType}" auth="${apiAuth}"
		input="conf/atom_container.properties"

	elif [[ "$atomType" = "CLOUD" ]]
	then
		ATOM_HOME=${INSTALL_DIR}/Cloud_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi
		
		source bin/installerToken.sh atomType=${atomType} cloudId=$cloudId
		./bin/installCloud.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" WORK_DIR="${WORK_DIR}" TMP_DIR="${TMP_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"
		source bin/updateSharedServer.sh atomName="${atomName}" overrideUrl=true url="${sharedWebURL}" apiType="${apiType}" auth="${apiAuth}"		
		
	elif [[ "$atomType" = "GATEWAY" ]]
	then
		ATOM_HOME=${INSTALL_DIR}/Gateway_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi
		
		source bin/installerToken.sh atomType=${atomType}
		./bin/installGateway.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" WORK_DIR="${WORK_DIR}" TMP_DIR="${TMP_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"

	elif [[ "$atomType" = "MOLECULE" ]]
	then
	        echo "Molecule environment variables: "
	        env	
		ATOM_HOME=${INSTALL_DIR}/Molecule_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi

		source bin/installerToken.sh atomType=${atomType}
		echo "Token ID is: ${tokenId}"
		./bin/installMolecule.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" WORK_DIR="${WORK_DIR}" TMP_DIR="${TMP_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"
		if [ ! -z "${env}" ]; 
		then
			source bin/createEnvAndAttachRoleAndAtom.sh env="${env}" classification=${classification} atomName="${atomName}" roleNames="${roleNames}" purgeHistoryDays="${purgeHistoryDays}" forceRestartTime="${forceRestartMin}"
		else
			source bin/updateAtom.sh atomId=${atomId} purgeHistoryDays="${purgeHistoryDays}" forceRestartTime=${forceRestartTime}
		fi
		source bin/updateSharedServer.sh atomName="${atomName}" overrideUrl=true url="${sharedWebURL}" apiType="${apiType}" auth="${apiAuth}"
		input="conf/molecule_container.properties"
	else
		echo "Invalid AtomType"
		exit 255
fi
${ATOM_HOME}/bin/atom stop

echo "$JRE_HOME" > "${ATOM_HOME}"/.install4j/inst_jre.cfg
echo "$JRE_HOME" > "${ATOM_HOME}"/.install4j/pref_jre.cfg
sed -i "s/-Xmx.*$/-Xmx${maxMem}/" "$ATOM_HOME/bin/atom.vmoptions"

echoi "Purgehistory days $purgeHistoryDays." 
# append additional atom JAVA options
cat <<EOF >>${ATOM_HOME}/bin/atom.vmoptions
-XX:+UseG1GC
-XX:+ParallelRefProcEnabled
-XX:+UseStringDeduplication
-XX:+HeapDumpOnOutOfMemoryError
-Duser.timezone=America/New_York
-Dcom.sun.management.jmxremote.authenticate=false
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.local.only=false
-Dcom.sun.management.jmxremote.port=5003
-Dcom.sun.management.jmxremote.rmi.port=5003
-Dcom.sun.management.jmxremote.password.file=/etc/jmxremote/jmxremote.password
-Dcom.sun.management.jmxremote.access.file=/etc/jmxremote/jmxremote.access
EOF


# update container properties
while IFS= read -r line; do echo "$line" >> ${ATOM_HOME}/conf/container.properties; done  < "$input"

	
#${ATOM_HOME}/bin/atom start
