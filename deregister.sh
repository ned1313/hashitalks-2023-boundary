#!/bin/bash

# Get the VM ID from the Azure Metadata Service
vm_id=$(curl -s -H Metadata:True --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01&format=json" | jq .compute.name -r)
# Check to see if the VM is being Terminated
result=$(curl -s --noproxy "*" 'http://169.254.169.254/metadata/scheduledevents?api-version=2019-01-01' -H Metadata:true | jq --arg vmid $vm_id -r '.Events[] | select(.EventType == "Terminate") | select(.Resources[] | contains($vmid)) | .EventId')

# If the VM is being deprovisioned, then stop the boundary-worker service
if [ $result != null ]
then
    sudo systemctl stop boundary-worker
    access_token=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | jq .access_token -r)
    boundary_id=$(curl -s "${key_vault_url}/secrets/boundary-cluster-id?api-version=2016-10-01" -H "Authorization: Bearer $access_token" | jq .value -r)
    boundary_username=$(curl -s "${key_vault_url}/secrets/boundary-cluster-username?api-version=2016-10-01" -H "Authorization: Bearer $access_token" | jq .value -r)
    boundary_password=$(curl -s "${key_vault_url}/secrets/boundary-cluster-password?api-version=2016-10-01" -H "Authorization: Bearer $access_token" | jq .value -r)
    boundary_auth_method_id=$(curl -s "${key_vault_url}/secrets/boundary-cluster-auth-method-id?api-version=2016-10-01" -H "Authorization: Bearer $access_token" | jq .value -r)

    export BOUNDARY_ADDR="https://$boundary_id.boundary.hashicorp.cloud"
    export BOUNDARY_PASSWORD=$boundary_password

    export BOUNDARY_TOKEN=$(boundary-worker authenticate password -keyring-type=none -auth-method-id=$boundary_auth_method_id -login-name=$boundary_username -password=env://BOUNDARY_PASSWORD -format=json | jq .item.attributes.token -r)
    worker_id=$(sudo cat /etc/boundary.d/worker/worker_id)
    boundary-worker workers delete -id=$worker_id -token env://BOUNDARY_TOKEN

    # Signal to Azure that the VM is ready to be deprovisioned
    curl -H Metadata:true -X POST -d '{"StartRequests": [{"EventId": "'$result'"}]}' http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01
fi