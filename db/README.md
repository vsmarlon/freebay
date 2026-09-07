# FreeBay — Database

The Prisma schema in `nest-backend/prisma/schema.prisma` is the source of truth.

Use Prisma commands from `nest-backend`; the old raw SQL migration and reset scripts were removed to avoid a second schema source.

## Prerequisites

- PostgreSQL 14+ and Redis running natively or on an externally managed host
- `psql` CLI available or a GUI client (DBeaver, pgAdmin, etc.)

## Usage

### Seed dev data

```bash
psql "postgresql://postgres:postgres@localhost:5432/freebay" -f db/seeds/001_seed_dev.sql
```

## File Structure

```
db/
├── README.md
└── seeds/001_seed_dev.sql          # Sample data for development
```
