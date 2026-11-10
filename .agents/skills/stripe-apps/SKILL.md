---
name: stripe-apps
description: Use when building or modifying Stripe Apps, Dashboard extensions, app manifests, backend events, or publishing workflows.
---

# Stripe Apps

Before designing the app, read [`references/discovery.md`](references/discovery.md) and obtain the required user decisions/confirmation; never scaffold before discovery. Before coding, fetch the relevant current canonical Stripe docs listed in [`references/canonical-docs.md`](references/canonical-docs.md).

Then use `stripe generate app <name>` (not `stripe apps create`) and adapt the generated project. UI extensions use SDK UI components, not raw HTML/CSS or browser storage/APIs. Check private-preview access before relying on custom objects, extension interfaces or full-page apps. Declare least-privilege permissions and CSP.

Read branch references only as needed: `ui-extensions.md`, `backend.md`, `webhooks.md`, `authentication.md`, `extension-types.md`, `onboarding-ux.md`, `workflow.md`, `publishing.md`. Preserve signature verification and secret-store controls. Upload is required before testing upload-generated signing secrets. Verify relevant build/test and show the exact completed workflow; never describe a placeholder as runnable.
