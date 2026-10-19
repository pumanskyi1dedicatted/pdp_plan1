-- 001_init.sql: schema for BankAPI

BEGIN;

CREATE TABLE IF NOT EXISTS users (
    username TEXT   NOT NULL,
    password BYTEA,
    own      BIGINT NOT NULL DEFAULT 0,
    debt     BIGINT NOT NULL DEFAULT 0
);

-- The account that collects fees. WHERE NOT EXISTS makes the migration safe to run twice.
INSERT INTO users (username, password, own, debt)
SELECT 'BANK', NULL, 0, 0
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'BANK');

COMMIT;
