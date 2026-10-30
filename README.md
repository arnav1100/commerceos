# COMMERCEOS

A premium, responsive e-commerce operations workspace. The included UI opens in a clearly labelled **DEMO DATA** workspace so it can be reviewed without credentials or external services.

> **Scope note — read before deployment.** The current interactive application is a browser-local demo (localStorage), not yet connected to Supabase Auth or live PostgreSQL CRUD. The Supabase migration in `supabase/migrations/` is a security-focused production schema foundation with RLS and transaction RPCs; it does not by itself make the UI a full-stack production system. Do not use this demo for real customer data, orders, or accounting. The app makes no claim of payment, tax, or jurisdictional invoice compliance.

## Run locally

Requirements: Node 20+ and npm.

```bash
npm install
npm run dev
```

Vite binds to `0.0.0.0`. Open the local URL printed in the terminal. All demo changes persist in this browser. Use **Settings → Reset workspace** to restore the synthetic seed dataset.

```bash
npm run test   # Vitest unit tests
npm run build  # TypeScript check and production build
npm run preview
```

## Implemented in the demo

- Responsive administration shell with Overview, Products, Orders, Inventory, Customers, Analytics, Invoices, and Settings.
- Clearly identified synthetic sample records; sales metrics derive from order/payment/status records, not hard-coded dashboard totals.
- Product create/edit/archive, category/status filtering, SKU validation, variants, pagination, and audit records for stock changes made in the product editor.
- Manual order creation starts as **Pending / Unpaid**. Order detail supports fulfillment and payment tracking. Entering Processing checks and deducts stock once; cancellation restores it; invalid status transitions and insufficient stock are rejected.
- Variant-level manual inventory adjustments, low-stock/out-of-stock filters, and movement history.
- Customer creation, search, profiles, spend and order history.
- Sales analytics and status breakdowns derived from demo orders. Unpaid, cancelled and refunded orders are excluded from revenue metrics.
- Invoice previews and downloadable PDFs. Invoice totals, item names, business identity, currency, and customer contact are snapshotted when first issued. No legal-compliance claim is made.
- Business settings are saved locally. Currency changes do not convert existing orders or invoices.
- Keyboard global search (`⌘K` / `Ctrl+K`), mobile drawer navigation, confirmations for archive/reset, and toast feedback.

## Supabase database foundation

The migration is intended for a Supabase project and includes:

- Normalized tenant, member, catalog, customer, order, inventory, and invoice tables using UUIDs and integer minor-unit money.
- Tenant RLS helpers and role checks, membership isolation, indexes, consistent foreign keys, unique invoice/order identifiers, and tenant consistency triggers.
- `create_business()` for authenticated workspace creation.
- `adjust_inventory()` for membership-checked atomic stock changes with movement records.
- `set_order_status()` for idempotent processing reservations and cancellation releases inside a database transaction.
- `issue_invoice()` for an immutable invoice/order financial snapshot.

Apply it only after reviewing it for your Supabase/PostgreSQL version:

```bash
supabase db push
```

Or paste `supabase/migrations/202610300001_commerceos_core.sql` into the Supabase SQL editor. Create a **private** `product-images` Storage bucket separately; the migration includes the recommended path convention and policy examples in comments. Configure file-size and MIME allowlists in Supabase Storage.

`.env.example` lists the requested browser-safe Supabase URL and publishable key names. **They are not currently read by the demo UI**; the service-role key must never be used in frontend code. A production release still needs the Supabase Auth screens/route guards, live data repository and query mutations, server-side product/order validation, authenticated storage client, tenant-isolation integration tests against PostgreSQL, and deployment-specific email/password-reset configuration. The UI intentionally does not pretend those integrations are active.

## Stock lifecycle

- New manual orders are Pending and Unpaid, and do not change stock.
- Transitioning to Processing validates all item availability and deducts stock exactly once.
- Cancelling a processed order restores stock once and writes an inventory movement.
- Terminal cancelled/delivered orders cannot be reopened in the local demo.
- The migration implements corresponding row-locking RPC operations for real Supabase persistence. Production UI must call those RPCs rather than writing quantities directly.

## Tests

`src/lib/data.test.ts` covers integer-minor-unit totals, currency formatting, inventory adjustment and negative-stock guards, one-time order stock deduction/release, idempotent status updates, invalid order lifecycle transitions, and immutable invoice snapshots. Database RLS and PostgreSQL concurrency tests require a configured Supabase local stack and are not claimed as run here.

## Project layout

```text
src/
  App.tsx                 admin screens and reusable interaction primitives
  lib/data.ts             typed demo data, calculations, lifecycle operations
  lib/data.test.ts        unit tests
  types/index.ts          domain types
  styles.css              design tokens and responsive UI
supabase/migrations/      Postgres schema, RLS and transactional RPCs
.env.example              browser-safe Supabase environment variable names
```
