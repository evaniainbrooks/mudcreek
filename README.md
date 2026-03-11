# Mudcreek

A multi-tenant auction and marketplace platform built with Rails 8. Supports live auctions with real-time bidding, fixed-price listings, rentals, offers, and Square-powered payments.

## Stack

- **Ruby** 4.0.1 · **Rails** 8.1
- **PostgreSQL** — all environments (primary, cache, queue, cable databases)
- **HAML** templates · **Stimulus** · **Turbo** · **Bootstrap 5**
- **Solid Queue** — background jobs · **Solid Cache** · **Solid Cable** (Action Cable via DB)
- **Sidekiq** — additional background processing
- **Square** — payment processing
- **imgproxy** — image optimisation and WebP conversion
- **Pundit** — authorisation · **Ransack** — search · **Pagy** — cursor-based pagination
- **ViewComponent** · **Active Storage** (disk in dev, S3-compatible in production)

## Prerequisites

| Tool | Notes |
|---|---|
| PostgreSQL | Running locally |
| Ruby 4.0.1 | Managed via rbenv/asdf |
| Node.js + Yarn | For JS/CSS bundling |
| MailHog | Email in development (`brew install mailhog`) |
| imgproxy | Image proxy (`brew install imgproxy`) |
| foreman | Process manager (`gem install foreman`) |

## Getting started

```bash
# Install Ruby dependencies
bundle install

# Install JS dependencies
yarn install

# Create and migrate the databases
bin/rails db:create db:migrate

# (Optional) seed development data
bin/rails db:seed

# Start all development processes
bin/dev
```

`bin/dev` starts the following processes via `Procfile.dev`:

| Process | What it does |
|---|---|
| `web` | Rails server on port 3000 |
| `js` | esbuild in watch mode |
| `css` | CSS bundler in watch mode |
| `mail` | MailHog SMTP + web UI (http://localhost:8025) |
| `listener` | PostgreSQL LISTEN/NOTIFY bid event listener |
| `imgproxy` | Image proxy on port 8080 |

## Environment variables

### Development

No `.env` file is needed. `IMGPROXY_URL` is set inline by `Procfile.dev`. Subdomain-based tenant switching works via `lvh.me` (e.g. `http://tenant.lvh.me:3000`).

### Production

Set the following secrets in your deployment environment:

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` |
| `IMGPROXY_URL` | imgproxy server endpoint |
| `IMGPROXY_KEY` | imgproxy signing key (hex) |
| `IMGPROXY_SALT` | imgproxy signing salt (hex) |

Square credentials and SMTP settings live in Rails encrypted credentials (`bin/rails credentials:edit`).

## Multi-tenancy

Each tenant is identified by its subdomain. The `set_current_tenant` before-action (via the `TenantResolution` concern) resolves the tenant from:

1. The request subdomain → `Tenant.find_by!(key: subdomain)`
2. A session-stored key in development (for switching without DNS)
3. The default tenant when no subdomain is present

All models that include `MultiTenant` are automatically scoped to `Current.tenant`.

## Auctions

- Listings are assigned to auctions and each gets an individual `ends_at` deadline
- Bids are placed via `BidPlacementService`, which extends the deadline if a bid arrives within the extension window
- `AuctionReconcilerJob` runs after each auction closes and marks winners
- Real-time bid updates are broadcast over Action Cable using PostgreSQL `LISTEN`/`NOTIFY` via `BidListener`

## Testing

```bash
# Run the full suite
bundle exec rspec

# Run a specific file
bundle exec rspec spec/requests/auctions_spec.rb
```

The suite uses RSpec, FactoryBot, and Shoulda Matchers. Request specs cover controllers; model specs cover validations and scopes; service/job specs use doubles to stay DB-agnostic where possible.

## Deployment

The app is deployed with [Kamal](https://kamal-deploy.org). Configuration lives in `config/deploy.yml`.

```bash
# First-time setup
kamal setup

# Deploy
kamal deploy
```

Secrets are read from `.kamal/secrets` (never committed). See that file for the expected variables.

## Image optimisation

All listing and auction images are routed through imgproxy, which resizes and converts to WebP on the fly. The `optimized_image_tag` helper in `ImageHelper` selects a preset based on context:

| Preset | Dimensions | Use |
|---|---|---|
| `:card` | 800 × 400 fill | Listing and auction card thumbnails |
| `:carousel_slide` | 1200 × 480 fill | Carousel main images |
| `:carousel_thumb` | 152 × 152 fill | Carousel navigation thumbnails |
| `:poster` | 800 × 600 fit | Auction detail page poster |

When `IMGPROXY_URL` is not set the helper falls back to the standard Active Storage URL, so development without imgproxy still works.
