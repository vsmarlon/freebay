# ADR-0001: Stripe PaymentSheet Migration (Mobile) Alongside Checkout Sessions (Web/Cart)

**Status:** Accepted

## Context

FreeBay accepted card payments through Stripe **Checkout Sessions** only: the frontend posts to
`POST /payments/checkout/:orderId`, gets a `checkoutUrl`, and opens it in an in-app webview. That flow
works on web but is a poor mobile experience — users are bounced out of the app into a browser-hosted
page.

The mobile app needed a native payment surface. Two designs were considered:

1. **Keep Checkout Sessions everywhere** and accept the webview UX on mobile.
2. **Dual flow:** keep Checkout Sessions for web and cart (which uses a webview today), and introduce
   Stripe **PaymentIntent + PaymentSheet** for the mobile single-product checkout, branched at runtime
   on `kIsWeb` in `payment_page.dart` (and gated Stripe SDK init in `main.dart`).

## Decision

(2). Mobile single-product checkout creates a PaymentIntent (`POST /payments/payment-intent/:orderId`)
and presents it natively with `flutter_stripe`'s PaymentSheet. Web and cart keep Checkout Sessions
unchanged — the cart checkout page (`cart_checkout_page.dart`) is deliberately **not** modified in this
migration.

Key decisions inside that flow:

- **`_handleCompleted` PAID idempotency guard** — before running the completion `$transaction`
  (`updateInventoryOnSale` / `markAsPaid` / `confirm` / `creditPending`), `process-webhook.usecase.ts`
  checks `transaction.status === 'PAID'` and returns `processed: true` without touching the DB. The
  Redis dedupe in `webhook.guard.ts` keys on a `stripe-webhook-id` request header, which **v1
  Stripe-Signature webhooks never send** — so the guard is the real duplicate-completion protection for
  Stripe retries (Stripe retries webhooks on non-2xx, e.g. when a notification call throws after the
  `$transaction` already committed). The two `notify*` calls stay outside the try/catch by design: a
  notification throw now produces a 500, Stripe retries, and the PAID guard short-circuits the retry
  instead of double-crediting the wallet.
- **`cs_` short-circuit in the PaymentIntent usecase** — `CreatePaymentIntentUseCase` first reads the
  order's `Transaction` row (`orderId` is `@unique`). If a Checkout Session (`externalId` starting with
  `cs_`) is already PENDING for that order, it rejects with `BAD_REQUEST` instead of creating a
  PaymentIntent, so the single unique `externalId` column is never silently overwritten by the other
  flow. A PENDING `pi_` transaction **replays** the stored idempotency key to Stripe rather than
  short-circuiting (Stripe dedupes the retry and returns the same PaymentIntent). PAID → "Order already
  paid"; any other existing transaction → "Order is not payable".
- **`receipt_email`, never `customer_email`** — `paymentIntents.create` returns HTTP 400 when given
  `customer_email`; the provider passes `receipt_email` (optional, from the buyer profile).
- **Card-only** — `automatic_payment_methods: { enabled: true }` without a Google Pay config in
  `SetupPaymentSheetParameters`, so the sheet presents card payment only. No Apple Pay/Google Pay in
  this pass.
- **`payment_intent.canceled` → expired handler** — the webhook handler maps `payment_intent.canceled`
  to the same `_handleExpired` path as `checkout.session.expired` (mark failed, cancel order, restore
  inventory). Dismissing the PaymentSheet is **not** a cancel — the PaymentIntent stays in
  `requires_payment_method` for ~24h and the user can retry; `canceled` fires only on explicit cancel or
  automatic expiry. `payment_intent.payment_failed` is logged and treated as unprocessed (no state
  change).
- **Stripe dashboard must subscribe** `payment_intent.succeeded`, `payment_intent.canceled`, and
  `payment_intent.payment_failed` in addition to the existing `checkout.session.completed` /
  `checkout.session.expired`.

## Consequences

- **Deployment path is `prisma db push`**, not `prisma migrate`. The migration history has no baseline
  for the `Transaction` table (it was created via db push before migrations existed), so
  `prisma migrate` cannot be used going forward. The new migration
  (`20260805000000_payment_intent_columns`) adds the `idempotencyKey` / `checkoutUrl` /
  `checkoutExpiresAt` columns with `IF NOT EXISTS` guards so it is replay-safe on a DB that already has
  them.
- The webhook whitelist now covers five events; the controller extracts `orderId` from
  `event.data.object.metadata` for all of them (PaymentIntents carry `metadata.orderId` the same way
  Checkout Sessions do) and drops the old `sessionId`/`paymentStatus` payload fields — the usecase never
  read them.
- The Checkout Session path now records `paymentMethod: 'CREDIT_CARD'` (was `'PIX'`) to match what is
  actually being paid with.
- WHY comments that keep the next reader honest: `main.dart` gates Stripe init on `kIsWeb` +
  `isNotEmpty` because `Stripe.publishableKey`'s getter throws `StripeConfigException` when unset, and
  `applySettings()` must only run once the key is set; the create-payment-session integration spec
  keeps its "Update buyer CPF for the payment info lookup" comment as a non-obvious prerequisite.
