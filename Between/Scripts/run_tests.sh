#!/usr/bin/env bash
# Run all Between tests (Python seed + Node API). On Mac, also runs Xcode unit tests.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Python seed tests ==="
python Scripts/test_seed_data.py

echo ""
echo "=== Node API tests ==="
cd api
npm test

if command -v xcodebuild >/dev/null 2>&1; then
  echo ""
  echo "=== iOS unit tests (BetweenTests) ==="
  cd "$ROOT"
  xcodebuild test \
    -project Between.xcodeproj \
    -scheme Between \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:BetweenTests \
    -quiet
else
  echo ""
  echo "Skipping iOS tests (xcodebuild not available — run on Mac)"
fi

echo ""
echo "All available tests passed."
