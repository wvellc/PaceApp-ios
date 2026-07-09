# Strava Integration — TODO

Backlog for the Strava integration. See `functions/STRAVA_SETUP.md` for the setup steps
and the flow (app does OAuth authorize only; Cloud Functions hold the secret, exchange
and refresh tokens, and upload summary activities).

## 🔴 Required to work (external + config)
- [ ] Create a Strava API app; set **Authorization Callback Domain = `strava-callback`**; copy Client ID + Secret — <https://www.strava.com/settings/api>
- [ ] Fill `clientId` and `functionsBaseURL` in `Utility/Constant/Strava.swift`
- [ ] `firebase functions:secrets:set STRAVA_CLIENT_SECRET`; put `STRAVA_CLIENT_ID` in `functions/.env`
- [ ] `cd functions && npm install`
- [ ] Upgrade the Firebase project to the **Blaze** plan (Cloud Functions require it)
- [ ] `firebase deploy --only functions,firestore:rules`
- [ ] Confirm the `events (userId + status)` composite index is deployed (used by backfill)

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
