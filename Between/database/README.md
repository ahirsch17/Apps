# Database Setup

## Architecture

```
Development:      LocalBackendService (JSON seed data)
                 ↓ Switch connection string
Production:      Azure SQL Database + RemoteBackendService
```

## Local Development (Current)

**No database needed** - uses in-memory JSON:

```swift
// BackendConfiguration.swift
static var mode: BackendMode = .local
```

Seed data: `Between/Resources/seed_data.json`

## Switch to Azure SQL (Production)

### Step 1: Create Empty Database

```bash
# Azure CLI
az sql db create \
  --name between-prod \
  --server between-sql-server

# Apply schema ONLY (no data)
sqlcmd -i azure-sql-schema.sql
```

Result: Empty tables, no students/courses/events.

### Step 2: Seed with Fake Data (Testing)

**Option A: SQL Script** (faster)
```bash
sqlcmd -i seed-local-data.sql
```

**Option B: API Script** (mimics production)
```bash
npm install
node seed-via-api.js
```

This creates:
- 4 test students
- 5 course sections
- 3 friendships
- 4 interests
- 2 campus events

**DELETE THIS DATA before production!**

### Step 3: Switch iOS App

```swift
// BackendConfiguration.swift
static var mode: BackendMode = .remote(
  baseURL: URL(string: "https://between-api.azurewebsites.net")!
)
```

That's it! No other code changes.

### Step 4: Remove Fake Data

```sql
-- Before going live, delete test data
DELETE FROM students WHERE id LIKE 'stu-%';
DELETE FROM sections WHERE section_id LIKE '%-001';
DELETE FROM campus_events WHERE id LIKE 'evt-%';
```

## Production Data Flow

**Real data comes from**:

1. **Students**: VT SSO integration
   ```
   User taps "Sign in with Virginia Tech"
   → VT OIDC redirect
   → API receives VT user info
   → INSERT INTO students
   ```

2. **Courses**: Canvas API webhook
   ```
   Canvas sends enrollment update
   → API receives course roster
   → INSERT INTO sections + enrollments
   ```

3. **Events**: Admin dashboard
   ```
   Staff creates event in admin panel
   → POST /admin/events
   → INSERT INTO campus_events
   ```

4. **Friendships**: User actions in app
   ```
   User taps "Add" on friend
   → POST /me/friend-requests
   → INSERT INTO friend_requests
   ```

## Schema vs Data

| File | Contains | When to Use |
|------|----------|-------------|
| `azure-sql-schema.sql` | Tables, indexes, views | Always (dev + prod) |
| `seed-local-data.sql` | Fake students/courses | Dev/testing only |
| `seed-via-api.js` | API-based seeding | Testing API flow |

## Testing Against Azure SQL

```bash
# Local: JSON seed data
xcodebuild test -scheme Between

# Azure: Real database
TEST_API_URL=https://between-test.azurewebsites.net \
xcodebuild test -scheme Between

# After tests, clean up test data
sqlcmd -Q "DELETE FROM students WHERE email LIKE 'test@%'"
```

## Migration Checklist

- [ ] Create Azure SQL Database
- [ ] Run `azure-sql-schema.sql`
- [ ] Test with `seed-local-data.sql`
- [ ] Run integration tests
- [ ] Deploy API to Azure App Service
- [ ] Update iOS app connection string
- [ ] Delete fake data
- [ ] Connect VT SSO
- [ ] Connect Canvas API
- [ ] Deploy to TestFlight

## Connection Strings

```bash
# Development (no database)
# Uses LocalBackendService

# Staging (Azure SQL)
export DATABASE_URL="Server=tcp:between-test.database.windows.net..."

# Production (Azure SQL)
export DATABASE_URL="Server=tcp:between-prod.database.windows.net..."
```

Switch by changing environment variable, that's all!
