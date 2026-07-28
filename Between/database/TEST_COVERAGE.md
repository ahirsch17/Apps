# Test Coverage Summary

## Current Coverage

### Unit Tests ✅
**Location**: `BetweenTests/`

| Test File | Coverage | Status |
|-----------|----------|--------|
| LocalBackendServiceTests | Event participation | ✅ Pass |
| SeedIntegrityTests | Seed data validation | ✅ Pass |
| BackendLogicTests | Schedule overlaps | ✅ Pass |

**Run**: `xcodebuild test -scheme Between`

### Integration Tests ⏳
**Location**: `BetweenTests/IntegrationTests.swift`

| Test | Azure SQL | Status |
|------|-----------|--------|
| Authentication flow | ✅ | Ready |
| Friend requests | ✅ | Ready |
| Event participation | ✅ | Ready |
| Presence updates | ✅ | Ready |
| Performance (< 2s) | ✅ | Ready |

**Run**: `TEST_API_URL=https://between-test.azurewebsites.net xcodebuild test -scheme Between`

## Azure SQL Compatibility ✅

### Schema Mapping
```
Local JSON           →  Azure SQL Table
─────────────────────────────────────────
universities         →  schools
students             →  students
sections             →  sections
enrollments          →  enrollments
friendships          →  friendships
friendRequests       →  friend_requests
presence             →  presence
plans                →  plans
interests            →  interests
studentProfiles      →  student_profiles
campusEvents         →  campus_events
eventParticipations  →  event_participations
partnerProfiles      →  partner_profiles
```

### Data Types
```sql
-- JSON arrays stored as NVARCHAR(MAX)
-- Example: meeting_days
Local:  ["Mon", "Wed", "Fri"]
Azure:  '["Mon","Wed","Fri"]'  -- JSON string

-- Timestamps
Local:  Date()
Azure:  DATETIME2 + GETUTCDATE()

-- Auto-increment
Local:  N/A (static IDs)
Azure:  IDENTITY(1,1)
```

## Migration Readiness ✅

**Current State**:
- ✅ Local seed data for dev/demo
- ✅ Protocol abstraction (`BetweenBackendServicing`)
- ✅ Azure SQL schema defined
- ✅ Migration guide documented

**To Deploy**:
1. Create Azure SQL Database
2. Run `azure-sql-schema.sql`
3. Update API connection string
4. Run integration tests
5. Deploy API to Azure App Service

**Zero Code Changes Required** - just swap connection string!

## Missing Coverage (Add Later)

### API Tests
- [ ] Rate limiting
- [ ] Authentication token expiry
- [ ] Course hash collisions
- [ ] Concurrent writes to same entity

### Client Tests
- [ ] Offline mode handling
- [ ] Schedule conflict resolution
- [ ] Privacy setting persistence
- [ ] Location permission flows

### Load Tests
- [ ] 1000 concurrent users
- [ ] Dashboard query performance
- [ ] Overlap calculation at scale
