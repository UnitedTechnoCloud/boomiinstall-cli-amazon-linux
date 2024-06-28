#!/bin/bash
#set -x
if [ -n "$platform" ] ; then
    if [[ -f /etc/boomi_runtime_installer ]]; then 
        echo "boomi_runtime_installer already run so will not be run again!"
        exit 0; 
    fi
fi

echo "begin boomi install..."
USR=boomi
GRP=boomi
whoami
echo "Cloud Platform : ${platform}"
echo "Atom Name : ${atomName}"
echo "Atom Type : ${atomType}"
echo "Boomi Environment : ${boomiEnv}"
echo "purge Days : ${purgeHistoryDays}"
echo "max Memory : ${maxMem}"
echo "efsMount : ${efsMount}"
echo "sharedWebURL : ${sharedWebURL}"

#  create boomi user
sudo groupadd -g 5151 -r $GRP
sudo useradd -u 5151 -g $GRP -r -m -s /bin/bash $USR
sudo usermod -aG sudo boomi
echo "boomi ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
sudo yum update -y && sudo yum upgrade -y
echo "install python..."
sudo yum install -y zip -y
sudo yum install python3-pip -y
python3 --version
sudo yum install -y ca-certificates curl gnupg -y

# set ulimits
sudo sysctl -w net.core.rmem_max=8388608
sudo sysctl -w net.core.wmem_max=8388608
sudo sysctl -w net.core.rmem_default=65536
sudo sysctl -w net.core.wmem_default=65536
printf "%s\t\t%s\t\t%s\t\t%s\n" $USR "soft" "nproc" "65535" | sudo tee -a /etc/security/limits.conf
printf "%s\t\t%s\t\t%s\t\t%s\n" $USR "hard" "nproc" "65535" | sudo tee -a /etc/security/limits.conf
printf "%s\t\t%s\t\t%s\t\t%s\n" $USR "soft" "nofile" "8192" | sudo tee -a /etc/security/limits.conf
printf "%s\t\t%s\t\t%s\t\t%s\n" $USR "hard" "nofile" "8192" | sudo tee -a /etc/security/limits.conf

# install java
echo "install java..."
yum install -y amazon-linux-extras
amazon-linux-extras install -y java-openjdk11
amazon-linux-extras install -y collectd
yum install -y collectd-java
yum install -y collectd-generic-jmx

# Disable SELinux for collectd
echo "Disabling SELinux..."
setenforce 0
sed -i "s%SELINUX=enforcing%SELINUX=disabled%g" /etc/selinux/config

# Looking for libjvm.so from the java-openjdk11 package that was installed
LIBJVM_SYMLINK=/usr/lib64/libjvm.so
if [ -L ${LIBJVM_SYMLINK} ] && [ -e ${LIBJVM_SYMLINK} ]; then
	    echo "Synlink to libjvm.so already exists. Skipping..."
    else
	        libjvm_location=$(sudo find / -name libjvm.so | grep -m 1 'java-11-openjdk')
		    echo "libjvm_location: $libjvm_location"
		        sudo ln -s $libjvm_location /usr/lib64/libjvm.so
fi

set -e
## download boomicicd CLI 
sudo yum install -y jq -y
sudo yum install libxml2 -y
sudo yum install -y nfs-utils

mkdir -p  /home/$USR/boomi/boomicicd
cd /home/$USR/boomi/boomicicd
echo "git clone https://github.com/UnitedTechnoCloud/boomiinstall-cli-amazon-linux..."
rm -rf boomiinstall-cli-amazon-linux
git clone https://github.com/UnitedTechnoCloud/boomiinstall-cli-amazon-linux
cd /home/$USR/boomi/boomicicd/boomiinstall-cli-amazon-linux/cli/
chmod +x scripts/bin/*.*
chmod +x scripts/home/*.*
set +e

# download Boomi installers
echo "download boomi installers..."
curl -fsSL https://platform.boomi.com/atom/atom_install64.sh -o atom_install64.sh && chmod +x "atom_install64.sh"
curl -fsSL https://platform.boomi.com/atom/molecule_install64.sh -o molecule_install64.sh && chmod +x "molecule_install64.sh"
curl -fsSL https://platform.boomi.com/atom/cloud_install64.sh -o cloud_install64.sh && chmod +x "cloud_install64.sh"
cp scripts/home/* /home/$USR

# Create the .profile
cd /home/$USR
cp /home/$USR/boomi/boomicicd/boomiinstall-cli-amazon-linux/cli/scripts/home/.profile .
echo "export platform=${platform}" >> .profile
chmod u+x /home/$USR/.profile
echo "if [ -f /home/$USR/.profile ]; then" >> /home/$USR/.bashrc
echo "	. /home/$USR/.profile" >> /home/$USR/.bashrc
echo "fi" >> /home/$USR/.bashrc
if [ "${platform}" = "aws" ]; then
    EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
    EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
    echo "export AWS_DEFAULT_REGION=$EC2_REGION" >> .profile	
    source /home/$USR/.profile
fi
            
# set up local directories for install
mkdir -p /mnt/boomi
mkdir -p /usr/local/boomi/work
mkdir -p /usr/local/boomi/tmp
mkdir -p /usr/local/bin
chown -R $USR:$GRP /mnt/boomi/
chown -R $USR:$GRP /home/$USR/
chown -R $USR:$GRP /usr/local/boomi/
chown -R $USR:$GRP /usr/local/bin/
whoami

# install boomi
sudo -u $USR bash << EOF
echo "install boomi runtime as $USR"
cd /home/$USR/boomi/boomicicd/boomiinstall-cli-amazon-linux/cli/scripts
if [ -n "$efsMount" ] ; then
    echo "setting EFS Mount:${efsMount} ..."
    source bin/efsMount.sh efsMount="${efsMount}" platform=${platform}
fi
export authToken=${boomiAtomsphereToken}
export client=${client}
export group=${group}
env
echo "run init.sh..."
. bin/init.sh atomType="${atomType}" atomName="${atomName}" env="${boomiEnv}" classification=${boomiClassification} accountId=${boomiAccountId} purgeHistoryDays=${purgeHistoryDays} maxMem=${maxMem} client=${client} group=${group} sharedWebURL=${sharedWebURL}
EOF

echo "boomi install complete..."

if [ -n "$platform" ] ; then
  touch /etc/boomi_runtime_installer
  echo "boomi_runtime_installer flag created"
fi
