# PaceApp (iOS)

Native iOS pace-tracking app for runners and walkers. Pair a **Garmin watch**, set a goal finish time, and get real-time feedback during the event on how your projected finish stacks up against your goal — including the required pace for the remaining intervals. Completed activities sync to **Firebase** and, optionally, straight to **Strava**.

- **Platform**: iOS 17.0+, SwiftUI (Observation framework)
- **Version**: 1.0.0 (build 10) · Bundle ID `net.paceapp`
- **Backend**: Firebase — Auth (phone OTP + email link), Firestore, Cloud Functions, Hosting
- **Watch**: Garmin ConnectIQ companion SDK
- **Website**: [paceapp.net](https://paceapp.net)

## Features

- **Goal-based events** — plan a run/walk/cycle with distance, goal time, and intervals; the watch tracks segments, pace, heart rate, and route.
- **Live watch sync** — events, results, and settings flow two-way between the app and the Garmin watch (gait derived from height, alert toggles, units).
- **History & analytics** — completed activities with filters, favorites, per-segment details, route map, and aggregate trends by week/month/year.
- **Strava sync** — connect once (OAuth) with the official "Connect with Strava" button (a spinner shows while it authenticates); completed activities upload automatically, with each segment as a Strava lap. Manual resync and disconnect from Settings, and the connection clears automatically if you revoke access on Strava.
- **Dual sign-in & session security** — phone OTP or email sign-in link, with inline re-authentication for account deletion. Sessions are server-validated: deleting or disabling the account on another device signs this one out, and your profile follows you to any device you sign in on.

## Getting started

Requirements: Xcode 16+, an iPhone 16/17-class simulator or device.

```bash
git clone https://github.com/wvellc/PaceApp-ios.git
cd PaceApp-ios
open PaceApp.xcodeproj
```

Dependencies resolve automatically via Swift Package Manager. Build and run the `PaceApp` scheme, or from the CLI:

```bash
xcodebuild -project PaceApp.xcodeproj -scheme PaceApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

> There is **no test target** — changes are verified by building. The Firebase client config (`GoogleService-Info.plist`) is included in the repo.

## Firebase

The project deploys three surfaces from the repo root (Firebase CLI, project `thepaceapp`, Blaze plan):

```bash
firebase deploy --only firestore:rules,firestore:indexes   # security rules + composite indexes
firebase deploy --only functions                            # Strava Cloud Functions (Node 20)
firebase deploy --only hosting                              # email sign-in page + Strava callback rewrite
```

## Strava integration

The app performs the OAuth authorize step only; **Cloud Functions** (`functions/`) hold the client secret, exchange/refresh tokens, and upload activities — the device never stores a Strava token.

- Setup (Strava API app, secrets, deploy): [`functions/STRAVA_SETUP.md`](functions/STRAVA_SETUP.md)
- Backlog and known limitations (athlete quota, summary-only uploads): [`STRAVA_TODO.md`](STRAVA_TODO.md)

## Project structure

```
├── PaceApp.swift / AppDelegate.swift   # App entry, Firebase + ConnectIQ setup, deep-link routing
├── Router/                             # Singleton Router + Destinations (push navigation, root flows)
├── Model/                              # Domain models + enums (EventDocument, UserModel, RunSegment, …)
├── Modules/                            # Feature screens — Auth, CreateAccount (onboarding), Dashboard tabs
├── DesignSystem/                       # Gilroy font tokens, colors, shared components (AppButton, toasts, …)
├── Utility/                            # Managers (Auth, Firestore repos, ConnectIQ, Strava), constants, extensions
├── functions/                          # Strava Cloud Functions (Node 20)
├── firebase-hosting/                   # Hosting pages + universal-link association files
└── firestore.rules / firestore.indexes.json
```

Deeper architecture notes, conventions, and pitfalls live in [`CLAUDE.md`](CLAUDE.md).

---

Built by [WVE Labs](https://wvelabs.com). All rights reserved.
