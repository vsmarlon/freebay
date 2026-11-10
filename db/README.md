# FreeBay — Database

The Prisma schema in `nest-backend/prisma/schema.prisma` is the source of truth.

Use Prisma commands from `nest-backend`; this pre-production project has no migration workflow before first production release.

## Prerequisites

- PostgreSQL 14+ and Redis running natively or on an externally managed host
- `psql` CLI available or a GUI client (DBeaver, pgAdmin, etc.)

## Usage

### Seed dev data

```bash
npm run db:sync
npm run db:seed
```

## File Structure

```
db/
└── README.md
```
