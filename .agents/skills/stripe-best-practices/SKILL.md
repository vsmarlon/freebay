---
name: stripe-best-practices
description: Use when designing, implementing, or reviewing Stripe payments, Checkout, Connect, billing, tax, Treasury, keys, webhooks, or API upgrades.
---

# Stripe integration guardrails

Use current official Stripe documentation for versioned API/SDK details; this skill is a routing and safety layer, not a version source. Read only the relevant `references/*.md` before integration work.

- Prefer restricted keys and least privilege; keep secrets out of source, logs and reports. Instantiate a `StripeClient`; do not use deprecated global key configuration.
- Never omit the signed webhook/idempotency design from payment fulfillment. Fulfillment must rely on verified events and correct asynchronous payment status, not success-page navigation.
- Do not set `payment_method_types` except the documented Terminal case; prefer dynamic payment methods/configuration. Before enabling Stripe Tax, confirm the account’s active registrations and read `references/tax.md`.
- Choose API by actual flow: Checkout Sessions for one-time payments, Setup Intents for saving methods, Accounts v2 for Connect; consult routing table/references for edge cases.
- Marketplace charge pattern, fee economics, liability and merchant relationship need explicit analysis; see `references/connect.md`. Keep money behavior read-only unless expressly authorized.

This repository currently uses Stripe paths; that does not prove real settlement, refunds, fulfillment or seller payouts. Read `docs/FEATURE_TRUTH.md` before FreeBay capability claims. Do not infer a crypto/Monero payment flow.
