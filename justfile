# Required environment variables (set these before running commands)
export TF_VAR_project_id := ""       # Your GCP project ID
export CLUSTER_NAME := ""            # Your cluster name
export TF_VAR_zone := ""             # GCP zone for the cluster
export NODE_COUNT := ""              # Number of worker nodes
export CONTROL_PLANE_SIZE := ""      # Machine type for control plane
export NODE_SIZE := ""               # Machine type for worker nodes
export TF_VAR_bucket_name := ""      # Must be globally unique
export TF_VAR_bucket_location := ""  # GCS bucket location

# Required environment variables check
_check-env:
    #!/usr/bin/env bash
    missing_vars=()
    [[ -z "${TF_VAR_project_id}" ]] && missing_vars+=("TF_VAR_project_id")
    [[ -z "${CLUSTER_NAME}" ]] && missing_vars+=("CLUSTER_NAME")
    [[ -z "${TF_VAR_zone}" ]] && missing_vars+=("TF_VAR_zone")
    [[ -z "${NODE_COUNT}" ]] && missing_vars+=("NODE_COUNT")
    [[ -z "${CONTROL_PLANE_SIZE}" ]] && missing_vars+=("CONTROL_PLANE_SIZE")
    [[ -z "${NODE_SIZE}" ]] && missing_vars+=("NODE_SIZE")
    [[ -z "${TF_VAR_bucket_name}" ]] && missing_vars+=("TF_VAR_bucket_name")
    [[ -z "${TF_VAR_bucket_location}" ]] && missing_vars+=("TF_VAR_bucket_location")
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "Error: Missing required environment variables:"
        printf '%s\n' "${missing_vars[@]}"
        echo "Please set the required variables at the top of the justfile"
        exit 1
    fi

# List available recipes
default:
    @just --list

# Setup required GCP APIs
setup: _check-env
    #!/bin/bash
    gcloud services enable cloudresourcemanager.googleapis.com
    gcloud services enable compute.googleapis.com
    gcloud services enable iam.googleapis.com
    gcloud services enable container.googleapis.com
    gcloud services enable storage.googleapis.com

# Initialize terraform
init: _check-env
    terraform init

# Create and configure the cluster
up spot="": _check-env
    #!/bin/bash
    set -e
    
    # Create GCS bucket
    terraform apply -auto-approve

    # Set kOps state store
    export KOPS_STATE_STORE="gs://$(terraform output -raw kops_state_store_bucket_name)"

    # Create cluster configuration
    echo "Creating cluster configuration..."
    kops create cluster \
        --name="${CLUSTER_NAME}" \
        --state="${KOPS_STATE_STORE}" \
        --zones="${TF_VAR_zone}" \
        --control-plane-zones="${TF_VAR_zone}" \
        --node-count="${NODE_COUNT}" \
        --control-plane-size="${CONTROL_PLANE_SIZE}" \
        --node-size="${NODE_SIZE}" \
        --control-plane-count=1 \
        --networking=cilium \
        --cloud=gce \
        --project="${TF_VAR_project_id}"

    if [ -n "$spot" ]; then
        # Configure spot instances
        echo "Modifying instance groups to use spot instances..."
        kops get ig --name "${CLUSTER_NAME}" -o yaml > ig_specs.yaml
        sed -i '/spec:/a\  gcpProvisioningModel: SPOT' ig_specs.yaml
        kops replace -f ig_specs.yaml
    fi

    # Create and validate cluster
    echo "Creating the cluster..."
    kops update cluster --name="${CLUSTER_NAME}" --yes
    kops export kubeconfig --admin
    
    echo "Waiting for cluster to be ready..."
    kops validate cluster --wait 10m

# Destroy the cluster and clean up resources
down: _check-env
    #!/bin/bash
    set -e
    export KOPS_STATE_STORE="gs://$(terraform output -raw kops_state_store_bucket_name)"
    kops delete cluster --name "${CLUSTER_NAME}" --yes
    terraform destroy -auto-approve

# Validate cluster status
validate: _check-env
    export KOPS_STATE_STORE="gs://$(terraform output -raw kops_state_store_bucket_name)" && \
    kops validate cluster

# Get cluster info
get-cluster: _check-env
    export KOPS_STATE_STORE="gs://$(terraform output -raw kops_state_store_bucket_name)" && \
    kops get cluster

# Export kubeconfig
get-kubeconfig: _check-env
    export KOPS_STATE_STORE="gs://$(terraform output -raw kops_state_store_bucket_name)" && \
    kops export kubeconfig --admin
