#!/usr/bin/env bash

# Make some config files
cat > config.yaml << FIN
bootstrap_url: http://${packet_device.dcos_bootstrap.network.0.address}:4040
cluster_name: ${dcos_cluster_name}
exhibitor_storage_backend: zookeeper
exhibitor_zk_hosts: ${packet_device.dcos_bootstrap.network.0.address}:2181
exhibitor_zk_path: /${dcos_cluster_name}
log_directory: /genconf/logs
master_discovery: static
master_list:
- ${packet_device.dcos_master.0.network.0.address}
- ${packet_device.dcos_master.1.network.0.address}
- ${packet_device.dcos_master.2.network.0.address}
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

cat > do-install.sh << FIN
#!/usr/bin/env bash
mkdir /tmp/dcos && cd /tmp/dcos           
curl -O http://{packet_device.dcos_bootstrap.network.0.address}:4040/dcos_install.sh
sudo bash dcos_install.sh $1
FIN