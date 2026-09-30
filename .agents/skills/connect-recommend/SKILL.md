---
name: connect-recommend
description: Use when recommending Stripe Connect configuration, account onboarding, charge patterns, seller payouts, or multi-party payment flows.
---

# Connect recommendation

Read [terminology rules](references/terminology-rules.md) before user-facing wording. Establish business model first; research a provided company URL/description, then scan existing project integration. Ask one decision at a time, reuse confirmed inputs and disclose assumptions. Read [company research](references/company-researcher.md), [decision matrix](references/decision-matrix.md), [discovery questions](references/discovery-questions.md), and [charge patterns](references/charge-patterns.md) when those branches apply.

Validate `(dashboard, fees_collector, losses_collector, charge pattern)` against [compatibility matrix](references/compatibility-matrix.md) before recommending; never present blocked tuples. Keep risk management separate from negative-balance liability. Respect hold-and-release constraints and explain platform fee economics, including the distinction between application fees and net transfers. Read [account types](references/account-types.md) for Accounts v2 configuration.

Produce a concise plan using [recommendation template](references/recommendation-template.md); include code-vs-Dashboard ownership, onboarding, webhooks, transfer/reversal and operational monitoring. Ask for confirmation and concrete next action. Do not initiate money movement or claim payout readiness without evidence.
