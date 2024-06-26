#!/bin/sh
# Script must be ran as root
# Developed for Amazon Linux 2

# Varibles 
BOOMI_INSTALL_DIR=/mnt/boomi/Molecule_BRKDA_DEV_AMZLINUX_Molecule
CLOUDWATCH_LOG_GROUP_NAME=boomi-barrakuda-cloudwatch-logs

# Install collectd
echo "Installing collectd ..."
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


# Load collectd config file
HOST_NAME=$(hostname | xargs)
echo "LoadPlugin logfile
LoadPlugin java
LoadPlugin network
LoadPlugin write_log

<Plugin logfile>
        LogLevel warning
        File \"/var/log/collectd.log\"
        Timestamp true
        PrintSeverity false
</Plugin>

<Plugin \"java\">
  # required JVM argument is the classpath
  # JVMArg \"-Djava.class.path=/installpath/collectd/share/collectd/java\"
  # Since version 4.8.4 (commit c983405) the API and GenericJMX plugin are
  # provided as .jar files.
  JVMARG \"-Djava.class.path=/usr/share/collectd/java/collectd-api.jar:/usr/share/collectd/java/generic-jmx.jar\"
  LoadPlugin \"org.collectd.java.GenericJMX\"

  <Plugin \"GenericJMX\">
    # Memory usage by memory pool.
    <MBean \"memory\">
        ObjectName \"java.lang:type=Memory,*\"
        InstancePrefix \"memory-heap\"
        #InstanceFrom \"name\"
        <Value>
            Type \"memory\"
            #InstanceFrom \"\"
            Table false
            Attribute \"HeapMemoryUsage.max\"
            InstancePrefix \"HeapMemoryUsage.max\"
        </Value>

        <Value>
            Type \"memory\"
            #InstanceFrom \"\"
            Table false
            Attribute \"HeapMemoryUsage.used\"
            InstancePrefix \"HeapMemoryUsage.used\"
        </Value>

    </MBean>

    <MBean \"garbage_collector\">
        ObjectName \"java.lang:type=GarbageCollector,*\"
        InstancePrefix \"gc-\"
        InstanceFrom \"name\"
        <Value>
            Type \"invocations\"
            #InstancePrefix \"\"
            #InstanceFrom \"\"
            Table false
            Attribute \"CollectionCount\"
        </Value>
        <Value>
            Type \"total_time_in_ms\"
            InstancePrefix \"collection_time\"
            #InstanceFrom \"\"
            Table false
            Attribute \"CollectionTime\"
        </Value>
    </MBean>

    <MBean \"os\">
        ObjectName \"java.lang:type=OperatingSystem\"
        InstancePrefix \"os-\"
        InstanceFrom \"name\"
        <Value>
            Type \"guage\"
            InstancePrefix \"os-open-file-\"
            Attribute \"OpenFileDescriptorCount\"
        </Value>
        <Value>
            Type \"guage\"
            InstancePrefix \"os-load-average\"
            Attribute \"SystemLoadAverage\"
        </Value>
    </MBean>


    <Connection>
      Host \"${HOST_NAME}\"
      ServiceURL \"service:jmx:rmi://localhost:5002/jndi/rmi://localhost:5002/jmxrmi\"
      Collect \"memory\"
      Collect \"garbage_collector\"
    </Connection>
  </Plugin>
</Plugin>

<Plugin \"write_log\">
    Format JSON
</Plugin>

<Plugin network>
    <Server \"127.0.0.1\" \"25826\">
        SecurityLevel None
    </Server>
</Plugin>
" | tee /etc/collectd.conf

# Install Amazon Cloudwatch Agent
echo "Installing Amaon Cloudwatch Agent ..."
yum install -y amazon-cloudwatch-agent  

AWS_CLOUDWATCH_AGENT_HOME="/opt/aws/amazon-cloudwatch-agent/bin"
INTERNAL_IP_ADDRESS=$(hostname -I | sed 's/\./_/g' | xargs)

echo "{
        \"agent\": {
                \"metrics_collection_interval\": 30,
                \"run_as_user\": \"root\"
        },
        \"logs\": {
                \"logs_collected\": {
                        \"files\": {
                                \"collect_list\": [
                                        {
                                                \"file_path\": \"${BOOMI_INSTALL_DIR}/logs/*.container.${INTERNAL_IP_ADDRESS}.log\",
                                                \"log_group_name\": \"${CLOUDWATCH_LOG_GROUP_NAME}\",
                                                \"log_stream_name\": \"{instance_id}\",
                                                \"timestamp_format\": \"%b %d, %Y %I:%M:%S %p %Z\",
                                                \"multi_line_start_pattern\": \"{datetime_format}\"
                                        }
                                ]
                        }
                }
        },
        \"metrics\": {
                \"metrics_collected\": {
                        \"collectd\": {
                                \"metrics_aggregation_interval\": 60,
                                \"service_address\": \"udp://127.0.0.1:25826\",
                                \"collectd_security_level\": \"none\"
                        },
                        \"disk\": {
                                \"measurement\": [
                                        \"used_percent\"
                                ],
                                \"metrics_collection_interval\": 30,
                                \"resources\": [
                                        \"*\"
                                ]
                        },
                        \"mem\": {
                                \"measurement\": [
                                        \"mem_used_percent\"
                                ],
                                \"metrics_collection_interval\": 30
                        }
                }
        }
}" | tee $AWS_CLOUDWATCH_AGENT_HOME/amazon-cloudwatch-agent.json 

$AWS_CLOUDWATCH_AGENT_HOME/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:$AWS_CLOUDWATCH_AGENT_HOME/amazon-cloudwatch-agent.json


echo "Setting up systemd for collectd and amazon-cloudwatch-agent"
systemctl enable collectd
systemctl stop collectd
systemctl start collectd
systemctl enable amazon-cloudwatch-agent
systemctl stop amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

echo "Installation complete!"
