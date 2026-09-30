---
name: upgrade-stripe
description: Use when upgrading Stripe API versions, server SDKs, Stripe.js, or mobile SDKs.
---

# Stripe upgrade

Always fetch the current changelog and official upgrade guide for the requested source/target versions; the version in this document is not authoritative. Identify account API version, SDK version and language before changes.

1. Enumerate breaking changes and webhook payload impact between versions.
2. Upgrade SDK and API version explicitly where supported; strongly typed SDKs may bind types to SDK release version—follow their current docs.
3. Test against the target API version in test mode/header before switching production defaults. Update webhook parsing and unknown-event handling.
4. Update Stripe.js/mobile SDK only when in scope; check their separate versioning rules.
5. Run focused payment/webhook tests and applicable repo gates; report staged rollout, exact versions and remaining risks.

Never expose test/secret keys in examples that could be mistaken for credentials. Preserve signed-webhook verification and idempotency.
