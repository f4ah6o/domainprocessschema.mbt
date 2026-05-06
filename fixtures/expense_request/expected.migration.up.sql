-- migrate:up
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL,
  role TEXT NOT NULL
);

CREATE TABLE expense_requests (
  id TEXT PRIMARY KEY NOT NULL,
  amount INTEGER NOT NULL,
  reason TEXT NOT NULL,
  applicant_id TEXT NOT NULL,
  status TEXT DEFAULT 'draft',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (applicant_id) REFERENCES users(id),
  CHECK (amount > 0),
  UNIQUE (applicant_id, created_at)
);

CREATE INDEX idx_expense_requests_status ON expense_requests (status);

CREATE INDEX idx_expense_requests_applicant_id_created_at ON expense_requests (applicant_id, created_at);
