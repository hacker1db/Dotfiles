# Runbook — Repository Analysis Guide

## What to Scan

**App identity**: `README.md`, `package.json`, `pom.xml`, `*.csproj`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `setup.py`
→ Extract: app name, language, framework, version.

**Dependencies**: `package.json`, `pom.xml`, `*.csproj`, `go.sum`, `Cargo.lock`, `requirements.txt`, `poetry.lock`
→ Count direct + transitive dependencies.

**Infrastructure**: `terraform/*.tf`, `bicep/*.bicep`, ARM templates (`*.json` with `$schema` containing `deploymentTemplate`), `Dockerfile`, `docker-compose.yml`, `containerapp.yaml`
→ Compute type, cloud provider, regions, resource types.

**CI/CD**: `.github/workflows/*.yml`, `azure-pipelines.yml`, `.azure-pipelines/`, `Jenkinsfile`
→ Pipeline stages, deployment targets, environments.

**Kubernetes**: `kubernetes/`, `helm/`, `charts/`, `k8s/`, `kustomization.yaml`
→ Services, deployments, ingress rules.

**Config**: `appsettings*.json`, `.env.example`, `config/`, `*.config.js`, `*.config.ts`
→ Environment variable names, feature flags, connection string names (never values).

**Source structure**: `src/` layout, API routes, data access patterns
→ API endpoints, database access layers, external service calls.

**Existing docs**: `docs/`, `openapi.yaml`, `swagger.json`, `ARCHITECTURE.md`.

## Repository URL Auto-Detection

```bash
git remote get-url origin
```

SSH to HTTPS conversion:
- `git@ssh.dev.azure.com:v3/org/project/repo` → `https://dev.azure.com/org/project/_git/repo`
- `git@github.com:org/repo.git` → `https://github.com/org/repo`

## Internal Summary to Build

- App name, language/framework, version
- Dependency count (direct + transitive)
- Infrastructure components (compute, storage, networking)
- Data stores (databases, caches, queues)
- External integrations (third-party APIs, SaaS)
- Network topology (VNets, subnets, load balancers, DNS)
- CI/CD stages and deployment method
- Observability tools (Application Insights, Datadog, Prometheus)

Skip missing files silently — never error on absent sources.
