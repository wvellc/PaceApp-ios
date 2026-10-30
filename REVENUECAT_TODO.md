# RevenueCat — Production Go-Live TODO

Dev/testing runs against the RevenueCat **Test Store** (public key `test_…`). The
app-side code is done, built and committed (`feat(subscriptions)` + `chore(deps)`).
What remains is wiring the real **App Store** (and later Play Store) products and
flipping the production key. The entitlement, offering, packages and published
paywall are already set up and carry over untouched.

> Never commit secrets here — shared secret, `.p8` keys, Issuer/Key IDs go only
> into the RevenueCat dashboard.

## Reference IDs

- Project: **Pace App** — `proj7998a365`
- Entitlement: `pace_app_pro` — `entlf7d83b55f8`
- Offering: `default` — `ofrng0237a4d320`
  - Package `$rc_monthly` — `pkge2d2943633d`
  - Package `$rc_annual` — `pkge699a0b65e9`
- Paywall: `PaceProPaywall` — `pw43378d268f1540d2` (published)
- Bundle ID: `net.paceapp`
- App Store product IDs: `pro_monthly`, `pro_yearly`

## A. RevenueCat — add the App Store app ✅ DONE

- [x] App Store app created — `app4faeb2743f`, bundle `net.paceapp`, subscription key configured
- [x] Public SDK key obtained (`appl_…`, wired into the app)
- [x] App Store Server Notifications + preview URL scheme (`rc-4faeb2743f`, in Info.plist) set

## B. Wire products ✅ DONE (via MCP)

- [x] Registered `pro_monthly` (`prod118bd2bdb0`) and `pro_yearly` (`prod8a8ddd2038`) on the App Store app
- [x] Attached both to entitlement `pace_app_pro`
- [x] Added `pro_monthly` → `$rc_monthly`, `pro_yearly` → `$rc_annual`

## C. App code ✅ DONE

- [x] `RevenueCatConst.apiKey` → build switch: Test Store key in DEBUG, `appl_` key in release
- [x] Builds clean

## D. App Store Connect — finish the subscriptions (group `22503378`)

- [ ] Reorder so **Yearly = Level 1** (makes monthly → yearly an immediate upgrade)
- [ ] Prices: `pro_monthly` $7.99, `pro_yearly` $59.99 (upfront; skip the monthly-commitment field)
- [ ] Display name + description per product:
  - `Unlimited Access (Monthly)` / `Unlimited Access (Yearly)`
  - `Unlimited events, sync & advanced insights.`
- [ ] Review screenshot per subscription (a Pace Pro paywall screenshot works)
- [ ] Submit the subscription group with the next app build

## E. Test Store (dev) — optional

- [ ] Fix Test Store prices to $7.99 / $59.99 in the product editor so the dev paywall shows real numbers

## F. Google Play Store + Android

> The Android app `net.paceapp` is registered (assetlinks.json, 3 signing
> fingerprints) but its **source is a separate Android codebase, not in this repo**.
> The RevenueCat Android SDK must be wired in there, not here.

> **STATUS 2026-10-30 — Android is LIVE and the purchase path is verified on a real
> device.** F2–F4 are done and F1's subscriptions are published (the on-device paywall
> showed live Play prices; confirm the exact amounts/display names in Play Console still
> match the intended values below — the test device's storefront rendered local-currency
> prices). End-to-end proof: internal-track install → paywall → Google test card → buy
> Monthly → `pace_app_pro` unlocked → "Subscribed". Non-charging test purchases need the
> tester under **Play Console → Setup → License testing**. Done in the Android repo
> (`origin/monetization`); its `CLAUDE.md` documents the layer.

### F1. Play Console — create the subscriptions (needs Play Console access; app on ≥ internal track)

- [ ] Subscription `pro_monthly` → base plan `monthly`, P1M, auto-renewing, **$7.99**
- [ ] Subscription `pro_yearly` → base plan `yearly`, P1Y, auto-renewing, **$59.99**
- Name (≤55): `Unlimited Access (Monthly)` / `Unlimited Access (Yearly)`
- Description (≤80): `Unlimited events, Garmin sync, unlimited Strava sharing & advanced insights.`
- Benefits (≤40, up to 4): `Unlimited events (free stops at 15)` · `Garmin watch sync` · `Unlimited Strava sharing` · `Advanced event insights`

### F2. RevenueCat — add the Play Store app ✅ DONE

- [x] Project settings → Apps → New → **Play Store**; package `net.paceapp`; service-account JSON uploaded
- [x] Public SDK key (`goog_…`) copied and wired into the Android app
- [x] Real-Time Developer Notifications configured (proven live by the on-device purchase → entitlement unlock)

### F3. Wire products ✅ DONE

- [x] Registered `pro_monthly:monthly`, `pro_yearly:yearly`
- [x] Attached both to `pace_app_pro`; added to `$rc_monthly` / `$rc_annual`

### F4. Android app code (separate Android repo) ✅ DONE

- [x] Added `com.revenuecat.purchases:purchases` (+ `purchases-ui` for the paywall)
- [x] Configured with the `goog_` key; `logIn` with the Firebase uid; gate on `pace_app_pro`; present the dashboard paywall (`PaywallActivityLauncher`); cap free events (default 15, now **remotely configurable** via Firebase Remote Config key `free_event_limit`) — mirrors iOS
