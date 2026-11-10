# 8. Rank on measured signal, not guessed weights

Date: 2026-11-06

## Status

Accepted

## Context

Explore feed ranking is a hand-tuned heuristic over likes, comments, shares,
recency, and a following boost. There are no impression, dwell, or negative
feedback events, no ranking baseline, and no holdout evaluation. Changing
weights without that data is unverifiable and can reward spam.

## Decision

Instrument before ranking: emit privacy-aware impression, dwell, hide/
not-interested, follow, save, cart, and purchase events; define healthy
engagement and abuse guards from that baseline; then ship a versioned ranker
behind a holdout experiment. No opaque model or new weights ship before the
baseline exists. Blocked-author exclusion and author diversity keep applying to
every ranker version.

## Consequences

- Ranking work is gated on event schema, retention, and privacy review.
- The first release may keep the current heuristic, but its inputs and the
  diversity guard become measurable and testable.
- Product decisions about "healthy engagement" are explicit, not inferred from
  raw engagement counts.
