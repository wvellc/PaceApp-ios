# Strava Integration — TODO

Backlog for the Strava integration. See `functions/STRAVA_SETUP.md` for the setup steps
and the flow (app does OAuth authorize only; Cloud Functions hold the secret, exchange
and refresh tokens, and upload summary activities).

## 🔴 Required to work (external + config)
- [ ] Create a Strava API app; set **Authorization Callback Domain = `thepaceapp.web.app`** (redirects to the hosted `/stravaCallback` relay → `paceapp://strava-callback`); copy Client ID + Secret — <https://www.strava.com/settings/api>
- [ ] Fill `clientId` and `functionsBaseURL` in `Utility/Constant/Strava.swift` (`redirectURI` already points at the relay)
- [ ] `firebase functions:secrets:set STRAVA_CLIENT_SECRET`; put `STRAVA_CLIENT_ID` in `functions/.env`
- [ ] `cd functions && npm install`
- [ ] Upgrade the Firebase project to the **Blaze** plan (Cloud Functions require it)
- [ ] `firebase deploy --only functions,firestore:rules,hosting` (hosting publishes the relay page)
- [ ] Confirm the `events (userId + status)` composite index is deployed (used by backfill)
- [ ] **Request a Strava connected-athlete quota increase** before onboarding real users (see note below) — <https://www.strava.com/settings/api>

## 🟡 Before shipping
- [ ] Replace the "Powered by Strava" text with Strava's official **"Connect with Strava"** button asset in both `StravaConnectScreen.swift` and `ConnectStravaStepView.swift` (brand-guideline requirement)
- [ ] End-to-end test on a real device — the OAuth round-trip and upload are untested
- [ ] `start_date_local` is sent as UTC ISO → activities may show a timezone offset; pass a real local start time if it matters
- [ ] **Track Strava sync status on the event document**
  - Add an explicit `stravaSyncStatus` field to `EventDocument` (`notSynced` / `pending` / `synced` / `failed`) instead of inferring it from `stravaActivityId` / `stravaSyncError`; surface it in History / Event Details
  - On any app-side event edit (name/location via `EditEvent` → `EventUpdateCenter`), set `stravaSyncStatus = pending` alongside the `updatedAt` stamp in `EventDocumentMapper`, then have a function re-push the change (`PUT /activities/{id}` or re-run the summary sync)
  - Formalizes the existing `stravaActivityId` + `stravaSyncedAt` (success) / `stravaSyncError` (failure) stamps into one status field and adds the "edited → needs re-sync" transition

## 🟢 Later
- [ ] Handle Strava's **deauthorization webhook** — flip `connected` to false when a user revokes access on Strava's side
- [ ] **GPX / route upload** (map + route) — needs per-point timestamps we don't currently store; would require a timestamped track from the watch
- [ ] Per-event **"Sync to Strava"** button on Event Details (the `stravaSync` function already exists)
- [ ] **Surface sync failures** — functions write `stravaSyncError` on the event, but nothing shows it yet

## ⚠️ Known limitation — Strava connected-athlete quota

**Symptom:** after authorizing, Strava returns `Error 403: Limit of connected athletes exceeded`
("This app has exceeded the limit of connected athletes… request a quota increase").

**Cause:** this is a **Strava-side app-tier limit**, not a bug in our app. Every new Strava API
app starts with a very low connected-athlete cap (often 1 — the owner). The OAuth flow, redirect
relay, Cloud Functions, and secret are all verified working; Strava blocks at its own quota gate.

**Dev workaround (to keep testing):**
- Each authorize tap consumes a slot even if the token exchange didn't finish. Revoke the existing
  grant at <https://www.strava.com/settings/apps> (find PaceApp → Revoke Access), then retry.
- Test with the **same Strava account that owns API app `269660`** (the owner gets the first slot).

**Real fix (to onboard users):** request a connected-athlete **quota increase** from Strava via the
form in the app's API settings — an approval step with Strava, nothing to change in the app.
