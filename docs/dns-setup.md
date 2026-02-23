# Cloudflare DNS Setup

All projects are accessed via subdomains of `ambleramble.org`, managed in Cloudflare.

## DNS Records

Add the following CNAME records in Cloudflare DNS for `ambleramble.org`:

| Type | Name | Target | Proxy Status |
|------|------|--------|-------------|
| CNAME | `@` | `<ambleramble-webapp>.azurewebsites.net` | DNS only (gray cloud) |
| CNAME | `chat` | `<yeolchatbot-webapp>.azurewebsites.net` | DNS only |
| CNAME | `chat-api` | `<yeolchatbot-funcapp>.azurewebsites.net` | DNS only |
| CNAME | `chatter` | `<chatter-webapp>.azurewebsites.net` | DNS only |
| CNAME | `chatter-api` | `<chatter-funcapp>.azurewebsites.net` | DNS only |
| CNAME | `humidity` | `<puerhumidity-webapp>.azurewebsites.net` | DNS only |
| CNAME | `recipes` | `<recipes-webapp>.azurewebsites.net` | DNS only |
| CNAME | `fitbit` | `<fitbit-webapp>.azurewebsites.net` | DNS only |
| CNAME | `guitar` | `<guitar-webapp>.azurewebsites.net` | DNS only |
| CNAME | `metronome` | `<metronome-webapp>.azurewebsites.net` | DNS only |

Replace `<name>` placeholders with the actual Azure Web App names after deploying via Bicep.

## Apex Domain Note

The `@` record (apex domain `ambleramble.org`) cannot be a standard CNAME because it conflicts with other DNS records (SOA, NS). Two options:

1. **Cloudflare CNAME Flattening** (recommended) — Cloudflare automatically flattens CNAME records at the apex. Just create a CNAME record for `@` and Cloudflare handles it.
2. **A record + TXT verification** — Get the App Service IP via `az webapp show` and create an A record plus a `asuid` TXT verification record.

## Adding a Custom Domain to App Service

After creating the DNS record:

```bash
# Add custom domain to the web app
az webapp config hostname add \
  --resource-group rg-shared-platform \
  --webapp-name <webapp-name> \
  --hostname <subdomain>.ambleramble.org

# Create a managed SSL certificate (free with B1+)
az webapp config ssl create \
  --resource-group rg-shared-platform \
  --name <webapp-name> \
  --hostname <subdomain>.ambleramble.org

# Bind the SSL certificate
az webapp config ssl bind \
  --resource-group rg-shared-platform \
  --name <webapp-name> \
  --certificate-thumbprint <thumbprint-from-previous-command> \
  --ssl-type SNI
```

### Bicep Alternative

Custom domain bindings can also be managed in Bicep for full IaC coverage. Add this to your project's `infra/main.bicep` after DNS is configured:

```bicep
resource customDomain 'Microsoft.Web/sites/hostNameBindings@2023-12-01' = {
  parent: webApp  // reference to your Microsoft.Web/sites resource
  name: '<subdomain>.ambleramble.org'
  properties: {
    siteName: '<webapp-name>'
    hostNameType: 'Verified'
    sslState: 'Disabled'  // Enable after SSL cert is created
  }
}
```

> **Note:** The DNS CNAME record must exist before deploying the Bicep binding, otherwise Azure validation will fail. For this reason, the CLI approach above is often easier for initial setup. Use Bicep bindings to ensure the configuration is reproducible if the app is ever recreated.

## Important Notes

- **DNS Only mode** — Use "DNS only" (gray cloud icon) in Cloudflare for Azure custom domain validation. After validation, you can optionally enable the orange cloud (proxy).
- **SSL is free** — App Service B1 includes free managed SSL certificates for custom domains.
- **Propagation** — DNS changes can take up to 48 hours to propagate, but typically complete within minutes with Cloudflare.
