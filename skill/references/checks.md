# Ship-It checks (lite)

15 checks, the ones that most often sink a Next.js + Supabase + Stripe launch. The paid edition adds the rest of the catalog, a Fix-It library, and a scanner. Severity is critical, high, medium, or low.

## Security

### SEC-01 — Row Level Security is enabled on every public table

- **Severity:** critical
- **Edition:** lite
- **Automated:** yes

**Detection**

Open supabase/migrations/*.sql (and any other *.sql). For every CREATE TABLE, confirm a later statement ALTER TABLE <same table> ENABLE ROW LEVEL SECURITY. If the app uses Supabase and there is no migrations directory, fail: dashboard-only RLS is invisible to review and to new environments. Ignore tables outside the scan and views.

**Why it matters**

The anon key ships in the browser. PostgREST exposes every public table. With RLS off, anyone who can read the bundle can read and write every row with curl.

**Fix**

In a new migration, run ALTER TABLE public.<table> ENABLE ROW LEVEL SECURITY for each table. Enabling RLS with no policies denies anon and authenticated (see SEC-25). Add policies in the same migration. Apply it with supabase db push or the Supabase SQL editor, then confirm in Dashboard → Authentication → Policies that RLS is on.

**Fix prompt**

> Enable Row Level Security on every table in public. Add a migration that runs ALTER TABLE ... ENABLE ROW LEVEL SECURITY for each table created in supabase/migrations. Do not turn RLS off to make queries work. Add owner policies in the same migration using auth.uid() = user_id, and show me the SQL before applying it.

### SEC-02 — No service-role key or server secrets committed in the repo

- **Severity:** critical
- **Edition:** lite
- **Automated:** yes

**Detection**

Search tracked files for sk_live_, sk_test_, rk_live_, whsec_, and JWTs whose payload role is service_role. Ignore example env files (.env.example, .env.local.example, .env.sample) and obvious placeholders such as sk_test_not_configured or sk_test_replace_me. A committed sk_live_EXAMPLE… literal is still a finding. Do not flag process.env.SUPABASE_SERVICE_ROLE_KEY with no literal value. Do not flag anon-role JWTs.

**Why it matters**

A service-role key bypasses RLS. A live Stripe secret or webhook secret in git history can charge customers or forge billing events. Git history keeps the key even after you delete the file.

**Fix**

Rotate the leaked key in the Supabase and Stripe dashboards. Remove the literal from the repo. Put the new value in .env.local and in Vercel → Settings → Environment Variables. Purge it from git history if it was ever committed (git filter-repo or the host's secret-scanning revoke flow). Keep only placeholder values in .env.example.

**Fix prompt**

> Find every committed secret (Supabase service-role JWT, sk_live_, sk_test_, rk_live_, whsec_). Remove the literals from source and from any .env file that is not gitignored. Replace them with process.env variables. Add a .env.example with empty placeholders. Tell me which keys I must rotate because they were in the tree. Do not print the secret values back to me.

### SEC-03 — NEXT_PUBLIC_ is not used for server secrets

- **Severity:** critical
- **Edition:** lite
- **Automated:** yes

**Detection**

Flag any env name matching NEXT_PUBLIC_.*(SECRET|SERVICE_ROLE|WEBHOOK|PRIVATE|SK_LIVE|SK_TEST) and any NEXT_PUBLIC_ variable whose value is a Stripe secret, webhook secret, or service-role JWT. Check .env*, next.config env, and source.

**Why it matters**

Next.js inlines every NEXT_PUBLIC_ variable into the browser bundle at build time. Prefixing the service role or sk_live_ this way publishes it to every visitor.

**Fix**

Rename the variable so it does not start with NEXT_PUBLIC_. Use NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY only. Read the service role and Stripe secret from server-only env (no NEXT_PUBLIC_ prefix) inside server components, route handlers, and server actions.

**Fix prompt**

> Search the repo for NEXT_PUBLIC_ variables that hold a secret (service role, Stripe secret, webhook secret, private key). Rename them to server-only env vars, move reads to server code, and delete the NEXT_PUBLIC_ names from .env.example and the Vercel project. The only Supabase keys allowed in the client are the URL and the anon key.

### SEC-04 — API routes and server actions reject unauthenticated callers

- **Severity:** critical
- **Edition:** lite
- **Automated:** yes

**Detection**

Open mutating route handlers (POST, PUT, PATCH, DELETE), GET handlers that touch Supabase or Stripe, and 'use server' files. Each must call getUser(), getSession(), requireSession(), exchangeCodeForSession(), auth.updateUser(), or an equivalent such as getServerSession, Better Auth, or Clerk. Public exceptions: /api/health, /api/auth, Stripe webhooks, and /auth/callback, /auth/confirm, /auth/reset. Sign-in-only server actions are public. A GET that only serves docs or static copy is not a failure. A comment ship-it: ignore SEC-04 with a reason is a waiver.

**Why it matters**

Route handlers and server actions are public URLs. Hiding the button does not hide the endpoint. Without a server-side user check, anyone can call checkout, profile update, or delete.

**Fix**

At the top of the handler, create the server Supabase client and run const { data: { user } } = await supabase.auth.getUser(). If user is null, return 401. Do not trust a user id from the request body. For webhooks, skip session auth and verify the signature instead (PAY-01).

**Fix prompt**

> Audit every route handler under app/api and every 'use server' action. If it reads or writes user data or creates a Stripe session, require supabase.auth.getUser() (not a user id from the body) and return 401 when there is no user. Leave /api/health and the Stripe webhook unauthenticated, and say so in a one-line comment. Show the diff.

### SEC-05 — .env files are gitignored

- **Severity:** high
- **Edition:** lite
- **Automated:** yes

**Detection**

Read .gitignore. .env.local must be ignored (.env*.local counts, which is the create-next-app default). Fail on .env only when a .env file is actually in the tree and the ignore rules do not cover it. Require !.env.example when a wildcard would hide the example file. If git ls-files lists a real env file, fail even when gitignore was added later.

**Why it matters**

Next.js projects keep secrets in .env.local. One missing gitignore line commits the service role and sk_live_ on the next save. Vercel never needs that file in git; it has its own env store.

**Fix**

Add this to .gitignore:

.env
.env.*
!.env.example

Remove cached files with git rm --cached .env .env.local. Keep .env.example, with empty values, in git.

**Fix prompt**

> Update .gitignore so .env and .env.local are ignored and .env.example is not. If those env files are already tracked, untrack them with git rm --cached without deleting the local copies. Do not commit their contents.

### SEC-06 — Security headers are set on responses

- **Severity:** high
- **Edition:** lite
- **Automated:** yes

**Detection**

Read next.config.js/ts/mjs and middleware.ts. Require all of: X-Content-Type-Options nosniff, a clickjacking control (X-Frame-Options DENY or SAMEORIGIN, or CSP frame-ancestors), and Referrer-Policy. Treat Strict-Transport-Security as required for production hosts. A header set in middleware counts.

**Why it matters**

Vercel's default Next response does not send these. Without them the app is easier to frame, MIME-sniff, and leak URLs in the Referer header. HSTS stops downgrade once you are on HTTPS, which Vercel is.

**Fix**

Add an async headers() function in next.config that returns those four headers for source '/:path*'. Keep CSP tight: default-src 'self', and add only the hosts you actually use (js.stripe.com, your Supabase project host). Do not ship Content-Security-Policy: default-src *.

**Fix prompt**

> Add security headers to next.config for every route: X-Content-Type-Options nosniff, X-Frame-Options DENY, Referrer-Policy strict-origin-when-cross-origin, and Strict-Transport-Security max-age=63072000; includeSubDomains; preload. Add a Content-Security-Policy that defaults to 'self' and allowlists only the Stripe and Supabase hosts this app uses. Do not disable the headers to silence console noise.

## Payments

### PAY-01 — Stripe webhooks verify the signature

- **Severity:** critical
- **Edition:** lite
- **Automated:** yes

**Detection**

Find the route that handles Stripe events (path contains webhook, or the file references stripe.webhooks). Require stripe.webhooks.constructEvent (or constructEventAsync). Fail handlers that trust event.type from a parsed JSON body.

**Why it matters**

Without the signature, anyone can POST { type: 'checkout.session.completed' } and your handler will mark them paid, grant a subscription, or bump credits.

**Fix**

Read the raw body with request.text(). Pass it with the stripe-signature header and STRIPE_WEBHOOK_SECRET to stripe.webhooks.constructEvent. Use the event object constructEvent returns, not the raw JSON. Return 400 if the header is missing or verification throws.

**Fix prompt**

> Update the Stripe webhook route so it reads request.text(), passes the stripe-signature header and STRIPE_WEBHOOK_SECRET to stripe.webhooks.constructEvent, and handles only the event that function returns. Return 400 when verification fails. Do not call request.json() on this route.

### PAY-02 — Prices and amounts are not taken from the client

- **Severity:** critical
- **Edition:** lite
- **Automated:** yes

**Detection**

In checkout or PaymentIntent creation, fail when unit_amount, amount, or price comes from the request body or search params (body.amount, body.price, body.unit_amount). A Price id picked from a menu the client sends is PAY-07.

**Why it matters**

The browser is not a pricing engine. If unit_amount is body.amount, the buyer sets the price. This shows up in every vibe-coded checkout that 'just passes the number from the button'.

**Fix**

Create Prices in the Stripe Dashboard and reference them by id from server env (STRIPE_PRICE_PRO). If you must use price_data, the amount has to be a constant or a server-side lookup in your database, never a field from the client.

**Fix prompt**

> Change checkout so the amount charged cannot be influenced by the request body. Use a Stripe Price id from server env or a server-side catalog. Delete unit_amount: body.amount and any client-supplied price. Keep the product name and amount in Stripe, not in the button.

### PAY-03 — Live and test Stripe keys are not mixed or committed

- **Severity:** critical
- **Edition:** lite
- **Automated:** yes

**Detection**

Fail if sk_live_ or rk_live_ appears in the repo outside a placeholder .env.example. Fail if both sk_test_ and sk_live_ appear as literals. Fail if a client file contains a secret key. Publishable keys (pk_test_, pk_live_) may appear as NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY. Confirm the secret's prefix matches the Vercel environment: test keys on Preview, live keys on Production.

**Why it matters**

A live secret in a Preview deployment charges real cards from a branch build. A test webhook secret on Production rejects every real event, so customers pay and the app never upgrades them. Committed keys are leaked keys.

**Fix**

Use sk_test_ and whsec_ test secrets in .env.local and Vercel Preview. Use live values only in Vercel Production. Never commit either. Gate any test-mode banner on the publishable key prefix so production cannot show 'test mode' by accident.

**Fix prompt**

> Remove committed Stripe secrets. Wire STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET so Preview uses test values and Production uses live values. Delete any fallback literal such as process.env.STRIPE_SECRET_KEY ?? 'sk_test_...'. Tell me which committed values need to be rolled in the Stripe Dashboard without repeating the secrets.

### PAY-04 — Webhook handlers are idempotent

- **Severity:** high
- **Edition:** lite
- **Automated:** yes

**Detection**

The webhook file, or a module it imports, must record the Stripe event id before fulfilling. That can be a processed_events or stripe_events table, an idempotency keyword, an insert or upsert whose payload includes event.id or event_id, or a unique constraint on event_id. Fail handlers that grant access and only then return 200, with no dedupe.

**Why it matters**

Stripe retries when your response is slow or not a 2xx, and it can deliver the same event more than once even when you returned 200. Without a unique event id, you double-credit, double-email, and flip subscriptions twice.

**Fix**

Create a table stripe_events (id text primary key, type text, received_at timestamptz default now()). Insert event.id first. On unique violation, return 200 immediately. Fulfill only after the insert succeeds. RLS on that table should allow no browser role; write it with the service role.

**Fix prompt**

> Make the Stripe webhook idempotent. Add a stripe_events table keyed by event id, insert event.id before changing the user's plan, and return 200 without fulfilling again when the insert conflicts. Keep this table off the browser client.

## SEO and sharing

### SEO-01 — The root layout exports a title and description

- **Severity:** high
- **Edition:** lite
- **Automated:** yes

**Detection**

app/layout.tsx (or src/app/layout.tsx) must export metadata or generateMetadata with both title and description. A <title> typed by hand in <head> inside the App Router is a miss; the metadata API is what Next expects. Pages that are unique should override the title.

**Why it matters**

Empty titles show the deployment URL in Google and in Slack. The root metadata is the default for every route you forget to customize, including the one you share on launch day.

**Fix**

export const metadata = { title: { default: 'Fieldnote', template: '%s · Fieldnote' }, description: 'One sentence a stranger understands.' }. Override title and description on marketing pages. Keep private pages noindexed (SEO-08) instead of writing clever titles for them.

**Fix prompt**

> Add metadata (title and description) to the root app layout via the Next.js metadata API, with a title template for inner pages. Write a real description. Do not leave the create-next-app defaults.

### SEO-02 — sitemap.ts and robots.ts exist

- **Severity:** high
- **Edition:** lite
- **Automated:** yes

**Detection**

Require app/sitemap.ts (or sitemap.js / public/sitemap.xml) and app/robots.ts (or public/robots.txt). Both empty files fail. The sitemap function must return at least the marketing URLs. See SEO-10 for what robots disallows.

**Why it matters**

Without a sitemap, launch-week indexing is slow and incomplete. Without robots, you also fail to tell crawlers to stay out of /api and /dashboard, so private URLs show up in search.

**Fix**

Add app/sitemap.ts that returns absolute URLs using metadataBase. Add app/robots.ts with allow / and disallow /api, /dashboard, /account, /billing, and other private prefixes. Do not disallow /.

**Fix prompt**

> Add app/sitemap.ts listing the public marketing URLs as absolute URLs, and app/robots.ts that allows / and disallows /api plus private app routes. Do not disallow the whole site.

## Analytics and ops

### OPS-01 — Error tracking is installed

- **Severity:** high
- **Edition:** lite
- **Automated:** yes

**Detection**

Require a project dependency or an initialized SDK: @sentry/nextjs, @highlight-run, bugsnag, rollbar, or Datadog RUM/logs. A console.error wrapper with nowhere to send it does not count. Check that the DSN is an env var, not a secret committed in source, and that sentry.server.config and sentry.client.config (or the equivalent) both exist for Next.

**Why it matters**

Vercel logs expire and do not group stack traces. The first failed webhook or hydration error after launch is invisible unless someone happens to have the tab open. You cannot fix what you never see.

**Fix**

Install @sentry/nextjs and run the wizard, or wire the SDK you already pay for. Set SENTRY_DSN in Vercel Production and Preview. Upload source maps in CI. Do not send the service-role key or Stripe signatures in extra context.

**Fix prompt**

> Install error tracking that runs in the browser and on the server (Sentry or the SDK this repo already uses). Read the DSN from env. Add it to .env.example. Do not log secrets, card data, or full request bodies in error context.

### OPS-02 — Privacy policy and terms pages exist

- **Severity:** high
- **Edition:** lite
- **Automated:** yes

**Detection**

Require a route for privacy (app/privacy/page.tsx or app/legal/privacy/page.tsx) and a route for terms (app/terms/page.tsx or app/terms-of-service/page.tsx). Fail placeholder lorem and fail a footer link that 404s. Stripe Checkout and many analytics tools expect both URLs.

**Why it matters**

You are storing account data in Supabase and payment data in Stripe. A privacy page is the minimum disclosure of what you collect and who you share it with (Supabase, Stripe, Vercel, the error tracker). Terms are what you point at when a billing dispute starts.

**Fix**

Publish /privacy and /terms in the same app so they share the production domain. Name the processors you actually use. Link both from the footer and from the signup form. This is not a substitute for a lawyer if you are unsure what you must say.

**Fix prompt**

> Add /privacy and /terms pages and link them from the footer and signup. Name Supabase, Stripe, Vercel, and the error tracker if those are in use. Remove placeholder copy. Do not invent legal claims; leave a short TODO where counsel still needs to review.

## Performance

### PERF-01 — Content images use next/image

- **Severity:** medium
- **Edition:** lite
- **Automated:** yes

**Detection**

Flag raw <img> in app/, components/, and src/ outside of files that are email templates or OG image markup. Require next/image for content images. An <img> inside next/og ImageResponse JSX is a false positive; waive that file.

**Why it matters**

Raw img tags ship the original bytes. Phone screens download desktop PNGs, layout shifts when the image arrives, and LCP misses the launch-post audience on slow connections.

**Fix**

Import Image from next/image. Set width and height or fill with a sized parent. Add remote hosts to images.remotePatterns (PERF-04). Do not set unoptimized globally to silence a config error.

**Fix prompt**

> Replace content <img> tags with next/image, with width and height or fill. Add any remote hosts to images.remotePatterns. Do not set images.unoptimized to true for the whole app.

