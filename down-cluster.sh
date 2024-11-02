#!/bin/bash

set -e

# Set environment variable for kOps state store
export KOPS_STATE_STORE="gs://$(terraform output -raw kops_state_store_bucket_name)"

# Delete the cluster using kOps
kops delete cluster --name oxn.dev.com --yes

# Terraform destroy to remove GCS bucket
terraform destroy -auto-approve

