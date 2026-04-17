.PHONY: help test test-unit test-integration

BACKEND_DIR  := backend
FRONTEND_DIR := frontend

# ─── default ────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  make test              Run everything (unit + integration)"
	@echo "  make test-unit         TypeScript + Jest + Flutter unit tests"
	@echo "  make test-integration  Flutter integration tests (headless Chrome)"
	@echo ""

# ─── combined ───────────────────────────────────────────────────────────────
test: test-unit test-integration
	@echo ""
	@echo "✓ All checks passed"

# ─── unit (ts + jest + flutter) ─────────────────────────────────────────────
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
	@echo "=== Flutter integration tests (headless Chrome) ==="
	@chromedriver --port=4444 & CHROME_PID=$$!; \
	sleep 2; \
	cd $(FRONTEND_DIR) && flutter drive \
		--driver=test_driver/integration_test.dart \
		--target=integration_test/app_test.dart \
		-d web-server \
		--driver-port=4444 \
		--headless; \
	EXIT=$$?; \
	kill $$CHROME_PID 2>/dev/null || true; \
	exit $$EXIT
