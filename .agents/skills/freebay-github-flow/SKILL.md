---
name: freebay-github-flow
description: Use when creating or organizing FreeBay GitHub issues, opening pull requests, or promoting an integration branch to master.
---

# FreeBay GitHub Flow

## Preflight

1. Read `AGENTS.md`, then inspect `git status`, remotes, the default branch, existing issues, PRs, and CI workflows.
2. Discover the default branch from GitHub and confirm the integration branch with the user. Never infer branch roles from names or create a permanent integration branch unless requested.
3. Keep unrelated worktree changes intact. Stop only when they directly conflict with the operation.

Preflight is complete when the repository, integration branch, target branch, worktree state, and existing trackers are known.

## Issues

1. Search open and closed issues before creating one.
2. Create one issue per independently verifiable outcome. Use an epic only for a multi-issue goal.
3. Include observed behavior, expected behavior, scope, acceptance checks, dependencies, and relevant labels.
4. Link child issues from their epic and link release-blocking epics from the release tracker.
5. Ask for confirmation before publishing a batch of issues unless the user already approved the exact batch.

Issue tracking is complete when every outcome has one non-duplicate issue and every dependency is linked.

## Pull Requests

1. Fetch remote refs and inspect the complete base-to-head diff.
2. Run the repository checks required by `AGENTS.md`; report any unavailable device or external-service checks.
3. Push only after user approval. Open the PR with linked issues, verification results, risks, and explicit exclusions.
4. Use the confirmed integration branch as the PR head and the discovered default branch as the release target.

The PR is ready when its diff is intentional, linked issues required for the promotion are closed, and required CI checks pass.

## Merge

1. Recheck PR approval, checks, conflicts, open blocking issues, and target branch immediately before merging.
2. Ask for explicit merge confirmation. Use a merge commit unless the user selected another repository-supported method.
3. Never force-push, bypass required checks, amend published history, or delete an integration branch without approval.
4. After merge, verify the remote target contains the merge and report the PR URL and resulting commit.

Promotion is complete only when GitHub reports the PR merged and the target branch contains the result.
