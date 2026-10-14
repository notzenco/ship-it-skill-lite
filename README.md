# Ship-It Skill

A free pre-launch checklist for **Next.js + Supabase + Stripe + Vercel** apps. You run it before you ship. The agent audits the repo and writes a prioritized scorecard with a paste-ready fix for every finding.

Fifteen checks. The ones that most often leak data or charge the wrong amount. MIT licensed. Same install in Claude Code, Codex, and Cursor.

## The three bugs this catches first

1. **The service role is in the browser.** A public env name, or a client component that imports the admin client. The anon key is meant to ship. The service role bypasses Row Level Security.
2. **RLS is off, or it exists only in the dashboard.** With RLS off, anyone who can read the bundle can read and write `public` tables.
3. **Checkout trusts the browser.** An amount taken from the request, or a webhook that parses JSON and skips signature verification.

## The 15 checks

| ID | Severity | What it looks for |
| --- | --- | --- |
| SEC-01 | critical | RLS enabled on every table in migrations |
| SEC-02 | critical | No service-role JWT or server secret committed |
| SEC-03 | critical | `NEXT_PUBLIC_` is not wrapping a secret |
| SEC-04 | critical | API routes and server actions check the user |
| SEC-05 | high | `.env.local` is gitignored, and a committed `.env` is too |
| SEC-06 | high | Security headers on responses |
| PAY-01 | critical | Stripe webhook calls `constructEvent` |
| PAY-02 | critical | Amounts are not taken from the client |
| PAY-03 | critical | Live and test Stripe keys are not mixed or committed |
| PAY-04 | high | Webhook handler dedupes on the event id |
| SEO-01 | high | Root metadata title and description |
| SEO-02 | high | `sitemap.ts` and `robots.ts` |
| OPS-01 | high | Error tracking is installed |
| OPS-02 | high | Privacy policy and terms pages exist |
| PERF-01 | medium | Content images use `next/image` |

Each check in `skill/references/checks.md` has a detection method, why it matters, the exact fix, and a prompt you can paste back into the agent.

## Install

From this directory. Claude Code and Codex install for your user. Cursor installs into the current project.

```bash
bash install.sh claude
```

```bash
bash install.sh codex
```

```bash
bash install.sh cursor
```

Windows: `./install.ps1 claude`, `./install.ps1 codex`, or `./install.ps1 cursor`.

Then ask for a pre-launch audit, or run **Ship it** in Cursor. Installing again overwrites the skill files and is safe to repeat. Pass `--project .` to install Claude or Codex into one repo instead of your user directory.

## What you get

The agent reads the checklist, opens your migrations, routes, and env names, and writes `SHIP-IT-REPORT.md`. Failures are ordered critical, then high, medium, low. Each one has a file, a reason, and a fix prompt. The score weights critical at 8, high at 4, medium at 2, and low at 1. A high-confidence critical is a "do not launch."

```markdown
# Ship-It Report (lite)

| | |
| --- | --- |
| Target | `my-app` |
| Edition | lite |
| Score | 46/100 |
| Verdict | Do not launch |

| Severity | Failed |
| --- | --- |
| critical | 3 |
| high | 2 |
| medium | 1 |

### CRITICAL SEC-01 — Row Level Security is enabled on every public table

- `supabase/migrations/001_init.sql:4` — Table notes is created without ENABLE ROW LEVEL SECURITY.

### CRITICAL PAY-01 — Stripe webhooks verify the signature

- `app/api/webhook/route.ts:8` — Webhook route does not call constructEvent.
```

## Ship-It Pro

**69 checks, a scanner, Fix-It prompts, and CI. US$29 once.**

The free edition stops at the holes that leak data or charge the wrong amount. Pro adds the rest: policies that use `auth.uid()`, rate limits, subscription sync, Open Graph and canonicals, a Fix-It library for the usual deploy failures, a Node scanner, and a GitHub Actions workflow (`--ci`, SARIF).

[Get Ship-It Pro](PRO_LINK)

Pro installs over this skill at the same path (`ship-it`). Keep the free edition until you do.

## License

MIT. See [LICENSE](LICENSE).
