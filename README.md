# Semanix Deployment Repository

This repository contains Kubernetes deployment manifests, Helm charts, and ArgoCD application configurations for all Semanix microservices.

## Repository Structure

```
.
├── helm/                  # Helm charts for all microservices
│   └── charts/            # Individual charts per microservice
│       ├── accessmanagement/
│       └── requestmanagement/
├── k8s/                   # Kubernetes manifests
│   ├── argocd/            # ArgoCD application manifests
│   ├── base/              # Base Kustomize configurations
│   └── overlays/          # Environment-specific overlays
├── dapr/                  # Dapr component configurations
├── docs/                  # Documentation
├── scripts/               # Utility scripts
└── .github/
    └── workflows/         # CI/CD workflows for chart validation
```

## GitOps Workflow

This repository follows GitOps principles:

1. All infrastructure changes are made through pull requests
2. ArgoCD watches this repository for changes
3. ArgoCD Image Updater watches the container registry for new image tags

## Setup Instructions

### ArgoCD Image Updater

To set up ArgoCD Image Updater for automatic container image updates:

1. See detailed instructions in [ArgoCD Image Updater Setup](docs/argocd-image-updater.md)
2. SSH into your VM that hosts the microk8s cluster
3. Ensure your `acr-pull-secret` exists in the `semanix` namespace
4. Run the setup script:
   ```bash
   export AZURE_REGISTRY_NAME=your-acr-name
   export ARGOCD_AUTH_TOKEN=$(argocd account generate-token)
   
   ./scripts/setup-argocd-image-updater.sh
   ```

## Adding a New Microservice

To add a new microservice:

1. Create a new Helm chart in `helm/charts/[service-name]/`
2. Create an ArgoCD application manifest in `k8s/argocd/[service-name]-app.yaml`
3. Configure ArgoCD Image Updater annotations in the application manifest

## Helm Chart Best Practices

All charts should follow these conventions:

- Use named templates in `_helpers.tpl`
- Define proper resource limits and requests
- Configure health probes
- Set appropriate security contexts
- Use ConfigMaps for configuration
- Reference secrets via external secret stores

## ArgoCD Setup

ArgoCD is configured to:

1. Watch this repository for changes to manifests
2. Auto-sync applications when changes are detected
3. Prune resources that are no longer defined
4. Self-heal drift

ArgoCD Image Updater is configured to:

1. Watch the Azure Container Registry for new image tags  
2. Update the Kubernetes deployments directly with new image tags
3. Follow tag pattern restrictions defined in annotations

## CI/CD Pipeline

The GitHub Actions workflow:

1. Lints all Helm charts on changes
2. Triggers ArgoCD sync for impacted applications

## Security Considerations

- Images are scanned for vulnerabilities before deployment
- All deployments use non-root users
- Network policies restrict communication between services
- Secrets are managed via external stores
- RBAC is properly configured for service accounts 