# FreeBay — Database Scripts

Raw SQL scripts for managing the PostgreSQL database.

> **Note:** The backend uses **Prisma** for ORM and migrations (`npx prisma migrate dev`).
> These raw SQL scripts are provided as an **alternative** for direct database management, CI/CD pipelines, or environments where Prisma CLI is not available.

## Prerequisites

- PostgreSQL 14+ running locally or via Docker
- `psql` CLI available or a GUI client (DBeaver, pgAdmin, etc.)

## Connection

```bash
# Default dev connection string (matches .env.example)
psql "postgresql://postgres:postgres@localhost:5432/freebay"
```

## Usage

### 1. Create all tables (fresh database)

```bash
psql "postgresql://postgres:postgres@localhost:5432/freebay" -f db/migrations/001_create_tables.sql
```

### 2. Seed dev data

```bash
psql "postgresql://postgres:postgres@localhost:5432/freebay" -f db/seeds/001_seed_dev.sql
```

### 3. Reset database (⚠️ destructive!)

```bash
psql "postgresql://postgres:postgres@localhost:5432/freebay" -f db/scripts/reset.sql
psql "postgresql://postgres:postgres@localhost:5432/freebay" -f db/migrations/001_create_tables.sql
psql "postgresql://postgres:postgres@localhost:5432/freebay" -f db/seeds/001_seed_dev.sql
```

## Docker Quick Start

```bash
# Start PostgreSQL with Docker
docker run --name freebay-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=freebay \
  -p 5432:5432 \
  -d postgres:16-alpine
```

## File Structure

```
db/
├── README.md                       # This file
├── migrations/
│   └── 001_create_tables.sql       # All CREATE TABLE + INDEX statements
├── seeds/
│   └── 001_seed_dev.sql            # Sample data for development
└── scripts/
    └── reset.sql                   # DROP all tables + enums (dev only)
```
