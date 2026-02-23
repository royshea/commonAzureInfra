# Adding a New Project to the Platform

This guide walks through adding a new project to the shared Azure infrastructure.

## Prerequisites

- Azure CLI installed and logged in
- GitHub repo for the project
- GitHub OIDC federation configured (see [Setup OIDC](#setup-github-oidc-federation) below)

## Step 1: Decide the Project Type

| Type | Framework | Hosting | Example |
|------|-----------|---------|---------|
| Static site | Astro, React, HTML/JS | App Service Web App (Node runtime) | ambleramble, metronome |
| Python web app | Flask, Streamlit | App Service Web App (Python runtime) | puerHumidity, fitbit |
| React + API | React frontend + Python Functions | Web App + Function App | yeOlChatbot, chatter |

**Language guidance:** Python is the preferred language for all new backend work, including Azure Functions. Existing C# Function Apps (yeOlChatbot, chatter) don't need to be ported immediately, but new Function Apps should use Python with the [v2 programming model (decorators)](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?pivots=python-mode-decorators). C# is acceptable only when extending an existing C# codebase. See [tech-standards.md](tech-standards.md) for full details.

## Step 2: Create the Project's Infrastructure

Each project manages its own Azure resources in its own repo. Copy the necessary Bicep modules from this repo and create a project-specific `infra/main.bicep`.

> **Module versioning:** Each Bicep module has a `// module-version: X.Y` comment at the top. When copying modules from this repo, note the version. Check back periodically to see if newer versions are available. See [Template Specs](#template-specs-future-option) below for a potential future alternative to copy-paste.

### Set up your project's infra directory

1. Create `infra/modules/` in your project repo
2. Copy the needed modules from `azure/infra/modules/`:
   - `web-app.bicep` (always needed)
   - `storage-rbac.bicep` (if your project uses shared storage)
   - `openai-rbac.bicep` (if your project uses shared OpenAI)
   - `function-app.bicep` (if your project has a Function App backend)

3. Create `infra/main.bicep` for your project:

```bicep
@description('Resource ID of the shared App Service Plan')
param appServicePlanId string

@description('Resource ID of the shared Storage Account (if needed)')
param storageAccountId string = ''

@description('Name of the shared Storage Account (if needed)')
param storageAccountName string = ''

@description('Resource ID of the shared OpenAI account (if needed)')
param openaiAccountId string = ''

param location string = 'westus2'

module webApp 'modules/web-app.bicep' = {
  name: 'web-app'
  params: {
    name: 'app-<yourproject>'
    location: location
    appServicePlanId: appServicePlanId
    linuxFxVersion: 'PYTHON|3.13'                                    // or NODE|22-lts
    startupCommand: 'gunicorn --bind=0.0.0.0 --timeout 600 app:app'  // adjust per project
    projectName: '<yourproject>'
    healthCheckPath: '/health'
    appSettings: [
      {
        name: 'AZURE_STORAGE_ACCOUNT_NAME'
        value: storageAccountName
      }
    ]
  }
}

// Grant Managed Identity access to shared storage
module storageAccess 'modules/storage-rbac.bicep' = if (!empty(storageAccountId)) {
  name: 'storage-rbac'
  params: {
    principalId: webApp.outputs.principalId
    storageAccountId: storageAccountId
    accessType: 'table'  // or 'blob', 'queue', 'both', or 'all'
  }
}

// Grant Managed Identity access to shared OpenAI
module openaiAccess 'modules/openai-rbac.bicep' = if (!empty(openaiAccountId)) {
  name: 'openai-rbac'
  params: {
    principalId: webApp.outputs.principalId
    openaiAccountId: openaiAccountId
  }
}
```

4. Create `infra/main.bicepparam` with the shared resource IDs:

```bicep
using 'main.bicep'

param appServicePlanId = '<asp-hobby-resource-id>'
param storageAccountId = '<sthobbyshared-resource-id>'
param storageAccountName = 'sthobbyshared'
param openaiAccountId = '<aoai-hobby-resource-id>'
```

### Deploy your project's infra

```bash
az deployment group create \
  --resource-group rg-shared-platform \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

### Azure Functions note

Python Azure Functions use the [v2 programming model](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?pivots=python-mode-decorators) with decorators. A minimal HTTP-triggered function looks like:

```python
import azure.functions as func

app = func.FunctionApp()

@app.route(route="hello", methods=["GET"])
def hello(req: func.HttpRequest) -> func.HttpResponse:
    name = req.params.get("name", "World")
    return func.HttpResponse(f"Hello, {name}!")
```

Initialize a new Python Functions project with:
```bash
func init --python -m V2
func new --name hello --template "HTTP trigger"
```

For Function Apps, use `function-app.bicep` instead of `web-app.bicep` in your project's `infra/main.bicep`. Function Apps use identity-based storage connections (`storageAccountName` parameter) — no connection strings needed. You must also grant the Function App's Managed Identity access to the storage account using `storage-rbac.bicep` with `accessType: 'all'` and `useBlobDataOwner: true` (required for Azure Functions runtime):

```bicep
module functionApp 'modules/function-app.bicep' = {
  name: 'function-app'
  params: {
    name: 'func-<yourproject>'
    location: location
    appServicePlanId: appServicePlanId
    linuxFxVersion: 'PYTHON|3.13'
    storageAccountName: storageAccountName
    projectName: '<yourproject>'
    healthCheckPath: '/api/health'
    corsAllowedOrigins: [
      'https://<yourproject>.ambleramble.org'
      'http://localhost:5173'
    ]
  }
}

// Function runtime needs Blob Data Owner + Queue + Table access
module functionStorageAccess 'modules/storage-rbac.bicep' = {
  name: 'function-storage-rbac'
  params: {
    principalId: functionApp.outputs.principalId
    storageAccountId: storageAccountId
    accessType: 'all'
    useBlobDataOwner: true
  }
}
```

C# Function Apps (existing projects only) use `linuxFxVersion: 'DOTNET-ISOLATED|8.0'`.

## Step 3: Configure DNS

1. Go to Cloudflare DNS for `ambleramble.org`
2. Add a CNAME record:
   - **Name:** `<subdomain>` (e.g., `myapp`)
   - **Target:** `app-<yourproject>.azurewebsites.net`
   - **Proxy status:** DNS only (gray cloud)
3. Add the custom domain to the App Service:

```bash
az webapp config hostname add \
  --resource-group rg-shared-platform \
  --webapp-name app-<yourproject> \
  --hostname <subdomain>.ambleramble.org
```

4. Create and bind SSL certificate (see [docs/dns-setup.md](dns-setup.md))

## Step 4: Set Up CI/CD

Each project gets **two workflows**:

1. **`deploy-infra.yml`** — Deploys the project's infra (runs on changes to `infra/`). Includes a what-if preview before deploying.
2. **`deploy-app.yml`** — Deploys app code (runs on changes to source code)

Copy the appropriate template from `templates/` into your project as `.github/workflows/deploy-app.yml` and update the `env` section:
- **Python apps:** `templates/python-deploy.yml`
- **Node.js / static sites:** `templates/node-deploy.yml`
- **\.NET apps:** `templates/dotnet-deploy.yml`

Create `.github/workflows/deploy-infra.yml`:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths: ['infra/**']
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - name: Preview changes (What-If)
        uses: azure/CLI@v2
        with:
          inlineScript: |
            az deployment group what-if \
              --resource-group rg-shared-platform \
              --template-file infra/main.bicep \
              --parameters infra/main.bicepparam
      - uses: azure/arm-deploy@v2
        with:
          resourceGroupName: rg-shared-platform
          template: infra/main.bicep
          parameters: infra/main.bicepparam
```

Add GitHub secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (see OIDC setup below).

## Step 5: Configure App Settings

Set non-secret configuration via app settings:

```bash
az webapp config appsettings set \
  --resource-group rg-shared-platform \
  --name app-<yourproject> \
  --settings \
    AZURE_OPENAI_ENDPOINT="<your-openai-endpoint>" \
    AZURE_OPENAI_DEPLOYMENT="<deployment-name>"
```

> **Note:** Storage and OpenAI authentication use Managed Identity via RBAC (configured in your `infra/main.bicep`). No connection strings or API keys should be stored in app settings. Use `AZURE_STORAGE_ACCOUNT_NAME` (not connection strings) and `DefaultAzureCredential` in your application code.

## Step 6: Deploy

Push to `main` and the GitHub Actions workflow will automatically deploy.

```bash
git push origin main
```

---

## Setup GitHub OIDC Federation

This eliminates the need for stored Azure credentials in GitHub secrets.

### One-time setup (already done for existing projects):

1. **Create an Azure AD App Registration:**
   ```bash
   az ad app create --display-name "github-hobby-deploy"
   ```

2. **Create a Service Principal:**
   ```bash
   az ad sp create --id <app-id>
   ```

3. **Assign least-privilege roles** (instead of broad Contributor):
   ```bash
   # Website Contributor — deploy app code to App Service
   az role assignment create \
     --assignee <app-id> \
     --role "Website Contributor" \
     --scope /subscriptions/<subscription-id>/resourceGroups/rg-shared-platform

   # Contributor — needed for the deploy-infra workflow to create/update resources
   # Scope to the resource group, not the entire subscription
   az role assignment create \
     --assignee <app-id> \
     --role "Contributor" \
     --scope /subscriptions/<subscription-id>/resourceGroups/rg-shared-platform
   ```

4. **Add federated credential for each repo:**
   ```bash
   az ad app federated-credential create \
     --id <app-id> \
     --parameters '{
       "name": "<repo-name>-main",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:<github-username>/<repo-name>:ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

5. **Add GitHub secrets to each repo:**
   - `AZURE_CLIENT_ID` — App registration client ID
   - `AZURE_TENANT_ID` — Azure AD tenant ID
   - `AZURE_SUBSCRIPTION_ID` — Azure subscription ID

### Adding a new repo to OIDC:

Only step 4 (add federated credential) and step 5 (add GitHub secrets) are needed for each new project repo.

---

## Template Specs (Future Option)

Currently, Bicep modules are copied from this repo into each project. This is simple but creates version drift. **Azure Template Specs** are a potential future upgrade:

- **What they are:** ARM/Bicep templates stored as versioned Azure resources (free)
- **How they work:** Publish a module once, reference it by version from any project
- **Reference syntax:** `module webApp 'ts:<subscriptionId>/<rgName>/web-app:1.0' = { ... }`

### Example workflow

```bash
# Publish a module as a template spec
az ts create \
  --name web-app \
  --version 1.0 \
  --template-file infra/modules/web-app.bicep \
  --resource-group rg-shared-platform

# Reference from a project's main.bicep (no copy needed)
# module webApp 'ts:<subscription-id>/rg-shared-platform/web-app:1.0' = { ... }
```

### Trade-offs vs. copy-paste

| | Copy-Paste (current) | Template Specs |
|---|---|---|
| Setup | Zero | One-time `az ts create` per module |
| Versioning | Manual (`// module-version` comment) | Built-in |
| Update propagation | Manual copy | Update version reference |
| Offline dev | ✅ | Needs `az` auth for bicep build |

For the current scale (< 10 projects), copy-paste with version comments is fine. Consider template specs if module updates become frequent or error-prone.

---

## Project Structure Convention

```
project-root/
├── .github/
│   └── workflows/
│       ├── deploy-infra.yml  # Deploys infra on changes to infra/
│       └── deploy-app.yml    # Deploys app code on source changes
├── infra/
│   ├── main.bicep            # Project's Azure resources
│   ├── main.bicepparam       # Shared resource IDs
│   └── modules/
│       ├── web-app.bicep     # Copied from azure/infra/modules/
│       ├── storage-rbac.bicep
│       └── openai-rbac.bicep
├── src/                      # Application source
├── .env.example              # Environment variable template
├── requirements.in           # Python dependency ranges (if Python)
├── requirements.txt          # Locked Python deps (if Python)
├── package.json              # Node deps (if Node/static)
└── README.md
```
