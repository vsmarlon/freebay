.PHONY: help lint analyze format architecture-check boundaries-check design-check routes-check test test-unit test-integration web-check web-dev perf-check run-profile

BACKEND_DIR  := nest-backend
FRONTEND_DIR := frontend
FLUTTER ?= flutter
DART ?= dart

help:
	@echo ""
	@echo "  make lint              Backend eslint (zero warnings)"
	@echo "  make analyze           Flutter static analysis (zero issues)"
	@echo "  make format            Dart format gate (frontend and design system)"
	@echo "  make architecture-check No removed repository/API identifiers"
	@echo "  make boundaries-check  Architecture boundary ratchet"
	@echo "  make design-check      Design system rules (see frontend/DESIGN.md)"
	@echo "  make routes-check      No raw route literals (navigate via AppRoutes)"
	@echo "  make test              Run everything (lint + analyze + unit + integration)"
	@echo "  make test-unit         TypeScript + Jest + Flutter unit tests"
	@echo "  make test-integration  Backend integration tests (needs configured native PostgreSQL + Redis; database freebay_test_db)"
	@echo "  make web-check         React web typecheck, lint, tests, and build (requires web/npm dependencies installed)"
	@echo "  make web-dev           Start the React web development server"
	@echo "  make perf-check DEVICE=<id>  Profile all five mobile flows (requires backend and fixtures)"
	@echo "  make run-profile DEVICE=<id> Run Flutter profile mode with frontend/.env"
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

architecture-check:
	@echo ""
	@echo "=== Removed architecture/API identifiers ==="
	node scripts/ci-check.js --architecture

boundaries-check:
	@echo ""
	@echo "=== Architecture boundary ratchet ==="
	node scripts/ci-check.js --boundaries

design-check:
	@echo ""
	@echo "=== Design system rules ==="
	node scripts/ci-check.js --design

routes-check:
	@echo ""
	@echo "=== Route literal rules (navigate via AppRoutes) ==="
	node scripts/ci-check.js --routes

test: lint analyze format architecture-check boundaries-check design-check routes-check test-unit test-integration
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

web-check:
	@echo "=== React web checks (typecheck, lint, tests, build) ==="
	npm run web:check

web-dev:
	npm run web:dev

perf-check:
	@echo ""
	@echo "=== Performance gate (all instrumented flows) ==="
	node scripts/perf-check.js --all --device $(DEVICE)

run-profile:
	cd $(FRONTEND_DIR) && $(FLUTTER) run --profile --dart-define-from-file=.env $(if $(DEVICE),-d $(DEVICE),)
