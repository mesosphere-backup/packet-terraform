provider "packet" {
  auth_token = "${var.packet_api_key}"
}

resource "packet_device" "dcos_bootstrap" {
  hostname = "${format("mesos-bootstrap-%02d", count.index + 1)}"

  operating_system = "coreos_stable"
  plan             = "${var.packet_boot_type}"

  user_data     = "#!/bin/bash\nwget -P /tmp http://downloads.mesosphere.com/dcos/testing/continuous/dcos_generate_config.sh"
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"
}

resource "packet_device" "dcos_master" {
  hostname = "${format("mesos-master-%02d", count.index + 1)}"
  operating_system = "coreos_stable"
  plan             = "${var.packet_master_type}"

  count         = "${var.dcos_master_count}"
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${var.dcos_init_pubkey}\"\n"
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"
}

resource "packet_device" "dcos_agent" {
  hostname = "${format("mesos-agent-%02d", count.index + 1)}"
  operating_system = "coreos_stable"
  plan             = "${var.packet_agent_type}"

  count         = "${var.dcos_agent_count}"
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${var.dcos_init_pubkey}\"\n"
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"  
}
