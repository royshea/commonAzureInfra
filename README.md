# Common Azure Infrastructure

Shared infrastructure and standards for deploying multiple hobby projects to Azure on a unified platform.

## Goals

- **Consistency** — Define a common Azure stack so new projects follow a standard pattern instead of ad-hoc resource creation.
- **Simplified deployment** — Every project deploys via GitHub Actions CI/CD triggered by pushes to `main`. No manual Azure Portal work.
- **Cost efficiency** — All projects share a single App Service Plan and common resources (storage, logging, OpenAI), keeping total spend low.
- **Security** — Managed Identity (MSI) for all service-to-service auth. OIDC federation for CI/CD. No stored credentials or connection strings.
- **Independence** — Each project remains a standalone repo. Projects manage their own Azure resources (Web App, Function App, RBAC) using Bicep modules copied from this repo.

## What this repo contains

```
├── infra/                  # Bicep templates for shared platform resources
│   ├── main.bicep          # Orchestrator (subscription-scoped)
│   ├── main.bicepparam     # Parameter values
│   └── modules/            # Reusable Bicep modules (copied into project repos)
├── templates/              # GitHub Actions workflow templates (copied into project repos)
├── docs/                   # Guidance and setup instructions
│   ├── new-project-guide.md    # Step-by-step: add a new project
│   ├── tech-standards.md       # Language, library, and tooling standards
│   ├── dns-setup.md            # Cloudflare DNS configuration
│   └── local-dev.md            # Local development setup
└── .github/workflows/     # CI/CD for this repo's shared infra
```

## Architecture

A single **App Service Plan (B1 Linux)** hosts all projects — static sites, Python web apps, React frontends, and Function App backends. Shared resources (Storage Account, Log Analytics, Application Insights, Azure OpenAI) live in one resource group.

Each project repo contains its own `infra/` directory with Bicep templates that reference the shared resources by ID. See [docs/new-project-guide.md](docs/new-project-guide.md) for the full pattern.

## Getting started

### Initial setup (one-time)

1. **Deploy shared infrastructure** — Deploys the resource group, App Service Plan, Storage Account, and other shared resources:
   ```bash
   az deployment sub create \
     --location <region> \
     --name shared-infra-initial \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

2. **Set up GitHub OIDC** — Create an Azure AD app registration with federated credentials so GitHub Actions can deploy without stored secrets. See [Setup GitHub OIDC Federation](docs/new-project-guide.md#setup-github-oidc-federation) for detailed steps.

3. **Add GitHub secrets** to this repo: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.

After this, any push to `main` that changes `infra/` will automatically redeploy the shared infrastructure.

### Adding a project

See [docs/new-project-guide.md](docs/new-project-guide.md) for the full walkthrough — covers creating the project's Bicep infra, DNS, CI/CD workflows, and RBAC.

### Standards and conventions

See [docs/tech-standards.md](docs/tech-standards.md) for language preferences, library choices, project structure, and versioning guidance.
