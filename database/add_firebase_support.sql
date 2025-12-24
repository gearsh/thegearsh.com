-- Gearsh Database Migration: Add Firebase Support
-- Run this after setting up Firebase to support hybrid authentication

-- Add firebase_uid column to users table
ALTER TABLE users ADD COLUMN firebase_uid TEXT UNIQUE;

-- Add provider columns for social auth tracking
ALTER TABLE users ADD COLUMN provider TEXT DEFAULT 'email';
ALTER TABLE users ADD COLUMN provider_id TEXT;

-- Create index on firebase_uid for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);

-- Make password_hash optional for social auth users
-- SQLite doesn't support ALTER COLUMN, so we work around it:
-- For new users signing in with Google/Apple, password_hash will be set to a placeholder

-- Update any existing users to have the 'email' provider
UPDATE users SET provider = 'email' WHERE provider IS NULL;

