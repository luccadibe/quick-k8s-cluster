#!/bin/bash


# Enable Cloud Resource Manager API
gcloud services enable cloudresourcemanager.googleapis.com

# Enable other required APIs for Kubernetes and storage
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable storage.googleapis.com
