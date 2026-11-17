# FreeBay Web Architecture

Status: incremental migration, **not** a claim that all existing files follow this model.

FreeBay is one product with two clients: `frontend/` (Flutter, Riverpod and Dio) and `web/`
(React Router, TanStack Query, browser HTTP). Both call the same NestJS REST and Socket.IO
backend. Backend authorization, lifecycle transitions, money, and privacy are authoritative.
Share HTTP contracts and business concepts across clients, not UI framework state.

## Dependency map

```text
React Router routes / feature presentation
                   |
                   v
        feature application hooks
             /             \
            v               v
      pure domain         feature data (API adapters)
                                |
                                v
                       core HTTP/session bridge
                                |
                                v
                         NestJS backend

shared UI components <- presentation only
```

`app/core` is **platform infrastructure**, not a dumping ground for business helpers.
`app/components` is **domain-independent UI**. Feature internals stay private; other
features may consume only public exports, preferably types or small feature surfaces.

## Optional feature layout

```text
app/features/social/
  index.ts                 # Public cross-feature contract
  domain/
    mentions.ts            # Pure text transformations
    mentions.test.ts
  data/                    # API requests, wire schemas, mappers (when useful)
  application/             # TanStack Query keys, queries, mutations, workflows
  presentation/            # Pages, post composer, media, dialogs
  routes.ts                # Router integration
```

Use layers when responsibilities need separation. A simple route can stay a route; do not
force empty folders or use cases that only forward one API method.

## Source-of-truth rules

| Concern | Owner |
| --- | --- |
| Server resources, pagination, mutation invalidation | TanStack Query or Router loaders |
| Authentication, access token exchange | Core session and HTTP client |
| URL-driven filters | React Router search params |
| Form draft and disclosure state | Closest React component/form |
| Socket subscriptions | Feature application hooks with cleanup |
| File/media DOM APIs | Focused browser adapter or component ref |
| Business calculations and transitions | Feature domain, server authoritative |
| Wire parsing and mapping | Feature data boundary with Zod where critical |
| Accessibility and responsive design | Shared UI primitives and presentation |

Keep one path for each operation. Do not create shadow stores, copied query caches,
new event buses, context wrappers around every hook, or duplicate JSON models just to
make a folder graph look symmetrical.

## Current migration candidates

1. Shell: split sidebar persistence/resize, navigation, search, and mobile chrome into
   cohesive components and external-system hooks; preserve SSR hydration and pointer capture.
2. Social: post composer, mentions, media selection, and typed mutation caching. Feed route
   should compose surfaces, not own image-editor and mention-input internals.
3. Marketplace: detail route owns too many query/mutation states; consolidate typed query
   options and product actions, preserve public SSR loader and price contracts.
4. Session: keep auth generation and cross-tab invalidation semantics while isolating
   transport, synchronization and provider responsibilities.
5. Chat: keep socket subscriptions, optimistic updates, scrolling, audio recording and
   view-once leases in focused workflows; never merge independent privacy lifecycles.
6. Commerce: preserve webhook settlement semantics, order states, integer cents, and
   idempotency. Extract only after capturing existing behavior.

## Enforcing the model

`web/eslint.config.js` applies strict dependency restrictions to new `domain/` and
`presentation/` directories. This prevents reintroducing direct HTTP/data imports from
presentation and framework imports from the domain. Existing legacy locations are not
silently grandfathered as 'clean'; they must migrate, with scoped changes and tests.
Extend the rule set once consumers are migrated so no permanent allowlist accumulates.

## Performance evidence

Measure p75/p95 page interactions, client JS payload, image bytes, navigation fetches,
feed renders, and session/Socket.IO churn before optimizing. Use React Profiler,
Lighthouse/real-device timings, Vite bundle reports and actual user journeys. A 10× goal
needs an explicitly named workload and measured baseline. Removing React state or
rewriting components does **not** by itself prove a 10× result.
