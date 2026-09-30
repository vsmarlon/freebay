# Performance: feed_scroll

- Status: **FAIL**; exit status: 1
- Tested revision: f48a5be008ea8520995e68441656899499ca08a1; working-tree changes:

```text
M .claude/settings.local.json
 M AGENTS.md
 M CLAUDE.md
 M FREEBAY_RELEASE_HANDOFF.md
 M Makefile
 M docs/DEVICE_TESTING.md
 M frontend/lib/features/auth/presentation/controllers/auth_controller.dart
 M frontend/lib/features/auth/presentation/controllers/auth_session_lifecycle.dart
 M frontend/lib/features/product/presentation/controllers/product_controller.dart
 M frontend/lib/features/product/presentation/pages/explorar_page.dart
 M frontend/lib/features/social/presentation/pages/post_search_page.dart
 M frontend/lib/features/social/presentation/providers/comment_likes_provider.dart
 M frontend/lib/features/social/presentation/providers/feed_provider.dart
 M frontend/lib/features/social/presentation/providers/likes_provider.dart
 M frontend/lib/features/social/presentation/providers/post_search_provider.dart
 M frontend/lib/features/social/presentation/providers/reposts_provider.dart
 M frontend/lib/features/social/presentation/providers/saves_provider.dart
 M frontend/lib/features/social/presentation/providers/user_search_provider.dart
 M frontend/libs/freebay_design_system/lib/components/brutalist_action_sheet.dart
 M frontend/test/features/orders/orders_page_test.dart
 M frontend/test/features/orders/sales_list_provider_test.dart
 M frontend/test/features/social/story_viewer_interaction_test.dart
 M nest-backend/prisma/schema.prisma
 M nest-backend/src/modules/social/data/repositories/comment-database.repository.ts
 M nest-backend/src/modules/social/data/repositories/post-database.repository.spec.ts
 M nest-backend/src/modules/social/data/repositories/post-query-helpers.ts
 M nest-backend/src/modules/social/data/repositories/share-database.repository.ts
 M nest-backend/src/modules/social/usecases/comment.usecase.ts
 M nest-backend/src/modules/social/usecases/like-post.usecase.ts
 M nest-backend/src/modules/social/usecases/save-post.usecase.ts
 M nest-backend/src/modules/social/usecases/search-posts.usecase.ts
 M nest-backend/src/modules/social/usecases/share-post.usecase.ts
 M nest-backend/src/modules/social/usecases/social.usecase.spec.ts
 M nest-backend/test/e2e/marketplace.journey.e2e-spec.ts
 M nest-backend/test/e2e/setup-e2e.ts
 M nest-backend/test/e2e/story-highlights.e2e-spec.ts
 M package.json
?? .agents/skills/freebay-perf/
?? .claude/skills/freebay-perf/
?? .codex/
?? docs/FEATURE_MAP.md
?? docs/test-runs/2026-09-26/
?? frontend/integration_test/
?? frontend/test/features/auth/social_session_isolation_test.dart
?? frontend/test/features/product/product_feed_refresh_test.dart
?? frontend/test/features/product/product_load_more_error_test.dart
?? frontend/test/features/social/post_search_error_test.dart
?? frontend/test/features/social/post_search_race_test.dart
?? frontend/test_driver/
?? opencode.json
?? perf/
?? scripts/perf-check.js
?? scripts/perf-check.test.js
```

- Environment: SM A305GT | android-arm64 | Android 11 (API 30); Flutter profile mode; backend and fixture: see docs/DEVICE_TESTING.md
- Command: `node scripts/perf-check.js feed_scroll --device RX8M70JDTQV --update-baseline`
- Fixture/reset: seeded catalog and posts; stories for story_view; authenticated user with a long real conversation for chat_scroll. Restore the same fixture before comparing.
- Expected: >=30 frames, build + raster below absolute budgets and within 20% of a measured same-device baseline, zero missed budgets.

| Metric | Actual | Prior baseline |
| --- | ---: | ---: |
| average_frame_build_time_millis | 1.954 | — |
| 90th_percentile_frame_build_time_millis | 2.894 | — |
| worst_frame_build_time_millis | 26.743 | — |
| missed_frame_build_budget_count | 3 | — |
| average_frame_rasterizer_time_millis | 7.056 | — |
| 90th_percentile_frame_rasterizer_time_millis | 11.458 | — |
| worst_frame_rasterizer_time_millis | 24.46 | — |
| missed_frame_rasterizer_budget_count | 9 | — |
| frame_count | 415 | — |

- Baseline: `perf/baselines/feed_scroll.json`; recorded at: not yet recorded
- Result: 90th_percentile_frame_rasterizer_time_millis 11.458ms >= 8ms; missed_frame_build_budget_count 3 exceeds 0; missed_frame_rasterizer_budget_count 9 exceeds 0
