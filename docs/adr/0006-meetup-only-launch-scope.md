# 6. Meetup-only launch scope

Date: 2026-11-06

## Status

Accepted

## Context

FreeBay's order lifecycle already assumes in-person handover: `Order` carries
`meetingScheduledAt` and `deliveryConfirmedAt`, the buyer confirms receipt, and
escrow releases after confirmation. The schema has no address, carrier,
tracking, shipping-cost, or label fields, and neither client has a shipping UI.

Shipping would change the money split, the dispute evidence model, the address
PII surface, and require carrier/provider decisions that do not exist yet.

## Decision

The first public release supports **meetup delivery only**. Buyers and sellers
arrange the handover in chat; the buyer confirms receipt to release escrow.
No address, carrier, tracking, label, or shipping fee is part of the launch
contract. Listings and checkout copy must not promise shipping.

## Consequences

- Sellers and buyers keep exchanging addresses only if they choose to, inside
  chat; the product does not collect or store a shipping address.
- Shipping becomes a separate, owner-approved product decision with its own
  schema, money-split, dispute-evidence, and retention work.
- Until then, `PATCH /orders/:id/ship` must not imply carrier tracking.
