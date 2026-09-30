# Agent skills maintenance

**Scope:** the 19 canonical `.agents/skills/**/SKILL.md` files and `.claude/skills` mirror. No application source or test files changed. Base revision: `455818164b7b87e5d57eb1dd84313eacd9ce580b`.

## Changes

- Compressed the 19 skill bodies into focused trigger, action, and completion guidance. Preserved skill names and branch discovery, with references deferred to existing authority files where useful.
- Corrected FreeBay skills to distinguish current behavior from target hardening phases: new backend use cases use concrete DB repositories; existing domain repository contracts remain; Flutter domain use cases need meaningful logic; interceptor/error behavior remains; P4/P5/P10 are not represented as implemented.
- Removed stale guest/crypto claims, inaccurate fixed animation/dark-mode guidance, large aspirational journey diagrams, and duplicated catalogs. Stripe security, signed-webhook/idempotency, capability-validation and explicit purchase-approval guardrails remain.
- Replaced the duplicate `.claude/skills` tree with a native filesystem symlink to `../.agents/skills`.

## Measured context savings

Counts cover only the 19 `SKILL.md` bodies, not their unchanged branch reference files. Original bytes were measured from Git base `4558181`; revised bytes from the working tree. Tokens are estimates (`UTF-8 bytes / 4`), not tokenizer counts. Words are whitespace-delimited.

| Skill | Before bytes | After bytes | Before words | After words | Estimated tokens saved |
|---|---:|---:|---:|---:|---:|
| connect-recommend | 23,031 | 1,536 | 2,786 | 150 | 5,374 |
| connect-required-verification-information | 28,737 | 1,856 | 3,499 | 244 | 6,720 |
| freebay-app-flows | 21,007 | 2,682 | 2,352 | 330 | 4,581 |
| freebay-backend-module | 6,410 | 2,042 | 642 | 267 | 1,092 |
| freebay-data-model | 3,699 | 1,310 | 502 | 167 | 597 |
| freebay-design-system | 2,646 | 1,098 | 342 | 141 | 387 |
| freebay-flutter-feature | 7,064 | 1,666 | 594 | 208 | 1,350 |
| freebay-github-flow | 2,501 | 1,030 | 368 | 138 | 368 |
| freebay-mobile-mcp | 6,235 | 1,073 | 846 | 136 | 1,291 |
| freebay-perf | 2,806 | 1,063 | 375 | 132 | 436 |
| freebay-prisma | 3,077 | 1,256 | 388 | 171 | 455 |
| freebay-system-design | 8,337 | 1,700 | 610 | 212 | 1,659 |
| stripe-apps | 13,273 | 1,230 | 1,981 | 140 | 3,011 |
| stripe-best-practices | 5,362 | 1,607 | 702 | 209 | 939 |
| stripe-directory | 5,680 | 1,214 | 767 | 168 | 1,116 |
| stripe-docs | 941 | 561 | 132 | 80 | 95 |
| stripe-projects | 8,362 | 1,317 | 1,239 | 167 | 1,761 |
| test-audit | 7,134 | 1,738 | 997 | 223 | 1,349 |
| upgrade-stripe | 5,823 | 1,087 | 709 | 151 | 1,184 |
| **Total** | **162,125** | **27,066** | **19,831** | **3,434** | **33,765** |

Aggregate reduction: **83.3% bytes**, **82.7% whitespace words**, approximately **33.8k estimated loaded tokens saved** when all 19 bodies are loaded. Existing reference files were preserved and are excluded from that savings figure.

## Verification record

- Before edits, complete `.agents/skills` and `.claude/skills` file-path sets and SHA-256 content hashes matched; no differing files were found.
- Tested actual PowerShell `New-Item -ItemType SymbolicLink` after verifying `.claude` parent and `.agents/skills` target. It created `.claude/skills -> ..\.agents\skills` as a filesystem symbolic link while the persistent `core.symlinks` setting remained `false`.
- The logical Claude mirror resolves all 19 `SKILL.md` files through the link. `git -c core.symlinks=true add -A -- .agents/skills .claude/skills docs/test-runs/2026-09-30/skills-maintenance/REPORT.md` staged the genuine symbolic link as mode `120000` (`.claude/skills`, blob `2b7a412b8fa0fb7e985b0793321bd4e698f2b6cd`); persistent `core.symlinks=false` remains unchanged.
- Relative Markdown links in all canonical skill bodies resolve. `git diff --check` and `git diff --cached --check` completed without whitespace errors. Git emitted LF-to-CRLF working-copy warnings for the edited Markdown files; contents and staging succeeded.

## Deviations and limits

- Detailed implementation inventories and illustrative journeys were removed in favor of `docs/FEATURE_TRUTH.md`, source, and branch references; those sources remain authoritative.
- P2/P4/P5/P10 are explicitly described as pending plan decisions, not completed work. This report records the skill-maintenance changes only, not completion of the hardening plan.
- The `connect-required-verification-information` body now defers detailed response-field/table rendering to live Stripe documentation because the former long mapping duplicated changing API response structure; validated prerequisite ordering and current-response requirements remain.
- No application code/tests were changed; no Flutter/Nest application suite was run. This is documentation-only validation.
