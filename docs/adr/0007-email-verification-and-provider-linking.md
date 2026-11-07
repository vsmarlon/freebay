# 7. Email verification and provider account linking

Date: 2026-11-06

## Status

Accepted

## Context

Password registration stores `emailVerified: false` and sends no verification
email, while login does not require verification. Google and Apple sign-in
auto-link to any existing account with the same email, trusting only the
provider's `email_verified` claim. An attacker can register a victim's email
first and keep password access; when the victim later uses the provider button,
the session lands in the attacker's account (orders, wallet, chats).

## Decision

1. Registration issues an email verification code and the account stays
   unverified until the owner consumes it.
2. Provider sign-in may link to an existing local account only when that local
   account is already verified, or when no local account exists (the provider
   email then creates a verified account).
3. An unverified local account must complete email verification before a
   provider identity is linked to it.
4. Selling, receiving payouts, and placing orders require a verified account.

## Consequences

- New endpoints and UI: request/consume email verification, resend limits,
  localized copy, and a verification gate on the money paths.
- Existing unverified accounts must verify before transacting; support needs a
  resend path.
- Social browsing remains available while unverified; only money actions gate.
- The provider-link rule is enforced server-side, not in either client.
