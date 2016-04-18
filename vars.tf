
variable "packet_api_key" {
  description = "Your packet API key"
}

variable "packet_project_id" {
  description = "Packet Project ID"
}

variable "packet_facility" {
  description = "Packet facility: US East(ewr1), US West(sjc1), or EU(ams1). Default: sjc1"
  default = "sjc1"
}

variable "packet_agent_type" {
  description = "Instance type of Agent"
  defaut = "baremetal_0"
}

variable "packet_master_type" {
  description = "Instance type of Master"
  default = "baremetal_0"
}

variable "packet_boot_type" {
  description = "Instance type of bootstrap unit"
  default = "baremetal_0"
}

variable "dcos_cluster_name" {
  description = "Name of your cluster. Alpha-numeric and hyphens only, please."
  default = "packet-dcos"
} 

variable "dcos_master_count" {
  default = "3"
  description = "Number of master nodes. 1, 3, or 5."
}

variable "dcos_agent_count" {
  description = "Number of agents to deploy"
  default = "4"
}

variable "dcos_public_agent_count" {
  description = "Number of public agents to deploy"
  default = "1"
}

variable "dcos_init_pubkey" {
  description = "Path to your public SSH key path"
  default = "./packet-key.pub"
}

variable "dcos_installer_url" {
  description = "Path to get DCOS"
  default = "https://downloads.dcos.io/dcos/EarlyAccess/dcos_generate_config.sh"
} 

variable "key_file_path" {
  description = "Path to your private SSH key for the project"
  default = "./packet-key"
}

variable "dcos_user" {
  description = "Username for SSH connections"
  default = "core"
}
