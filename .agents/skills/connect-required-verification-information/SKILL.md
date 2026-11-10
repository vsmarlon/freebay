---
name: connect-required-verification-information
description: Use when determining Stripe Connect account verification or onboarding requirements for a specific country, entity, dashboard, service agreement, or capability.
---

# Fetch current Connect requirements

Requirements vary by setup and change over time. Fetch Stripe’s public requirements endpoints; never answer from a remembered/static field list. Ask one validated setup field at a time, using multiple-choice questions and the full validated option list when there are more than four options. Reuse valid user-provided answers.

1. Ask API version (recommend v2), fetch platform countries, then fetch selections for the chosen platform country.
2. Validate account country before asking dashboard, service agreement and entity type. Ask business structure only when returned and ORR program only when offered.
3. Filter capabilities against country, service agreement and API-version constraints. If an earlier field changes, invalidate/recheck dependent fields. Never offer a known-invalid option.
4. Once complete, call requirements endpoint with the exact validated setup; also fetch website and MCC restrictions for chosen capabilities. Treat build/transport errors as retryable, validation errors as invalid setup—not a business conclusion.
5. Present the exact setup, reproducible query/link, currently due vs eventually due, verification details, enforcement and supplemental website/MCC restrictions. For comparisons, validate both setups independently.

For endpoint fields, dependency details and table mapping rules, consult the current Stripe endpoint/docs rather than relying on stale copied schema. Use external-facing terms; preserve user-requested but incompatible choices in the explanation. Do not claim data fetch succeeded unless the actual response was received.
