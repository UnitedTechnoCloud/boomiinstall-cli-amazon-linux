#!/bin/bash

export DD_AGENT_MAJOR_VERSION=${DatadogAgentMajorVersion}
export DD_API_KEY=${DataDogAPIKey}
export DD_SITE="datadoghq.com"
#bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"
bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"

. /home/boomi/.profile
cat <<EOF >> /etc/datadog-agent/datadog.yaml
tags:
 - client:${client}
 - group:${group}
 - environment:${environment}
 - pod_name:${ATOM_LOCALHOSTID}
 - container_name:${BOOMI_CONTAINERNAME}
EOF

cat <<EOF > /etc/datadog-agent/conf.d/process.d/conf.yaml

init_config:

instances:
- name: ${BOOMI_CONTAINERNAME}
  search_string: ['com.boomi.container.core.Container']
  exact_match: False
EOF

chown dd-agent:dd-agent /etc/datadog-agent/conf.d/process.d/conf.yaml

cat <<EOF > /etc/datadog-agent/conf.d/jmx.d/conf.yaml

init_config:
  is_jmx: true
  collect_default_metrics: true
  java_bin_path: /usr/bin/java
  conf:
    - include:
        domain: com.boomi.container.services
        type:
          - ExecutionManager
          - MessageQueue
          - ResourceManager
          - Scheduler
    - include:
        domain: java.lang
        attribute:
          - SystemLoadAverage
instances:
  - host: 127.0.0.1
    port: 5003
    name: ${BOOMI_CONTAINERNAME}
EOF

chown dd-agent:dd-agent /etc/datadog-agent/conf.d/jmx.d/conf.yaml

echo "restart datadog service after applying config changes..."
sudo systemctl restart datadog-agent.service 

echo "datadog install complete.."

if [ -n ${platform} ] ; then
  touch /etc/datadog_installer
  echo "datadog_installer flag created"
fi
