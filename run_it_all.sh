#! /usr/bin/bash

terraform apply
terraform output | grep agent-ip | sed -e 's/agent-ip = //' | tr ',' '\n' > agent-list
terraform output | grep master-ip | sed -e 's/master-ip = //' | tr ',' '\n' > master-list
terraform output | grep bootstrap-ip | sed -e 's/bootstrap-ip = //' > bootstrap-ip
bash bootstrap.sh
pssh -h master-list -iv -X "-o StrictHostKeyChecking=no" -X "-o UserKnownHostsFile=/dev/null" -X "-o GlobalKnownHostsFile=/dev/null" -X -T -I -t 0 -l core < masters.sh 
pssh -h agent-list -iv -X "-o StrictHostKeyChecking=no" -X "-o UserKnownHostsFile=/dev/null" -X "-o GlobalKnownHostsFile=/dev/null" -X -T -I -t 0 -l core < agents.sh 