# 9. Lifecycle state machines: one transition table, guarded writes, server-computed actions

Date: 2026-11-09
Status: accepted

## Context

Twelve lifecycles in the app are implicit. State is spread across status enums,
booleans, timestamps, and free-text reasons, and every reader re-derives it.
The failures repeat in three shapes:

1. **Read-check-then-write.** A use case reads the current status, decides, then
   updates by id. A concurrent transition can land between the read and the
   write. Dispute evidence and withdrawal do this today; order shipping and
   payment settlement already use the guarded pattern.
2. **Duplicate truth.** A status enum sits next to booleans or timestamps that
   answer the same question (`isVerified` vs `phoneVerified`, `CANCELLED` with
   escrow still `HELD`, payment status copied onto order, transaction, group,
   and wallet).
3. **Client re-derivation.** Flutter and web each branch on raw status and
   booleans to decide which buttons to show, so they offer actions the backend
   rejects and hide actions the backend accepts.

## Decision

Each aggregate with a lifecycle owns one pure domain module containing:

- the persisted enum as the **only** state (missing composite states become
  explicit enum values, never a derived tuple);
- a transition table of `from -> event -> to`, with guard predicates and side
  effects named;
- `availableActions(state, actor, context)` derived from the same table.

Every state-changing write goes through one guarded repository helper that
compiles a transition into a conditional `updateMany` with the expected `from`
state and the guard predicates in the `where` clause. Zero rows updated is a
conflict; there is no read-then-write path for a state change.

Read models expose the persisted `status` plus, per viewer, an `allowedActions`
list computed by pure predicates shared with the transition use cases. Clients
render and gate on `allowedActions`; they do not branch on status, booleans, or
timestamps to decide what a participant may do. Where a provider precondition
cannot be expressed by a predicate, the write use case still re-checks it
before writing.

No state-machine library. Transitions execute in the database, so an in-memory
machine would add a second source of truth and a second place to keep the
guards.

## Consequences

- The API change is additive: existing fields stay until every reader is gone.
- Flutter and web must ship with the backend that emits `allowedActions`. A
  missing list means "no actions", never "fall back to local rules", so a
  half-deployed client cannot invent a transition.
- Dead fields that encoded no lifecycle (`Order.meetingScheduledAt`,
  `Report.hideFromUser`, `User.isGuest`, `ConversationPreference.deletedAt`)
  were removed once their last reader was deleted.
- Money-moving lifecycles (order, escrow, dispute, payment) are migrated first;
  social lifecycles follow the same table shape without a shared framework.

## Alternatives considered

- **XState or a shared spec with codegen.** Rejected: the authoritative
  transitions already live in SQL predicates. A generated machine would
  duplicate them in TypeScript and Dart and drift on the first hotfix.
- **Keep per-client derivation and only strengthen backend guards.** Rejected:
  it fixes double-spend but leaves dead buttons, stalled mobile orders, and
  three different answers for the same order state.
