---
name: freebay-app-flows
description: Use when tracing or changing a FreeBay user journey, state transition, route, or cross-layer flow.
---

# FreeBay journeys

Before claiming or changing capability, read [`docs/FEATURE_TRUTH.md`](../../../docs/FEATURE_TRUTH.md). Trace UI -> provider/repository -> HTTP/socket -> use case -> persistence/side effect; flow descriptions are intended guides, not proof of implementation. Read [DEVICE_TESTING.md](../../../docs/DEVICE_TESTING.md) for device evidence and [`frontend/DESIGN.md`](../../../frontend/DESIGN.md) for UI rules.

## Shared invariants

- Navigate only with `AppRoutes` constants/builders. Preserve all five `AppShell` tab indexes and shell state; nested gestures must not switch tabs. Chat retains reverse scrolling, keyboard behavior, header and bottom controls.
- New UI copy uses generated `AppLocalizations`; shared state follows the frontend guidance in `frontend/AGENTS.md` (generated Riverpod providers and feature-boundary exports).
- Auth includes email/password, Google and biometrics; do not invent guest login. Token/session state is sensitive; logout and account switching must not retain user-scoped providers.
- Money is integer cents. Payment settlement is provider-webhook driven, not inferred from a checkout success screen. Stripe paths and operational readiness are distinct; no Monero/crypto flow is established.
- Enforce authorization/privacy at the backend boundary, including private media, blocked users and view-once access. Do not claim screenshot prevention or atomic single-open without evidence.

## Journey-specific checks

- **Auth/onboarding:** inspect router redirects, persisted session/onboarding flags, token refresh, biometric cancellation fallback and secure storage. Third-party sign-in requires device/provider proof.
- **Social/profile:** distinguish posts, reposts and product/listing posts; preserve privacy filters, counts, search and cursor pagination. Feed ranking is a bounded heuristic, not a personalized recommendation engine. No guest journey.
- **Stories/chat media:** readiness means media actually loaded; view-once grace and platform screenshot behavior must be stated as implemented, not assumed. Verify permissions, upload/download and playback on device.
- **Cart/payments/orders:** follow cart intent/session contract through PaymentSheet/hosted checkout, signed webhook and final order state. Pending order or opened sheet is not settled payment. Shipping/fulfillment gaps are in FEATURE_TRUTH.
- **Wallet/disputes/notifications:** inspect current status rules and provider side effects; do not promise payouts, push delivery or moderation journeys without operational evidence.

For current routes, owners, limits and journey evidence, use FEATURE_TRUTH and source. Avoid copying route matrices or sequence diagrams here; they go stale.
