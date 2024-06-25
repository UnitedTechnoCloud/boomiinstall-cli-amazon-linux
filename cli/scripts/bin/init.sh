#!/bin/bash

source bin/common.sh
# get atom id of the by atom name
# mandatory arguments
unset atomType ATOM_HOME
ARGUMENTS=(atomName accountId classification)
OPT_ARGUMENTS=(proxyHost proxyPort proxyUser proxyPassword installDir workDir tmpDir javaHome jreHome atomType purgeHistoryDays roleNames forceRestartMin maxMem apiType apiAuth sharedWebURL serviceUserName mountPoint env client group)

inputs "$@"

if [ "$?" -gt "0" ]
then
       return 255;
fi

export h1="Content-Type: application/json"
export h2="Accept: application/json"
export WORKSPACE=`pwd`

echo "env are: "
env

echo "Cloud Platform : ${platform}"
echo "Atom Name : ${atomName}"
echo "Atom Type : ${atomType}"
echo "Boomi Environment : ${env}"
echo "purge Days : ${purgeHistoryDays}"
echo "max Memory : ${maxMem}"
echo "efsMount : ${efsMount}"
echo "authToken : ${authToken}"
echo "client : ${client}"
echo "group : ${group}"
echo "region : ${region}"
echo "classification is: ${boomiClassification}"
echo "Git Org Repo Name: ${GitRepoName}"

# Keys that can change
export VERBOSE="false" # Bash verbose output; set to true only for testing, will slow execution.
export SLEEP_TIMER=0.2 # Delays curl request to the platform to set the rate under 5 requests/second
# Derived keys
export baseURL=https://api.boomi.com/api/rest/v1/$accountId

if [ -z "${installDir}" ]
then
      export installDir=/mnt/boomi 
fi

if [ -z "${workDir}" ]
then
     export workDir=/usr/local/boomi/work 
fi

if [ -z "${jreHome}" ]
then
     export jreHome=/usr/lib/jvm/jre 
fi

if [ -z "${javaHome}" ]
then
     export javaHome=/usr/bin/java 
fi

if [ -z "${tmpDir}" ]
then
     export tmpDir=/usr/local/boomi/tmp 
fi

if [ -z "${atomType}" ]
then
     export atomType="ATOM" # ATOM, MOLECULE, CLOUD 
fi

if [ -z "${purgeHistoryDays}" ]
then
     export purgeHistoryDays="14"  
fi

if [ -z "${roleNames}" ]
then
     export roleNames="Administrator, Support, Production Support" 
fi

if [ -z "${forceRestartMin}" ]
then
   export forceRestartMin=10	
fi

if [ -z "${maxMem}" ]
then
     export maxMem=4g 
fi

if [ -z "${apiType}" ]
then
     export apiType="advanced" 
fi

if [ -z "${apiAuth}" ]
then
     export apiAuth=basic 
fi

if [ -z "${sharedWebURL}" ]
then
     export sharedWebURL="https:\/\/not-set\.com"
fi

if [ -z "${serviceUserName}" ]
then
     export serviceUserName="boomi"  
fi

if [ -z "${mountPoint}" ]
then
     export mountPoint="/mnt/boomi" # Env classification TEST, PRODD 
fi

if [ "$?" -gt "0" ]
then
       return 255;
fi

if [ ! -z "${client}" ]
then
	echo "export client='$client'" >> /home/$serviceUserName/.profile
fi

if [ ! -z "${group}" ]
then
	echo "export group='$group'" >> /home/$serviceUserName/.profile
fi

if [ ! -z "${env}" ]
then
	echo "export environment='$env'" >> /home/$serviceUserName/.profile
fi

atomName="$(echo "${atomName}" | sed -e 's/-/_/g')"

if [ "$atomType" = "ATOM" ];
then
        export ATOM_HOME="${installDir}/Atom_${atomName}"
elif [ "$atomType" = "MOLECULE" ];
then
        export ATOM_HOME="${installDir}/Molecule_${atomName}"
elif [ "$atomType" = "CLOUD" ];
then
        export ATOM_HOME="${installDir}/Cloud_${atomName}"
elif [ "$atomType" = "GATEWAY" ];
then
        export ATOM_HOME="${installDir}/Gateway_${atomName}"
fi

echo "export ATOM_HOME='$ATOM_HOME'" >> /home/$serviceUserName/.profile
echo "export BOOMI_CONTAINERNAME='$atomName'" >> /home/$serviceUserName/.profile
i=0
while [ $i -lt 10 ]
do
        viewfile_count=$(ls $ATOM_HOME/bin/views/*molecule_$i* 2> /dev/null | wc -l)
        if [ ${viewfile_count} -eq 0 ];  then
                ATOM_LOCALHOSTID=molecule_$i;
                break;
        else
                i=$((i + 1))
        fi
done

if [ "$atomType" = "ATOM" ];
then
	echo "export ATOM_LOCALHOSTID=atom" >> /home/$serviceUserName/.profile
	echo "export pod_name=atom" >> /home/$serviceUserName/.profile
else
	echo "export ATOM_LOCALHOSTID=${ATOM_LOCALHOSTID}" >> /home/$serviceUserName/.profile
	echo "export pod_name=${ATOM_LOCALHOSTID}" >> /home/$serviceUserName/.profile
fi


source /home/$serviceUserName/.profile
# install Boomi only if the atom binaries are not installed
if [[ ! -f ${ATOM_HOME}/bin/atom ]]
then
	source bin/installBoomi.sh
else
	echo "Atom is already installed at $ATOM_HOME, will install only the start up service"	
fi
ln -sf ${ATOM_HOME}/bin/atom /usr/local/bin/atom
cp -f /home/$serviceUserName/restart.sh ${ATOM_HOME}/bin
sudo bin/installBoomiService.sh atomName="${atomName}" atomHome="${ATOM_HOME}" serviceUserName=${serviceUserName} mountPoint="${mountPoint}"
