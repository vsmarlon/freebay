# Web architecture instructions

Read the root [AGENTS.md](../AGENTS.md), [DESIGN.md](DESIGN.md), [README.md](README.md), and
[ARCHITECTURE.md](ARCHITECTURE.md) before a web change. Preserve the React Router 7,
React 19, TanStack Query, and Tailwind 4 stack. Do not copy Flutter layers mechanically.

## Dependency directions

- `app/core/` contains genuinely application-wide capabilities: authenticated HTTP, session, locale,
  routes, media, and query-key primitives. Feature-specific behavior does not go here.
- `app/components/` contains reusable, domain-agnostic UI and browser adapters. UI primitives must not
  import a business feature.
- `app/features/<name>/domain/` contains pure business logic, types, and selectors when needed. No React,
  transport, browser globals, query client, or persistence. A feature without complex rules may omit it.
- `app/features/<name>/data/` contains API contracts, adapters, endpoint requests, and runtime response
  validation when needed. Never mount components or own UI state here.
- `app/features/<name>/application/` contains feature hooks, query definitions, mutations, and workflows.
  TanStack Query is canonical server-state storage. Domain utilities do not import application modules.
- `app/features/<name>/presentation/` contains feature components and route surfaces. It can use feature
  application hooks, domain types, and shared components. Do not reach into HTTP or repositories.
- Existing feature files outside these optional folders are migration targets, not proof of correctness.
  Migrate by cohesive user journey, not mass renames.

## React code rules

- Every piece of state has one owner. Remote state: Query/Router loader. URL state: Router/search params.
  Persistent browser preference: a dedicated storage adapter. Component state: ephemeral UI only.
- A component may define event handlers; React does not eliminate `onClick` or `onChange`. Remove
  redundant handlers and effects, not genuine interaction logic. Prefer semantic forms and native controls.
- `useRef` is permitted for imperative browser APIs (media, canvas, focus, pointer capture), not as
  an alternative state store. Prefer controlled fields, callback refs where lifecycle wiring is needed,
  and `useSyncExternalStore` for genuine external stores.
- No broad `unknown` recursion across unrelated API response shapes. Define and validate concrete
  endpoint contracts at the data boundary; patch typed Query caches with explicit keys.
- No arbitrary `as` assertions to fix component typing. Use literal values, typed component boundaries,
  explicit parsers, and narrow the actual source of uncertainty.
- Do not add wrapping services, interfaces, repositories, helpers, hooks, barrels, or layers for a single
  trivial expression. Cohesion and source-of-truth matter more than folder counts.
- No diagnostic slogans (`ponytail:`, `TODO AI`, `hack`, generic narration). Comments explain WHY:
  invariants, constraints, concurrency, security, accessibility, or non-obvious browser behavior.
- Preserve SSR boundaries, auth cookie flows, session generation, pagination, money in integer cents,
  locale routing, and the backend's authorization decisions.

## Acceptance checklist

For each edited journey: identify the actual duplication or coupling; establish behavior before the
change; migrate without behavior drift; add only focused regression tests; run scoped TypeScript, ESLint,
Prettier, relevant Vitest file, and affected build/e2e gates when available. For visual changes retain
the screenshot proof required by root AGENTS.md. Record commands and failures precisely. Do not claim
runtime speedups without measured before/after evidence.

When adding a feature capability, explain its boundary owner and public contract in the PR. Disallow
new deep imports into other feature internals; use the feature's public API. Legacy deep imports should
be retired incrementally with their consumers.
