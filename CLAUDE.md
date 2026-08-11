# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# PaceApp iOS — Project Intelligence

> Last verified against the codebase on 2026-08-11 (branch `strava-integration`).

## Overview

**PaceApp** is a native iOS running/walking pace-tracking app built with **SwiftUI** (iOS 17+). It pairs with **Garmin ConnectIQ** watches to sync real-time activity data (segments, heart rate, pace, distance) and persists everything to **Firebase** (Auth, Firestore). The app uses a light-mode-only, dark-themed design system built around the **Gilroy** font family and a neon-aqua-on-navy color palette.

- **Bundle ID**: `net.paceapp` (the string `com.garmin.paceapp` in `PaceApp-Info.plist` is a `CFBundleURLName` identifier for the ConnectIQ URL type, **not** the app bundle ID).
- **Firebase Project**: `thepaceapp`
- **Minimum iOS**: 17.0
- **Xcode project**: `PaceApp.xcodeproj` (no `.xcworkspace`; dependencies are Swift Package Manager, not CocoaPods). Scheme: `PaceApp`.
- **Color Scheme**: Force `.light` — the "dark" look comes from dark background colors, not system dark mode.

---

## Recent Architecture Notes (current — overrides any stale detail below)

Read this first. Where it disagrees with older sections, this wins.

### Events — one embedded document, no subcollection
- The event model is **`EventDocument`** (`Model/EventDocument.swift`, previously named `FirestoreEventDocument`), stored as a single doc at `events/{id}`. **Segments are an embedded `[RunSegment]` array on the document — there is no `events/{id}/segments` subcollection.** Route GPS is one encoded `routePolyline` string (`PolylineCodec`, `Utility/Extensions/PolylineCodec.swift`).
- Key fields: `status` (`active`/`completed`/`deleted` → `EventStatus`, defined in the same file), `syncStatus` (`pending`/`synced` — plain String, no enum), `source` (`phone`/`watch`), `activityType`, `createdAt`. Variable-shape watch data uses `FirestoreFlexibleValue` (`completedSegments`).
- Repository: **`FirestoreEventRepository.shared`** (accessor: `EventRepository.shared` enum). The single parse path for raw ConnectIQ `[String: Any]` payloads is **`EventDocumentMapper`** — never parse event dicts anywhere else.
- **Immutable on sync**: `id` (doc key), `source`, and `createdAt` are set once at creation and must never be rewritten by a later app⇄watch sync. `FirestoreEventRepository.upsert` reloads the existing doc and preserves them. App-created payloads tag `source: "phone"`; a source-less payload arriving through the sync layer is treated as `"watch"`.
- **Active events ignore date**: `observeActiveEvents` has NO `scheduledAt >= today` filter, so a past-due but still-active event stays visible on Home instead of being orphaned.

### Tab navigation — `TabNavigationState` above the lazy TabView
- **`TabBarScreen` holds the four tab *screens* (not ViewModels) as `@State`** (`homeScreen`, `historyScreen`, `analyticsScreen`, `profileScreen`) so each screen keeps its identity — and therefore its own `@State` ViewModel — across tab switches. Each screen owns its VM (e.g. `HomeScreen` has `@State private var viewModel = HomeViewModel()`).
- **`TabNavigationState`** (`Modules/Dashboard/TabNavigationState.swift`, `@Observable`) lifts tab-child routing out of the lazy `TabView`: children write `selectedActivity` / `duplicateActivity` / `selectedMetric` (+ `analyticsViewModel`), and `TabBarScreen` declares the matching `.navigationDestination(item:)` modifiers **outside the TabView**. Event Details, Duplicate Run, and Analytics Detail are pushed this way — they are **not** `Destinations` cases.
- `PaceTab` cases are `.home`, `.history`, `.stats`, `.profile` (the Analytics tab is `.stats`).

### ConnectIQ ⇄ app settings sync
- Two-way: watch→Firestore via `applyRemoteSettings`; app→watch via `sendSettings()` / `getSettingsPayload()` (message `sync_settings`). Call `sendSettings()` after any app-side settings mutation.
- **Reply echoes in-payload alerts**: when `applyRemoteSettings` answers a height-carrying payload (gait derivation), it builds the `sync_settings` reply from `getSettingsPayload(gaitOverride:)` and **overlays the `vibrate_alert`/`beep_alert` values from the incoming payload** — Firestore may not have persisted them yet, so re-reading the profile would race and echo stale values back to the watch.
- **Gait unit/value boundary**: the watch speaks `ft`/`m` and sends step length as a String (`"2.5"`); the app stores full words `Feet`/`Meters` and a `Double`. Convert only at the boundary — `settingDouble` (lenient number), `appGaitUnit` (in), `watchGaitUnit` (out). Internal gait unit is always `"Feet"`/`"Meters"` (matches `AppSegmentedControl` keys).
- `AuthManager` runs a **live Firestore profile listener** (`startProfileListener`) that keeps `userDetails` current, so watch→Firestore changes appear without relaunch. Screens re-sync their VM on `AuthManager.shared.userDetails` change (see `ProfileScreen`).

### Watch settings request + gait from height
- **`request_settings`** (`requestSettings()`) asks the watch to reply with a full `sync_settings` payload (its normal syncs omit body metrics). Sent on **watch connect** (in `connectToApp`) and on **every Profile tab appear** (`ProfileScreen.onAppear`).
- The response carries body-metric keys: `user_height` (cm), `user_weight` (grams), plus `walking_step_length`/`running_step_length` (mm). `applyRemoteSettings` persists `heightCm` + `weightKg` (grams ÷1000) to `UserModel` via `UserProfileRepository.updateBodyMetrics`.
- **Gait is always derived from `user_height`** (the source of truth) via `GaitStrideCalculator` (`Model/GaitStrideCalculator.swift`) — walking = height × 0.413, running = height × 0.65 (meters), then converted to the app unit / mm. The watch's `walking_gait`/`running_gait` can be stale, so re-derive whenever `user_height` is present (no one-time gate). Computed step lengths are pushed back to the watch so it measures distance correctly.
- Trade-off: because gait re-derives from height on each connect / Profile visit, a **manual** Update Gait edit is overwritten. A "manual override" flag would be needed to keep manual edits.
- `UserModel` stores `heightCm` / `weightKg` (optional `Double`, metric). Not collected by onboarding — currently watch-sourced only.

### ActivityType carried end-to-end
- `ActivityType` (`run`/`walking`/`cycling`/`other`, defined in `Modules/Dashboard/Home/NewRun/ViewModel/ActivityType.swift`) exposes `.title` (header text) and `.icon` (asset). `EventDocument.eventType` is a typed accessor over the stored `activityType` string; `ActivityData.eventType` carries it to the UI (set by `EventDocumentMapper`). Drives the EventDetails title and the Home/History activity-row icons.

### Home is a single native `List`
- Home is one `List` — a self-sizing header row + upcoming events as rows with native `.swipeActions`. This replaced a `ScrollView` + custom gesture row. History uses the same `List` + `.swipeActions` pattern (the reference for smooth scroll + swipe).
- **Never put a `GeometryReader` inside a `List`/collection cell** — the unstable self-sizing height crashes with `UICollectionView … recursive layout loop`. Size deterministically (e.g. from `UIScreen.main.bounds.width`).
- **Buttons inside a `List` row need `.buttonStyle(.borderless)` / `.plain`**, otherwise the row swallows the tap (this is why `runActionGrid` and the metric capsules set an explicit button style).

### In-app FAQ via SafariView
- **`SafariView`** (`DesignSystem/Components/SafariView.swift`) wraps `SFSafariViewController`. The FAQ opens from the Home nav bar (yellow `questionmark.circle` in `AppNavigation`'s trailing slot) and from a Settings row. URLs live in **`NetworkConst.WebUrl`** (`Utility/Constant/Network.swift`): `privacyPolicy`, `termsOfService`, `licences`, `faq`, `wvelabs`.

### EventDetails map
- Show the route map only when `hasRouteData` == **≥ 2 valid, non-`(0,0)` coordinates**. `routeCoordinates` filters invalid/placeholder points the watch/Firebase send; a single point can't draw a polyline.

### Edit propagation (name/location) + live list updates
- The Firestore write is the source of truth. **`EventUpdateCenter`** broadcasts a name/location edit (mirrors **`EventDeletionCenter`** for deletes — both in `Utility/Manager/`); **Home upcoming, History, Favorites, and Event Details** each observe it via `.onChange` and patch the matching row in place — no refetch. History floats the just-edited row to the top (it orders by `updatedAt`).
- **`ActivityData` uses content-aware `==`** — NOT id-only. SwiftUI `List`/`ForEach` skips re-rendering a row when its value compares equal, so an id-only `==` froze edited/synced rows (title/location never redrew). Keep `Identifiable.id` + `hash(into:)` on `id`, but compare the displayed fields in `==`.
- **Every event write stamps `updatedAt`** — the mapper's `document(...)` and `updatedDocument(...)` set it to now; `softDelete` uses `serverTimestamp`. History's default (unfiltered) query orders by `userId ASC, status ASC, updatedAt DESC` (composite index required + deployed).

### Account deletion + re-authentication
- **`AuthManager.deleteAccount()` order matters**: (1) `disconnectFromApp()` FIRST — otherwise live watch sync keeps writing to Firestore mid-deletion and floods `permission denied` once the token is gone; (2) `stopProfileListener()` + `StravaManager.shared.stopObserving()`; (3) **best-effort data cleanup** via `deleteDocuments(matching:label:)` — never aborts the deletion, but logs skipped cleanups; (4) delete the user doc + `user.delete()`; (5) `Auth.auth().signOut()` (clears the keychain session even if delete failed); (6) wipe `userDetails`/`currentUser`/`AppSession`.
- **Reauth-then-delete, no sign-out**: Firebase `user.delete()` needs a recent login. Settings shows an in-app confirm popup, then reauthenticates inline using the **already signed-in contact** — phone: OTP sheet (`sendReauthOTP` → `reauthenticateWithPhone`); email: link + "check your email" wait sheet, completed in `PaceApp.onOpenURL` gated by `AuthManager.isReauthenticatingForDeletion` (so the returning link is treated as reauth, not a fresh sign-in). `deleteAccount()` runs only after reauth succeeds. Sheets: `Modules/Dashboard/Settings/ReauthDeleteSheets.swift`.
- **Friendly auth errors**: never surface `error.localizedDescription` to users. Route every auth/sign-in error through **`AuthErrorMapper.message(for:)`** (`Utility/Manager/Auth/`), which maps `AuthErrorCode` + network errors to short non-technical copy.

### Gait unit conversion (Feet ⇄ Meters)
- `GaitStrideCalculator.convert(_:fromUnit:toUnit:)` converts a step length between `Feet`/`Meters`, snapped to the picker's 1-dp resolution. `GaitSelectionView` calls it on the Meters/Feet segment `.onChange` so the shown value stays the same real measurement — shared by onboarding **SetGaitStepView** and **Profile → UpdateGait** (same component).

### Strava integration (client OAuth + Cloud Functions)
- Split responsibility: the app does the OAuth **authorize** step only; **Cloud Functions** (`functions/index.js`) hold the client secret, exchange/refresh tokens, and upload activities as **TCX files** (`POST /uploads`) so each PaceApp segment becomes a Strava **lap**. The device never stores a Strava token.
- iOS pieces: **`StravaConst`** (`Utility/Constant/Strava.swift` — clientId, scope `activity:write`, redirect), **`StravaManager`** (`Utility/Manager/Strava/`, `@Observable` singleton — connect/disconnect/syncRecent + Firestore state listener), **`StravaAPI`** (URLSession client calling the HTTPS functions with the Firebase ID token — deliberately no `FirebaseFunctions` SPM product), **`StravaConnectScreen`** (`Modules/Dashboard/Profile/Strava/`).
- `connect()` opens the Strava app (`strava://oauth/mobile/authorize`) or the external browser — never `ASWebAuthenticationSession` (it stalls on the custom-scheme return). `redirectURI` is `https://thepaceapp.web.app/stravaCallback/` (Strava requires a real callback domain).
- **The return leg is a universal link** — applinks + wildcard AASA mean iOS opens the app directly with the **https** URL. `StravaManager.isStravaCallback` accepts BOTH forms (`paceapp://strava-callback` and the https link); the `stravaCallback` function 302-redirects to the deep link as the Safari fallback.
- Functions: `stravaExchange` (code→tokens), `stravaSync` (one event), `stravaBackfill` (recent unsynced, batched), `stravaDisconnect` (revokes via **`POST /oauth/revoke`** — the deprecated `/oauth/deauthorize` is retired 2027-06-01), `onEventCompleted` (Firestore trigger — auto-upload on the active→completed transition), `stravaWebhook` (Strava push subscription — GET handshake + POST athlete-deauthorize → clear the connection). Secret via `firebase functions:secrets:set STRAVA_CLIENT_SECRET`; client id in `functions/.env`.
- State: server-only tokens in `stravaTokens/{uid}` (rules deny all client access); client-readable summary at `users/{uid}.strava` `{connected, athleteName}` mirrored by `startObserving()`/`stopObserving()` (stopped on logout + account delete). Synced events get stamped `stravaActivityId` (dedupe) + `stravaSyncedAt` / `stravaSyncError`.
- **Revocation → disconnect**: a genuine revoke (Strava returns **401**, or the webhook's athlete-deauthorize event) routes through `clearStravaConnection` → `users/{uid}.strava.connected = false`, so the live listener flips Settings to "Not connected". `isRevocation(e)` clears **only** on a real revoke — a bad client secret / transient 5xx / **403** (scope-or-quota, not a revoke) must NOT delete tokens. Webhook does its work **before** responding (Cloud Run throttles post-response) and drops non-subscription POSTs once `STRAVA_WEBHOOK_SUBSCRIPTION_ID` is armed.
- **TCX laps**: `buildTCX` emits one `<Lap>` per `completedSegments` entry (distance + time + avg HR) so segments render as Strava laps; no per-segment data → a single whole-activity lap. Uploads are **async** — `POST /uploads` → poll `GET /uploads/{id}` for the `activity_id`, then `PUT /activities/{id}` sets the exact `sport_type` + name + rich description.
- **Upload honesty**: covered distance = `actualDistance`, else the sum of `completedSegments.completed_distance`, omitted entirely when nothing was covered — never the planned `distanceValue`. Start time = `completedAt − actualTimeSeconds`. Event `measure` is `"Miles"`/`"Kilometers"`/`"Kms"` — functions treat anything ≠ `"Miles"` as km.
- Entry points: Profile menu row → `.stravaIntegration`; Settings card (official orange **Connect with Strava** button when disconnected via the shared **`StravaConnectButton`** — `Modules/Shared/`, asset `icStravaConnectOrange` on the `StravaOrange` color; **gradient Resync + red Disconnect** when connected); onboarding `connectStrava` step — its **footer** is that same Connect button until linked, then **Next**. Backlog + Strava's connected-athlete quota limitation (403 on authorize) live in `STRAVA_TODO.md` / `functions/STRAVA_SETUP.md`.

### Deletes only on a user action (fix `aa13faa`)
- The watch's **bulk `deletedEventIds`** list (from `sync_request`/`sync_all`) is reconciled **locally only** via **`reconcileDeletedEventIds`** — a sync replay never writes a Firestore soft-delete, and an id that's also live in the same payload's active/completed lists is kept (**live-data-wins**). This stopped completed events from silently flipping to `deleted` on the next sync.
- Only an **explicit** delete writes to Firestore: the app delete or the watch's `delete_event` command (both → `applyDeletedEventId` → `softDelete`). `applyDeletedEventLocally` is the no-Firestore-write half shared by both paths.
- A user-deleted event **stays deleted** — `FirestoreEventRepository.upsert` preserves a stored `deleted` status, so a later watch re-sync can't resurrect it. Id-less watch payloads are **skipped** (no more `Int(Date())` clock-key duplicate docs).

### Cross-account watch sync (foreign events)
- The watch keeps its full event list across app accounts, so after an account delete/switch it replays deletes for docs the new uid can't touch → `permission denied` flood. `applyDeletedEventId` records such ids in **`AppSession.foreignEventIds`** on the first denial and skips them on every later replay (list cleared on logout).
- `firestore.rules` events **read** allows `resource == null`, so gets/listens on not-yet-created docs return a clean "not found" instead of permission-denied (upsert preloads and fresh-event listeners rely on this).
- `deleteAccount()` cleanup goes through `deleteDocuments(matching:label:)` — still best-effort, but a skipped cleanup now logs a warning instead of silently orphaning docs.

### Working style (owner preferences)
- **Single-line comments** — one concise `//` line over multi-line blocks; keep structure clean. Still preserve `// MARK: -` sections and author headers.
- **Example / flow when needed** — add a short inline example or the data flow only where it genuinely aids understanding (e.g. `// watch "2.5" ft → 2.5 Feet`), not on self-explanatory lines.
- **At most two comment lines together** — never stack more than two `//` lines in one place; if a block needs more explanation than that, the code is too dense — simplify it instead. (`// MARK: -` headers don't count.)
- **Commit messages** — conventional `type(scope): summary`, but the summary and bullets must be **non-technical and high-level** (what the user experiences), not implementation detail.
- **Sole-author commits** — every commit has a single author (the git logged-in user). **Never** append a `Co-Authored-By:` trailer (no Claude co-author).
- **Build check** — `xcodebuild -project PaceApp.xcodeproj -scheme PaceApp -destination 'id=<sim-udid>' build`. There is no test target. Get an available iPhone 16-class simulator UDID via `xcrun simctl list devices available`.

---

## Build, Test & Deploy Commands

> There is **no test target** in this project — `Command+U` / `xcodebuild test` will not run anything. Verify changes by building.

**Build (CLI):**
```bash
xcodebuild -project PaceApp.xcodeproj -scheme PaceApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Preferred in-editor build/log workflow** (this environment exposes Xcode tools):
- `BuildProject` to compile, then `GetBuildLog` with `severity: error` to read failures.
- Run this after each batch of file writes.

**Firebase deploy** (requires `firebase-cli`, from repo root):
```bash
firebase deploy --only firestore:rules,firestore:indexes   # security rules + composite indexes
firebase deploy --only functions                            # Strava Cloud Functions (Blaze plan + STRAVA_CLIENT_SECRET secret)
firebase deploy --only hosting                              # email sign-in page + /stravaCallback function rewrite
```

**Dependencies** are resolved by Xcode via SPM automatically. To resolve from CLI:
```bash
xcodebuild -resolvePackageDependencies -project PaceApp.xcodeproj -scheme PaceApp
```

---

## Architecture

### App Entry & Lifecycle

| File | Role |
|---|---|
| `PaceApp.swift` | `@main` SwiftUI `App` struct. Sets up `Router`, toast/alert overlays, keyboard dismissal, `onOpenURL` handler chain |
| `AppDelegate.swift` | `@UIApplicationDelegateAdaptor`. Configures Firebase, registers Gilroy fonts, sets up AuthManager, initializes ConnectIQ, configures 500MB Firestore persistent cache, sets up swift-log |

**`onOpenURL` handler priority chain**: (1) Firebase reCAPTCHA → (2) Strava callback (`paceapp://strava-callback` OR the https universal link — `StravaManager.isStravaCallback`) → (3) Email sign-in link → (4) ConnectIQ `connect://` scheme.

### Navigation — Router Pattern

The app uses a **singleton `Router`** (`@Observable`, `@MainActor`) injected via SwiftUI's `@Environment`:

| Concept | Detail |
|---|---|
| **Push navigation** | `NavigationStack(path: $router.path)` with `Destinations` enum |
| **Root switching** | `router.setRoot(_:)` swaps the entire root flow with a `CATransition` on the key window |
| **Root flows** | `RootFlow` enum (nested in `extension Router`): `.splash`, `.welcome`, `.auth`, `.authenticating`, `.accountCreation`, `.dashboard` |
| **Duplicate protection** | `isNavigating` flag prevents rapid double-tap pushes (400ms cooldown) |
| **Back navigation** | `router.pop()` or `router.popToRoot()` |
| **Tab-child detail pushes** | Go through `TabNavigationState` + `.navigationDestination(item:)` on `TabBarScreen`, NOT `Destinations` (see Recent Architecture Notes) |

> **Important**: Never instantiate a new `Router` — always use `Router.shared`. Views access it via `@Environment(Router.self)`.

**Destinations Enum** (all push-navigable screens; `Hashable, Codable`):
```swift
enum Destinations: Hashable, Codable {
    case login
    case verifyOTP(phoneNumber: String, verificationID: String)
    case accountCreated
    case createRunEvent
    case favoritesRun
    case notifications
    case settings
    case termsOfService
    case privacyPolicy
    case licenses
    case updateGait
    case manageWatch
    case stravaIntegration
    case editProfile
}
```
Each destination maps to its screen in `Router+Destination.swift` via `@ViewBuilder func destinationView(for:)`.

> Event Details, Duplicate Run, and Analytics Detail are pushed via `TabNavigationState`, not `Destinations`.

### Singleton Graph

Core singletons (most are `@Observable @MainActor`):

| Singleton | Purpose |
|---|---|
| `Router.shared` | Navigation state |
| `AuthManager.shared` | Firebase Auth + live profile listener (`userDetails`) |
| `UserProfileRepository.shared` | Accessor to `FirestoreUserProfileRepository` — `users` CRUD |
| `EventRepository.shared` | Accessor enum to `FirestoreEventRepository` — `events` CRUD + listeners |
| `FavoritesRepository.shared` | Accessor enum to `FirestoreFavoritesRepository` — favorites |
| `AnalyticsRepository.shared` | Analytics reads (direct Firestore, see Analytics note) |
| `ConnectIQManager.shared` | Garmin watch communication |
| `StravaManager.shared` | Strava OAuth + connection state (client half; Cloud Functions do uploads) |
| `ToastManager.shared` | Global toast notifications |
| `AppAlertManager` | Global alert overlay |
| `AppSessionManager.shared` | UserDefaults wrapper |
| `EventUpdateCenter.shared` / `EventDeletionCenter.shared` | In-app broadcast of event edits/deletes for live list patching |
| `HapticManager` | Haptic feedback |

---

## Module Organization

```
PaceApp-ios/
├── PaceApp.swift                 # @main entry
├── AppDelegate.swift             # Firebase + APNs + font registration
├── Router/                       # Router.swift, Destinations.swift, Router+Destination.swift, Router+Roots.swift
├── Model/                        # Domain models
│   ├── UserModel.swift           # User profile (computed: isProfileCompleted, contactInfo; heightCm/weightKg watch-synced)
│   ├── ActivityData.swift        # UI-layer event model (pre-formatted display strings; content-aware ==)
│   ├── EventDocument.swift       # Codable Firestore event doc + EventStatus + FirestoreFlexibleValue
│   ├── RunSegment.swift          # Segment with HR/pace/cadence arrays
│   ├── RunInterval.swift         # Walk/run interval config
│   ├── GaitUserData.swift        # Gait metrics (step length + unit per gait type)
│   ├── GaitStrideCalculator.swift # Height→stride derivation + Feet⇄Meters conversion
│   ├── HomeMetric.swift          # Dashboard metric display
│   ├── NotificationItem.swift    # Push notification model
│   ├── ProfileMenuItem.swift     # Profile menu item model
│   ├── SettingsMenuItem.swift    # Settings menu item model
│   ├── WatchDevice.swift         # Garmin device model
│   └── Enums/                    # 14 enums (see Enums section)
├── Modules/
│   ├── Auth/                     # Splash/, Welcome/, Login/, OTPVerification/, Authenticating/, Complation/
│   ├── CreateAccount/            # CreateAccountScreen.swift + StepViews/ + ViewModel/ (watch-pairing onboarding wizard)
│   └── Dashboard/                # TabBarScreen.swift + TabNavigationState.swift + tabs
│       ├── Home/                 # HomeScreen, NewRun/ (CreateRunEventScreen), EditEvent/, EventDetails/, Favorites/, MetricsPopup/
│       ├── History/              # HistoryScreen + ViewModel + Views
│       ├── Analytics/            # AnalyticsScreen + Components/Models/Repository/ViewModel
│       ├── Profile/              # ProfileScreen, ManageWatch/, UpdateGait/, Strava/ (StravaConnectScreen), Views/
│       ├── Settings/             # SettingScreen, SettingsViewModel, ReauthDeleteSheets, AppWebViewScreen
│       └── Notifications/        # Push notification UI
├── DesignSystem/
│   ├── AppGradients.swift
│   ├── Components/               # AppButton, AppTextField, AppNavigation, SafariView, … + AppAlert/, AppBackground/, Toasts/
│   ├── Font/                     # AppFonts.swift, Gilroy+Font.swift, GilroyFontModifier.swift
│   └── Styles/                   # ButtonGlassStyle, PlainSelectedButtonStyle
├── Utility/
│   ├── Constant/                 # AppConstant.swift, Keys.swift, Garmin.swift, Strava.swift, Network.swift, typeAlias.swift
│   ├── Extensions/               # Array, CGFloat, Color, Date, MKCoordinateRegion, PolylineCodec, String, Task, ToolBar, UIWindow, View
│   ├── Helpers/                  # Logger, Debouncer, ValidationProvider
│   ├── Manager/
│   │   ├── Auth/                 # AuthManager.swift, AuthErrorMapper.swift
│   │   ├── Firestore/            # Interfaces/, Repositories/, Mappers/ (see Data Layer)
│   │   ├── App Session/          # AppSessionManager.swift, AppSessionKey.swift
│   │   ├── Strava/               # StravaManager.swift (OAuth + state), StravaAPI.swift (functions client)
│   │   ├── ConnectIQManager.swift        # (loose file — no ConnectIQ/ subdir)
│   │   ├── EventUpdateCenter.swift
│   │   ├── EventDeletionCenter.swift
│   │   ├── HapticManager.swift
│   │   └── ImagePickerManager.swift
│   └── Modifier/                 # Animations (Shake, SlideTransition, Pulse)
├── Resources/                    # Assets.xcassets, Colors.xcassets, Fonts/, Localizable.xcstrings
├── firebase-hosting/public/      # index.html, emailSignIn/index.html, .well-known/ (AASA + assetlinks.json)
├── functions/                    # Cloud Functions (Strava) — index.js, STRAVA_SETUP.md, .env (client id)
├── STRAVA_TODO.md                # Strava backlog + known limitations (athlete quota)
├── firestore.rules               # Security rules (owner-only access)
├── firestore.indexes.json        # Composite indexes (5, all on events)
├── firebase.json                 # Firebase config (firestore + functions + hosting)
└── GoogleService-Info.plist      # Firebase credentials
```

---

## Data Layer — Firestore Repository Pattern

### Architecture

```
View → ViewModel → Accessor (EventRepository.shared) → FirestoreEventRepository → EventDocumentMapper → EventDocument (Codable) → Firestore
```

### Repository Structure (actual)

```
Utility/Manager/Firestore/
├── Interfaces/
│   ├── EventRepositoryProtocol.swift        # + EventRepository accessor enum + ListenerRegistrationToken
│   ├── UserProfileRepositoryProtocol.swift
│   └── FavoritesRepositoryProtocol.swift    # + FavoritesRepository accessor enum
├── Repositories/
│   ├── FirestoreEventRepository.swift
│   ├── FirestoreUserProfileRepository.swift
│   └── FirestoreFavoritesRepository.swift
└── Mappers/
    └── EventDocumentMapper.swift            # THE single ConnectIQ/Firestore parse path
```

> Document models live in top-level `Model/` (`EventDocument.swift`, `UserModel.swift`, `RunSegment.swift`) — there is no `Firestore/Models/` content and no `FirestoreCollections.swift`.

### Collection Paths

| Collection | Path | Purpose |
|---|---|---|
| `users` | `users/{uid}` | User profile + nested `gait` map + flat settings fields |
| `events` | `events/{eventId}` | Run/walk events; **segments embedded on the doc**, plus `routePolyline`, `status`, `syncStatus`, `source` |
| ~~`segments`~~ | ~~`events/{eventId}/segments`~~ | **Deprecated** — segments are an embedded `[RunSegment]` array (a leftover subcollection rule still exists in `firestore.rules`) |
| `favorites` | `favorites/{favoriteId}` | User favorited events |
| `stravaTokens` | `stravaTokens/{uid}` | Strava OAuth tokens — **server-only** (rules deny all; Cloud Functions read/write via admin SDK) |

### Repository APIs (actual)

**`EventRepositoryProtocol`** (implemented by `FirestoreEventRepository`):
- `observeActiveEvents(userId:onChange:) -> ListenerRegistrationToken`
- `fetchActiveEvents(userId:)` / `fetchCompletedEvents(userId:limit:cursor:)`
- `fetchFilteredCompletedEvents(userId:pageSize:cursor:distanceMin:distanceMax:date:location:)`
- `upsert(from:isCompleted:syncStatus:source:userId:)` — preserves `id`/`source`/`createdAt` on existing docs
- `updateMetadata(eventId:userId:name:location:)` — name/location edits
- `softDelete(eventId:userId:)` — sets `status: deleted` + `deletedAt` server timestamp
- `fetchEvents(byIds:)` / `fetchAllEventPayloads(userId:)`

**`UserProfileRepositoryProtocol`** (implemented by `FirestoreUserProfileRepository`):
- `fetchProfile`, `upsertProfile`, `listenToProfile`
- `updateGait`, `updateIntervalVibrate`, `updateIntervalBeep`, `updateDistanceUnit`, `updateBodyMetrics(heightCm:weightKg:userId:)`

**`FavoritesRepositoryProtocol`** (implemented by `FirestoreFavoritesRepository`):
- `isFavorited(userId:eventId:)`, `toggleFavorite(userId:eventId:)`, `fetchFavoriteEventIds(userId:)`

### EventDocument (Codable, `Model/EventDocument.swift`)

Key fields: `id: Int` (doc key), `userId`, `status`, `name`, `location`, `scheduledAt`, `completedAt?`, `activityType`, `distanceValue`, `measure`, `goalTimeSeconds`, `lookBackIntervals`, `avgPaceSeconds?`, `avgHeartRate?`, `elevationGain?`, `effortPercentage?`, `actualTimeSeconds?`, `actualDistance?`, `timeVarianceSeconds?`, `paces: [Int]?`, `completedSegments: [[String: FirestoreFlexibleValue]]?`, `syncStatus`, `source`, `createdAt`, `updatedAt`, `deletedAt?`, `segments: [RunSegment]?`, `routePolyline: String?`.

### UserModel (`Model/UserModel.swift`)

`uuid`, `firstName?`, `lastName?`, `gender?`, `email?`, `phoneNumber?`, `gait: GaitUserData?`, `intervalVibrate?`, `intervalBeep?`, `distanceUnit: MeasureUnit?`, `heightCm?`, `weightKg?`, `lastSyncedAt?`. Computed: `contactInfo`, `isProfileCompleted`.

### EventDocumentMapper

Static-only. Key methods: `document(...) -> (EventDocument, [RunSegment])`, `updatedDocument(...)`, `activityData(...)` (→ UI model), `connectIQPayload(from:)` (app→watch), `analyticsRecord(from:) -> EventAnalyticsRecord?`, plus lenient parse helpers (`parseConnectIQDate`, `parseTimeString`, `parseSignedTimeVariance`, `mapActivityType`/`reverseMapActivityType`, `computeEffortPercentage`, …). Uses `PolylineCodec` for `routePolyline`.

### Firestore Security Rules

```
users/{userId} (+ subdocs)   → read/write: auth.uid == userId
events/{eventId}             → read: owner OR resource == null (clean "not found" for missing docs)
                                update/delete: auth.uid == resource.data.userId
                                create: auth.uid == request.resource.data.userId
  segments/{segId}           → leftover rule (owner check via parent get()) — subcollection no longer written
favorites/{favId}            → read/delete: auth.uid == resource.data.userId
                                create: auth.uid == request.resource.data.userId
stravaTokens/{userId}        → all client access denied (Cloud Functions admin SDK only)
```

### Composite Indexes (deployed, `firestore.indexes.json`)

All on `events`:

| Fields | Purpose |
|---|---|
| `userId` ASC + `status` ASC + `scheduledAt` ASC | Active/upcoming events |
| `userId` ASC + `status` ASC + `completedAt` DESC | History (newest first) |
| `userId` ASC + `status` ASC + `updatedAt` DESC | History default order (recently touched first) |
| `userId` ASC + `status` ASC + `completedAt` ASC | Analytics date-range reads |
| `userId` ASC + `status` ASC + `distanceValue` ASC + `completedAt` DESC | Filtered history (distance range) |

---

## Authentication System

### Dual Auth Methods

| Method | Flow |
|---|---|
| **Phone OTP** | Enter phone → `PhoneAuthProvider.verifyPhoneNumber()` (APNs/reCAPTCHA) → 6-digit OTP → `signIn(with: PhoneAuthCredential)` |
| **Email Link** | Enter email → `sendSignInLink(toEmail:)` → User clicks link → `signIn(withEmail:link:)` |

### AuthManager Lifecycle

1. `configure()` — called from AppDelegate
2. Registers `addStateDidChangeListener` on `Auth.auth()`
3. On auth state change: fetches Firestore user profile (creates if new user), starts the live profile listener
4. Calls `router.setupRootNavigation()` to set appropriate root flow
5. `autoLogin()` — checks `Auth.auth().currentUser`, restores session

### Auth Flow Screens (`Modules/Auth/`)

```
SplashScreen → (autoLogin) → Dashboard OR WelcomeScreen
WelcomeScreen → LoginScreen (LoginViewModel; Phone/Email tabs)
LoginScreen → OTPVerificationScreen (phone; OTPVerificationViewModel + OTPState machine)
           → "check your email" (email link)
→ AuthenticatingScreen → ComplationScreen (.otpVerified / .accountCreation) → Dashboard OR CreateAccount
```

> Screen names: `SplashScreen`, `WelcomeScreen`, `LoginScreen`, `OTPVerificationScreen`, `AuthenticatingScreen`, `ComplationScreen` (folder/typo spelling "Complation" is intentional in the codebase). Only Login and OTPVerification have their own ViewModels.

### Key Auth Rules

- **PhoneAuthUIDelegate** must be held strongly on `AuthManager` during `verifyPhoneNumber` — don't let it deallocate
- **Email link different device**: If `Keys.emailForSignIn` is empty when link arrives, show error and redirect to `.auth`
- **`continueURL`**: Must be path-qualified (`https://thepaceapp.firebaseapp.com/emailSignIn`), not bare domain root
- **`linkDomain`**: Must not be set for `.firebaseapp.com` domains
- **Friendly errors**: route all auth errors through `AuthErrorMapper.message(for:)` — never `error.localizedDescription`

---

## Onboarding — CreateAccount Wizard

The CreateAccount flow is a **watch-pairing onboarding wizard**, not a body-metrics form. Steps are driven by the **`CreateAccountStep`** enum (`Model/Enums/CreateAccountStep.swift`, `Int, CaseIterable`):

| Step | View (`Modules/CreateAccount/StepViews/`) | Purpose |
|---|---|---|
| `.profile` | `ProfileStepView` | Name / basic profile |
| `.pairWatch` | `PairWatchStepView` | Start Garmin pairing |
| `.chooseYourModel` | `ChooseDevicesStepView` | Pick the watch model |
| `.showConnectedWatch` | `ConnectWatchStepView` | Confirm connected watch |
| `.setGait` | `SetGaitStepView` | Step length (shared `GaitSelectionView` with Profile → UpdateGait) |
| `.connectStrava` | `ConnectStravaStepView` | Link Strava via the shared `StravaManager` flow (Skip available) |

- `connectStrava` is the **active final step** (re-enabled). The step view reads `StravaManager` from the environment; `CreateAccountScreen` overrides the footer title to **"Next"** when `strava.isConnected`, and the footer tap then calls `finishOnboarding()` instead of relaunching OAuth.
- Container: `CreateAccountScreen.swift` (module root — no `Screen/` subdir). State: `CreateAccountViewModel` with `var currentStep: CreateAccountStep = .profile`; advancement via the enum's computed `next` / `previous` (no `totalSteps` property).
- The enum provides per-step `title`, `footerButtonTitle`, `showsBack`/`showsSkip`.
- `ManageWatchStep` (`currentConnected`, `pairWatch`, `chooseYourModel`) mirrors the pairing steps for Profile → Manage Watch.

---

## Forms & Validation

### Validation Stack

Validation is driven by the **`ValidationType`** enum (`Model/Enums/ValidationType.swift`), not per-rule methods:

```swift
// ValidationProvider (Utility/Helpers/) — single public entry point
ValidationProvider.isValid(text: vm.email, type: .email)
```

- `ValidationType` cases: `name`, `location`, `email`, `password`, `confirmPassword(new:)`, `phoneNumber`, `alphanumeric`, `custom(regex:)`, `none` — each exposes an `errorMessage`.
- Flow: `ValidationProvider.isValid` → ViewModel computed `isValid` → `AppTextField.errorMessage` (inline) / `ShakeModifier` (animation) / `ToastManager` (global).
- `Constant.Config` holds `validPasswordLength` (8) and `OTPLength` (6).

### Form Best Practices (Follow These)

1. **ViewModel owns all form state** — never use `@State` for form fields in views
2. **Validation is centralized** in the ViewModel via computed properties
3. **Use `AppTextField`** for all text inputs — never raw `TextField`
4. **Use `AppSegmentedControl`** for enum-based selections
5. **Use `@Bindable var viewModel`** in step/sub views for binding, but **never declare `@Bindable` inside `body`**
6. **Keyboard types** must be set per field (`.numberPad`, `.decimalPad`, `.default`)
7. **Save operations** always go through repository layer, never raw Firestore calls
8. **Error display**: `AppTextField.errorMessage` for inline errors, `ToastManager` for global errors
9. **Loading state**: `AppButton.isLoading` during async save operations

---

## Design System

### Color Palette (from `Colors.xcassets`)

| Token | Usage |
|---|---|
| `.darkSeaBlue` | Primary background dark |
| `.traditionalNavyBlue` | Background gradient end |
| `.neonAquaBlue` | Accent / highlight (tab tint) |
| `.fluorescentMint` | Secondary accent / "ahead of goal" delta |
| `.redBoho` | "Behind goal" delta / destructive accents |
| `.radiantBlue` | App tint, active states |
| `.slateGrey` | Muted text, dividers |
| `.pureWhite` | Primary text |
| `.softWhite` | Secondary text |
| `.stravaOrange` | Strava brand orange (`#FC5200`) — the Connect with Strava button fill |

### Gradients (`AppGradients`)

| Gradient | Purpose |
|---|---|
| `AppGradients.background` | Full-screen background (darkSeaBlue → traditionalNavyBlue) |
| `AppGradients.button` | Primary CTA buttons |
| `AppGradients.border` | Glass card/button borders |

### Typography — Gilroy Font System

Registered in AppDelegate. Files: `DesignSystem/Font/AppFonts.swift` (tokens), `Gilroy+Font.swift` (weight enum), `GilroyFontModifier.swift`.

**Font tokens** are `weight + size` statics on `Font` (e.g. `.semiBold16` = `Gilroy.semiBold.size(16)`), spanning light/regular/medium/semiBold/bold/extraBold.

> **Never** use `Font.system(...)` or `Font.custom("Gilroy-...", size:)` directly. Always use tokens.

### UI Constants (`Constant`, in `Utility/Constant/AppConstant.swift`)

| Constant | Value |
|---|---|
| `Constant.UI.animationDuration` | 0.3 |
| `Constant.UI.glassBlurRadius` | 20 |
| `Constant.UI.listRowSpacing` | 12 |
| `Constant.UI.spacing16` | 16 |
| `Constant.UI.defaultCornerRadius` / `cardCornerRadius` | 12 |
| `Constant.UI.cornerRadius16` | 16 |
| `Constant.UI.defaultBorderWidth` | 1 |
| `Constant.UI.defaultPadding` | 16 |
| `Constant.UI.padding12` | 12 |
| `Constant.UI.disabledOpacity` | 0.5 |
| `Constant.UI.defaultKeyboardToolBarHeight` | 44 |
| `Constant.Config.validPasswordLength` | 8 |
| `Constant.Config.OTPLength` | 6 |

### Components (`DesignSystem/Components/`)

| Component | Purpose |
|---|---|
| `AppButton` | Primary CTA with gradient, loading, disabled states |
| `GlassButton` | Secondary CTA with translucent glass effect |
| `AppTextField` | Text input with floating label, error state |
| `AppSegmentedControl` | Generic enum-based toggle with glass styling |
| `AppNavigation` | Custom nav bar with leading/trailing slots |
| `AppLabel` / `LabelNewRun` | Styled labels |
| `OTPFieldView` | 6-digit OTP boxes with auto-advance |
| `DatePickerField` / `DatePickerSheet` | Date input + wheel sheet |
| `DualRangeSlider` | Two-thumb range slider (History distance filter) |
| `SafariView` | `SFSafariViewController` wrapper (FAQ) |
| `WebView` | WKWebView wrapper (`AppWebViewScreen` for terms/privacy/licenses) |
| `NoDataView` | Empty-state placeholder |
| `LogoWithText`, `ProfilePhotoShape`, `Spacing` | Misc shared UI |
| `AppAlert/` | `AppAlertManager` + `AppAlertModel` + `AppAlertView` + `InstallAppAlert` |
| `AppBackground/` | `AppBackground`, `AppCardBackground`, `BackgroundContainer` |
| `Toasts/` | `ToastManager`, `ToastView`, `ToastContainerView`, `InstallToast`, `ToastValue` |

**Usage examples:**
```swift
AppButton(title: "Continue", isLoading: vm.isLoading, isEnabled: vm.isValid) { vm.submit() }
ToastManager.shared.present(.error("Something went wrong"))
```

### View Modifiers

| Modifier | Purpose |
|---|---|
| `.appBackground()` | Apply gradient background |
| `.dismissKeyboardOnTap()` | Global tap-to-dismiss (applied at NavigationStack level — don't add per-screen) |
| `.installToast(position: .top)` | Toast overlay (app root only) |
| `.installAppAlert()` | Alert overlay (app root only) |
| `.cardStyle()` | Standard card styling |
| `.shimmer()` | Loading shimmer |
| `.onFirstAppear(_:)` | Execute only on first appearance |

### Animation Modifiers (`Utility/Modifier/`)

| Modifier | Purpose |
|---|---|
| `ShakeModifier` | Horizontal shake on validation error (bound to `Bool`) |
| `SlideTransitionModifier` | Slide transition for screen changes |
| `PulseModifier` | Repeating pulse/glow for active indicators |

### Button Styles

`ButtonGlassStyle` (glass blur + gradient border), `PlainSelectedButtonStyle` (selected/unselected tabs/filters).

---

## Enums Reference

`Model/Enums/` contains exactly these (conformances vary — check the file):

| Enum | Cases / Purpose |
|---|---|
| `GaitType` | `.walking` (`"Walking"`), `.running` (`"Running"`); `.label` = "Walk"/"Run" |
| `Gender` | `.male`, `.female`, `.other`, `.preferNotToSay` |
| `LoginType` | `.phoneNumber`, `.email` |
| `PaceTab` | `.home`, `.history`, `.stats`, `.profile` |
| `CreateAccountStep` | Onboarding steps (see Onboarding section) |
| `CreateEventType` | `.new`, `.duplicate` — event editor mode |
| `ManageWatchStep` | `.currentConnected`, `.pairWatch`, `.chooseYourModel` |
| `OTPState` | Phone-auth state machine: `.idle`, `.sending`, `.otpSent(verificationID:)`, `.verifying`, `.success`, `.error(String)` |
| `ComplationScreenType` | `.otpVerified`, `.accountCreation` — completion screen variant |
| `LoadingState` | `.show`, `.hide` |
| `MetricType` | `.bpm`, `.hrs`, `.pace`, `.time`, `.minMile` |
| `EventDetailsStepViewField` | Focus fields `.eventName`, `.location` |
| `ProfileMenuItemType` | `.navigation`, `.toggle(binding:value:)` |
| `ValidationType` | Validation kinds (see Forms & Validation) |

**Enums defined elsewhere** (not in Model/Enums/):

| Enum | Location | Cases |
|---|---|---|
| `ActivityType` | `Modules/Dashboard/Home/NewRun/ViewModel/ActivityType.swift` | `.run`, `.walking`, `.cycling`, `.other` (+ `.title`, `.icon`, `.watchString`) |
| `MeasureUnit` | `Modules/Dashboard/Home/NewRun/ViewModel/MeasureUnit.swift` | `.km = "Kms"`, `.miles = "Miles"` — THE distance-unit type (there is no `DistanceUnit`/`WeightUnit`/`HeightUnit` type) |
| `EventStatus` | `Model/EventDocument.swift` | `.active`, `.completed`, `.deleted` |
| `RootFlow` | `Router/Router+Roots.swift` (nested in `extension Router`) | `.splash`, `.welcome`, `.auth`, `.authenticating`, `.accountCreation`, `.dashboard` |
| `CreateRunStep` | `Modules/Dashboard/Home/NewRun/ViewModel/CreateRunStep.swift` | New-run form steps |

> There is no `SyncStatus` enum — `EventDocument.syncStatus` is a plain String (`"pending"`/`"synced"`). Gait step-length unit is stored as the full word `"Feet"`/`"Meters"` (not `ft`/`m` — that's only the watch wire format).

---

## Tab Bar & ViewModel Ownership

### TabBarScreen Structure

4 tabs: **Home** → **History** → **Stats (Analytics)** → **Profile**

```swift
// TabBarScreen holds the SCREENS as @State — each screen owns its own ViewModel.
@State private var tabNavState = TabNavigationState()
@State private var homeScreen      = HomeScreen()
@State private var historyScreen   = HistoryScreen()
@State private var analyticsScreen = AnalyticsScreen()
@State private var profileScreen   = ProfileScreen()
```

Holding the screen structs as `@State` preserves each screen's identity — and therefore its `@State` ViewModel — across tab switches. `TabNavigationState` is injected via `.environment(tabNavState)` and its `.navigationDestination(item:)` modifiers sit on the TabView (never inside it).

> **Never construct ViewModels inline in `body`** — they will reinitialize on every tab switch or NavigationStack path change.

### Module → ViewModel → Repository Flow

| Module | Screen / ViewModel | Repository | Operations |
|---|---|---|---|
| Home | `HomeScreen` / `HomeViewModel` | `EventRepository.shared` | Active events listener, delete, favorite |
| Home/NewRun | `CreateRunEventScreen` / `CreateRunEventViewModel` | `EventRepository.shared` | Create event (`CreateEventType.new` / `.duplicate`) |
| Home/EditEvent | `EditEventScreen` | `EventRepository.shared` | Update name/location (`updateMetadata`) |
| Home/EventDetails | `EventDetailsScreen` / `EventDetailsViewModel` | `FirestoreEventRepository` / `FirestoreFavoritesRepository` | Event + embedded segments; favorite; map gated on `hasRouteData` |
| Home/Favorites | `FavoritesRunScreen` / `FavoritesViewModel` | `FavoritesRepository.shared` | Fetch/toggle favorites |
| History | `HistoryScreen` / `HistoryViewModel` | `EventRepository.shared` | Completed events, paging, filters |
| Analytics | `AnalyticsScreen` / `AnalyticsViewModel` | `AnalyticsRepository.shared` | Aggregate by period (week/month/year/all) |
| Analytics/Detail | `AnalyticsDetailScreen` | (shares `AnalyticsViewModel` via `tabNavState`) | Detailed trends and charts |
| Profile | `ProfileScreen` / `ProfileViewModel` | `UserProfileRepository.shared` | Profile display, watch re-sync on appear |
| Profile/Edit | `EditProfileScreen` / VM | `UserProfileRepository.shared` | Update profile |
| Profile/Gait | `UpdateGaitScreen` / `UpdateGaitViewModel` | `UserProfileRepository.shared` | Update gait |
| Profile/Watch | `ManageWatchScreen` / `ManageWatchViewModel` | `ConnectIQManager.shared` | Pair/unpair Garmin devices |
| Settings | `SettingScreen` / `SettingsViewModel` | `AuthManager.shared`, `UserProfileRepository.shared`, `StravaManager.shared` | Logout, delete account, toggles, FAQ, Strava card (Connect / Resync + Disconnect) |
| Notifications | `Notifications/` module | — | Push notification display |

> **Analytics exception**: `AnalyticsRepository` (`Modules/Dashboard/Analytics/Repository/`) talks to Firestore **directly** (`fetchCompletedEvents(userId:from:to:)` → `EventDocumentMapper.analyticsRecord`), bypassing the protocol layer. Keep new event reads/writes in `FirestoreEventRepository` unless extending analytics.

---

## ConnectIQ / Garmin Integration

- `ConnectIQManager.shared` (`Utility/Manager/ConnectIQManager.swift`) — handles all watch communication via Garmin ConnectIQ SDK
- **Background mode**: `bluetooth-central` in `UIBackgroundModes`
- **URL scheme**: `connect://` registered for ConnectIQ callbacks (`paceapp://` is registered separately for the Strava callback)
- **Queries schemes**: `gcm-ciq` + `strava` in `LSApplicationQueriesSchemes`
- **Cold launch**: `restoreSessionIfNeeded()` + `resyncPendingEvents()`
- **Key operations**: `initialize()`, `pairDevice()`, `unpairDevice()`, `sendMessage(_:)`, `handleOpenURL(_:)`
- **Settings sync**: `sendSettings(gaitOverride:)` (app→watch), `applyRemoteSettings(_:)` (watch→app; echoes in-payload `vibrate_alert`/`beep_alert` when replying), `requestSettings()` (ask the watch for its body metrics). Gait math lives in `GaitStrideCalculator` (`Model/`).

---

## Extensions Reference (`Utility/Extensions/`)

| File | Purpose |
|---|---|
| `View+Ext.swift` | `.appBackground()`, `.dismissKeyboardOnTap()`, `.installToast()`, `.installAppAlert()`, `.cardStyle()`, `.shimmer()`, `.onFirstAppear(_:)` |
| `Color+Ext.swift` | Named color accessors (`.darkSeaBlue`, `.neonAquaBlue`, …) |
| `String+Ext.swift` | Trimming, formatting helpers |
| `Date+Ext.swift` | Date formatting/comparison helpers |
| `Array+Ext.swift` / `CGFloat+Ext.swift` | Collection / numeric helpers |
| `MKCoordinateRegion+Ext.swift` | Map region fitting for the route map |
| `PolylineCodec.swift` | Google encoded-polyline encode/decode (route GPS ↔ `routePolyline`) |
| `Task+Ext.swift` | Task convenience helpers |
| `ToolBar+Ext.swift` | Keyboard toolbar helpers |
| `UIWindow+Ext.swift` | Key-window access (root transitions) |

> Font tokens live in `DesignSystem/Font/AppFonts.swift`, not in an Extensions file.

---

## Session Management

**`AppSessionManager`** (`Utility/Manager/App Session/`, UserDefaults wrapper) — keys are the **`AppSessionKey`** enum:
- `isUserCanViewMetricsPopUp` → `canShowMetricsOnboarding: Bool`
- `pairedWatchUUID` → `pairedWatchUUID: String?`
- `pairedDevices` → `pairedDevices: [PersistedDevice]`
- `lastWatchSyncDate` → `lastWatchSyncDate: Date?`
- `foreignEventIds` → `foreignEventIds: [Int]` (event ids owned by a previous account — watch replays are skipped)

`removeAllData()` wipes everything except `ignoreKeyList` (`.isUserCanViewMetricsPopUp`).

**`Keys`** (`Utility/Constant/Keys.swift`, raw UserDefaults string keys): `accessToken`, `garminAccessToken`, `userProfile`, `onboardingComplete`, `emailForSignIn` (email-link auth completion).

> **User settings** (gait, units, alert toggles) are stored on the **Firestore user document**, NOT in UserDefaults.

---

## Key Conventions & Patterns

### Swift / SwiftUI Patterns

- **Observation framework** (`@Observable`, `@ObservationIgnored`) — **NOT** Combine's `ObservableObject`/`@Published`
- **`@MainActor`** on all singletons and UI-bound classes
- **`// MARK: -`** sections in every file — preserve them
- **File headers**: Standard Xcode format `//  FileName.swift  //  PaceApp  //  Created by FURKAN VIJAPURA on ...`
- **Tab indentation**: The project uses **tabs**, not spaces
- **Comment policy**: Prefer **single-line** `//` comments; add a short example or flow only when it aids understanding; **never stack more than two comment lines together** (`// MARK:` headers exempt). Never remove existing `// MARK:` sections or author headers

### Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Screens | `*Screen` suffix | `HomeScreen`, `SettingScreen` |
| ViewModels | `*ViewModel`, usually in `ViewModel/` subdirectory | `HomeViewModel`, `CreateRunEventViewModel` |
| Enums | PascalCase, mostly in `Model/Enums/` | `GaitType`, `PaceTab` |
| Font tokens | `weight + size` | `.semiBold16`, `.bold24` |
| Color assets | camelCase named colors | `.darkSeaBlue`, `.neonAquaBlue` |
| Constants | `Constant.Config.*`, `Constant.UI.*` | `Constant.UI.defaultCornerRadius` |
| Storage keys | `Keys.*` statics / `AppSessionKey` enum | `Keys.emailForSignIn` |
| Gradients | `AppGradients.*` | `AppGradients.background` |
| Repositories | `Firestore*Repository` class + accessor enum | `FirestoreEventRepository` via `EventRepository.shared` |
| Protocols | `*Protocol` suffix | `EventRepositoryProtocol` |
| Mappers | `*Mapper` with static methods | `EventDocumentMapper.document(...)` |

---

## Critical Rules

1. **Never use `ObservableObject`/`@Published`** — the project uses Swift's `@Observable` macro exclusively.
2. **Never create new Router instances** — always use `Router.shared` and `@Environment(Router.self)`.
3. **Always use tab indentation** — match the existing codebase style.
4. **Preserve all `// MARK: -` sections** and file header comments. Never remove inline comments or block comments.
5. **Firestore operations must go through the Repository layer** — never write raw Firestore calls in ViewModels or Views (known exception: `AnalyticsRepository`).
6. **New screens** must follow the `*Screen` naming convention and be added to both `Destinations` enum and `Router+Destination.swift` (or, for tab-child details, to `TabNavigationState` + `TabBarScreen`'s destinations).
7. **New root flows** must be added to `RootFlow` enum in `Router+Roots.swift` and handled in `Router.rootView()`.
8. **Colors**: Use named color assets from `Colors.xcassets` — never hardcode hex values inline.
9. **Fonts**: Always use the `Font` extension tokens (`.semiBold16`, etc.) — never use `Font.custom("Gilroy-...", size:)` directly in views.
10. **Bundle ID**: `net.paceapp`. Do not confuse with `com.garmin.paceapp`, which is only the `CFBundleURLName` for the ConnectIQ `connect://` URL type in `PaceApp-Info.plist`.
11. **Keyboard dismissal**: Applied globally via `.dismissKeyboardOnTap()` at the NavigationStack level — don't add per-screen.
12. **Firestore cache**: 500 MB persistent cache configured in AppDelegate — don't reconfigure elsewhere.
13. **Never declare `@Bindable var viewModel` inside `body`** — always derive `Binding<T>` from a `@State` property to prevent @Observable re-registration feedback loops.
14. **`navigationDestination` placement** — must never be placed inside lazy containers (`TabView`, `List`, `LazyVStack`, `ScrollView`). Must be above the `TabView` boundary (this is exactly what `TabNavigationState` + `TabBarScreen` implement).
15. **ActivityData stable IDs** — never use `let id = UUID()` on model types in lists. Use stable, deterministic IDs (Firestore document ID or sync ID).
16. **Timer and `@Observable`** — `Timer.scheduledTimer` fires off MainActor. Mutations to `@Observable` state must be dispatched to `@MainActor` explicitly.
17. **Firestore user settings** — use flat fields + nested map on the user document, not subcollections. Avoids doubling Firestore read costs on launch.
18. **`continueURL` for Firebase email link** — must be path-qualified (e.g., `https://thepaceapp.firebaseapp.com/emailSignIn`), not a bare domain root.
19. **Form validation** — always centralize in ViewModel, never inline in views. Use `ValidationProvider.isValid(text:type:)`.
20. **New forms** — use `AppTextField` and `AppSegmentedControl` from the design system. Never create ad-hoc form components.
21. **Comment discipline** — write **single-line** `//` comments; include a short example or flow only when it genuinely helps (e.g. `// watch "2.5" ft → 2.5 Feet`); **never stack more than two comment lines together** in one place (`// MARK: -` headers are exempt). If a block needs more, simplify the code. Preserve existing `// MARK: -` sections and author headers.
22. **Sole-author commits** — commits always have a single author (the git logged-in user). **Never** add a `Co-Authored-By:` trailer or any second author.

---

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| **Tab ViewModel re-init loop** | Tab **screens** held as `@State` on `TabBarScreen`; each screen owns its VM as `@State`. Never construct either inline in `body`. |
| **`@Bindable` feedback loop** | Never use `@Bindable var viewModel` inside `body`. Use stable `Binding<T>` computed properties derived from `@State`. |
| **Double navigation** | `Router.navigate(to:)` has 400ms debounce guard — don't bypass it. |
| **reCAPTCHA delegate lifetime** | `PhoneAuthUIDelegate` must be held strongly on `AuthManager` during `verifyPhoneNumber`. |
| **Email link different device** | If `Keys.emailForSignIn` is empty when email link arrives, show error and redirect to `.auth`. |
| **ActivityData UUID identity** | Using `let id = UUID()` causes SwiftUI to destroy/rebuild every list row on Firestore snapshot. Use stable IDs. |
| **Timer threading** | `Timer.scheduledTimer` fires off `@MainActor`. Wrap mutations in `Task { @MainActor in ... }`. |
| **Mapper field loss** | When editing `EventDocumentMapper`/`UserModel` coding, preserve derived fields (`isProfileCompleted`, `contactInfo`, `ActivityData`'s pre-formatted display strings) — they're easily silently dropped. |
| **`GeometryReader` in a `List` cell** | Crashes at launch: `UICollectionView … recursive layout loop`. Size deterministically (e.g. `UIScreen.main.bounds.width`), never via `GeometryReader` inside a self-sizing row. |
| **Un-tappable button in a `List` row** | The row swallows the tap. Give buttons `.buttonStyle(.borderless)` / `.plain` so each stays independently tappable. |
| **`source`/`id` flipping on sync** | `EventDocument.source`, `id`, `createdAt` are write-once. Rely on `FirestoreEventRepository.upsert` preserving them — don't rewrite them from an echoed watch payload. |
| **Gait unit shows wrong / segment inactive** | Watch sends `ft`/`m` + String numbers; convert with `appGaitUnit`/`watchGaitUnit`/`settingDouble`. App stores `"Feet"`/`"Meters"`. |
| **Edited list row doesn't refresh** | `ActivityData` id-only `==` makes SwiftUI skip re-rendering the row. Compare displayed fields in `==` (identity/hash stay on `id`). |
| **Watch echoes stale alert toggles** | When replying to a settings payload, overlay the incoming `vibrate_alert`/`beep_alert` onto `getSettingsPayload()` — Firestore persistence races the reply. |
| **`permission denied` flood on account delete** | Firestore writes (watch sync) outlive the auth token. Disconnect the watch + stop writers BEFORE `signOut()`/`user.delete()`; make delete-path reads best-effort so they can't abort. |
| **`user.delete()` silently fails / account survives** | Firebase needs a recent login. Reauthenticate inline first (`reauthenticateWithPhone` / email link via `isReauthenticatingForDeletion`); don't `try?`-swallow the delete. |
| **Raw Firebase error shown to user** | Route auth errors through `AuthErrorMapper.message(for:)` — never `error.localizedDescription` in a toast/alert. |
| **Strava callback silently ignored** | The return arrives as `paceapp://strava-callback` OR the https universal link. Route both via `StravaManager.isStravaCallback` in `onOpenURL` — matching only the custom scheme drops the universal-link form with no error. |
| **Fractional watch values truncated to 0** | `EventDocumentMapper.mapGenericDicts` must check `Double` BEFORE `NSNumber` — the NSNumber branch's `.intValue` stored `0.25` as `0` (broke `completedSegments` distances). |
| **Foreign-event `permission denied` flood** | The watch replays deletes for another account's docs on every connect. First denial records the id in `AppSession.foreignEventIds`; later replays skip it. |
| **Strava shows planned distance / absurd pace** | Never upload `distanceValue` as covered distance — use `actualDistance` or the `completed_distance` sum, and omit the field when 0 (functions `coveredDistance`). |
| **Completed event flips to `deleted` on sync** | The bulk `deletedEventIds` replay must be **local-only** (`reconcileDeletedEventIds`) — never a Firestore `softDelete`. Only `delete_event` / app delete write deletes; live-data-wins keeps an id present in the same payload. |
| **Strava connection wrongly cleared** | Clear only on a real revoke — Strava returns **401** for invalidated tokens. A `403` (scope/quota) or a `400` client-credential error must NOT delete tokens, else a config slip mass-disconnects everyone (`isRevocation`). |

---

## Dependencies (Swift Packages, from `Package.resolved`)

| Package | Version | Purpose |
|---|---|---|
| **firebase-ios-sdk** | 12.14.0 | `FirebaseAuth`, `FirebaseFirestore`, `FirebaseCore` |
| **connectiq-companion-app-sdk-ios** (Garmin) | 1.8.0 | ConnectIQ watch SDK |
| **swift-log** (apple) | 1.13.1 | Structured logging (`Logger.app`) |
| **CountryPicker** (SURYAKANTSHARMA) | 5.0.2 | Country/dial-code picker for phone auth |

Plus Firebase's transitive deps (abseil, gRPC, GoogleAppMeasurement, GoogleUtilities, leveldb, nanopb, promises, app-check, …). **FITSwiftSDK has been removed** — older notes referencing it are obsolete.

---

## Firebase Hosting

```
firebase-hosting/public/
├── index.html                       # Landing page
├── emailSignIn/index.html           # Email sign-in deep link (redirects back to app)
├── 404.html                         # Custom 404
└── .well-known/
    ├── apple-app-site-association   # iOS universal links (wildcard /* — also the Strava OAuth return path)
    └── assetlinks.json              # Android app links (net.paceapp, 3 SHA-256 fingerprints)
```

> `/stravaCallback` is **not** a static page — a `firebase.json` rewrite routes it to the `stravaCallback` Cloud Function (302 → `paceapp://strava-callback`, the Safari fallback when the universal link doesn't fire).

**APNs**: Required for silent push phone verification.
**Reversed client ID**: `app-1-652638681487-ios-0bf0155356db81a4d6f3fa` (URL scheme for reCAPTCHA).

---

## Workflow Conventions

### Pre-Edit Workflow

1. **Read all relevant files** before making changes.
2. **Fix root causes** rather than symptoms.
3. **Prefer complete file rewrites** over incremental partial fixes when conflicting or redundant code is the source of confusion.

### Adding a New Feature Checklist

1. Create screen in `Modules/{Feature}/` following `*Screen` naming
2. Create ViewModel following `*ViewModel` naming (own as `@State` at the right scope)
3. If new Firestore data: add Protocol (Interfaces/) → Repository (Repositories/) → Codable model (`Model/`) → Mapper
4. Add destination to `Destinations` + `Router+Destination.swift` — or to `TabNavigationState` + `TabBarScreen` if it's a tab-child detail push
5. Use `AppTextField`, `AppSegmentedControl`, `AppButton` from DesignSystem
6. Add a `ValidationType` case if a new field kind needs validation
7. Apply `.appBackground()` and use font tokens

### Build Verification

After each batch of file writes: `BuildProject` → `GetBuildLog` with `severity: error`.

### Git Commits

Conventional commits style — **sole author, no `Co-Authored-By:` trailer**; summary is non-technical and user-facing:
```
feat(scope): impactful non-technical summary

- detail line 1
- detail line 2
```

---

## Known Gaps & On the Horizon

- **Leftover `segments` subcollection rule** in `firestore.rules` — segments are embedded now; the rule is harmless but dead.
- **`AnalyticsRepository` bypasses the protocol layer** — reads Firestore directly; acceptable for read-only aggregation, but don't copy the pattern for writes.
- **Manual gait edits are overwritten** by height-derived gait on each watch connect / Profile visit — a "manual override" flag would be needed to preserve them.
- **`heightCm`/`weightKg` are watch-sourced only** — onboarding doesn't collect them.
- **Strava uploads carry per-segment laps** (TCX) but are still **summary-level** — no GPS map / route or HR trace (no timestamped track is stored); new-API-app athlete quota applies (403 "limit of connected athletes" until Strava grants an increase). The official "Connect with Strava" button, revoke-endpoint migration, and the deauthorization webhook are now **in**; remaining work — register the webhook push subscription + arm `STRAVA_WEBHOOK_SUBSCRIPTION_ID`, a `stravaSyncStatus` field on events, and GPX/HR upload — is tracked in `STRAVA_TODO.md`.
- **No test target** — verification is build-only.
- **Localization** — copy lives in `Resources/Localizable.xcstrings`; keep user-facing strings localized.
