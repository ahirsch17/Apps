# Azure SQL Migration Guide

## Current State
- **Local**: In-memory seed data (JSON) via `LocalBackendService`
- **API**: REST endpoints expecting database backend
- **Tests**: Unit tests with seed data, integration tests pending

## Azure SQL Setup

### 1. Create Azure SQL Database
```bash
# Azure CLI
az sql server create \
  --name between-sql-server \
  --resource-group between-rg \
  --location eastus \
  --admin-user betweenAdmin \
  --admin-password [SecurePassword]

az sql db create \
  --resource-group between-rg \
  --server between-sql-server \
  --name between-prod \
  --service-objective S1 \
  --max-size 10GB
```

### 2. Apply Schema
```bash
# Connect and run schema
sqlcmd -S between-sql-server.database.windows.net \
  -d between-prod \
  -U betweenAdmin \
  -P [SecurePassword] \
  -i azure-sql-schema.sql
```

### 3. Environment Variables
```bash
# Add to Azure App Service or .env
DATABASE_URL=Server=tcp:between-sql-server.database.windows.net,1433;Database=between-prod;User ID=betweenAdmin;Password=[SecurePassword];Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;
```

## Migration Steps

### Phase 1: Schema Migration
1. Run `azure-sql-schema.sql` on Azure SQL
2. Verify tables created
3. Set up Row-Level Security policies

### Phase 2: Seed Initial Data
```sql
-- Insert VT as first school
INSERT INTO schools (id, name, email_domain, timezone)
VALUES ('vt', 'Virginia Tech', 'vt.edu', 'America/New_York');

-- Insert interests
INSERT INTO interests (id, school_id, name, icon)
VALUES 
  ('int-volleyball', 'vt', 'Volleyball', 'sportscourt.fill'),
  ('int-soccer', 'vt', 'Soccer', 'soccerball');
```

### Phase 3: Update API Connection
```javascript
// Old: PostgreSQL
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// New: Azure SQL (use mssql package)
const sql = require('mssql');
const config = {
  server: process.env.AZURE_SQL_SERVER,
  database: process.env.AZURE_SQL_DATABASE,
  user: process.env.AZURE_SQL_USER,
  password: process.env.AZURE_SQL_PASSWORD,
  options: {
    encrypt: true,
    trustServerCertificate: false
  }
};
```

### Phase 4: Test Migration
```bash
# Run integration tests against Azure SQL
npm test -- --env=azure

# Verify endpoints
curl https://between-api.azurewebsites.net/v1/health
```

## Key Differences: PostgreSQL vs Azure SQL

| Feature | PostgreSQL | Azure SQL |
|---------|-----------|-----------|
| JSON Arrays | `text[]` | `NVARCHAR(MAX)` (JSON string) |
| Auto-increment | `SERIAL` | `IDENTITY(1,1)` |
| NOW() | `NOW()` | `GETUTCDATE()` |
| String comparison | Case-sensitive | Case-insensitive (default) |
| Schema | Multiple schemas | Single `dbo` schema |

## Test Coverage

### Unit Tests (Client-side)
- ✅ LocalBackendService mutations
- ✅ Seed data integrity
- ✅ Schedule overlap calculations
- ⏳ Event participation logic

### Integration Tests (API)
```bash
# Create integration test suite
npm test -- --integration
```

Required coverage:
- [ ] Auth endpoints (`/v1/auth/login`, `/v1/auth/sso`)
- [ ] Dashboard endpoint (`/v1/me/dashboard`)
- [ ] Friend request flow
- [ ] Event participation
- [ ] Presence updates

### Load Tests
```bash
# Azure Load Testing
az load test create \
  --test-id between-load-test \
  --resource-group between-rg
```

## Security Checklist

- [ ] Enable Azure SQL firewall rules (allow Azure services)
- [ ] Set up Managed Identity for App Service → SQL
- [ ] Enable Transparent Data Encryption (TDE)
- [ ] Configure backup retention (7-35 days)
- [ ] Set up Azure Monitor alerts
- [ ] Enable Query Performance Insights
- [ ] Configure Row-Level Security for student data

## Monitoring

```sql
-- Check slow queries
SELECT TOP 10
    qs.execution_count,
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    qt.text AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY avg_elapsed_time DESC;
```

## Rollback Plan

If migration fails:
1. Keep LocalBackendService as fallback
2. API can route to backup PostgreSQL instance
3. DNS switch back to old endpoint
4. Seed data always in git as source of truth
