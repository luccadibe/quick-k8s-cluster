# GCP Kubernetes Cluster with kOps

This repository contains scripts and configurations to set up a Kubernetes cluster on Google Cloud Platform (GCP) using kOps (Kubernetes Operations).

## Prerequisites

Before you begin, ensure you have the following installed:
- [Terraform](https://www.terraform.io/downloads.html) (v1.9.0+)
- [kOps](https://kops.sigs.k8s.io/getting_started/install/) (v1.31.0+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

## Project Structure
```
.
├── main.tf                 # Terraform configuration for GCS bucket
├── cluster-config.yaml     # kOps cluster configuration
├── setup.sh               # Script to enable required GCP APIs
├── up-cluster.sh         # Script to create the cluster
└── down-cluster.sh       # Script to tear down the cluster
```

## Setup Instructions

1. **Initialize GCP Project**
   ```bash
   # Enable required GCP APIs
   ./setup.sh
   ```

2. **Configure GCP Authentication**
   ```bash
   gcloud auth application-default login
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

## Available Scripts

### `setup.sh`
Enables the required Google Cloud APIs for the project:
- Cloud Resource Manager API
- Compute Engine API
- Identity and Access Management (IAM) API
- Kubernetes Engine API
- Cloud Storage API

### `up-cluster.sh`
Creates the Kubernetes cluster with the following steps:
1. Creates a GCS bucket for kOps state storage
2. Generates cluster configuration
3. Configures instance groups with spot instances
4. Creates and validates the cluster

Usage:
```bash
./up-cluster.sh <project-id>
```

### `down-cluster.sh`
Tears down the cluster and cleans up resources:
1. Deletes the Kubernetes cluster
2. Removes the GCS bucket

Usage:
```bash
./down-cluster.sh
```

## Cluster Configuration

The cluster is configured with:
- Region: europe-west1-b
- Control plane: 1 node (e2-standard-2)
- Worker nodes: 3 nodes (e2-standard-2)
- Networking: Cilium
- Instance type: Spot instances for cost optimization

## Working with Your Cluster

After the cluster is created, you can interact with it using `kubectl`. The `up-cluster.sh` script automatically configures your kubeconfig.

## Cleanup

To delete the cluster and clean up all resources:
```bash
./down-cluster.sh
```

## Important Notes

- The cluster uses spot instances to optimize costs
- The GCS bucket has a 2-day retention policy
- All nodes are in a single zone for simplicity
- The cluster uses Cilium for networking

