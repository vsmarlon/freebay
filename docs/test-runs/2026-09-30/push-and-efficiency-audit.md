# Push and efficiency audit — 2026-09-30

Revision: `f48a5be008ea8520995e68441656899499ca08a1` plus the existing working tree and this session's edits. User requested production improvements with lean verification, without adding a repository regression suite.

## Decisions

- Push must reach every registered, signed-in installation.
- Disabled categories mute push but preserve the in-app inbox.
- Verification uses real NestJS HTTP/socket boundaries and PostgreSQL, replacing only Firebase's external SDK delivery. Device/provider delivery is separate evidence.

## Behavioral probe authoring gate

The disposable runner is `C:/Users/Qiyana/AppData/Local/Temp/opencode/freebay-push-audit.e2e-spec.js`; it uses the existing AppModule, validation/interceptors, guarded database cleanup, and real repositories.

- **Contract:** ordinary HTTP chat sends create one recipient inbox event; a retry does not duplicate it. **Failure:** push dispatch exists only in the socket entry point. **Coverage gap:** current chat socket/privacy and location tests do not exercise HTTP notification dispatch. No production testing hook is added.
- **Planned next boundary:** authenticated token registration, rotation, ownership transfer, single-installation logout, preference enforcement and invalid-token cleanup with recorded SDK deliveries. Current tests do not prove these contracts. No mocked database or duplicated provider-local proof will be used.
- **Filter boundary:** real catalog HTTP query for a zero-cent upper bound; Flutter transport for the open-ended maximum. Existing slider-gesture coverage does not establish these values in the actual query.

Runs and final evidence will be recorded below; source inspection alone is not a passing run or a measured performance improvement.
