variable "naming_prefix" {
  type        = string
  description = "(Optional) The prefix to use for all resources in this example. Defaults to hcp."
  default     = "hcp"
}

variable "location" {
  type        = string
  description = "(Optional) Azure location for resources. Defaults to West US."
  default     = "westus"
}

variable "address_space" {
  type        = list(string)
  description = "(Optional) The address space that is used by the virtual network. Defaults to [10.0.0.0/16]"
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  type        = list(string)
  description = "(Optional) List of address prefixes to use for the subnets. Defaults to two subnets."
  default = [
    "10.0.0.0/24",
    "10.0.1.0/24",
  ]
}

variable "subnet_names" {
  type        = list(string)
  description = "(Optional) List of subnet names. Defaults to two subnets: workers and clients."
  default = [
    "workers",
    "clients",
  ]
}

variable "worker_vm_size" {
  type        = string
  description = "(Optional) The size of the VMs to create. Defaults to Standard_D2s_v3."
  default     = "Standard_D2s_v3"
}

variable "worker_vm_count" {
  type        = number
  description = "(Optional) The number of worker VMs to create. Defaults to 1."
  default     = 1
}

variable "boundary_worker_user" {
  type = object({
    username = string
    password = string
  })
  description = "(Required) The username and password for the Boundary user that can register workers."
  sensitive   = true
}

variable "boundary_id" {
  type        = string
  description = "(Required) The ID of the HCP Boundary instance."
}

variable "boundary_password_auth_method_id" {
  type        = string
  description = "(Required) The ID of the HCP Boundary password auth method."
}

variable "vmss_admin_username" {
  type        = string
  description = "(Required) The admin username of the VMSS"
}

variable "vmss_source_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Values for the source image of the VMSS"
}

variable "vmss_os_disk_storage_account_type" {
  type        = string
  description = "The storage account type of the VMSS OS disk"
  default     = "StandardSSD_LRS"
}

variable "vmss_os_disk_caching" {
  type        = string
  description = "The caching type of the VMSS OS disk"
  default     = "ReadWrite"
}

variable "vmss_zones" {
  type        = list(string)
  description = "The zones of the VMSS"
  default     = null
}

variable "vmss_range" {
  type = object({
    min = number
    max = number
  })
  description = "(Optional) The range of the VMSS Instances. Defaults to 1-4."
  default = {
    min = 1
    max = 4
  }
}

variable "vmss_working_hours_utc" {
  type = object({
    start = number
    end   = number
  })
  description = "(Optional) The working hours of the VMSS in UTC. Defaults to 9am-6pm EST."
  default = {
    start = 4
    end   = 13
  }
}