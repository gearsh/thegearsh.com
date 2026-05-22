-- Add username support for shareable artist booking links
-- Run against production D1 when deploying username-based profile URLs

-- Ensure username column exists (no-op if already present)
ALTER TABLE users ADD COLUMN username TEXT;

-- Backfill missing usernames from display/stage names where possible
-- Manual follow-up may be needed for duplicates; signup/login APIs also backfill at runtime.
