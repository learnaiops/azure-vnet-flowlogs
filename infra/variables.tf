variable "vm_admin_password" {
  description = "Admin password for the test VMs"
  type        = string
  sensitive   = true
}

variable "allowed_ip_address" {
  description = "Public IP address allowed to access storage accounts and VMs via RDP"
  type        = string
}
