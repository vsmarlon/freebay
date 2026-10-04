# Device resume preflight — 2026-10-01

Preflight on the online Galaxy A30 (`RX8M70JDTQV`, `SM-A305GT`, Android 11) succeeded: the installed app launched, exposed an expired-session screen, and reached an empty login form. Package metadata identifies only a historical debug APK (`1.0.0`, code `1`); it does not identify the current checkout.

Current-source Flutter attach reached syncing but failed with compile errors. No login, backend or runtime database identity, target UX flow, hot restart, or performance check was verified. The installed-app screenshot is [`login-preflight-old-apk.png`](login-preflight-old-apk.png).

See [`device resume report`](../../../test-runs/2026-10-01/device-resume/REPORT.md) for exact checks, blockers, and evidence limits. This is not a completed device run.
