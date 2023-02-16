# hashitalks-2023-boundary

Demo code for HashiTalks 2023 Boundary Presentation. I will update this `README.md` with a YouTube link of the presentation once it's available.

## Background

This demo is focused on standing up self-managed workers for HCP Boundary. It is not meant to be used with Boundary OSS. The self-managed workers are part of a virtual machine scale-set in Azure. The demo also stands up a virtual network and the other necessary infrastructure to run the demo. I may refactor the code into modules to make just the workers deployable beyond just the demo.

## Prerequisites

You will need the following:

* Azure Subscription and Owner access
* Terraform 1.3+
* Azure CLI for authentication in Terraform
* HCP Boundary cluster deployed
* Boundary CLI for authentication in Terraform

## Setup

For Azure access, you will need to run the Azure CLI:

```bash
az login
az account set -s "SUBSCRIPTION_NAME"
```

To set up Boundary access for the Boundary provider, you will need to set the BOUNDARY_ADDR and log in. When you deploy HCP Boundary, be sure to gather the username, password, and auth method ID for both the login process and Terraform variables. If the Boundary CLI cannot stash your token in a keyring, it will print it to the terminal and you'll need to put it into the environment variable `BOUNDARY_TOKEN`.

You can get authenticate to HCP Boundary with the following commands:

```bash
export BOUNDARY_ADDR="https://HCP_BOUNDARY_ADDR"

# Log into Boundary and get the token value
boundary authenticate password -auth-method-id=METHOD_ID -login-name=LOGIN_NAME

# Set the token value if it's not exported
export BOUNDARY_TOKEN="TOKEN_VALUE"
```

Next you should rename the `terraform.tfvars.example` file to `terraform.tfvars` and fill in the variables. The required variables are:

* `boundary_worker_user` - The username and password for the Boundary user that will be created for worker registration.
* `boundary_id` - The ID of the HCP Boundary cluster. You can get this from the HCP Boundary cluster URL.
* `boundary_password_auth_method_id` - This is the ID of the Global scope password auth method. It should be the same auth ID you used to log in to HCP Boundary.
* `vmss_admin_username` - The username for the VMSS admin user. An SSH key will be generated automatically.
* `vmss_source_image` - The example file uses Ubuntu 20.04 LTS. You can use any image that is available in your Azure subscription, but you may need to tweak the setup script to work with the image.
* `boundary_worker_tags` - This is a list of tags to apply to the Boundary worker. This helps Boundary decide which workers are eligible for a particular host.

## Running the Demo

Once your setup is done, simply run the standard Terraform commands:

```bash
terraform init
terraform apply
```

After the demo is finished deploying, you will see new workers appear in your HCP Boundary cluster. You can also see the workers as VMSS instances in the Azure portal.

## Resources

The demo deploys the following resources:

**Azure**

* Resource group for all resources
* Virtual Network with two subnets
* Virtual Machine Scale Set using the first subnet
* Network security group for the VMSS allowing port 9202 inbound
* User Managed Identity for the VMSS
* Azure Key Vault for storing the Boundary information
* Azure Key Vault Secrets for the Boundary information
* Autoscale settings for the VMSS based on Daily schedule

**Boundary**

* Role with a grant to allow worker creation, listing, and deletion
* User with the role assignd
* Account in the password auth method for the user

**Other**

* TLS key pair for VMSS
* TLS private key written to file in the module directory

## Cleanup

You can cleanup all the resources with the following command:

```bash
terraform destroy
```

And then you can delete the Boundary cluster from HCP.

## What's Next

I'd like to refactor the code into modules and make it more generic. I'd also like to make the autoscale policy more flexible, although that's challenging since there are so many possible options.

I'm also planning on implementing the `deregister.sh` script into the VMSS setup to enable automatic worker deregistration.

Thanks for trying out the code and please log an issue or hit me up on Twitter/LinkedIn if you have any questions or suggestions.
