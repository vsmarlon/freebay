#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_PID=""

cleanup() {
  echo "Cleaning up..."
  if [ -n "$BACKEND_PID" ]; then
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
  cd "$ROOT_DIR/backend" && docker-compose down 2>/dev/null || true
}

trap cleanup EXIT

echo "=== Starting backend services ==="
cd "$ROOT_DIR/backend"

# Start database via docker-compose
if command -v docker-compose &>/dev/null; then
  docker-compose up -d
elif command -v docker &>/dev/null; then
  docker compose up -d
else
  echo "Warning: docker-compose not found, assuming database is already running"
fi

# Wait for database to be ready
echo "Waiting for database..."
sleep 3

# Install deps and start backend
npm ci --silent
npm run build 2>/dev/null || true
npm run dev &
BACKEND_PID=$!

# Wait for backend to be ready
echo "Waiting for backend to start..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:3333/health >/dev/null 2>&1; then
    echo "Backend is ready!"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "Warning: Backend health check timed out, proceeding anyway..."
  fi
  sleep 1
done

echo ""
echo "=== Running Flutter unit tests ==="
cd "$ROOT_DIR/frontend"
flutter pub get
flutter test

echo ""
echo "=== Running Flutter integration tests ==="
flutter test integration_test

echo ""
echo "=== All tests passed ==="
