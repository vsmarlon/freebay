.PHONY: help lint analyze test test-unit test-integration

BACKEND_DIR  := nest-backend
FRONTEND_DIR := frontend

help:
	@echo ""
	@echo "  make lint              Backend eslint (zero warnings)"
	@echo "  make analyze           Flutter static analysis (zero issues)"
	@echo "  make test              Run everything (lint + analyze + unit + integration)"
	@echo "  make test-unit         TypeScript + Jest + Flutter unit tests"
	@echo "  make test-integration  Backend integration tests (needs a freebay_test database)"
	@echo ""

lint:
	@echo ""
	@echo "=== Backend lint ==="
	cd $(BACKEND_DIR) && npm run lint

analyze:
	@echo ""
	@echo "=== Flutter analysis ==="
	cd $(FRONTEND_DIR) && flutter analyze --fatal-infos

test: lint analyze test-unit test-integration
	@echo ""
	@echo "✓ All checks passed"

test-unit:
	@echo ""
	@echo "=== TypeScript type-check ==="
	cd $(BACKEND_DIR) && npx tsc --noEmit
	@echo ""
	@echo "=== Backend tests (Jest) ==="
	cd $(BACKEND_DIR) && npm test
	@echo ""
	@echo "=== Flutter unit tests ==="
	cd $(FRONTEND_DIR) && flutter test

test-integration:
	@echo ""
	@echo "=== Backend integration tests (needs a freebay_test database) ==="
	cd $(BACKEND_DIR) && npm run test:integration
