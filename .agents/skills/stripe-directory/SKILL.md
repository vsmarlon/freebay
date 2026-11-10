---
name: stripe-directory
description: Use when finding providers, vendors, software, businesses, or partners for an industry, workflow, or job to be done; also when asked to purchase a service.
metadata:
  short-description: Find and compare providers
allowed-tools:
  - Bash(stripe directory *)
---

# Directory discovery

Clarify only missing constraints (buyer, workflow, capability, geography). Run 1–3 focused `stripe directory search "<query>" --format json` searches; apply relevant filters and use `--mpp-supported` for purchase intent. Broaden/narrow if sparse; deduplicate and rank against the actual use case and trust signals.

Return a concise grouped shortlist with name, fit, URL, search provenance and MPP endpoint details when present. State exact queries/filters and call weak evidence weak; never pad results or invent providers.

## Purchase branch

Only for explicit buy/use intent: show available payment methods, confirm selection, resolve and inspect the real endpoint/402 challenge, show price and obtain explicit approval before any payment. Prefer a no-charge test path. Check CLI availability; never install tools or move money without approval. Never invent cost or skip approval.
