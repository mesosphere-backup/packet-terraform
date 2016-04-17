provider "packet" {
  auth_token = "${var.packet_api_key}"
}

resource "packet_device" "dcos_bootstrap" {
  hostname = "${format("mesos-bootstrap-%02d", count.index)}"

  operating_system = "coreos_stable"
  plan             = "${var.packet_boot_type}"

  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.dcos_init_pubkey}")}\"\n"
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"
  provisioner "remote-exec" {
  inline = [
    "wget -q -O dcos_generate_config.sh -P $HOME ${var.dcos_installer_url}",
    "mkdir $HOME/genconf"
    ]
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
  provisioner "local-exec" {
    command = "echo BOOTSTRAP=\"${packet_device.dcos_bootstrap.network.0.address}\" >> ips.txt"
  }
  provisioner "local-exec" {
    command = "echo CLUSTER_NAME=\"${var.dcos_cluster_name}\" >> ips.txt"
  }  
  provisioner "local-exec" {
    command = "./make-files.sh"
  }
  provisioner "file" {
    source = "./ip-detect"
    destination = "$HOME/genconf/ip-detect"
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
  provisioner "file" {
    source = "./config.yaml"
    destination = "$HOME/genconf/config.yaml"
      connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
  provisioner "remote-exec" {
    inline = ["sudo bash $HOME/dcos_generate_config.sh",
              "docker run -d -p 4040:80 -v $HOME/genconf/serve:/usr/share/nginx/html:ro nginx 2>/dev/null",
              "docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 --name=dcos_int_zk jplock/zookeeper 2>/dev/null"
              ]
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
}

resource "packet_device" "dcos_master" {
  hostname = "${format("mesos-master-%02d", count.index)}"
  operating_system = "coreos_stable"
  plan             = "${var.packet_master_type}"

  count         = "${var.dcos_master_count}"
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.dcos_init_pubkey}")}\"\n"
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"
  provisioner "local-exec" {
    command = "echo ${format("MASTER_%02d", count.index)}=\"${self.network.0.address}\" >> ips.txt"
  }
  provisioner "local-exec" {
    command = "sleep ${var.bootstrap_timeout}"
  }
  provisioner "file" {
    source = "./do-install.sh"
    destination = "/tmp/do-install.sh"
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
  provisioner "remote-exec" {
    inline = "bash /tmp/do-install.sh master"
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
}

resource "packet_device" "dcos_agent" {
  hostname = "${format("mesos-agent-%02d", count.index)}"
  depends_on = ["packet_device.dcos_bootstrap"]
  operating_system = "coreos_stable"
  plan             = "${var.packet_agent_type}"

  count         = "${var.dcos_agent_count}"
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.dcos_init_pubkey}")}\"\n"
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"  
  provisioner "file" {
    source = "do-install.sh"
    destination = "/tmp/do-install.sh"
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
  provisioner "remote-exec" {
    inline = "bash /tmp/do-install.sh slave"
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
}


resource "packet_device" "dcos_public_agent" {
  hostname = "${format("mesos-public-agent-%02d", count.index)}"
  depends_on = ["packet_device.dcos_bootstrap"]
  operating_system = "coreos_stable"
  plan             = "${var.packet_agent_type}"

  count         = "${var.dcos_public_agent_count}"
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.dcos_init_pubkey}")}\"\n"
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"  
  provisioner "file" {
    source = "do-install.sh"
    destination = "/tmp/do-install.sh"
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }  
  provisioner "remote-exec" {
    inline = "bash /tmp/do-install.sh slave_public"
    connection {
      user = "${var.dcos_user}"
      private_key = "${var.key_file_path}"
    }
  }
}
