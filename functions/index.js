/**
 * PaceApp Cloud Functions — Strava integration.
 *
 * The iOS/Android app performs the OAuth *authorize* step only and sends the
 * returned code here. These functions hold the Strava client secret, exchange
 * and refresh tokens, store them server-side (never on device), and upload
 * completed activities as TCX files (POST /uploads) so each PaceApp segment
 * lands as a Strava lap.
 *
 * Config:
 *   firebase functions:secrets:set STRAVA_CLIENT_SECRET
 *   (STRAVA_CLIENT_ID is a plain param — set in .env or the deploy environment)
 */

const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { defineString, defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// MARK: - Config

const STRAVA_CLIENT_ID = defineString("STRAVA_CLIENT_ID");
const STRAVA_CLIENT_SECRET = defineSecret("STRAVA_CLIENT_SECRET");

const STRAVA_TOKEN_URL = "https://www.strava.com/oauth/token";
const STRAVA_DEAUTH_URL = "https://www.strava.com/oauth/deauthorize";
const STRAVA_ACTIVITIES_URL = "https://www.strava.com/api/v3/activities";
const STRAVA_UPLOADS_URL = "https://www.strava.com/api/v3/uploads";

// PaceApp activity string → Strava sport_type.
const SPORT_BY_ACTIVITY = { Run: "Run", Walking: "Walk", Cycling: "Ride", Other: "Workout" };

// PaceApp activity → TCX Sport attribute (the schema allows only Running/Biking/Other;
// the exact Strava sport_type is set afterwards via PUT /activities/{id}).
const TCX_SPORT_BY_ACTIVITY = { Run: "Running", Walking: "Running", Cycling: "Biking", Other: "Other" };

// MARK: - Auth helper

/** Verifies the Firebase ID token on the request and returns the uid, or null (response already sent). */
async function requireUid(req, res) {
  const match = (req.get("Authorization") || "").match(/^Bearer (.+)$/);
  if (!match) {
    res.status(401).json({ error: "Please sign in again to continue." });
    return null;
  }
  try {
    const decoded = await admin.auth().verifyIdToken(match[1]);
    return decoded.uid;
  } catch (e) {
    res.status(401).json({ error: "Your session expired. Please sign in again." });
    return null;
  }
}

// MARK: - Strava token helpers

/** POSTs a form-encoded token request to Strava and returns the parsed JSON. */
async function stravaTokenRequest(params) {
  const resp = await fetch(STRAVA_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(params),
  });
  const json = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const err = new Error(json.message || "Strava token request failed.");
    err.status = resp.status;
    throw err;
  }
  return json;
}

/** Persists tokens server-side and a client-readable summary on the user doc. Returns the athlete name. */
async function storeTokens(uid, token) {
  const athlete = token.athlete || {};
  const athleteName = [athlete.firstname, athlete.lastname].filter(Boolean).join(" ");

  await db.doc(`stravaTokens/${uid}`).set({
    accessToken: token.access_token,
    refreshToken: token.refresh_token,
    expiresAt: token.expires_at, // epoch seconds
    scope: token.scope || null,
    athleteId: athlete.id || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await db.doc(`users/${uid}`).set({
    strava: {
      connected: true,
      athleteId: athlete.id || null,
      athleteName: athleteName || null,
      connectedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  }, { merge: true });

  return athleteName;
}

/** Marks the account disconnected server-side + client-side. Used when Strava has
 *  revoked our tokens (a refresh/API call returns 401/400) so the app reflects it. */
async function clearStravaConnection(uid) {
  await db.doc(`stravaTokens/${uid}`).delete().catch(() => {});
  await db.doc(`users/${uid}`).set({
    strava: { connected: false, athleteName: null, athleteId: null },
  }, { merge: true });
}

/** Returns a valid access token for the user, refreshing (and re-storing) it if it's near expiry. */
async function getValidAccessToken(uid) {
  const snap = await db.doc(`stravaTokens/${uid}`).get();
  if (!snap.exists) throw new Error("Strava is not connected.");
  const data = snap.data();

  const now = Math.floor(Date.now() / 1000);
  if (data.expiresAt && now < data.expiresAt - 300) return data.accessToken;

  let refreshed;
  try {
    refreshed = await stravaTokenRequest({
      client_id: STRAVA_CLIENT_ID.value(),
      client_secret: STRAVA_CLIENT_SECRET.value(),
      grant_type: "refresh_token",
      refresh_token: data.refreshToken,
    });
  } catch (e) {
    // 400/401 on refresh = the user revoked access (or Strava invalidated the token).
    // Clear the connection so the app shows "Not connected"; leave transient 5xx/network
    // errors intact so we retry next time.
    if (e.status === 400 || e.status === 401) {
      await clearStravaConnection(uid);
      throw new Error("Strava is not connected.");
    }
    throw e;
  }
  await db.doc(`stravaTokens/${uid}`).set({
    accessToken: refreshed.access_token,
    refreshToken: refreshed.refresh_token, // Strava rotates the refresh token
    expiresAt: refreshed.expires_at,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  return refreshed.access_token;
}

// MARK: - Activity upload

const METERS_PER_MILE = 1609.344;

/** The event's unit comes from the user's preference at creation ("Miles"; anything else is km). */
function isMiles(event) {
  return event.measure === "Miles";
}

/** Unit label for descriptions, matching the event's stored measure. */
function unitLabel(event) {
  return isMiles(event) ? "mi" : "km";
}

/** Distance (in the event's unit) → meters for Strava. Rejects non-finite/negative values. */
function metersFor(distance, event) {
  const d = Number(distance);
  if (!Number.isFinite(d) || d <= 0) return 0;
  return isMiles(event) ? d * METERS_PER_MILE : d * 1000;
}

/** Distance actually covered — actualDistance, else the sum of per-segment completed_distance. */
function coveredDistance(event) {
  if (Number(event.actualDistance) > 0) return Number(event.actualDistance);
  const segments = Array.isArray(event.completedSegments) ? event.completedSegments : [];
  return segments.reduce((total, s) => total + (parseFloat(s.completed_distance) || 0), 0);
}

/** Seconds → "H:MM:SS" (or "MM:SS" under an hour). */
function fmtTime(totalSeconds) {
  const s = Math.max(0, Math.round(totalSeconds));
  const h = Math.floor(s / 3600);
  const m = String(Math.floor((s % 3600) / 60)).padStart(2, "0");
  const sec = String(s % 60).padStart(2, "0");
  return h > 0 ? `${h}:${m}:${sec}` : `${m}:${sec}`;
}

/** Every meaningful stat the manual-create endpoint can't carry as a field goes in the description. */
function activityDescription(event, covered) {
  const unit = unitLabel(event);
  const lines = [];

  if (event.location) lines.push(`📍 ${event.location}`);

  if (covered > 0) {
    let line = `📏 ${covered.toFixed(2)} ${unit}`;
    if (Number(event.distanceValue) > 0) line += ` of ${Number(event.distanceValue).toFixed(2)} ${unit} planned`;
    lines.push(line);
  }

  if (Number(event.actualTimeSeconds) > 0) {
    let line = `⏱ ${fmtTime(event.actualTimeSeconds)}`;
    if (Number(event.goalTimeSeconds) > 0) {
      const diff = event.actualTimeSeconds - event.goalTimeSeconds;
      line += ` · goal ${fmtTime(event.goalTimeSeconds)} (${diff <= 0 ? "−" : "+"}${fmtTime(Math.abs(diff))})`;
    }
    lines.push(line);
  }

  // Watch pace first; else derive from what was actually covered.
  const paceSec = Number(event.avgPaceSeconds) > 0
    ? Number(event.avgPaceSeconds)
    : (covered > 0 && Number(event.actualTimeSeconds) > 0 ? event.actualTimeSeconds / covered : 0);
  if (paceSec > 0) lines.push(`⚡ Avg pace ${fmtTime(paceSec)} /${unit}`);

  if (Number(event.avgHeartRate) > 0) lines.push(`❤️ Avg HR ${event.avgHeartRate} bpm`);
  if (Number(event.elevationGain) > 0) lines.push(`⛰ Elevation gain ${Math.round(event.elevationGain)} m`);
  if (Number(event.effortPercentage) > 0) lines.push(`💪 Effort ${Math.round(event.effortPercentage)}%`);

  // Per-segment splits — only segments the watch actually recorded something for.
  const segments = Array.isArray(event.completedSegments) ? event.completedSegments : [];
  const splits = segments
    .map((s, i) => ({ n: i + 1, d: parseFloat(s.completed_distance) || 0, t: s.elapsed_time }))
    .filter((s) => s.d > 0 || s.t);
  if (splits.length > 1) {
    lines.push("Splits:");
    splits.forEach((s) => lines.push(`${s.n}. ${s.d > 0 ? `${s.d.toFixed(2)} ${unit}` : "—"}${s.t ? ` · ${s.t}` : ""}`));
  }

  lines.push("Synced from PaceApp");
  return lines.join("\n");
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** Parses a segment's elapsed time — "H:MM:SS"/"MM:SS" or a raw number — into seconds. */
function secondsFromTime(value) {
  if (typeof value === "number" && Number.isFinite(value)) return Math.max(0, Math.round(value));
  if (typeof value !== "string") return 0;
  const trimmed = value.trim();
  if (/^\d+(\.\d+)?$/.test(trimmed)) return Math.max(0, Math.round(parseFloat(trimmed)));
  const parts = trimmed.split(":").map((p) => parseInt(p, 10));
  if (parts.length === 0 || parts.some((n) => Number.isNaN(n))) return 0;
  return parts.reduce((acc, n) => acc * 60 + n, 0);
}

/** Real start time (ms) and elapsed seconds — completedAt marks the finish, so start = finish − elapsed. */
function startInfo(event) {
  const elapsed = Number(event.actualTimeSeconds) > 0 ? Number(event.actualTimeSeconds) : Number(event.goalTimeSeconds) || 0;
  const endTs = event.completedAt || event.scheduledAt;
  const endMs = endTs && endTs.toDate ? endTs.toDate().getTime() : Date.now();
  const startMs = endMs - (Number(event.actualTimeSeconds) > 0 ? elapsed * 1000 : 0);
  return { startMs, elapsed };
}

/** One lap per recorded PaceApp segment; falls back to a single whole-activity lap. */
function buildLaps(event) {
  const segments = Array.isArray(event.completedSegments) ? event.completedSegments : [];
  const laps = segments
    .map((s) => ({
      meters: Math.round(metersFor(parseFloat(s.completed_distance) || 0, event)),
      seconds: secondsFromTime(s.elapsed_time),
    }))
    .filter((l) => l.meters > 0 || l.seconds > 0);
  if (laps.length > 0) return laps;

  // No per-segment detail — represent the whole activity as one lap.
  const meters = Math.round(metersFor(coveredDistance(event), event));
  const seconds = Number(event.actualTimeSeconds) > 0 ? Number(event.actualTimeSeconds) : Number(event.goalTimeSeconds) || 1;
  return [{ meters, seconds: Math.max(1, seconds) }];
}

/** Builds a TCX with one <Lap> per PaceApp segment — this is what makes them Strava laps. */
function buildTCX(event) {
  const { startMs } = startInfo(event);
  const sport = TCX_SPORT_BY_ACTIVITY[event.activityType] || "Other";
  const hr = Number(event.avgHeartRate) > 0 ? Math.round(Number(event.avgHeartRate)) : null;
  const hrPoint = hr ? `<HeartRateBpm><Value>${hr}</Value></HeartRateBpm>` : "";
  const hrLap = hr ? `<AverageHeartRateBpm><Value>${hr}</Value></AverageHeartRateBpm>` : "";

  let cursorMs = startMs;
  let cumulativeMeters = 0;
  const lapXml = buildLaps(event).map((lap) => {
    const lapStartISO = new Date(cursorMs).toISOString();
    const lapEndISO = new Date(cursorMs + lap.seconds * 1000).toISOString();
    const startMeters = cumulativeMeters;
    cumulativeMeters += lap.meters;
    cursorMs += lap.seconds * 1000;
    // Two trackpoints per lap give Strava a monotonic time+distance stream to build laps from.
    return `<Lap StartTime="${lapStartISO}">`
      + `<TotalTimeSeconds>${lap.seconds}</TotalTimeSeconds>`
      + `<DistanceMeters>${lap.meters}</DistanceMeters>`
      + `<Calories>0</Calories>${hrLap}`
      + `<Intensity>Active</Intensity><TriggerMethod>Manual</TriggerMethod><Track>`
      + `<Trackpoint><Time>${lapStartISO}</Time><DistanceMeters>${startMeters}</DistanceMeters>${hrPoint}</Trackpoint>`
      + `<Trackpoint><Time>${lapEndISO}</Time><DistanceMeters>${cumulativeMeters}</DistanceMeters>${hrPoint}</Trackpoint>`
      + `</Track></Lap>`;
  }).join("");

  return `<?xml version="1.0" encoding="UTF-8"?>`
    + `<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">`
    + `<Activities><Activity Sport="${sport}"><Id>${new Date(startMs).toISOString()}</Id>`
    + lapXml
    + `</Activity></Activities></TrainingCenterDatabase>`;
}

/** Uploads a TCX to Strava; returns the upload job json ({ id, activity_id, error, status }). */
async function uploadTCX(accessToken, tcx, { externalId, name, description }) {
  const form = new FormData();
  form.append("data_type", "tcx");
  form.append("external_id", externalId);
  if (name) form.append("name", name);
  if (description) form.append("description", description);
  form.append("file", new Blob([tcx], { type: "application/xml" }), `${externalId}.tcx`);

  const resp = await fetch(STRAVA_UPLOADS_URL, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}` },
    body: form,
  });
  const json = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const err = new Error(json.message || json.error || "Strava rejected the upload.");
    err.status = resp.status;
    throw err;
  }
  return json;
}

/** Polls an upload job until Strava finishes processing it and returns the new activity id. */
async function pollUpload(accessToken, uploadId) {
  for (let attempt = 0; attempt < 12; attempt++) {
    await sleep(1500);
    const resp = await fetch(`${STRAVA_UPLOADS_URL}/${uploadId}`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    const json = await resp.json().catch(() => ({}));
    if (json.activity_id) return json.activity_id;
    if (json.error) {
      // A duplicate still names the existing activity — reuse its id so we stop retrying.
      const dup = String(json.error).match(/duplicate of activity (\d+)/i);
      if (dup) return Number(dup[1]);
      throw new Error(json.error);
    }
  }
  throw new Error("Strava upload is still processing. It will appear shortly.");
}

/** Sets the exact sport type, name and description on the created activity (best-effort). */
async function updateActivity(accessToken, activityId, { sportType, name, description }) {
  const form = new URLSearchParams();
  if (sportType) form.append("sport_type", sportType);
  if (name) form.append("name", name);
  if (description) form.append("description", description);
  await fetch(`${STRAVA_ACTIVITIES_URL}/${activityId}`, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: form,
  }).catch(() => {});
}

/** Syncs a single event to Strava as a TCX upload with laps (no-op if already synced). */
async function syncEvent(uid, eventRef, event) {
  if (event.stravaActivityId) return null;
  const accessToken = await getValidAccessToken(uid);

  const name = event.name || "PaceApp Activity";
  const description = activityDescription(event, coveredDistance(event));
  const externalId = `paceapp-${eventRef.id}`;

  const lapCount = buildLaps(event).length;
  logger.info(`syncEvent: uploading ${externalId} as ${lapCount} lap(s)…`);
  let upload;
  try {
    upload = await uploadTCX(accessToken, buildTCX(event), { externalId, name, description });
  } catch (e) {
    // A 401/403 here means the access token was revoked while still unexpired (so the
    // refresh path in getValidAccessToken didn't run). Clear so the app reflects it.
    if (e.status === 401 || e.status === 403) {
      await clearStravaConnection(uid);
      throw new Error("Strava is not connected.");
    }
    throw e;
  }
  logger.info(`syncEvent: Strava accepted upload ${upload.id} for ${externalId}, awaiting processing…`);
  const activityId = await pollUpload(accessToken, upload.id);

  // The TCX only carries a coarse sport; set the exact Strava sport_type here.
  await updateActivity(accessToken, activityId, {
    sportType: SPORT_BY_ACTIVITY[event.activityType] || "Workout",
    name,
    description,
  });

  await eventRef.set({
    stravaActivityId: activityId,
    stravaSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
    stravaSyncError: admin.firestore.FieldValue.delete(),
  }, { merge: true });
  return activityId;
}

// MARK: - Endpoints

/**
 * OAuth callback relay. Strava redirects here (a real https domain, as it requires),
 * and this 302-redirects to the app's paceapp://strava-callback deep link, forwarding
 * the query (code/scope/error) unchanged. A *server* redirect is followed by
 * ASWebAuthenticationSession and in-app browsers, which block a page's JavaScript
 * from auto-navigating to a custom scheme without a tap.
 */
exports.stravaCallback = onRequest((req, res) => {
  const query = req.url.includes("?") ? req.url.slice(req.url.indexOf("?")) : "";
  res.set("Location", "paceapp://strava-callback" + query);
  res.status(302).send();
});

/** Exchange an OAuth code for tokens and connect the account. */
exports.stravaExchange = onRequest({ secrets: [STRAVA_CLIENT_SECRET] }, async (req, res) => {
  const uid = await requireUid(req, res);
  if (!uid) return;
  const code = req.body && req.body.code;
  if (!code) {
    res.status(400).json({ error: "Missing authorization code." });
    return;
  }
  try {
    const token = await stravaTokenRequest({
      client_id: STRAVA_CLIENT_ID.value(),
      client_secret: STRAVA_CLIENT_SECRET.value(),
      code,
      grant_type: "authorization_code",
    });
    const athleteName = await storeTokens(uid, token);
    res.json({ athleteName });
  } catch (e) {
    logger.error("stravaExchange failed", e);
    res.status(502).json({ error: "Couldn't connect to Strava. Please try again." });
  }
});

/** Manually sync one event by id. */
exports.stravaSync = onRequest({ secrets: [STRAVA_CLIENT_SECRET] }, async (req, res) => {
  const uid = await requireUid(req, res);
  if (!uid) return;
  const eventId = req.body && req.body.eventId;
  if (!eventId) {
    res.status(400).json({ error: "Missing event id." });
    return;
  }
  try {
    const ref = db.doc(`events/${eventId}`);
    const snap = await ref.get();
    if (!snap.exists || snap.data().userId !== uid) {
      res.status(404).json({ error: "Activity not found." });
      return;
    }
    const id = await syncEvent(uid, ref, snap.data());
    res.json({ synced: id ? 1 : 0, stravaActivityId: id || null });
  } catch (e) {
    logger.error("stravaSync failed", e);
    const notConnected = String(e.message).includes("not connected");
    res.status(502).json({ error: notConnected ? "Please connect Strava first." : "Couldn't sync to Strava." });
  }
});

/** Sync recent completed activities that haven't reached Strava yet. */
exports.stravaBackfill = onRequest({ secrets: [STRAVA_CLIENT_SECRET], timeoutSeconds: 300 }, async (req, res) => {
  const uid = await requireUid(req, res);
  if (!uid) return;
  try {
    // Small batch — each TCX upload is processed asynchronously by Strava, so a large
    // batch would blow the request timeout. Repeat taps clear a big backlog in chunks.
    const query = await db.collection("events")
      .where("userId", "==", uid)
      .where("status", "==", "completed")
      .limit(8)
      .get();

    let synced = 0;
    for (const doc of query.docs) {
      const data = doc.data();
      if (data.stravaActivityId) continue;
      try {
        const id = await syncEvent(uid, doc.ref, data);
        if (id) synced++;
      } catch (e) {
        logger.warn(`backfill skipped ${doc.id}: ${e.message}`);
      }
    }
    res.json({ synced });
  } catch (e) {
    logger.error("stravaBackfill failed", e);
    res.status(502).json({ error: "Couldn't sync to Strava. Please try again." });
  }
});

/** Deauthorize on Strava and clear stored tokens. */
exports.stravaDisconnect = onRequest({ secrets: [STRAVA_CLIENT_SECRET] }, async (req, res) => {
  const uid = await requireUid(req, res);
  if (!uid) return;
  try {
    const snap = await db.doc(`stravaTokens/${uid}`).get();
    const accessToken = snap.exists ? snap.data().accessToken : null;
    if (accessToken) {
      await fetch(STRAVA_DEAUTH_URL, {
        method: "POST",
        headers: { Authorization: `Bearer ${accessToken}` },
      }).catch(() => {});
    }
    await db.doc(`stravaTokens/${uid}`).delete().catch(() => {});
    await db.doc(`users/${uid}`).set({
      strava: { connected: false, athleteName: null, athleteId: null },
    }, { merge: true });
    res.json({ disconnected: true });
  } catch (e) {
    logger.error("stravaDisconnect failed", e);
    res.status(502).json({ error: "Couldn't disconnect. Please try again." });
  }
});

// MARK: - Deauthorization webhook

// Verify token you choose; it must match the `verify_token` used when creating the
// Strava push subscription. Not a secret — Strava only echoes it back on the handshake.
const STRAVA_WEBHOOK_VERIFY_TOKEN = "paceapp-strava-webhook";

// Set to the numeric id Strava returns when you register the push subscription. Once set,
// POSTs whose subscription_id doesn't match are dropped (spoof guard). null = not yet set.
const STRAVA_WEBHOOK_SUBSCRIPTION_ID = null;

/**
 * Strava push-subscription webhook. Two roles:
 *  - GET: the one-time subscription validation handshake (echo hub.challenge).
 *  - POST: event delivery. We act only on athlete deauthorization (updates.authorized=false),
 *    clearing that athlete's connection so the app reflects "Not connected" instantly.
 * Requires a push subscription registered with Strava pointing at this function URL
 * (https://us-central1-thepaceapp.cloudfunctions.net/stravaWebhook) — one-time setup.
 */
exports.stravaWebhook = onRequest(async (req, res) => {
  if (req.method === "GET") {
    const mode = req.query["hub.mode"];
    const token = req.query["hub.verify_token"];
    const challenge = req.query["hub.challenge"];
    if (mode === "subscribe" && token === STRAVA_WEBHOOK_VERIFY_TOKEN) {
      res.json({ "hub.challenge": challenge });
    } else {
      res.status(403).send("Forbidden");
    }
    return;
  }

  if (req.method === "POST") {
    const body = req.body || {};

    // Spoof guard — Strava payloads are unsigned, so drop anything not from our subscription.
    if (STRAVA_WEBHOOK_SUBSCRIPTION_ID != null
      && Number(body.subscription_id) !== Number(STRAVA_WEBHOOK_SUBSCRIPTION_ID)) {
      res.status(200).send("IGNORED");
      return;
    }

    const deauthorized =
      body.object_type === "athlete" &&
      body.aspect_type === "update" &&
      body.updates && String(body.updates.authorized) === "false";

    // Do the work BEFORE responding — on Functions v2 (Cloud Run) CPU is throttled
    // once the response is sent, so post-response work isn't guaranteed to complete.
    if (deauthorized) {
      try {
        const snap = await db.collection("stravaTokens")
          .where("athleteId", "==", body.owner_id).get();
        for (const doc of snap.docs) {
          await clearStravaConnection(doc.id); // doc id == uid
        }
        logger.info(`stravaWebhook: deauthorized athlete ${body.owner_id} (${snap.size} user[s])`);
      } catch (e) {
        logger.error("stravaWebhook deauthorize failed", e);
      }
    }

    res.status(200).send("EVENT_RECEIVED");
    return;
  }

  res.status(405).send("Method Not Allowed");
});

// MARK: - Auto-sync trigger

/** When an event transitions into "completed", push it to Strava if the user is connected. */
exports.onEventCompleted = onDocumentWritten(
  { document: "events/{eventId}", secrets: [STRAVA_CLIENT_SECRET], timeoutSeconds: 120 },
  async (event) => {
    const after = event.data && event.data.after;
    if (!after || !after.exists) return;
    const data = after.data();

    // Act only on the transition into completed — avoids re-firing on our own write-back.
    const before = event.data.before;
    const beforeStatus = before && before.exists ? before.data().status : null;
    if (data.status !== "completed" || beforeStatus === "completed") return;

    const eventId = event.params.eventId;
    if (data.stravaActivityId) {
      logger.info(`onEventCompleted: ${eventId} already on Strava (activity ${data.stravaActivityId})`);
      return;
    }
    if (!data.userId) return;

    const tokenSnap = await db.doc(`stravaTokens/${data.userId}`).get();
    if (!tokenSnap.exists) {
      logger.info(`onEventCompleted: ${eventId} completed but Strava is not connected — skipping`);
      return;
    }

    try {
      logger.info(`onEventCompleted: syncing ${eventId} to Strava…`);
      const activityId = await syncEvent(data.userId, after.ref, data);
      logger.info(`onEventCompleted: ${eventId} → Strava activity ${activityId}`);
    } catch (e) {
      logger.warn(`auto-sync failed for ${eventId}: ${e.message}`);
      await after.ref.set({ stravaSyncError: e.message }, { merge: true }).catch(() => {});
    }
  }
);
