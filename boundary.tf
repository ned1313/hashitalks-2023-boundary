provider "boundary" {
  addr = "" # This is a weird quirk of the provider and may be fixed in the future
}

# Create an account in the password auth method
resource "boundary_account_password" "main" {
  auth_method_id = var.boundary_password_auth_method_id
  type           = "password"
  login_name     = var.boundary_worker_user.username
  password       = var.boundary_worker_user.password
}

# Create a user for worker vms
resource "boundary_user" "main" {
  description = "Boundary Worker Creation User"
  name        = "boundary-worker-creation-user"
  scope_id    = "global"
  account_ids = [boundary_account_password.main.id]
}

# Create a role for worker vms
resource "boundary_role" "main" {
  description   = "Boundary Worker Creation Role"
  name          = "boundary-worker-creation-role"
  grant_strings = ["id=*;type=worker;actions=create:worker-led,list,delete"]
  principal_ids = [boundary_user.main.id]
  scope_id      = "global"
}

