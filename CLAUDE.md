# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development
bin/dev                              # Start all processes (web, js, css, mail, listener, imgproxy, nginx, ngrok, localstack)
bin/rails db:create db:migrate       # Create and migrate databases
bin/rails db:seed                    # Seed development data

# Testing
bundle exec rspec                    # Run full test suite
bundle exec rspec spec/path/to_spec.rb  # Run a single file
bundle exec rspec spec/path/to_spec.rb:42  # Run a specific example

# Linting
bin/rubocop                          # Ruby style (Omakase)
bin/haml-lint                        # HAML templates
yarn lint:js                         # ESLint
yarn typecheck                       # TypeScript type checking

# Security
bin/brakeman --quiet                 # Static security analysis
bin/bundler-audit                    # Gem vulnerability scan

# CI (runs all of the above)
bin/ci
```

Subdomain multi-tenancy works via `lvh.me` in development (e.g. `http://tenant.lvh.me:3000`).

## Architecture

### Multi-tenancy

All tenants are identified by subdomain. `TenantResolution` (included in `ApplicationController`) resolves the current tenant from: subdomain → session key (dev) → default tenant. Models that include the `MultiTenant` concern are automatically scoped to `Current.tenant` — never query these models without the tenant scope in place.

### Auction / Bidding

- `BidPlacementService` — validates and saves bids; extends `AuctionListing#ends_at` when a bid arrives within the extension window
- `ProxyBiddingService` — automated proxy bidding on behalf of users
- Real-time updates flow: bid saved → PostgreSQL `NOTIFY` → `BidListener` process (lib/bid_listener.rb) picks it up → `BidBroadcastService` pushes via Action Cable → Stimulus controller updates UI
- `AuctionReconcilerJob` marks winners after close; `GenerateAuctionInvoicesJob` + `ChargeInvoiceJob` handle post-auction billing

### Payments

Square is the payment processor. `SquareCustomerService` manages Square customer records. Payment webhooks arrive at a dedicated controller and are processed by `ProcessPaymentJob`. Credentials live in Rails encrypted credentials (`bin/rails credentials:edit`).

### Image Optimisation

All images go through imgproxy. The `optimized_image_tag` helper (in `ImageHelper`) picks a preset (`:card`, `:carousel_slide`, `:carousel_thumb`, `:poster`) and signs the URL. Falls back to the raw Active Storage URL when `IMGPROXY_URL` is not set.

### Background Jobs

Dual queuing: **Solid Queue** (database-backed, default) and **Sidekiq** (for additional processing). Jobs live in `app/jobs/`. The `bid_listener` process (`bin/bid_listener`) is separate from the job queue — it's a long-running PostgreSQL `LISTEN` process started by Procfile.dev.

### Frontend

TypeScript (strict) + Stimulus + Turbo + Bootstrap 5. Entry point: `app/javascript/application.ts`. Stimulus controllers are in `app/javascript/controllers/`. JavaScript is bundled by esbuild (`yarn watch:js`); CSS by the Rails CSS bundler (`yarn watch:css`).

### Database

Four logical databases all backed by PostgreSQL: primary app data, Solid Cache, Solid Queue, and Solid Cable. Schema uses PostgreSQL enums for state machines (listing state, invoice status, lot state, offer state, etc.). Custom functions and triggers live under `db/functions/` and `db/triggers/`.

### Testing

RSpec with FactoryBot and Shoulda Matchers. Request specs cover controllers; model specs cover validations and scopes; service/job specs use doubles where appropriate. `bin/rails test` is wired to run RSpec via `rspec-rails`.
