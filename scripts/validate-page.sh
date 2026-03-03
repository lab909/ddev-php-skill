#!/bin/bash
# validate-page.sh - Quick validation of a PHP page served by DDEV
# Usage: bash validate-page.sh [path] [project-dir]
set -euo pipefail
PAGE_PATH="${1:-/}"
PROJECT_DIR="${2:-.}"
cd "$PROJECT_DIR"
PROJECT_NAME="$(basename "$(pwd)")"
BASE_URL="https://${PROJECT_NAME}.ddev.site"
FULL_URL="${BASE_URL}${PAGE_PATH}"
echo "DDEV Page Validation: $FULL_URL"
echo "[1/4] Checking DDEV status..."
if ! ddev describe > /dev/null 2>&1; then
    echo "DDEV not running. Starting..."
    ddev start
fi
echo "DDEV is running"
echo "[2/4] Checking HTTP response..."
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "$FULL_URL")
echo "HTTP Status: $HTTP_CODE"
echo "[3/4] Checking for PHP errors..."
RESPONSE=$(curl -sk "$FULL_URL")
echo "$RESPONSE" | grep -iE "(Fatal error|Warning|Notice|Parse error)" && echo "PHP errors found" || echo "No PHP errors"
echo "[4/4] Checking server logs..."
ddev logs --tail=20 2>&1 | grep -iE "(error|fatal)" && echo "Log errors found" || echo "No log errors"
echo "Validation complete"
