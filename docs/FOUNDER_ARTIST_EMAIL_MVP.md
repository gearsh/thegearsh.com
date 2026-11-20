# Gearsh Command — Artist Email Workspace (MVP)

## Existing infrastructure
- Public website and founder dashboard: Cloudflare Pages, D1 database.
- Founder access: bearer session plus `FOUNDER_ACCESS_KEY` header through `requireFounder`.
- Outgoing email: Resend REST API, using `RESEND_API_KEY` and verified `EMAIL_FROM` company-domain address.
- Per-artist Email action: Gearsh Command > Artists, backed by `/api/founder/artist-email`.
- Outgoing audit: `founder_artist_email_log` D1 table. `accepted` means provider accepted the send, **not** delivered/read.
- Incoming email: no previous Gmail or domain inbox connector existed.

## New UI
Gearsh Command > **Artist email**:
- Inbox: recent mail **from registered artists** in `thegearsh@gmail.com`, including messages to company aliases **only after Cloudflare Email Routing forwards them there**.
- Read message: displays extracted plain text, never untrusted HTML.
- Sent history: provider acceptance/failure status for messages sent using the Gearsh artist Email action.
- Compose: use **Artists > Email** for an individual account. No bulk marketing, no auto-response.
- Unrelated personal Gmail messages are excluded from returned inbox results (only registered artist email addresses match).

## Required configuration before inbox works
1. **Cloudflare Email Routing:** Under thegearsh.com Email Routing, add the company-domain aliases that should feed the inbox (e.g. `hello@thegearsh.com`, `support@thegearsh.com`) and forward to **thegearsh@gmail.com**. Verify Gmail as destination. Confirm the domain's MX routing is compatible; do not replace existing working MX records blindly.
2. **Google Cloud:** Create or select a project, enable **Gmail API**, configure OAuth consent and create an OAuth client for the Gmail account owner. Authorize **only** `https://www.googleapis.com/auth/gmail.readonly`, request `access_type=offline`, and acquire a refresh token for **thegearsh@gmail.com**. Use a proper production OAuth configuration: Google external OAuth clients in *Testing* can issue refresh tokens expiring after 7 days.
3. **Cloudflare Pages Production > Variables and Secrets:** set the following as **Secret** (not Text):
   - `GEARSH_GMAIL_CLIENT_ID` (OAuth client ID)
   - `GEARSH_GMAIL_CLIENT_SECRET` (OAuth client secret)
   - `GEARSH_GMAIL_REFRESH_TOKEN` (refresh token granted to thegearsh@gmail.com)
4. Continue using `RESEND_API_KEY` as a production Secret; set `EMAIL_FROM` to an address under a **verified sending domain** e.g. `The Gearsh <nhlanhla@thegearsh.com>`. Optional `GEARSH_REPLY_TO` can be a company-domain mailbox routed to Gmail, or default `thegearsh@gmail.com`.
5. Redeploy the production Pages project after secret changes. Do not commit or paste OAuth tokens, email passwords or Resend keys anywhere in GitHub or chat.
6. Test: email a registered artist from Gearsh Command > Artists > Email, verify sent-history `accepted`, have the artist reply, verify reply arrives in thegearsh@gmail.com, then view the new inbox.

## Scope and limitations
- Gmail integration is **read-only**. The app does not send via Gmail API, use Gmail passwords, expose raw OAuth tokens or fetch attachments.
- Messages from non-artist contacts will remain in Gmail but are not shown in Gearsh Command.
- Only up to the **65 most recent inbox messages** are inspected per refresh; this is an MVP, not a full searchable archive.
- Outgoing emails are sent from the verified company-domain address through Resend, with Reply-To pointing at the unified Gmail inbox. Replies don't become part of the outgoing email log.
- Gmail OAuth's sensitive/restricted scope may require Google review, suitable consent configuration and/or Workspace controls. Never disable authentication checks to speed up setup.
- Gmail forwarding must be tested for each company-domain alias. Configuring this app does **not** create an actual company-domain inbox.
- Verification test must include one inbox item received directly at Gmail and one forwarded from an active company-domain alias.
- The founder-only API remains protected by the same founder session + private key as Gearsh Command.
