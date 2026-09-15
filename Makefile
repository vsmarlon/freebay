.PHONY: help lint analyze format design-check routes-check test test-unit test-integration

BACKEND_DIR  := nest-backend
FRONTEND_DIR := frontend
FLUTTER ?= fvm flutter
DART ?= fvm dart

help:
	@echo ""
	@echo "  make lint              Backend eslint (zero warnings)"
	@echo "  make analyze           Flutter static analysis (zero issues)"
	@echo "  make format            Dart format gate (frontend and design system)"
	@echo "  make design-check      Design system rules (see frontend/DESIGN.md)"
	@echo "  make routes-check      No raw route literals (navigate via AppRoutes)"
	@echo "  make test              Run everything (lint + analyze + unit + integration)"
	@echo "  make test-unit         TypeScript + Jest + Flutter unit tests"
	@echo "  make test-integration  Backend integration tests (needs configured native PostgreSQL + Redis; database freebay_test_db)"
	@echo ""

lint:
	@echo ""
	@echo "=== Backend lint ==="
	cd $(BACKEND_DIR) && npm run lint

analyze:
	@echo ""
	@echo "=== Flutter analysis ==="
	cd $(FRONTEND_DIR) && $(FLUTTER) analyze --fatal-infos lib test libs/freebay_design_system/lib

format:
	@echo ""
	@echo "=== Dart format gate ==="
	cd $(FRONTEND_DIR) && $(DART) format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib

design-check:
	@echo ""
	@echo "=== Design system rules ==="
	@cd $(FRONTEND_DIR) && ! grep -rnE \
		"BorderRadius\.(circular|all|only|vertical|horizontal)|StadiumBorder|CircleBorder|CircleAvatar|ClipOval|BoxShape\.circle|blurRadius|Curves\.(elasticOut|easeOutBack|easeInOut)|accentAmber|Divider\(" \
		lib libs/freebay_design_system/lib --include=*.dart \
		|| (echo "" && echo "Banned pattern above. See frontend/DESIGN.md." && exit 1)
	@echo "OK"

routes-check:
	@echo ""
	@echo "=== Route literal rules (navigate via AppRoutes) ==="
	@cd $(FRONTEND_DIR) && ! grep -rnE \
		"(context|appRouter)\.(go|push|pushReplacement|replace)\([[:space:]]*['\"]/" \
		lib --include=*.dart \
		|| (echo "" && echo "Raw route literal above. Navigate via AppRoutes (see AGENTS.md)." && exit 1)
	@echo "OK"

test: lint analyze format design-check routes-check test-unit test-integration
	@echo ""
	@echo "✓ All checks passed"

test-unit:
	@echo ""
	@echo "=== TypeScript type-check ==="
	cd $(BACKEND_DIR) && npx tsc --noEmit
	@echo ""
	@echo "=== Test database guard ==="
	cd $(BACKEND_DIR) && npm run test:safety
	@echo ""
	@echo "=== Backend tests (Jest) ==="
	cd $(BACKEND_DIR) && npm test
	@echo ""
	@echo "=== Flutter unit tests ==="
	cd $(FRONTEND_DIR) && $(FLUTTER) test

test-integration:
	@echo ""
	@echo "=== Backend integration tests (needs configured native PostgreSQL + Redis) ==="
	cd $(BACKEND_DIR) && npm run test:integration
