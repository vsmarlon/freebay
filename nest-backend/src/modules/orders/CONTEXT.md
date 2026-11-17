# Orders — Glossary

## Language

**Order**:
A purchase of one product between a buyer and a seller, with a quantity, price, platform fee, and seller amount.

**Order state**:
The single lifecycle position of an order, stored in `Order.status`. It is the only state clients and the backend may branch on. Escrow and payment fields describe aspects of that state; they are not a second state.

**Order lifecycle**:
`PENDING → CONFIRMED → SHIPPED → DELIVERED → COMPLETED`, with `DISPUTED`, `REFUND_PENDING`, and `CANCELLED` as branches. `REFUND_PENDING` is a cancellation whose refund has not settled yet; `CANCELLED` means no money remains with the order.

**Handover**:
The customer-facing meaning of the `SHIPPED` state in the meetup-only model: the seller has asserted the in-person handover, and the buyer has not yet confirmed receipt. It does not imply a carrier.
_Avoid_: Shipping, delivery (for this state)

**Delivery confirmation**:
The buyer's assertion that the item was received. It moves `SHIPPED → DELIVERED` and starts the escrow release clock.

**Escrow release**:
The movement of held funds to the seller's available balance. It happens on `COMPLETED`, after explicit buyer confirmation or the release delay, and never on handover alone.

**Refund pending**:
The state after a cancellation is accepted and before the payment provider confirms the refund. The buyer must not see the order as simply cancelled.

**Cancellation kind**:
Why an order was cancelled — buyer request, seller request, checkout abandoned, dispute refund, or payment failure. It is separate from the free-text cancellation reason and is not itself a workflow state.

**Allowed action**:
An action the signed-in participant may take in the order's current state. The backend computes the list; clients render it instead of deriving actions from status or booleans.
