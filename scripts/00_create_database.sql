-- Run this file while connected to the default "postgres" database.
-- CREATE DATABASE cannot run inside a transaction block / another DB context.
SELECT 'CREATE DATABASE "motorportal"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'motorportal')\gexec
