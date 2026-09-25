CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    kind TEXT NOT NULL CHECK (kind IN ('income', 'expense')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind TEXT NOT NULL CHECK (kind IN ('income', 'expense')),
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    category_id UUID REFERENCES categories (id),
    source TEXT NOT NULL DEFAULT 'telegram',
    raw_message TEXT,
    parsed_by TEXT,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transactions_occurred_at ON transactions (occurred_at DESC);

CREATE TABLE recurring_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    description TEXT NOT NULL,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    category_id UUID REFERENCES categories (id),
    due_day SMALLINT NOT NULL CHECK (due_day BETWEEN 1 AND 31),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
