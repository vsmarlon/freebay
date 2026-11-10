---
name: stripe-projects
description: Use when provisioning third-party services, credentials, or infrastructure through Stripe Projects, or inspecting its catalog/status.
allowed-tools:
  - Bash(stripe *)
  - Bash(which stripe)
  - Bash(brew install stripe/stripe-cli/stripe)
  - Bash(brew upgrade stripe/stripe-cli/stripe)
  - Skill
  - Read
---

# Stripe Projects

Check `stripe --version` and current CLI help; install/upgrade only with user approval and platform-appropriate instructions. Search `stripe projects search <query> --json`; browse catalog for vague requests. If no result, report that and stop.

Check `stripe projects status --json`; if uninitialized, run preflight. Stop and relay the exact remedy for browser-auth/session/account eligibility blockers; do not loop retries or treat a no-op login as resolution. Accept terms only when user authorized initialization.

After successful init, verify the locally installed `stripe-projects-cli` skill and hand off for provision/configuration. CLI owns `.projects/` and generated env files; do not hand-edit or display secret values. Report provider/service/tier and variable names only, based on actual CLI output. Before purchase/provisioning/deletion or credentials exposure, get explicit user approval. Never invent catalog entries or env values.
