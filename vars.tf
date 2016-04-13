
variable "packet_api_key" {
  description = "Your packet API key"
}

variable "packet_project_id" {
  description = "Packet Project ID"
}

variable "packet_facility" {
  description = "Packet facility: [ewr1|sjc1|ams1]"
}

variable "packet_agent_type" {
  description = "Type of Agent"
}

variable "packet_master_type" {
  description = "Type of Master"
}

variable "packet_boot_type" {
  default = "baremetal_0"
}

variable "dcos_master_count" {
  default = 3
}

variable "dcos_agent_count" {
  description = "Number of agents to deploy"
}

variable "dcos_public_agent_count" {
  description = "Number of agents to deploy"
}

variable "dcos_init_pubkey" {
  description = "Your public SSH key"
}
