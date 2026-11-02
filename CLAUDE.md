# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Shared Azure platform for a set of hobby projects: Bicep for the shared resources, plus the modules, workflow templates, and standards that each project repo copies. It contains no application code and has no tests. Project apps live in their own repos.

The repo is **public**. Alert recipients (emails, phone numbers) must never be committed; they reach deployments only through GitHub secrets. `local/` is gitignored and holds private notes, so don't copy from it into tracked files.

## Commands

There is no build system. Validate changes with the Bicep CLI (`--stdout` avoids writing compiled JSON next to the source):

```bash
az bicep build --file infra/main.bicep --stdout > /dev/null        # compile the template and all modules
az bicep build --file infra/modules/web-app.bicep --stdout > /dev/null  # compile one module
az bicep build-params --file infra/main.bicepparam --stdout > /dev/null # check the params file against main.bicep
az bicep lint --file infra/main.bicep
```

Preview against real Azure (requires `az login`, read-only):

```bash
az deployment group what-if \
  --resource-group rg-shared-platform \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

## Deployment

- Pushing to `main` with changes under `infra/` deploys to production via `.github/workflows/deploy-infra.yml`. `workflow_dispatch` also triggers it.
- The what-if step is informational: it runs immediately before the deploy in the same job and nothing pauses for review. **Merging is deploying.**
- This repo has no PR CI, so run the validation commands above before opening a PR.
- Changes outside `infra/` (docs, templates, this file) don't trigger a deploy.
- Follow the branch + PR workflow in `docs/tech-standards.md`; never push directly to `main`.
- The workflow uses `azure/CLI` (not `azure/arm-deploy`) because of quoting issues when passing the JSON receiver secrets as inline `--parameters`.
- `main.bicepparam` sets `actionGroupEmailReceivers` and `actionGroupSmsReceivers` to `[]`; CI overrides them from secrets. `main.bicep` only includes the action group module when at least one list is non-empty, so a deploy without those parameters skips it and outputs an empty `actionGroupName`.

## Architecture

**The shared/project split is the key concept.** Everything runs in one resource group, `rg-shared-platform` (`westus3`), but it has two kinds of owner:

- **This repo** deploys the shared resources through `infra/main.bicep`: Log Analytics, Storage, the B1 Linux App Service Plan, Azure OpenAI, App Insights, and the Action Group.
- **Each project repo** deploys its own Web App, Function App, RBAC assignments, and alerts into the same resource group, and references shared resources with the Bicep `existing` keyword.

Consequences:

- Deploys must stay in Incremental mode (the `az` default). Complete mode would delete every project's resources, since they aren't in this template.
- Project-specific blob containers and tables belong in the project's infra, not in `blobContainers`/`tableNames` here.
- Shared resource names are derived from `namePrefix` (`asp-hobby`, `aoai-hobby`, `appi-hobby`, `law-hobby`, `ag-hobby-alerts`) plus `sthobbyshared`. Project repos refer to these names literally, so renaming one breaks them.

**`infra/modules/` has two audiences.** `main.bicep` uses `log-analytics`, `storage`, `app-service-plan`, `openai`, `app-insights`, and `action-group`. It does **not** use `web-app`, `function-app`, `storage-rbac`, or `openai-rbac`: those exist only to be copied into project repos, so a successful deploy here doesn't exercise them, and they only appear in a compile if built directly.

**Modules are distributed by copy-paste**, and versioned with a `// module-version: X.Y` comment on line 1. Bump it when changing a module, since it's how project repos detect drift. Nothing propagates changes to existing projects automatically. `docs/` refers to this repo's modules as `azure/infra/modules/`.

**Authentication is identity-based throughout.** Apps use system-assigned Managed Identity with RBAC granted through the `*-rbac` modules, and CI uses OIDC federation. Avoid introducing connection strings or API keys for Azure services. Function Apps need `storage-rbac` with `accessType: 'all'` and `useBlobDataOwner: true` for the Functions runtime.

**`appSettings` replace rather than merge on every deploy**, in both `web-app.bicep` and `function-app.bicep`. Any setting missing from a project's Bicep is wiped, including ones set by hand. Secrets therefore go through `@secure()` params and `readEnvironmentVariable()` as described in `docs/new-project-guide.md` (Step 5).

## Keeping things in sync

- `docs/new-project-guide.md` embeds Bicep and workflow snippets that mirror the modules and templates. Update them when changing a module's parameters or a workflow pattern.
- `templates/*.yml` are starting points copied into project repos as `deploy-app.yml`; they aren't run here.
- `docs/tech-standards.md` is the source of truth for the language, library, and tooling standards that project repos follow.
