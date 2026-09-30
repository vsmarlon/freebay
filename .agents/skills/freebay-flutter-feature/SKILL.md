---
name: freebay-flutter-feature
description: Use when adding or changing a FreeBay Flutter feature, provider, repository, use case, page, widget, or route.
---

# Flutter feature slice

Read root [`AGENTS.md`](../../../AGENTS.md), [`freebay-design-system`](../freebay-design-system/SKILL.md), and `docs/FEATURE_TRUTH.md` for capability work. Inspect the existing feature layout first: some legacy features do not have all three layers; do not add folders for uniformity.

- Concrete repositories in `data/repositories` call backend HTTP only via shared Dio and `requestEither<T>`; they map responses/failures into immutable models. Domain repository contracts stay where present.
- Domain use cases are for actual validation, logic, orchestration or mapping. Do not create a one-call pass-through wrapper. Data entities may be imported by domain logic; domain must not import data repositories. Shared/server state belongs in Riverpod; local state is ephemeral.
- Use generated Freezed/JSON artifacts through build_runner, not manual generated-file edits. No `any`/unsafe type escape hatches; narrow JSON input.
- Register routes with `AppRoutes` constants/builders; never raw route literals. Keep tab indexes, shell gestures, accessibility and keyboard behavior intact.
- Use design-system exports/components and `frontend/DESIGN.md` tokens. Do not prescribe fixed animation milliseconds or conditional dark-mode colors.

For behavior changes, follow TDD/E2E policy and `test-audit`. Verify focused real boundary first, then applicable Flutter format/analyze/tests/build from `AGENTS.md`; save repeatable E2E/device evidence and label unavailable checks blocked.
