# ArgoCD Image Updater Setup

This document explains how to set up and use ArgoCD Image Updater with Azure Container Registry (ACR) for automatic image updates in your Kubernetes deployments.

## Overview

ArgoCD Image Updater watches your container registries for new image versions and automatically updates your Kubernetes deployments when new versions are detected. This completes the GitOps workflow by handling image updates without modifying Git repositories.

## Prerequisites

- Kubernetes cluster (microk8s) with ArgoCD installed
- Existing `acr-pull-secret` in the `semanix` namespace with ACR credentials
- kubectl configured to access your cluster
- argocd CLI tool installed

## Installation

### 1. SSH into Your VM

First, log into the VM that hosts your microk8s Kubernetes cluster:

```bash
ssh user@your-vm-ip
```

### 2. Generate an ArgoCD API Token

Generate an API token for the ArgoCD Image Updater to use:

```bash
argocd login <your-argocd-server>
ARGOCD_AUTH_TOKEN=$(argocd account generate-token)
echo $ARGOCD_AUTH_TOKEN  # Save this for the next step
```

### 3. Set Environment Variables

```bash
export AZURE_REGISTRY_NAME=your-acr-name
export ARGOCD_AUTH_TOKEN=token-from-previous-step
```

### 4. Verify the ACR Pull Secret

The Image Updater is configured to use your existing `acr-pull-secret` in the `semanix` namespace. Make sure it exists:

```bash
kubectl get secret acr-pull-secret -n semanix
```

If it doesn't exist or you need to create it:

```bash
kubectl create secret docker-registry acr-pull-secret \
  --docker-server=${AZURE_REGISTRY_NAME}.azurecr.io \
  --docker-username=<your-acr-username> \
  --docker-password=<your-acr-password> \
  -n semanix
```

### 5. Run the Setup Script

Clone the deployment repository to your VM (if not already there) and run the setup script:

```bash
# Clone the repo if needed
git clone https://github.com/YOUR_ORG/semanix-deployment.git
cd semanix-deployment

# Run the setup script
chmod +x scripts/setup-argocd-image-updater.sh
./scripts/setup-argocd-image-updater.sh
```

## Configuration

### Application Annotations

ArgoCD applications need annotations to tell the Image Updater which images to watch. These are already configured in our ArgoCD application manifests:

```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: myimage=registry.example.com/myimage
    argocd-image-updater.argoproj.io/myimage.update-strategy: digest
    argocd-image-updater.argoproj.io/myimage.allow-tags: regexp:^[a-f0-9]{7}$
```

### Annotation Explanation

- `image-list`: Defines which image to watch. The format is `<image-name>=<registry-path>`
- `update-strategy`: How to determine if an image is newer (semver, digest, or name)
- `allow-tags`: Filter which tags to consider

## Usage

Once installed, ArgoCD Image Updater requires no manual intervention. It will:

1. Scan your ArgoCD applications for Image Updater annotations
2. Check the configured registries for newer versions of images
3. Update the Kubernetes deployments directly with the new image versions

## Verification

Check the logs to ensure it's working:

```bash
kubectl -n argocd logs -f deployment/argocd-image-updater
```

You should see log entries showing the Image Updater scanning your applications and checking for updates.

## Troubleshooting

### Common Issues

1. **Authentication Failures**:
   - Check if the `acr-pull-secret` in the `semanix` namespace has valid credentials
   - Verify Image Updater has permissions to access the secret
   - If using microk8s, make sure the registry is accessible from the cluster

2. **Image Not Updating**:
   - Ensure annotations are correctly configured
   - Check if the image tag pattern matches your CI pipeline tags
   - Verify the Image Updater can access your registry

3. **Permissions Issues**:
   - Check if the service account has sufficient permissions
   - Verify the ArgoCD token is valid

For more detailed troubleshooting, check the [official documentation](https://argocd-image-updater.readthedocs.io/en/stable/). 