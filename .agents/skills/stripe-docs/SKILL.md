---
name: stripe-docs
description: Use when the user or agent needs to search or read Stripe documentation or API reference.
metadata:
  short-description: Read Stripe docs via CLI
allowed-tools:
  - Bash(stripe docs *)
---

Use `stripe docs` for docs.stripe.com content instead of curl/WebFetch:

```bash
stripe docs /payments
stripe docs search "payment intents"
stripe docs api product
stripe docs api GET /v1/products
stripe docs api product.created
```

Check current command help if syntax differs; cite the retrieved page/API details rather than memory.
