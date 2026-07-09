# Strava Integration — Setup

The app does OAuth **authorize** only; the **client secret, token exchange/refresh,
and activity upload all live in Cloud Functions**. The device never holds a Strava token.

## 1. Create a Strava API application
<https://www.strava.com/settings/api>

- **Authorization Callback Domain**: `strava-callback`
  (must match the host in `paceapp://strava-callback`)
- Note your **Client ID** and **Client Secret**.

## 2. Fill the iOS config
`Utility/Constant/Strava.swift`:
- `clientId` → your Strava Client ID
- `functionsBaseURL` → your deployed region base, e.g.
  `https://us-central1-thepaceapp.cloudfunctions.net`

The `paceapp` URL scheme and `strava` query scheme are already in `PaceApp-Info.plist`.

## 3. Configure the Functions secrets
```bash
cd functions && npm install
firebase functions:secrets:set STRAVA_CLIENT_SECRET   # paste the Client Secret
echo "STRAVA_CLIENT_ID=<your client id>" > .env       # not secret; also ships in the app
```

## 4. Deploy
```bash
firebase deploy --only functions,firestore:rules
```
> Cloud Functions require the **Blaze** plan.

## Endpoints (called by the app with the Firebase ID token)
| Function | Trigger | Purpose |
|---|---|---|
| `stravaExchange` | HTTPS POST `{code}` | OAuth code → tokens, connect account |
| `stravaSync` | HTTPS POST `{eventId}` | Upload one completed event |
| `stravaBackfill` | HTTPS POST | Upload recent unsynced completed events |
| `stravaDisconnect` | HTTPS POST | Deauthorize + clear tokens |
| `onEventCompleted` | Firestore `events/{id}` write | Auto-upload when an event becomes `completed` |

## Data
- `stravaTokens/{uid}` — access/refresh tokens (server-only; rules deny all client access).
- `users/{uid}.strava` — client-readable summary `{ connected, athleteName, athleteId }`.
- Each synced event is stamped `stravaActivityId` (dedupe) + `stravaSyncedAt`.

## Notes
- Uploads are **summary** activities (`POST /activities`): name, sport, distance,
  elapsed time, start date, avg HR in the description. No GPS map / HR trace — the
  stored event data has no per-point timestamps or HR stream.
- Strava brand guidelines: the connect screen shows "Powered by Strava". Replace the
  text with Strava's official "Connect with Strava" button asset before release.
