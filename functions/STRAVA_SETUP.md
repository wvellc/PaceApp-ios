# Strava Integration — Setup

The app does OAuth **authorize** only; the **client secret, token exchange/refresh,
and activity upload all live in Cloud Functions**. The device never holds a Strava token.

## 1. Create a Strava API application
<https://www.strava.com/settings/api>

- **Authorization Callback Domain**: `thepaceapp.web.app`
  (Strava requires a real domain; it redirects to `/stravaCallback`, a Cloud Function
  that 302-redirects to the `paceapp://strava-callback` deep link.)
- Note your **Client ID** and **Client Secret**.

## 2. Fill the iOS config
`Utility/Constant/Strava.swift`:
- `clientId` → your Strava Client ID
- `functionsBaseURL` → your deployed region base, e.g.
  `https://us-central1-thepaceapp.cloudfunctions.net`
- `redirectURI` is already the hosted relay (`https://thepaceapp.web.app/stravaCallback/`) —
  change the domain only if you host on a different one. It relays to the existing
  `paceapp://strava-callback` deep link, which `PaceApp.onOpenURL` already handles.

The `paceapp` URL scheme and `strava` query scheme are already in `PaceApp-Info.plist`.
The `/stravaCallback` rewrite → `stravaCallback` function already exists in `firebase.json`.

## 3. Configure the Functions secrets
```bash
cd functions && npm install
firebase functions:secrets:set STRAVA_CLIENT_SECRET   # paste the Client Secret
echo "STRAVA_CLIENT_ID=<your client id>" > .env       # not secret; also ships in the app
```

## 4. Deploy
```bash
firebase deploy --only functions,firestore:rules,hosting
```
> Cloud Functions require the **Blaze** plan. `hosting` wires `/stravaCallback` to the redirect function.

## Endpoints (called by the app with the Firebase ID token)
| Function | Trigger | Purpose |
|---|---|---|
| `stravaExchange` | HTTPS POST `{code}` | OAuth code → tokens, connect account |
| `stravaSync` | HTTPS POST `{eventId}` | Upload one completed event |
| `stravaBackfill` | HTTPS POST | Upload recent unsynced completed events |
| `stravaDisconnect` | HTTPS POST | Revoke (`/oauth/revoke`) + clear tokens |
| `onEventCompleted` | Firestore `events/{id}` write | Auto-upload when an event becomes `completed` |
| `stravaWebhook` | HTTPS GET/POST | Push-subscription: handshake + athlete-deauthorize → clear connection |

## Data
- `stravaTokens/{uid}` — access/refresh tokens (server-only; rules deny all client access).
- `users/{uid}.strava` — client-readable summary `{ connected, athleteName, athleteId }`.
- Each synced event is stamped `stravaActivityId` (dedupe) + `stravaSyncedAt`.

## Notes
- Uploads are **TCX files** (`POST /uploads`): each PaceApp segment becomes a Strava **lap**
  (distance + time + avg HR), then `PUT /activities/{id}` sets the exact sport type + rich
  description. Still summary-level — no GPS map / HR trace (no per-point timestamps stored).
- Disconnect uses **`POST /oauth/revoke`** (the deprecated `/oauth/deauthorize` is retired
  2027-06-01). A revoke elsewhere is detected by a **401** or the webhook and clears the connection.

## Deauthorization webhook (one-time setup)
Register the push subscription after deploying (`verify_token` must match `STRAVA_WEBHOOK_VERIFY_TOKEN`):
```bash
curl -X POST https://www.strava.com/api/v3/push_subscriptions \
  -F client_id=<CLIENT_ID> \
  -F client_secret=<CLIENT_SECRET> \
  -F callback_url=https://us-central1-thepaceapp.cloudfunctions.net/stravaWebhook \
  -F verify_token=paceapp-strava-webhook
```
The response `{"id": <n>}` is the subscription id — set `STRAVA_WEBHOOK_SUBSCRIPTION_ID = <n>` in `index.js` and redeploy to arm the spoof guard (only one subscription per app is allowed).
