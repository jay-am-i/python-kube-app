# AKS CI/CD Project with Terraform, GitHub Actions, and Docker
![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)

This repository demonstrates a complete CI/CD pipeline for deploying a Python application to **Azure Kubernetes Service (AKS)** using **Terraform**, **GitHub Actions**, **Azure Container Registry (ACR)**, and **Docker**.
---
## Table of Contents
- [Project Overview](#project-overview)  
- [Architecture](#architecture)  
- [Prerequisites](#prerequisites)  
- [Terraform Infrastructure](#terraform-infrastructure)  
- [GitHub Actions Pipelines](#github-actions-pipelines)  
  - [Infra Pipeline](#infra-pipeline)  
  - [Deploy Pipeline](#deploy-pipeline)  
- [Docker Image Tagging](#docker-image-tagging)  
- [Accessing the Application](#accessing-the-application)  
- [Notes & Best Practices](#notes--best-practices)
---
## Project Overview
This project automates:
1. Provisioning of Azure resources (Resource Group, AKS cluster, ACR) using **Terraform**.  
2. Continuous integration and deployment of a Python application via **GitHub Actions**.  
3. Docker image builds and pushes to **Azure Container Registry**.  
4. Deployment of Kubernetes manifests (`Deployment` and `Service`) to AKS.
---
## Architecture
GitHub Actions (CI/CD)
        │
        ▼
    Azure Container Registry (ACR)
        │
        ▼
Azure Kubernetes Service (AKS) Cluster
        │
        ▼
      Pods & Services
        │
        ▼
   External Access via LoadBalancer
- **Terraform** provisions:
  - Resource Group (`kubedemo-rg`)  
  - Container Registry (`kubedemocr`)  
  - AKS Cluster (`kubedemok8scluster`)  
  - Role assignment for AKS to pull images from ACR
- **GitHub Actions**:
  - **Infra Pipeline:** Terraform `init`, `plan`, `apply`
  - **Deploy Pipeline:** Docker build, push, Kubernetes deployment
---
## Prerequisites
- Azure subscription with sufficient privileges  
- GitHub repository with **Secrets** set:
  - `AZURE_CREDENTIALS` → Service Principal JSON  
  - `ARM_SUBSCRIPTION_ID` → (optional for Terraform)  
- Local or CI environment with:
  - `kubectl`
  - `az` CLI
  - `docker`
---
## Terraform Infrastructure
**Files:**
- `main.tf` → defines resources  
- `variables.tf` → project variables (`prefix`, `vm_size`, `node_count`, `max_pods`)  
- `terraform.tf` → provider configuration
**Key Resources:**
resource "azurerm_resource_group" "rg" { name = "kubedemo-rg" }
resource "azurerm_container_registry" "acr" { name = "kubedemocr" }
resource "azurerm_kubernetes_cluster" "aks" { name = "kubedemok8scluster" }
resource "azurerm_role_assignment" "aks_acr_pull" { ... }
**Outputs:**
output "acr_login_server" { value = azurerm_container_registry.acr.login_server }
output "aks_name" { value = azurerm_kubernetes_cluster.aks.name }
> After running Terraform, the infra is ready and AKS has permission to pull images from ACR.
---
## GitHub Actions Pipelines
### Infra Pipeline (`infra.yml`)
- Trigger: push to `master` in `terraform/**`  
- Steps:
  1. Checkout repository
  2. Setup Terraform
  3. Azure login
  4. Terraform init, plan, apply
**Note:** The SP must have **Owner** privileges at the subscription level or sufficient permissions to assign roles.
### Deploy Pipeline (`deploy.yml`)
- Trigger: push to `master` for application files (`app.py`, `Dockerfile`, `k8s/**`, etc.)  
- Steps:
  1. Checkout code
  2. Azure login
  3. Set AKS context (kubeconfig)
  4. Login to ACR
  5. Build Docker image
  6. Push Docker image
  7. Update Kubernetes deployment YAML (`IMAGE_PLACEHOLDER` replaced with built image tag)
  8. Deploy both Deployment & Service to AKS
  9. Optional: verify deployment
---
## Docker Image Tagging
- Images are tagged using **GitHub Actions run number**:
IMAGE=mycontainerregistry.azurecr.io/myapp:v${{ github.run_number }}
- Advantages:
  - Incremental versioning (`v1`, `v2`, `v3`)  
  - Easy to reference deployed version in AKS  
- Optional: Combine with Git SHA for traceability:
IMAGE=mycontainerregistry.azurecr.io/myapp:v${{ github.run_number }}-${{ github.sha }}
---
## Accessing the Application
1. Check that pods and services are running:
kubectl get pods
kubectl get svc
2. Look for your `Service` of type `LoadBalancer`:
NAME       TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)
kubeapp    LoadBalancer   10.0.23.157   20.44.12.123   80:31445/TCP
- **EXTERNAL-IP** → public IP assigned by Azure  
- Open in browser: `http://<EXTERNAL-IP>`  
> Note: First-time provisioning can take 1–3 minutes for LoadBalancer IP to appear.
---
## Notes & Best Practices
- Keep **Terraform-managed resources** in state. If a resource exists in Azure but is not in Terraform state, use `terraform import`.  
- Always use **unique Docker tags** to prevent overwriting images.  
- For production, consider separating **infra** and **deploy pipelines** with approvals.  
- If LoadBalancer EXTERNAL-IP is `<pending>`, wait or check events with:
kubectl describe svc kubeapp
---
## References
- [Azure Kubernetes Service Documentation](https://learn.microsoft.com/en-us/azure/aks/)  
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)  
- [GitHub Actions for Azure](https://github.com/Azure/actions)  
- [Docker and GitHub Actions](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)
---