# Change Request — Repository Analysis Guide

## What to Scan

**App identity**: `README.md`, `package.json`, `pom.xml`, `*.csproj`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `setup.py` → extract app name, language, framework, version.

**Dependencies**: `package.json`, `pom.xml`, `*.csproj`, `go.sum`, `Cargo.lock`, `requirements.txt`, `poetry.lock` → count direct + transitive.

**Infrastructure**: `terraform/*.tf`, `bicep/*.bicep`, ARM templates, `Dockerfile`, `docker-compose.yml`, `containerapp.yaml` → compute type, cloud provider, regions, resource types.

**CI/CD**: `.github/workflows/*.yml`, `azure-pipelines.yml`, `.azure-pipelines/`, `Jenkinsfile` → pipeline stages, deployment targets, environments.

**Kubernetes**: `kubernetes/`, `helm/`, `charts/`, `k8s/`, `kustomization.yaml` → services, deployments, ingress rules.

**Config**: `appsettings*.json`, `.env.example`, `config/`, `*.config.js` → env var names, feature flags, connection string names (never values).

**Source structure**: `src/` top-level, API routes, data access patterns → API endpoints, DB access layers, external service calls.

**Existing docs**: `docs/`, `openapi.yaml`, `swagger.json`, `ARCHITECTURE.md`.

## Repository URL Auto-detection

```bash
git remote get-url origin
```

Convert SSH to HTTPS:
- `git@ssh.dev.azure.com:v3/org/project/repo` → `https://dev.azure.com/org/project/_git/repo`
- `git@github.com:org/repo.git` → `https://github.com/org/repo`

## Internal Summary to Build

- App name, language/framework, version
- Dependency count (direct + transitive)
- Infrastructure components (compute, storage, networking)
- Data stores (databases, caches, queues)
- External integrations (third-party APIs, SaaS services)
- Network topology (VNets, subnets, load balancers, DNS)
- CI/CD stages and deployment method
- Observability tools (Application Insights, Datadog, Prometheus, etc.)

Skip missing files silently — never error on absent sources.
