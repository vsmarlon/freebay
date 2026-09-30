---
name: freebay-mobile-mcp
description: Use whenever using mobile-mcp for FreeBay device reproduction, interaction, testing, or evidence.
---

# Mobile verification

Before device work, read [`docs/DEVICE_TESTING.md`](../../../docs/DEVICE_TESTING.md) and `freebay-app-flows`; establish a concrete expected outcome and fixture. Discover local devices first; use remote only on explicit request. Select the actual app/session and avoid exposing credentials.

Inspect accessibility elements after each screen change and act only on current refs/labels. Capture screenshot, logs and crash state for the target outcome. Group known interactions into a batch. A mock, widget test or screenshot alone does not establish a real journey; payment-sheet launch does not establish settlement.

Report device/model/OS, app revision, fixture/reset steps, exact actions and outcome, evidence paths, and failures. Do not claim privacy, provider, multi-device or delivery behavior without a relevant test. Follow `docs/test-runs/<date>/` evidence rules; blocked device runs stay blocked.
