# Testing Between

Between has three test layers: **Python seed integrity**, **Node `/v1` API**, and **iOS unit tests** (`BetweenTests`). Run everything with:

```bash
./Scripts/run_tests.sh
```

On Windows (without Xcode), run Python and Node separately:

```bash
python Scripts/test_seed_data.py
cd api && npm install && npm test
```

## What is covered

| Layer | Location | Focus |
|-------|----------|--------|
| Seed | `Scripts/test_seed_data.py`, `api/v1/seedValidator.js` | Referential integrity, enrolled-only event participants, real counts |
| API logic | `api/v1/*.test.js` | DataStore mutations, events/dashboard builders, schedule engine, crypto |
| HTTP | `api/v1/routes.test.js` | Auth, events interested POST, partner opt-in, course hashes |
| iOS | `BetweenTests/` | CourseHashService, EventsBuilder counts, seed JSON on disk |

## Key invariants (tested)

- **Event counts** come only from `eventParticipations` rows for students with enrollments — no synthetic padding.
- **Partner profiles** require mutual opt-in (`lookingForPartner` participation).
- **markEventInterested** rejects students without enrollments (e.g. suggested contacts).
- **Course hashes** use `SHA256(schoolId:canonicalCourseId)` and never send raw CRNs to the server.

## iOS tests (Mac only)

```bash
xcodebuild test \
  -project Between.xcodeproj \
  -scheme Between \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:BetweenTests
```

## Demo credentials (used in route tests)

- Email: `alex.hirsch@vt.edu`
- Password: `demo123`
- Activation: `482910`
