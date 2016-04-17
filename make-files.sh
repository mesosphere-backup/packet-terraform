#!/usr/bin/env bash
. ./ips.txt
# Make some config files
cat > config.yaml << FIN
bootstrap_url: http://$BOOTSTRAP:4040
cluster_name: $CLUSTER_NAME
exhibitor_storage_backend: zookeeper
exhibitor_zk_hosts: $BOOTSTRAP:2181
exhibitor_zk_path: /$CLUSTER_NAME
log_directory: /genconf/logs
master_discovery: static
master_list:
- $MASTER_00
- $MASTER_01
- $MASTER_02
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
curl -O http://$BOOTSTRAP:4040/dcos_install.sh
sudo bash dcos_install.sh \$1
FIN
rm -rf ./ips.txt