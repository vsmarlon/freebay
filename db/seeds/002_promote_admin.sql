-- Promote a user to ADMIN so the /admin routes become reachable.
--
-- There is no HTTP route that grants the ADMIN role: registration always writes
-- 'USER', so the first administrator has to be promoted here. Run this against
-- the target database, then have that user LOG IN AGAIN — the role is read from
-- the JWT payload, not from the database, so an existing token keeps its stale
-- 'USER' role until a new one is issued.
--
--   psql -h localhost -U postgres -d freebay -f db/seeds/002_promote_admin.sql
--
-- Replace the e-mail below before running.

UPDATE "User"
SET role = 'ADMIN'
WHERE email = 'admin@freebay.local';

SELECT id, email, role FROM "User" WHERE role = 'ADMIN';
