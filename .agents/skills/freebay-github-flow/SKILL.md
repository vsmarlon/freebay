---
name: freebay-github-flow
description: Use when creating FreeBay GitHub issues, opening pull requests, or promoting an integration branch.
---

# GitHub workflow

Read root `AGENTS.md`; inspect status, remotes, default branch, full diff, related issues/PRs and CI. Discover branch roles from GitHub and confirm the target with the user; keep unrelated changes untouched.

- **Issues:** search open/closed issues first; one issue per independently verifiable outcome, link dependencies, include observable behavior and acceptance checks. Ask before publishing a batch unless the exact batch is approved.
- **PR:** run applicable repo gates and report blocked device/services. Push only with approval; describe evidence, risk and exclusions.
- **Merge/promotion:** recheck approval, checks, conflicts and blockers immediately before; obtain explicit merge confirmation. Never force-push or bypass checks.

Complete only when the requested GitHub action is actually confirmed; report URL and resulting revision where applicable.
