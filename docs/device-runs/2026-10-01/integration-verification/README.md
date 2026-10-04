# Integration verification — device lane — 2026-10-01

**BLOCKED after reconnection:** initial discovery and `adb devices -l` had no device. Fresh discovery after owner steering found the physical Galaxy A30 (`RX8M70JDTQV`, `SM-A305GT`, Android 11, online). Individual mobile-MCP calls worked after an initial on-device agent timeout. Launching installed `com.freebay.app` showed an expired-session screen; there was no authenticated fixture. No credentials were available through a verified-safe path, and no guest route was entered.

Current checkout is `c9808b106c3d53f07837542e93f25fd52c6bfbe5` on `feat/production-hardening`; extensive pre-existing dirty changes mean this does not identify the installed app's source. No live app VM-service/DTD URI was found, so the existing session could not be hot-restarted and source reload is unconfirmed. Startup info provides timings only, not source or backend/database identity.

Evidence: `session-expired.png`; filtered FreeBay error log `freebay-errors.log` had 0 entries; device crash inventory contained one unrelated `com.samsung.android.forest` report. No requested UX flow is claimed verified, and the Close Friends candidate-search issue flagged by owner was not exercised. No performance baseline was updated.

See [`docs/test-runs/2026-10-01/integration-verification/device/REPORT.md`](../../test-runs/2026-10-01/integration-verification/device/REPORT.md) for exact scope and unblock requirements.
