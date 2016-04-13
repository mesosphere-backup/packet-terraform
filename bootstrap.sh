#! /usr/bin/bash

terraform apply
terraform output master-ip | tr ',' '\n' > master-list
terraform output agent-ip | tr ',' '\n' > agent-list
terraform output agent-public-ip | tr ',' '\n' > public-agent-list

BOOTSTRAP_IP=$(terraform output bootstrap-ip)
MASTER_1=$(awk 'NR==1' master-list | tr ',' '\n')
MASTER_2=$(awk 'NR==2' master-list | tr ',' '\n')
MASTER_3=$(awk 'NR==3' master-list | tr ',' '\n')

# Make some config files
cat > config.yaml << FIN
bootstrap_url: http://$BOOTSTRAP_IP:4040
cluster_name: packet-dcos
exhibitor_storage_backend: zookeeper
exhibitor_zk_hosts: $BOOTSTRAP_IP:2181
exhibitor_zk_path: /zk-example
log_directory: /genconf/logs
master_discovery: static
master_list:
- $MASTER_1
- $MASTER_2
- $MASTER_3
resolvers: 
- 8.8.4.4
- 8.8.8.8
FIN

cat > ip-detect << FIN
#!/usr/bin/env bash
set -o nounset -o errexit
export PATH=/usr/sbin:/usr/bin:\$PATH
echo \$(ip addr show bond0 | grep -Eo '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}' | head -1)
FIN

# Make a script

cat > master.sh << FIN
#! /usr/bin/bash
mkdir /tmp/dcos && cd /tmp/dcos           
curl -O http://$BOOTSTRAP_IP:4040/dcos_install.sh
sudo bash dcos_install.sh master
FIN

cat > agent.sh << FIN
#! /usr/bin/bash
mkdir /tmp/dcos && cd /tmp/dcos           
curl -O http://$BOOTSTRAP_IP:4040/dcos_install.sh
sudo bash dcos_install.sh slave
FIN

cat > public-agent.sh << FIN
#! /usr/bin/bash
mkdir /tmp/dcos && cd /tmp/dcos           
curl -O http://$BOOTSTRAP_IP:4040/dcos_install.sh
sudo bash dcos_install.sh slave_public
FIN

# Prep and create the installer
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null core@$BOOTSTRAP_IP "wget -q -P /tmp https://s3.amazonaws.com/downloads.mesosphere.io/dcos/testing/CM.7/dcos_generate_config.sh && mkdir /tmp/genconf"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null ip-detect core@$BOOTSTRAP_IP:/tmp/genconf/ip-detect
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null config.yaml core@$BOOTSTRAP_IP:/tmp/genconf/config.yaml
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null core@$BOOTSTRAP_IP "cd /tmp/ && bash dcos_generate_config.sh"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null core@$BOOTSTRAP_IP "docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 --name=dcos_int_zk jplock/zookeeper &> /dev/null"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null core@$BOOTSTRAP_IP "docker run -d -p 4040:80 -v /tmp/genconf/serve:/usr/share/nginx/html:ro nginx &> /dev/null"
# Distribute the installer
pssh -h master-list -e error-logs -o output-logs -p 100 -X "-o StrictHostKeyChecking=no" -X "-o UserKnownHostsFile=/dev/null" -X "-o GlobalKnownHostsFile=/dev/null" -X -T -I -t 100 -l core < master.sh 
pssh -h agent-list -e error-logs -o output-logs -p 100 -X "-o StrictHostKeyChecking=no" -X "-o UserKnownHostsFile=/dev/null" -X "-o GlobalKnownHostsFile=/dev/null" -X -T -I -t 100 -l core < agent.sh
pssh -h public-agent-list -e error-logs -o output-logs -p 100 -X "-o StrictHostKeyChecking=no" -X "-o UserKnownHostsFile=/dev/null" -X "-o GlobalKnownHostsFile=/dev/null" -X -T -I -t 100 -l core < public-agent.sh
