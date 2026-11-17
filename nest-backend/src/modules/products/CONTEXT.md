# Products — Glossary

## Language

**Product listing**:
A seller's offer of one item for a price, with a condition, an optional category, media, and a quantity.

**Listing state**:
The single lifecycle position of a listing, stored in `Product.status`: `ACTIVE`, `PAUSED`, `SOLD`, or `DELETED`.

**Seller pause**:
An `ACTIVE` listing the seller chose to hide while keeping it resumable. Stored as `PAUSED` with pause reason `SELLER`.

**Reservation hold**:
A `PAUSED` listing with pause reason `RESERVED`, claiming the last unit for one open order. Only that order's cancellation or expiry releases it; the seller may not edit, resume, or delete it while held.

**Moderation removal**:
A listing removed by moderation or account purge. Stored as `PAUSED` with pause reason `MODERATION` and a non-null `deletedAt`; it is never resumable.

**Sold out**:
A listing whose sold count reached its quantity. Stored as `SOLD`; a cancelled order may return the corresponding units and re-activate it.

**Stock**:
The implicit availability, `quantity - soldCount`. A seller may not lower `quantity` below `soldCount`.

_Avoid_: using `PAUSED` alone to mean any of seller pause, reservation, or removal
