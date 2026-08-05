/**
 * PaceApp Cloud Functions — Strava integration.
 *
 * The iOS/Android app performs the OAuth *authorize* step only and sends the
 * returned code here. These functions hold the Strava client secret, exchange
 * and refresh tokens, store them server-side (never on device), and upload
 * completed activities to Strava as summary activities (POST /activities).
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

// PaceApp activity string → Strava sport_type.
const SPORT_BY_ACTIVITY = { Run: "Run", Walking: "Walk", Cycling: "Ride", Other: "Workout" };

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
  if (!resp.ok) throw new Error(json.message || "Strava token request failed.");
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

/** Returns a valid access token for the user, refreshing (and re-storing) it if it's near expiry. */
async function getValidAccessToken(uid) {
  const snap = await db.doc(`stravaTokens/${uid}`).get();
  if (!snap.exists) throw new Error("Strava is not connected.");
  const data = snap.data();

  const now = Math.floor(Date.now() / 1000);
  if (data.expiresAt && now < data.expiresAt - 300) return data.accessToken;

  const refreshed = await stravaTokenRequest({
    client_id: STRAVA_CLIENT_ID.value(),
    client_secret: STRAVA_CLIENT_SECRET.value(),
    grant_type: "refresh_token",
    refresh_token: data.refreshToken,
  });
  await db.doc(`stravaTokens/${uid}`).set({
    accessToken: refreshed.access_token,
    refreshToken: refreshed.refresh_token, // Strava rotates the refresh token
    expiresAt: refreshed.expires_at,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  return refreshed.access_token;
}

// MARK: - Activity upload

/** Distance → meters (Strava expects meters). App stores "Miles" or "Kms"; anything not "Miles" is km. */
function metersFor(distance, measure) {
  if (!distance) return 0;
  return measure === "Miles" ? distance * 1609.34 : distance * 1000;
}

/** Distance actually covered — actualDistance, else the sum of per-segment completed_distance. */
function coveredDistance(event) {
  if (event.actualDistance > 0) return event.actualDistance;
  const segments = Array.isArray(event.completedSegments) ? event.completedSegments : [];
  return segments.reduce((total, s) => total + (parseFloat(s.completed_distance) || 0), 0);
}

/** Builds the form body for POST /activities from a PaceApp event document. */
function activityForm(event) {
  const distance = coveredDistance(event);
  const elapsed = event.actualTimeSeconds || event.goalTimeSeconds || 0;
  // completedAt marks the finish — subtract elapsed so Strava gets the real start.
  const endTs = event.completedAt || event.scheduledAt;
  const endMs = endTs && endTs.toDate ? endTs.toDate().getTime() : Date.now();
  const startISO = new Date(endMs - (event.actualTimeSeconds ? elapsed * 1000 : 0)).toISOString();

  const form = new URLSearchParams({
    name: event.name || "PaceApp Activity",
    sport_type: SPORT_BY_ACTIVITY[event.activityType] || "Workout",
    start_date_local: startISO,
    elapsed_time: String(Math.max(0, Math.round(elapsed))),
  });
  // Never report the planned distance as covered — omit when nothing was actually covered.
  if (distance > 0) form.append("distance", String(Math.round(metersFor(distance, event.measure))));
  form.append("description", event.avgHeartRate
    ? `Avg HR ${event.avgHeartRate} bpm • Synced from PaceApp`
    : "Synced from PaceApp");
  return form;
}

/** Creates the activity on Strava and returns its id. */
async function createStravaActivity(accessToken, form) {
  const resp = await fetch(STRAVA_ACTIVITIES_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: form,
  });
  const json = await resp.json().catch(() => ({}));
  if (!resp.ok) throw new Error(json.message || "Strava rejected the activity.");
  return json.id;
}

/** Syncs a single event to Strava (no-op if already synced). Returns the activity id or null. */
async function syncEvent(uid, eventRef, event) {
  if (event.stravaActivityId) return null;
  const accessToken = await getValidAccessToken(uid);
  const activityId = await createStravaActivity(accessToken, activityForm(event));
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
exports.stravaBackfill = onRequest({ secrets: [STRAVA_CLIENT_SECRET] }, async (req, res) => {
  const uid = await requireUid(req, res);
  if (!uid) return;
  try {
    const query = await db.collection("events")
      .where("userId", "==", uid)
      .where("status", "==", "completed")
      .limit(30)
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

// MARK: - Auto-sync trigger

/** When an event transitions into "completed", push it to Strava if the user is connected. */
exports.onEventCompleted = onDocumentWritten(
  { document: "events/{eventId}", secrets: [STRAVA_CLIENT_SECRET] },
  async (event) => {
    const after = event.data && event.data.after;
    if (!after || !after.exists) return;
    const data = after.data();

    // Act only on the transition into completed — avoids re-firing on our own write-back.
    const before = event.data.before;
    const beforeStatus = before && before.exists ? before.data().status : null;
    if (data.status !== "completed" || beforeStatus === "completed") return;
    if (data.stravaActivityId || !data.userId) return;

    const tokenSnap = await db.doc(`stravaTokens/${data.userId}`).get();
    if (!tokenSnap.exists) return; // user hasn't connected Strava

    try {
      await syncEvent(data.userId, after.ref, data);
    } catch (e) {
      logger.warn(`auto-sync failed for ${event.params.eventId}: ${e.message}`);
      await after.ref.set({ stravaSyncError: e.message }, { merge: true }).catch(() => {});
    }
  }
);
