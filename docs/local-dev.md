# Local Development Guide

Each project type has a standard local development setup. All projects should work locally without any Azure resources by using emulators or local fallbacks.

## Storage: Azurite (Azure Storage Emulator)

[Azurite](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite) emulates Azure Blob, Queue, and Table Storage locally.

### Install & Run

```bash
# Install globally
npm install -g azurite

# Run all services
azurite --silent --location ./azurite-data

# Or run specific services
azurite-table --silent    # Table Storage only
azurite-blob --silent     # Blob Storage only
```

### Connection String

Use this connection string in your `.env` or app settings for local development:

```
DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;
```

### VS Code Extension

Install the **Azurite** VS Code extension for one-click start/stop.

## Python / Flask Apps

Projects: puerHumidity, docker (recipes), fitbit

```bash
# Install uv (if not already installed)
pip install uv

# Create virtual environment
uv venv

# Activate (Windows)
.venv\Scripts\Activate.ps1

# Activate (macOS/Linux)
source .venv/bin/activate

# Install dependencies from lockfile
uv pip install -r requirements.txt

# Run Flask app
flask run --port 5000
# Or with Gunicorn (macOS/Linux only)
gunicorn --bind=0.0.0.0:5000 app:app
```

### Environment Variables

Create a `.env` file from `.env.example`:

```env
STORAGE_TYPE=local                           # Use local storage fallback
# AZURE_STORAGE_CONNECTION_STRING=<azurite>  # Or use Azurite
# AZURE_TABLE_NAME=sensorreadings
```

> **Note:** Local development uses connection strings (Azurite or `UseDevelopmentStorage=true`). In production, apps use Managed Identity via `DefaultAzureCredential` — only `AZURE_STORAGE_ACCOUNT_NAME` is needed, not a connection string.

## Streamlit Apps

Project: fitbit

```bash
uv pip install -r requirements.txt
streamlit run app.py --server.port 8501
```

## Node.js / React / Astro Static Sites

Projects: ambleramble, metronome, guitarPractice

```bash
npm install
npm run dev    # Starts dev server with hot reload
npm run build  # Produces production build in dist/ or build/
```

## C# Azure Functions (Backend)

Projects: yeOlChatbot backend, chatter backend

```bash
cd <backend-directory>

# Install Azure Functions Core Tools if not already installed
# https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local

# Start the Functions host locally
func start --port 7071
```

### Local Settings

Create `local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AZURE_STORAGE_CONNECTION_STRING": "UseDevelopmentStorage=true",
    "AZURE_OPENAI_ENDPOINT": "<your-openai-endpoint>",
    "AZURE_OPENAI_DEPLOYMENT": "<your-deployment-name>"
  }
}
```

> **Note:** In deployed environments, Azure OpenAI access uses Managed Identity (no API key needed).
> For local development, you can use `DefaultAzureCredential` from the Azure Identity SDK,
> which picks up your `az login` session automatically.

## React Frontends (with Function Backend)

Projects: yeOlChatbot frontend, chatter frontend

```bash
# Terminal 1: Start backend
cd backend && func start --port 7071

# Terminal 2: Start frontend
cd frontend && npm run dev
```

Configure the frontend to point API calls to `http://localhost:7071` during development (usually via a `.env.local` or proxy config in `vite.config.ts`).

## Azure OpenAI

For local development, use `DefaultAzureCredential` which automatically picks up your `az login` session. No API key is needed:

```env
AZURE_OPENAI_ENDPOINT=<your-openai-endpoint>
AZURE_OPENAI_DEPLOYMENT=<your-deployment-name>
```

In deployed environments, Managed Identity handles authentication automatically. See the Azure Identity SDK documentation for [DefaultAzureCredential](https://learn.microsoft.com/en-us/python/api/azure-identity/azure.identity.defaultazurecredential).
