#!/bin/bash
# Script to set up ArgoCD Image Updater with appropriate credentials
# Run this script on the VM that has your microk8s cluster

# Ensure required variables are set
if [ -z "$AZURE_REGISTRY_NAME" ]; then
  echo "ERROR: Please set AZURE_REGISTRY_NAME environment variable"
  exit 1
fi

if [ -z "$ARGOCD_AUTH_TOKEN" ]; then
  echo "ERROR: Please set ARGOCD_AUTH_TOKEN environment variable"
  echo "You can get this by running: argocd account generate-token"
  exit 1
fi

# Verify the ACR pull secret exists
if ! kubectl get secret acr-pull-secret -n semanix &>/dev/null; then
  echo "WARNING: Secret acr-pull-secret not found in semanix namespace."
  echo "Make sure it exists and contains Docker credentials for ${AZURE_REGISTRY_NAME}.azurecr.io"
  echo "If needed, you can create it with:"
  echo "kubectl create secret docker-registry acr-pull-secret \\"
  echo "  --docker-server=\${AZURE_REGISTRY_NAME}.azurecr.io \\"
  echo "  --docker-username=<your-acr-username> \\"
  echo "  --docker-password=<your-acr-password> \\"
  echo "  -n semanix"
  read -p "Do you want to continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Generate the kubeconfig secret
echo "Creating ArgoCD Image Updater token secret..."
kubectl -n argocd create secret generic argocd-image-updater-secret \
  --from-literal=argocd.token="$ARGOCD_AUTH_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# Process the template and apply
echo "Applying ArgoCD Image Updater manifests..."
cat k8s/argocd/image-updater.yaml | \
  sed "s/\${AZURE_REGISTRY_NAME}/$AZURE_REGISTRY_NAME/g" | \
  kubectl apply -f -

echo "Waiting for ArgoCD Image Updater to start..."
kubectl -n argocd rollout status deployment argocd-image-updater

echo "ArgoCD Image Updater has been set up successfully!"
echo "You can check logs with: kubectl -n argocd logs -f deployment/argocd-image-updater" 