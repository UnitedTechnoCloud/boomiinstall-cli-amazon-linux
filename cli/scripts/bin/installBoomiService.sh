#!/bin/bash

source bin/common.sh
ARGUMENTS=(atomName serviceUserName atomHome mountPoint)
authToken="BOOMI_TOKEN."
inputs "$@"
echo "create atom.service ..."
cat <<EOF >/etc/systemd/system/atom.service
[Unit]
Description=Boomi $atomName
After=network.target
RequiresMountsFor="${mountPoint}"
[Service]
User=$serviceUserName
WorkingDirectory=/home/${serviceUserName}
PassEnvironment=JAVA_HOME
ExecStart="/home/${serviceUserName}/start-atom.sh"
ExecStop="/home/${serviceUserName}/stop-atom.sh"
Type=forking
TimeoutStartSec=600
Restart=always
[Install]
WantedBy=multi-user.target
EOF

echo "setup $atomname JMX integration..."
mkdir -vp /etc/jmxremote
cat <<EOF >/etc/jmxremote/jmxremote.password
monitorRole Password
EOF
cat <<EOF >/etc/jmxremote/jmxremote.access
monitorRole readonly
EOF
# change the permissions on both files so only owner can edit and view them.
chmod -R 0600 /etc/jmxremote
chown -R $serviceUserName:$serviceUserName /etc/jmxremote/jmxremote.*

echo "setup atom.service ..."
systemctl enable atom
systemctl start atom
systemctl is-active --quiet atom && echo "Service is running..."
