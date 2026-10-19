import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import process from 'node:process';
import { URL } from 'node:url';

if (process.argv.includes('--apply')) throw new Error('This audit is read-only; no apply mode exists.');
if (!process.argv.includes('--read-only')) throw new Error('Pass --read-only to confirm this database audit is read-only.');

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error('DATABASE_URL is required.');
const parsedUrl = new URL(databaseUrl);
const databaseName = parsedUrl.pathname.replace(/^\//, '');
if (databaseName !== 'freebay_test_db' && process.env.CPF_AUDIT_ALLOW_NONTEST_READ_ONLY !== '1') {
  throw new Error('Refusing non-test database; set CPF_AUDIT_ALLOW_NONTEST_READ_ONLY=1 only after owner approval.');
}

const pool = new Pool({
  connectionString: databaseUrl,
  options: '-c default_transaction_read_only=on',
});
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

try {
  const users = await prisma.user.findMany({ select: { cpf: true, cpfHash: true } });
  const plaintext = users.filter((user) => user.cpf && !user.cpf.startsWith('v1:'));
  const duplicateGroups = (values) => {
    const counts = new Map();
    for (const value of values) counts.set(value, (counts.get(value) ?? 0) + 1);
    return [...counts.values()].filter((count) => count > 1).length;
  };
  const normalizedCpf = plaintext.map((user) => user.cpf.replace(/[^a-zA-Z0-9]/g, '').toUpperCase());
  const hashes = users.flatMap((user) => user.cpfHash ? [user.cpfHash] : []);

  process.stdout.write(`${JSON.stringify({
    mode: 'read-only; no rows changed',
    rows: users.length,
    encryptedV1Rows: users.filter((user) => user.cpf?.startsWith('v1:')).length,
    plaintextRows: plaintext.length,
    plaintextRowsMissingHash: plaintext.filter((user) => !user.cpfHash).length,
    hashRowsMissingCpf: users.filter((user) => user.cpfHash && !user.cpf).length,
    duplicateNormalizedPlaintextGroups: duplicateGroups(normalizedCpf),
    duplicateHashGroups: duplicateGroups(hashes),
  }, null, 2)}\n`);
} finally {
  await prisma.$disconnect();
  await pool.end();
}
