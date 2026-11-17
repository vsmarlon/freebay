# Chat — Glossary

## Language

**Direct conversation**:
A one-to-one thread between two users, optionally about a product. Stored with its two participants sorted by id and a nullable `initiatorId`.

**Conversation request**:
A direct conversation in `PENDING`: the initiator started it without the target following them. The initiator may send the opening message; the other participant must accept before replying.

**Active conversation**:
A direct conversation in `ACTIVE`. Both participants may send.

**Blocked**:
A relationship enforced by the `Block` table, not by conversation status. `ConversationStatus.BLOCKED` is reserved and has no writer; sending and starting are refused by the block lookup.
_Avoid_: treating `BLOCKED` as the source of truth for blocking

**Conversation preference**:
One participant's per-thread view state: archived, deleted, muted, theme, background. A new incoming message restores a deleted preference.
