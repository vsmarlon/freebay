# Root read-only verification — 2026-09-30

**Revision:** `c9808b106c3d53f07837542e93f25fd52c6bfbe5` (`HEAD` at verification time). No source or test files were edited by this verification. No credentials were used. `make test` was not run because the parallel backend/frontend gates were still active; this avoids duplicate DB-test/CPU load.

## Working-tree identity

Captured before creating this report. `git status --porcelain=v1 -uall` contained 262 entries (tracked, deleted, and untracked), SHA-256 `74708766bba21601a7478ecb129d9a4ea7ebb2168e96fb9fd6a665ff2eab78b2`. The detailed paths and status codes were emitted by that command during the verification; they include extensive user WIP across frontend, backend, docs, and scripts. No user changes were staged, restored, or otherwise modified by this verification. This hash is the status-line manifest digest, not a source-content digest.

Commands:

```text
git rev-parse HEAD
c9808b106c3d53f07837542e93f25fd52c6bfbe5

git status --porcelain=v1 -uall | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const xs=s.trimEnd().split(/\r?\n/); const crypto=require('node:crypto'); console.log(JSON.stringify({entries:xs.length,sha256:crypto.createHash('sha256').update(xs.join('\n')+'\n').digest('hex')}))})"
{"entries":262,"sha256":"74708766bba21601a7478ecb129d9a4ea7ebb2168e96fb9fd6a665ff2eab78b2"}

git ls-files -u
(no output; zero unmerged index entries)
```

## Checks

### `node scripts/ci-check.js` — exit 1

```text
Design ratchet additions:
[
  {
    "file": "frontend/lib/features/orders/presentation/pages/orders_tab.dart",
    "specifier": "EdgeInsets.all",
    "rule": "D4"
  },
  {
    "file": "frontend/lib/features/profile/presentation/widgets/profile_tabs.dart",
    "specifier": "EdgeInsets.fromLTRB",
    "rule": "D4"
  },
  {
    "file": "frontend/lib/features/social/presentation/widgets/feed_post_list.dart",
    "specifier": "EdgeInsets.symmetric",
    "rule": "D4"
  },
  {
    "file": "frontend/lib/features/social/presentation/widgets/story_page.dart",
    "specifier": "Colors.white",
    "rule": "D3"
  },
  {
    "file": "frontend/lib/features/social/presentation/widgets/story_page.dart",
    "specifier": "Colors.white",
    "rule": "D3"
  },
  {
    "file": "frontend/lib/features/social/presentation/widgets/story_page.dart",
    "specifier": "Colors.white",
    "rule": "D3"
  }
]
```

All six reported findings are in Flutter UX working-tree files, not changes made for this root verification. The gate currently rejects those D3/D4 findings against the present design baseline; no baseline or source changes were made to suppress the failure.

### `npm run test:ci-scripts` — exit 0

```text
> test:ci-scripts
> node --test scripts/ci-check.test.js scripts/perf-check.test.js

✔ architecture gate rejects removed safe identifiers only (2.8448ms)
✔ architecture gate still detects removed repository identifiers in imports (0.1463ms)
✔ route and design gates keep their existing policy (0.333ms)
✔ design ratchet permits baseline findings and resolved findings but rejects additions (0.7239ms)
✔ design scanner catches only feature-level raw design tokens (0.8393ms)
✔ a real trace with both build and raster timings passes (1.0193ms)
✔ missing frame metrics cannot be green (0.2244ms)
✔ raster jank fails even when build timings are fast (0.103ms)
✔ 20% regression from a measured baseline fails below the absolute threshold (0.1591ms)
✔ absolute frame budgets fail at the boundary (1.1358ms)
ℹ tests 10
ℹ suites 0
ℹ pass 10
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 313.0051
```

### `git -c core.symlinks=true diff --check` — exit 0

No whitespace errors. Git emitted LF-to-CRLF working-copy warnings for changed text files; those warnings are not diff-check failures.

### Documentation and conflict checks

- Local Markdown link scan: **20 changed/untracked Markdown files, 20 local Markdown links, 0 missing targets**. It checked Markdown link syntax only; inline example paths, globs, and command fragments were not treated as links.
- `git ls-files -u`: no output.
- `rg -n '^(<<<<<<<|=======|>>>>>>>)' AGENTS.md docs frontend/AGENTS.md frontend/DESIGN.md .agents/skills/freebay-app-flows/SKILL.md .agents/skills/freebay-flutter-feature/SKILL.md scripts/ci-check.js scripts/ci-check.test.js -g '*.md' -g '*.js'`: no matches.
- `.claude/skills` is a filesystem symbolic link with target `..\.agents\skills`; both canonical and mirrored views expose 19 skill directories. `git ls-files -s .claude/skills` reports mode `120000`, blob `2b7a412b8fa0fb7e985b0793321bd4e698f2b6cd`. The persistent config remains `core.symlinks=false`; the explicit `-c core.symlinks=true` was used only for the requested diff check.

## Not run

`make test` and the backend/frontend gates were not run here. The parallel jobs were still active, so root verification intentionally did not duplicate resource-intensive work. No source/test edits, commits, pushes, staging, stash operations, or database operations were performed.
