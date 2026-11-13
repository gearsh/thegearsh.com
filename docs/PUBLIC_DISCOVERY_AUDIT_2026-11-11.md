# Public discovery audit — 11 November 2026

Scope: `/api/artists/feed`, `/api/search`, and `/api/artists`. This is a **visibility-only** improvement. It does not delete accounts, profiles, images, services, bookings, or payment records.

## Findings

- `/api/artists/feed` already excludes disabled accounts, `is_demo` records, seeded unclaimed email accounts and removal-request usernames, but records made during QA without `is_demo` can still surface.
- The feed previously deduplicated by `artist_id` only. Different artist-profile rows owned by the same user could appear more than once.
- `/api/search` and `/api/artists` did not share the feed's demo/removal filters. They now share the *narrow* known-test and identity-dedupe policy, but broader visibility parity remains follow-up work.
- The frontend has additional card-level deduplication. No record-level production database exports were available to establish whether any specific apparent duplicate represents two separate profiles, or repeated feed category entries.

## Classification of the previously observed public names

| Account / name | Classification | Action |
| --- | --- | --- |
| Revamp Signup Check | Explicit QA/test display name | Hide from public feed/search/list APIs only |
| Revamp Browser Check | Explicit QA/test display name | Hide from public feed/search/list APIs only |
| The Gearsh (`gearsh`) | Company/admin-like account; role unverified | Review privately, preserve and leave unchanged pending owner confirmation |
| Hot pepper carwash | Likely non-creative business | Review classification; do not auto-hide without checking offered services |
| Adinkra Media Pty LTD | Potential legitimate creative agency | Preserve; allow under a future studio/agency profile type |
| Lodge themkhosi, dj | Ambiguous venue / DJ identity | Review, do not hide |
| Other listed performer names | Potential real artists | Preserve even with missing photo |

## Changes proposed

- A shared policy hides only the two *exact* test display names observed in the audit, case/whitespace-insensitively. This is a stopgap; preferred long-term solution is an explicit admin-controlled `discovery_visibility` or `account_type` field with audit logs.
- Deduplicate repeated rows by `artist_id` only, never by user ID or artist name. One user may legitimately own multiple distinct profiles. No database mutation.
- Apply the shared policy to the feed, artist list, and search results.

## Limitations / release checks

1. Verify the two test profiles no longer appear in all three public endpoints, and that their account records remain intact.
2. Check known creative profiles, agency profiles, and account profile pages still work; check the homepage, directory, and search suggestions after cache expiry.
3. Count before/after visible unique *user IDs* and compare to backend records; do not interpret category membership as a duplicate user.
4. Query production database privately for duplicate `artist_profiles.user_id` and overlapping display names; inspect rather than deleting.
5. Review account-type/category design for businesses, studios, venues, artists and clients. Do not classify by a broad keyword matching `lodge`, `media`, `carwash` or `Gearsh`.
6. Search/list endpoint pagination may return fewer than the requested page size when filtered rows are among the first page. Move explicit filtering into a central query only after schema/compatibility review.
7. The search/list endpoints do not yet mirror every feed exclusion (notably `is_demo` and removal requests). Resolve consistently as a separate carefully tested change.

### Safety

No schema migrations, no `DELETE`, no `UPDATE` to user data, no automated account suspension, and no aggressive name-based fuzzy deduplication.
