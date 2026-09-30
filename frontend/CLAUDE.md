# Flutter frontend guidance

@../AGENTS.md

Read [`DESIGN.md`](DESIGN.md) and load the `freebay-design-system` skill before UI work. Reuse design-system components/tokens; use `AppRoutes` for navigation and Riverpod for shared state. `AppShell` tabs retain state: preserve the existing keep-alive and guarded-load pattern rather than fetching unconditionally during rebuilds. Follow the feature's actual layer structure; domain use cases may use data entities but not concrete data repositories.

After entity JSON/codegen edits, run `dart run build_runner build --delete-conflicting-outputs` from this directory and review the generated diff. Validate frontend changes with the commands in the root `AGENTS.md`; device and perf claims need their corresponding skills/evidence.
