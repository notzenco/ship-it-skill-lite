# Ship-It report template (lite)

Write this to `SHIP-IT-REPORT.md`. The free edition has 15 checks. Say so at the top, so nobody thinks the list was the whole launch.

```markdown
# Ship-It Report (lite)

| | |
| --- | --- |
| Target | <app root> |
| Edition | lite |
| Date | YYYY-MM-DD |
| Score | <0-100>/100 |
| Verdict | <Ready to launch \| Fix high and critical findings first \| Do not launch> |

15 checks. Passed <n>, failed <n>, not applicable <n>.

## Summary

| Severity | Failed |
| --- | --- |
| critical | 0 |
| high | 0 |
| medium | 0 |
| low | 0 |

## Do these before launch

### CRITICAL SEC-00 — Title

**Where**

- `path/file.ts:line` — what was found

**Why it matters**

From the check.

**Fix**

The concrete change.

**Paste this**

> The fix prompt, with the file you found.

## Passed

- SEC-00 — title

## Not applicable

- SEC-00 — why
```

## Rubric

| Severity | Weight |
| --- | --- |
| critical | 8 |
| high | 4 |
| medium | 2 |
| low | 1 |

`score = round(100 * weight of passes / weight of passes and fails)`.

| Score | Verdict |
| --- | --- |
| 90–100 | Ready to launch |
| 70–89 | Fix high and critical findings first |
| 0–69 | Do not launch |

Not applicable stays out of the ratio. Do not print secret values. Do not change code unless the user asks.
