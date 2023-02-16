resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_user_assigned_identity" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  name = local.worker_user_id
}

resource "azurerm_network_security_group" "main" {
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  name                = "${var.naming_prefix}-vmss-nsg"
}

resource "azurerm_network_security_rule" "boundary_in" {
  name                        = "boundary-client-inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9202"
  source_address_prefix       = "*"
  destination_address_prefix  = var.subnet_prefixes[0]
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_linux_virtual_machine_scale_set" "main" {
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  name                            = "${var.naming_prefix}-vmss"
  sku                             = var.worker_vm_size
  instances                       = var.worker_vm_count
  admin_username                  = var.vmss_admin_username
  disable_password_authentication = true
  upgrade_mode                    = "Automatic"

  admin_ssh_key {
    username   = var.vmss_admin_username
    public_key = tls_private_key.main.public_key_openssh
  }

  source_image_reference {
    publisher = var.vmss_source_image.publisher
    offer     = var.vmss_source_image.offer
    sku       = var.vmss_source_image.sku
    version   = var.vmss_source_image.version
  }

  os_disk {
    storage_account_type = var.vmss_os_disk_storage_account_type
    caching              = var.vmss_os_disk_caching
  }

  zones = var.vmss_zones

  network_interface {
    name                      = "${var.naming_prefix}-vmss-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.main.id

    ip_configuration {
      name      = "${var.naming_prefix}-vmss-ip-config"
      primary   = true
      subnet_id = module.vnet.vnet_subnets[0]
      public_ip_address {
        name              = "${var.naming_prefix}-vmss-pip"
        domain_name_label = "${var.naming_prefix}${random_id.id.hex}"
      }
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.main.id
    ]
  }

  termination_notification {
    enabled = true
    timeout = "PT5M"
  }

  custom_data = base64encode(templatefile("${path.module}/boundary.tmpl", {
    key_vault_url = azurerm_key_vault.main.vault_uri
    boundary_tags = var.boundary_worker_tags
  }))

}

resource "local_file" "tls_private_key" {
  filename = "${path.module}/tls_private_key.pem"
  content  = tls_private_key.main.private_key_pem
}

# Schedule autoscaling
resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "DailyAutoScaleUp"
  enabled             = true
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = "AutoScaleUpEveryWeekDay"

    capacity {
      default = var.vmss_range.max
      minimum = var.vmss_range.min
      maximum = var.vmss_range.max
    }

    recurrence {
      days    = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      hours   = [var.vmss_working_hours_utc.start]
      minutes = [0]
    }
  }

  profile {
    name = "AutoScaleDownEveryWeekDay"

    capacity {
      default = var.vmss_range.min
      minimum = var.vmss_range.min
      maximum = var.vmss_range.max
    }

    recurrence {
      days    = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      hours   = [var.vmss_working_hours_utc.end]
      minutes = [0]
    }
  }
}