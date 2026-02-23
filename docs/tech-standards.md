# Technology Standards

Architectural guidance for all hobby projects hosted on the shared Azure platform. Projects should follow these standards for consistency, maintainability, and ease of onboarding.

## Language Preference

**Python is the preferred language for new backend projects**, including Azure Functions. Python covers the widest range of use cases across the existing portfolio (web apps, data processing, dashboards, API integrations) and has the largest existing codebase. Azure Functions has full Python support via the [v2 programming model (decorators)](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?pivots=python-mode-decorators), which provides a clean, Flask-like developer experience.

C# is acceptable when there is a strong reason — for example, if a project is extending an existing C# codebase. Existing C# Function Apps (yeOlChatbot, chatter) do not need to be ported immediately, but new Function Apps should use Python. New greenfield projects should default to Python unless there's a compelling justification.

**TypeScript/React** is the standard for frontend web applications. **Astro** is acceptable for content-focused static sites (blogs, documentation).

---

## Python Standards

### Core Libraries (all Python web projects)

These libraries form the standard stack. New Python projects should use all of them unless there's a specific reason not to.

| Library | Purpose | Notes |
|---------|---------|-------|
| **Flask** | Web framework | Lightweight, well-understood, fits the project scale. Use for APIs, webhooks, and server-rendered apps. |
| **gunicorn** | Production WSGI server | Required for App Service deployment. Not used in local dev. |
| **python-dotenv** | Environment configuration | Load `.env` files for local dev; App Service uses app settings in production. |
| **httpx** | HTTP client | For calling external APIs (SmartThings, Fitbit, OpenAI, etc.). Supports both sync and async. Replaces `requests`. |
| **pydantic** | Data validation & models | Type-safe data models. Use for API request/response schemas and configuration. |

> **Note:** `requests` was previously the standard HTTP client. New projects should use `httpx` instead. Existing projects using `requests` should migrate when convenient — `httpx` has an almost identical API for sync usage (`httpx.get()`, `httpx.post()`, etc.).

### Data & Visualization Libraries (when applicable)

| Library | Purpose | When to use |
|---------|---------|-------------|
| **pandas** | Data processing | Projects that manipulate tabular data, time series, or need aggregation/transformation. |
| **plotly** | Interactive charts | Projects with data visualization. Produces interactive HTML charts. |

### Azure SDK Libraries (as needed)

| Library | Purpose | When to use |
|---------|---------|-------------|
| **azure-functions** | Azure Functions SDK | Projects using Azure Functions (HTTP triggers, timer triggers, etc.). Use the v2 programming model with decorators. |
| **azure-data-tables** | Azure Table Storage | Projects storing structured key-value data (sensor readings, conversations, etc.). |
| **azure-storage-blob** | Azure Blob Storage | Projects storing files (recipes, uploads, etc.). |
| **azure-identity** | Azure authentication | Projects that need managed identity or service principal auth to Azure resources. |

### Dev Tooling (all Python projects)

| Tool | Purpose | Notes |
|------|---------|-------|
| **uv** | Package manager | Fast, modern replacement for pip. Use for installs, lockfiles, and virtual environments. |
| **ruff** | Linter + formatter | Replaces black, isort, flake8, and pylint in a single fast tool. |
| **mypy** | Type checking | Catch type errors before runtime. Use strict mode for new projects. |
| **pytest** | Testing | Standard test runner. Use with `pytest-cov` for coverage. |

### Exception: Streamlit

**Streamlit** is an acceptable alternative to Flask for **dashboard-style applications** where the primary purpose is interactive data visualization and the app doesn't need custom routing, APIs, or webhooks. Fitbit is the current example. Streamlit apps still use the same data libraries (pandas, plotly, httpx) and deploy to App Service identically.

### Project Structure

```
project-root/
├── app/                      # Application package
│   ├── __init__.py
│   ├── routes/               # Flask route blueprints
│   ├── models/               # Pydantic models
│   ├── services/             # Business logic
│   └── storage/              # Storage access layer
├── infra/
│   ├── main.bicep            # Project's Azure resources
│   ├── main.bicepparam       # Shared resource IDs
│   └── modules/              # Copied from azure/infra/modules/
├── tests/
│   └── ...
├── .github/
│   └── workflows/
│       ├── deploy-infra.yml  # Deploys infra on changes to infra/
│       └── deploy-app.yml    # Deploys app code
├── .env.example
├── app.py                    # Flask app entry point
├── pyproject.toml            # Project metadata + tool config
├── requirements.in           # Human-edited dependency ranges
├── requirements.txt          # Locked dependencies (auto-generated by uv)
└── README.md
```

### `pyproject.toml` Standard Configuration

All Python projects should use `pyproject.toml` for project metadata and tool configuration:

```toml
[project]
name = "project-name"
version = "0.1.0"
requires-python = ">=3.13"

[tool.ruff]
target-version = "py313"
line-length = 120

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.mypy]
python_version = "3.13"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
```

### Dependency Management & Version Pinning

Use **`uv`** for all Python package management. It replaces `pip`, `pip-tools`, and `virtualenv` in a single fast tool.

#### Workflow

1. **`requirements.in`** — Human-edited file with minimum version ranges:
   ```
   Flask>=3.1.0
   gunicorn>=23.0.0
   python-dotenv>=1.0.0
   httpx>=0.28.0
   pydantic>=2.10.0
   ```

2. **`requirements.txt`** — Auto-generated lockfile with exact pins (committed to git):
   ```bash
   uv pip compile requirements.in -o requirements.txt
   ```

3. **CI installs from the lockfile** for reproducible builds:
   ```bash
   uv pip install -r requirements.txt
   ```

#### Re-pinning for Upgrades

Run periodically (e.g., monthly) to pick up new versions:

```bash
# Upgrade all packages to latest compatible versions
uv pip compile --upgrade requirements.in -o requirements.txt

# Or upgrade a specific package
uv pip compile --upgrade-package flask requirements.in -o requirements.txt

# Review changes
git diff requirements.txt

# Test, then commit
uv pip install -r requirements.txt
pytest
git add requirements.in requirements.txt
git commit -m "chore: upgrade Python dependencies"
```

Do **not** use exact pins (`==`) in `requirements.in` unless there's a known compatibility issue. The lockfile (`requirements.txt`) handles exact pinning automatically.

---

## TypeScript / React Standards

### Core Libraries (all React projects)

| Library | Purpose | Notes |
|---------|---------|-------|
| **react** | UI framework | Standard for all interactive frontends. |
| **react-dom** | DOM rendering | Always paired with react. |
| **react-router-dom** | Client-side routing | For multi-page SPAs. Not needed for single-page apps. |
| **tailwindcss** | CSS framework | Utility-first styling. Use the Vite plugin (`@tailwindcss/vite`). |

### Auth Libraries (projects with authentication)

| Library | Purpose | Notes |
|---------|---------|-------|
| **@azure/msal-browser** | Azure AD / B2C auth | Core MSAL library for token acquisition. |
| **@azure/msal-react** | React MSAL wrapper | Provides hooks and components for auth in React apps. |

### Build Tooling (all React projects)

| Tool | Purpose | Notes |
|------|---------|-------|
| **vite** | Build tool + dev server | Fast, modern replacement for CRA. **Do not use Create React App** (deprecated). |
| **@vitejs/plugin-react** | React support for Vite | Required Vite plugin for React projects. |
| **typescript** | Type safety | All frontend projects should use TypeScript, not plain JavaScript. |
| **eslint** | Linting | Use the flat config format (eslint.config.js). |

### Libraries to Avoid

| Library | Reason | Replacement |
|---------|--------|-------------|
| **react-scripts** (CRA) | Deprecated, unmaintained | **vite** |
| **axios** | Unnecessary — native `fetch()` covers all use cases | `fetch()` API |
| **postcss + autoprefixer** (standalone) | Tailwind v4 handles this internally | **@tailwindcss/vite** |

### Static Sites

**Astro** is the standard for content-focused static sites (blogs, documentation). It produces zero-JS static HTML by default and supports Markdown content natively. React components can be embedded when interactivity is needed.

### Project Structure

```
project-root/
├── src/
│   ├── components/           # Reusable React components
│   ├── pages/                # Route-level components
│   ├── hooks/                # Custom React hooks
│   ├── services/             # API client functions
│   ├── types/                # TypeScript type definitions
│   └── auth/                 # MSAL configuration
├── infra/
│   ├── main.bicep            # Project's Azure resources
│   ├── main.bicepparam       # Shared resource IDs
│   └── modules/              # Copied from azure/infra/modules/
├── public/                   # Static assets
├── .github/
│   └── workflows/
│       ├── deploy-infra.yml  # Deploys infra on changes to infra/
│       └── deploy-app.yml    # Deploys app code
├── .env.example
├── index.html                # Vite entry point
├── vite.config.ts
├── tsconfig.json
├── eslint.config.js
├── package.json
└── README.md
```

---

## Version Recommendations (as of February 2026)

These are point-in-time recommendations. Update to the latest stable versions when starting a new project or performing a major upgrade.

### Python

| Package | Recommended Version | Notes |
|---------|-------------------|-------|
| Python runtime | 3.13 | Latest stable. App Service supports it. |
| Flask | ≥3.1.0 | |
| gunicorn | ≥23.0.0 | |
| python-dotenv | ≥1.0.0 | |
| httpx | ≥0.28.0 | Replaces `requests`. Sync + async support. |
| pydantic | ≥2.10.0 | v2 is a major rewrite from v1; always use v2. |
| pandas | ≥2.2.0 | |
| plotly | ≥5.24.0 | |
| azure-data-tables | ≥12.5.0 | |
| azure-storage-blob | ≥12.24.0 | |
| uv | ≥0.6.0 | Package manager. Install via `pip install uv` or standalone installer. |
| ruff | ≥0.9.0 | |
| mypy | ≥1.14.0 | |
| pytest | ≥8.3.0 | |

### TypeScript / React

| Package | Recommended Version | Notes |
|---------|-------------------|-------|
| Node.js runtime | 22 LTS | |
| react | ^19.0.0 | |
| react-dom | ^19.0.0 | |
| react-router-dom | ^7.6.0 | v7 has breaking changes from v6 (loader/action patterns). |
| tailwindcss | ^4.1.0 | v4 uses CSS-based config (no tailwind.config.js). |
| @tailwindcss/vite | ^4.1.0 | |
| @azure/msal-browser | ^4.12.0 | |
| @azure/msal-react | ^3.0.12 | |
| typescript | ~5.7.0 | |
| vite | ^6.3.0 | |
| @vitejs/plugin-react | ^4.3.0 | |
| eslint | ^9.22.0 | Flat config format. |

---

## General Practices

### Environment Configuration
- Use `.env` files locally (loaded by python-dotenv or Vite's built-in support)
- Use Azure App Service **Application Settings** in production (injected as environment variables)
- Never commit `.env` files — commit `.env.example` with placeholder values

### API Communication
- Frontend → Backend: Use `fetch()` with the backend's subdomain URL
- Backend → External APIs: Use `httpx` (Python) with proper error handling and timeouts
- Backend → Azure services: Use Azure SDK libraries with Managed Identity (`DefaultAzureCredential`)

### Testing
- Python: `pytest` with `pytest-cov`
- TypeScript: Vitest (bundled with Vite) or Jest
- Aim for tests on business logic and API endpoints; UI testing is optional for hobby projects

### Error Handling
- Python: Use Flask error handlers; return JSON error responses for API endpoints
- TypeScript: Use React error boundaries for UI; try/catch for async operations
- Log errors to console (picked up by Log Analytics via App Service diagnostics)

### Health Checks

All backend apps should expose a health check endpoint. App Service uses this to detect and restart unhealthy instances.

**Python (Flask):**
```python
@app.route("/health")
def health():
    return {"status": "healthy"}, 200
```

**Configure in Bicep** via the `healthCheckPath` parameter in `web-app.bicep` or `function-app.bicep`:
```bicep
healthCheckPath: '/health'
```

Static sites don't need health checks.

### Observability

All apps should include the Application Insights connection string in their app settings to enable telemetry:

```bicep
appSettings: [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: '<appi-hobby-connection-string>'
  }
]
```

For Python apps, install `opencensus-ext-azure` or `azure-monitor-opentelemetry` to send traces and metrics. For Node.js apps, the App Service platform handles basic telemetry automatically.
