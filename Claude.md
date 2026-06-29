# PaceApp iOS — Project Intelligence

## Overview

**PaceApp** is a native iOS running/walking pace-tracking app built with **SwiftUI** (iOS 17+). It pairs with **Garmin ConnectIQ** watches to sync real-time activity data (segments, heart rate, pace, distance) and persists everything to **Firebase** (Auth, Firestore). The app uses a light-mode-only, dark-themed design system built around the **Gilroy** font family and a neon-aqua-on-navy color palette.

---

## Architecture

### App Entry & Lifecycle

- **Entry point**: `PaceApp.swift` — `@main` SwiftUI `App` struct.
- **AppDelegate**: `AppDelegate.swift` — configured via `@UIApplicationDelegateAdaptor`. Handles `FirebaseApp.configure()`, APNs token registration, reCAPTCHA URL scheme callbacks, and universal link reception.
- **Color scheme**: Force light mode (`.preferredColorScheme(.light)`) — the "dark" look comes from dark background colors, not system dark mode.

### Navigation — Router Pattern

The app uses a **singleton `Router`** (`@Observable`, `@MainActor`) injected via SwiftUI's `@Environment`:

| Concept | Detail |
|---|---|
| **Push navigation** | `NavigationStack(path: $router.path)` with `Destinations` enum |
| **Root switching** | `router.setRoot(_:)` swaps the entire root flow with a `CATransition` on the key window |
| **Root flows** | `RootFlow` enum: `.splash`, `.welcome`, `.auth`, `.authenticating`, `.accountCreation`, `.dashboard` |
| **Duplicate protection** | `isNavigating` flag prevents rapid double-tap pushes (400ms cooldown) |

**Important**: Never instantiate a new `Router` — always use `Router.shared`. Views access it via `@Environment(Router.self)`.

### Module Organization

```
PaceApp-ios/
├── PaceApp.swift              # @main entry
├── AppDelegate.swift          # Firebase + APNs setup
├── Router/                    # Navigation (Router, Destinations, RootFlow)
├── Model/                     # Domain models (UserModel, ActivityData, enums)
│   └── Enums/                 # All enums (GaitType, PaceTab, Gender, etc.)
├── Modules/                   # Feature screens
│   ├── Auth/                  # Splash, Welcome, Login, OTP, Authenticating
│   ├── CreateAccount/         # Multi-step account setup (StepViews, ViewModel)
│   └── Dashboard/             # Main app (TabBarScreen)
│       ├── Home/              # Events list, NewRun, EditEvent, Favorites
│       ├── History/           # Completed events
│       ├── Analytics/         # Charts & stats (has own Models, Repository)
│       ├── Profile/           # User profile, ManageWatch, UpdateGait
│       ├── Settings/          # App settings, legal pages
│       └── Notifications/     # Push notification UI
├── DesignSystem/              # Shared UI layer
│   ├── AppGradients.swift     # background, border, button gradients
│   ├── Components/            # AppButton, AppTextField, AppAlert, Toasts, etc.
│   ├── Font/                  # Gilroy font registration + AppFonts type scale
│   └── Styles/                # ButtonGlassStyle, PlainSelectedButtonStyle
├── Utility/
│   ├── Constant/              # AppConstant, Keys, Garmin config, Network URLs
│   ├── Extensions/            # View+Ext, Color+Ext, String+Ext, Date+Ext, etc.
│   ├── Helpers/               # Logger, Debouncer, ValidationProvider
│   ├── Manager/
│   │   ├── Auth/              # AuthManager (singleton, Firebase Auth)
│   │   ├── Firestore/         # Repository pattern (Interfaces → Repositories → Models → Mappers)
│   │   ├── App Session/       # AppSessionManager + AppSessionKey (UserDefaults)
│   │   └── ConnectIQManager   # Garmin watch communication
│   └── Modifier/              # SwiftUI view modifiers (Animations/)
└── Resources/
    ├── Assets.xcassets         # Images
    ├── Colors.xcassets         # Named colors
    ├── Fonts/                  # Gilroy .ttf files
    └── Localizable.xcstrings   # Localization
```

### Data Layer — Firestore Repository Pattern

```
Interfaces/           → Protocol definitions (EventRepositoryProtocol, etc.)
Repositories/         → Concrete Firestore implementations
Models/               → Firestore document structs (FirestoreEventDocument, etc.)
Mappers/              → Bidirectional mapping: domain ↔ Firestore documents
```

**Collections**: `users/{uid}`, `events/{eventId}` (+ `segments` subcollection), `favorites/{favoriteId}`. All rules enforce `request.auth.uid == userId` ownership.

---

## Key Conventions & Patterns

### Swift / SwiftUI Patterns

- **Observation framework** (`@Observable`, `@ObservationIgnored`) — NOT Combine's `ObservableObject`/`@Published`.
- **Singletons**: `Router.shared`, `AuthManager.shared`, `ConnectIQManager.shared`, `ToastManager.shared`, `UserProfileRepository.shared`.
- **`@MainActor`** on all singletons and UI-bound classes.
- **MARK comments**: Every file uses `// MARK: -` sections consistently. Preserve them.
- **File headers**: Standard Xcode `//  FileName.swift  //  PaceApp  //  Created by FURKAN VIJAPURA on ...` format.
- **Tab indentation**: The project uses **tabs**, not spaces.
- **Code comments policy**: Never remove inline comments, `// MARK:` sections, or block comments when editing. Always preserve author headers. Condense two lines comments to single line where meaning is fully preserved. Add inline comments where missing.

### Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Screens | `*Screen` suffix | `HomeScreen`, `SettingScreen`, `AnalyticsDetailScreen` |
| ViewModels | `*ViewModel` in `ViewModel/` subdirectory | `HomeViewModel`, `SettingsViewModel` |
| Enums | PascalCase, in `Model/Enums/` | `GaitType`, `PaceTab`, `LoginType` |
| Font tokens | `weight + size` | `.semiBold16`, `.bold24`, `.extraBold34` |
| Color assets | camelCase named colors | `.darkSeaBlue`, `.neonAquaBlue`, `.fluorescentMint` |
| Constants | `Constant.Config.*`, `Constant.UI.*` | `Constant.UI.defaultCornerRadius` |
| Storage keys | `Keys.*` static strings | `Keys.emailForSignIn` |
| Gradients | `AppGradients.*` | `AppGradients.background`, `AppGradients.button` |

### Design System Rules

- **Font family**: Gilroy exclusively (Light, Regular, Medium, SemiBold, Bold, ExtraBold). Use the `Font` extension tokens (e.g., `.semiBold16`), never raw `Font.system(...)`.
- **Background**: Always apply `.appBackground()` modifier — it renders `AppGradients.background` (darkSeaBlue → traditionalNavyBlue).
- **Buttons**: Use `AppButton` or `GlassButton` components. Primary gradient = `AppGradients.button`.
- **Text fields**: Use `AppTextField` component with built-in validation styling.
- **Toasts**: `ToastManager.shared.present(.error(...))` or `.success(...)`. Installed at app root via `.installToast(position: .top)`.
- **Alerts**: Custom `AppAlert` system, installed via `.installAppAlert()`.
- **Tint**: App-wide tint is `.radiantBlue`.
- **Segmented control**: Custom `AppSegmentedControl` with glass styling.
- **Corner radius**: `Constant.UI.defaultCornerRadius` (12pt) or `Constant.UI.cornerRadius16` (16pt).

### Authentication

- **Dual auth methods**: Phone OTP (via Firebase Phone Auth + APNs/reCAPTCHA) AND passwordless email link.
- **Auth flow**: `AuthManager.configure()` registers a global `addStateDidChangeListener`. On auth state change it fetches the Firestore profile, seeds a new user if needed, and calls `router.setupRootNavigation()`.
- **Deep link priority**: (1) Firebase reCAPTCHA → (2) Email sign-in link → (3) ConnectIQ.

### ConnectIQ / Garmin Integration

- `ConnectIQManager` handles all watch communication via the Garmin ConnectIQ SDK.
- Background mode: `bluetooth-central` in `UIBackgroundModes`.
- URL scheme: `connect://` registered for ConnectIQ callbacks.
- `gcm-ciq` in `LSApplicationQueriesSchemes`.
- On cold launch: `restoreSessionIfNeeded()` + `resyncPendingEvents()`.

### Tab Bar

4 tabs via `TabBarScreen`: **Home** → **History** → **Analytics (Stats)** → **Profile**. Each tab view is held as `@State` to prevent ViewModel re-creation on tab switch.

### ViewModel Ownership

All tab ViewModels (`HomeViewModel`, `HistoryViewModel`, `AnalyticsViewModel`) are lifted into `TabBarScreen` as `@State` and injected into tab screens. **Never construct ViewModels inline in `body` or inside tab views** — they will reinitialize on every tab switch or NavigationStack path change.

---

## Critical Rules

1. **Never use `ObservableObject`/`@Published`** — the project uses Swift's `@Observable` macro exclusively.
2. **Never create new Router instances** — always use `Router.shared` and `@Environment(Router.self)`.
3. **Always use tab indentation** — match the existing codebase style.
4. **Preserve all `// MARK: -` sections** and file header comments. Never remove inline comments or block comments.
5. **Firestore operations must go through the Repository layer** — never write raw Firestore calls in ViewModels or Views.
6. **New screens** must follow the `*Screen` naming convention and be added to both `Destinations` enum and `Router+Destination.swift`.
7. **New root flows** must be added to `RootFlow` enum in `Router+Roots.swift` and handled in `Router.rootView()`.
8. **Colors**: Use named color assets from `Colors.xcassets` — never hardcode hex values inline (except in `AppGradients` which documents the palette).
9. **Fonts**: Always use the `Font` extension tokens (`.semiBold16`, etc.) — never use `Font.custom("Gilroy-...", size:)` directly in views.
10. **Bundle ID**: `com.garmin.paceapp` (Garmin-namespaced for ConnectIQ integration).
11. **Keyboard dismissal**: Applied globally via `.dismissKeyboardOnTap()` at the NavigationStack level — don't add per-screen.
12. **Firestore cache**: 500 MB persistent cache configured in AppDelegate — don't reconfigure elsewhere.
13. **Never declare `@Bindable var viewModel` inside `body`** — always derive `Binding<T>` from a `@State` property to prevent @Observable re-registration feedback loops cascading up the view hierarchy.
14. **`navigationDestination` placement** — must never be placed inside lazy containers (`TabView`, `List`, `LazyVStack`, `ScrollView`). Must be above the `TabView` boundary.
15. **ActivityData stable IDs** — never use `let id = UUID()` on model types in lists. It causes SwiftUI to destroy and rebuild every row on every Firestore snapshot. IDs must be stable and deterministic (e.g., Firestore document ID or sync ID).
16. **Timer and `@Observable`** — `Timer.scheduledTimer` fires off MainActor (background thread). Mutations to `@Observable` state must be dispatched to `@MainActor` explicitly.
17. **Firestore user settings** — use flat fields + nested map on the user document, not subcollections. Avoids doubling Firestore read costs on launch.
18. **`continueURL` for Firebase email link** — must be path-qualified (e.g., `https://<projectId>.firebaseapp.com/emailSignIn`), not a bare domain root. `linkDomain` must not be set for `.firebaseapp.com` domains.

---

## Firebase Configuration

| Service | Details |
|---|---|
| **Project** | `thepaceapp` (Firebase) |
| **Auth methods** | Phone (OTP + APNs/reCAPTCHA), Email link (passwordless) |
| **Firestore collections** | `users`, `events`, `events/{id}/segments`, `favorites` |
| **Security rules** | Owner-only read/write via `request.auth.uid` checks |
| **Hosting** | `firebase-hosting/` directory for web assets |
| **APNs** | Required for silent push phone verification |
| **Reversed client ID** | `app-1-652638681487-ios-0bf0155356db81a4d6f3fa` (URL scheme for reCAPTCHA) |

---

## Dependencies (Swift Packages)

- **Firebase** (FirebaseAuth, FirebaseFirestore, FirebaseCore)
- **ConnectIQ** (Garmin Connect IQ iOS SDK)
- **FITSwiftSDK** (Garmin FIT file parsing — pre-existing unresolved build error, not introduced by recent work)
- **swift-log** (`Logging` module — `import Logging`)

---

## Common Pitfalls

- **TabBarScreen ViewModel loop**: Tab screens are held as `@State` properties to prevent re-creation. Don't construct them inline in the `TabView` body. ViewModels must be owned at `TabBarScreen` scope as `@State` and injected — never constructed inline.
- **`@Bindable` feedback loop**: In `SettingScreen`, using `@Bindable var viewModel` inside `body` caused @Observable re-registration feedback loops. Fixed by replacing with stable `Binding<T>` computed properties derived from `@State`.
- **Double navigation**: `Router.navigate(to:)` has a 400ms debounce guard — don't bypass it.
- **reCAPTCHA delegate lifetime**: `PhoneAuthUIDelegate` must be held strongly on `AuthManager` during the `verifyPhoneNumber` call — don't let it get deallocated.
- **Email link different device**: If `Keys.emailForSignIn` is empty when an email link arrives, the user opened on a different device — show error and redirect to `.auth`.
- **ActivityData UUID identity**: Using `let id = UUID()` causes SwiftUI to destroy and rebuild every list row on every Firestore snapshot. Always use stable, deterministic IDs.
- **Timer threading**: `Timer.scheduledTimer` fires off `@MainActor`. Wrap `@Observable` mutations in `Task { @MainActor in ... }` or `DispatchQueue.main.async`.

---

## Workflow Conventions

### Pre-Edit Workflow

1. **Read all relevant files** before making changes.
2. **Fix root causes** rather than symptoms.
3. **Prefer complete file rewrites** over incremental partial fixes when conflicting or redundant code is the source of confusion.

### Build Verification

After each batch of file writes: `BuildProject` → `GetBuildLog` with `severity: error` is the standard verification cycle.

### Git Commits

Conventional commits style:
```
feat(scope): impactful non-technical summary

- detail line 1
- detail line 2
```
High-level non-technical descriptions preferred over implementation-detail-heavy messages.

---

## In-Progress & On the Horizon

### Model Consolidation (In Progress)

Targeted for unification into shared models usable across both Firestore and app layers:

| Firestore Document | App Model | Status |
|---|---|---|
| `EventSegmentDocument` | `RunSegment` | Pending |
| `FirestoreEventDocument` | `ActivityData` | Pending |
| `FirestoreUserDocument` | `UserModel` | Pending |

> **⚠️ Critical**: During consolidation, these computed/derived fields must be preserved — they are at risk of being silently dropped:
> - `formattedGoalTime`
> - `totalGoalSeconds`
> - `isProfileCompleted`
> - `contactInfo`

### Analytics & History Firestore Wiring

Analytics and History tabs were previously using hardcoded dummy data. Full MVVM Firestore wiring with `AnalyticsRepository`, period bucketing, and composite index on `userId + syncType + date` was planned — **status should be verified** before assuming it's complete.

### Firestore Security Rules

Security rules have been written and are functional. Ongoing refinement may be needed as new collections/subcollections are added.

### User Settings Migration

User settings (gait data, interval toggles, preferred distance unit) have been migrated from `UserDefaults` to Firestore — stored as a nested `gait` map plus flat scalar fields on the user document.
