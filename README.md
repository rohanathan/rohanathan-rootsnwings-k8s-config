# Roots & Wings – GKE Configuration Repository  
_This repo defines the full GitOps-driven DevSecOps architecture for the Roots & Wings platform._

---

## Overview  
This repository manages:
- Terraform-provisioned **GKE cluster**
- Kubernetes manifests for **frontend**, **backend**, and **infrastructure controllers**
- Continuous delivery via **Argo CD**
- Certificate + DNS automation via **cert-manager** and **ExternalDNS**

---

## 🔁 GitOps Flow  

**Cloud Build (from App Repo)**  
   - Updates image tags in `frontend/values.yaml` & `backend/values.yaml`  
   - Commits directly to `main` branch  

**Argo CD (in GKE)**  
   - Continuously syncs manifests from this repo  
   - Applies updates declaratively to the cluster  

**Istio Gateway**  
   - Routes `/` → frontend  
   - Routes `/api/*` → backend  
   - TLS from cert-manager’s Let’s Encrypt certificate  

---

## Security & Access  

| Component | Responsibility | Identity Binding |
|------------|----------------|------------------|
| cert-manager | Issue TLS certs via ACME DNS-01 | GCP Workload Identity → Cloud DNS |
| external-dns | Manage A/CNAME/TXT records | GCP Workload Identity → Cloud DNS |
| Argo CD | Sync manifests to GKE | GCP IAM (Workload Identity) |
| Cloud Build | Push image & commit tags | IAM-scoped service account |

---

## Observability  

- **Prometheus** – metrics scraping  
- **Grafana** – dashboards (CPU, memory, success rate)  
- **Kiali** – live mesh topology  
- **Jaeger** – distributed tracing  

---

## Terraform Resources  
- GKE cluster with Workload Identity  
- Custom VPC + Subnet with secondary ranges  
- Node pool with autoscaling & cost-optimized spot instances  
- Artifact Registry + Cloud DNS API enablement  

---

## Linked Repositories  
| Repo | Description |
|------|--------------|
| [rootsnwings-webapp](https://github.com/rohanathan/rootsnwings-webapp) | Application source code (frontend + backend) |
| [rohanathan-rootsnwings-k8s-config](https://github.com/rohanathan/rohanathan-rootsnwings-k8s-config) | This config repository (GitOps + Terraform) |

---

**Author:** Rohanathan Suresh  
**LinkedIn:** [https://www.linkedin.com/in/rohanathan-suresh/](https://www.linkedin.com/in/rohanathan-suresh/)  
**License:** MIT
