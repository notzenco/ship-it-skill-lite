---
name: ship-it
description: Use when the user is about to launch or ship a Next.js app that uses Supabase, Stripe, or Vercel and the free Ship-It checklist is installed, or when they ask for a pre-launch, RLS, webhook, or SEO check.
---

# Ship-It (lite)

Audit the app before launch. The deliverable is a scorecard, not a refactor. This is the free edition: 15 checks.

## When to use

Use this when the user wants to ship, launch, or review production readiness of a Next.js app that uses Supabase, Stripe, or Vercel.

Skip it for a library with no app, or a question about one line of code.

## What to read

- `references/checks.md` — the 15 checks. Each one has a detection method, why it matters, the fix, and a paste-ready prompt.
- `references/report-template.md` — the scorecard and the scoring rubric.

## Steps

1. Find the app root: the directory with `package.json` and `app/` or `src/app/`. Do not audit `node_modules` or `.next`.
2. Walk every check in `references/checks.md`. Open the files the detection step names. Record file and line.
3. Mark a check not applicable only when that integration is absent. Missing Stripe means the PAY checks are not applicable. A missing webhook on an app that charges cards is a failure.
4. Write `SHIP-IT-REPORT.md` from `references/report-template.md`. Order failures critical, then high, medium, low.
5. Lead the chat reply with the verdict, the score, and the critical findings.
6. Do not change application code unless the user asks. Do not print secret values.
7. If the user asks to fix findings, do criticals first, then highs. Re-read the checks after each fix.

## Do not

- Trust a price, user id, or redirect target from the browser.
- Treat a dashboard-only RLS toggle as done when there is no migration.
- Call the launch ready while a critical check is still failing.

The free edition stops here. Webhook idempotency beyond the signature, subscription sync, security headers details, and the usual deploy traps are a larger catalog.
