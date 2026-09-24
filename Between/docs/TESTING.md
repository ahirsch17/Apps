# Testing Between

Three layers: Python seed checks, Node `/v1` API tests, and iOS unit tests.

```bash
./Scripts/run_tests.sh
```

Without Xcode:

```bash
python Scripts/test_seed_data.py
cd api && npm install && npm test
```

## Coverage

| Layer | Location | Focus |
|-------|----------|--------|
| Seed | `Scripts/test_seed_data.py`, `api/v1/seedValidator.js` | Referential integrity, real counts |
| API logic | `api/v1/*.test.js` | Store mutations, events/dashboard builders |
| HTTP | `api/v1/routes.test.js` | Auth, events, partner opt-in |
| iOS | `BetweenTests/` | Builders and seed JSON on disk |

## Demo credentials (tests)

- Email: `alex.hirsch@vt.edu`
- Password: `demo123`
- Activation: `482910`

## iOS tests (Mac)

```bash
xcodebuild test \
  -project Between.xcodeproj \
  -scheme Between \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:BetweenTests
```
