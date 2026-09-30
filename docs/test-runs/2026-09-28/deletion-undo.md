# Deletion undo — verification record

**Scope:** user-initiated chat message/conversation, post, story, and highlight removal in Flutter. Revision and exact check results will be filled in after the run.

**Risk partitions before isolation:** Undo must send zero deletion requests; expiry must send exactly one; consecutive removals must not silently lose the remaining undo opportunity; leaving the screen must not crash or drop an accepted deletion; API failure must surface an error and restore/refetch the item. For chat messages and stories, a pending deletion must not show a false success. A story highlight is physically deleted on the server; there is no restore API, so Undo must precede the HTTP call.

**E2E gap:** `frontend/integration_test` contains performance tests only. No local Android/iOS device was returned by `mobile_list_available_devices` for this run, so the real Flutter → HTTP → database journey is blocked. Widget tests will exercise the visible undo/expiry timing with request-recording repositories; these do not establish real backend persistence or cross-device behavior.
