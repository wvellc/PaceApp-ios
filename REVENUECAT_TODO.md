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

## A. RevenueCat — add the App Store app (needs ASC credentials)

- [ ] Project settings → Apps → New → **App Store**
  - App name: `Pace App (App Store)`
  - Bundle ID: `net.paceapp`
  - App-Specific Shared Secret: **copied ✅** — paste into this field
  - In-App Purchase Key (`.p8` + Key ID + Issuer ID) — recommended; enables product auto-import + refunds
- [ ] Copy the generated public SDK key (`appl_…`)
- [ ] App Store Server Notifications V2 — paste RevenueCat's URL into ASC (Production **and** Sandbox)

## B. Wire products (automatable via the RevenueCat MCP once app A exists)

- [ ] Register products `pro_monthly`, `pro_yearly` on the App Store app
- [ ] Attach both to entitlement `pace_app_pro`
- [ ] Add `pro_monthly` → `$rc_monthly`, `pro_yearly` → `$rc_annual`

## C. App code

- [ ] `RevenueCatConst.apiKey` → build switch: Test Store key in DEBUG, `appl_` key in release
- [ ] Build to confirm

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

## F. Play Store (later)

- [ ] Create subscriptions `pro_monthly` / `pro_yearly` (base plans `monthly` / `yearly`) — names/benefits per spec
- [ ] Add the Play app in RevenueCat; register `pro_monthly:monthly`, `pro_yearly:yearly`; attach to `pace_app_pro` + packages
