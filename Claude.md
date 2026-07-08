# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# PaceApp iOS — Project Intelligence

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
- The event model is **`EventDocument`** (`Model/EventDocument.swift`), stored as a single doc at `events/{id}`. **Segments are an embedded `[RunSegment]` array on the document — there is no `events/{id}/segments` subcollection.** Route GPS is one encoded `routePolyline` string (`PolylineCodec`).
- Key fields: `status` (`active`/`completed`/`deleted` → `EventStatus`), `syncStatus` (`pending`/`synced`), `source` (`phone`/`watch`), `activityType`, `createdAt`.
- Repository: **`FirestoreEventRepository.shared`** (protocol namespace: `EventRepository.shared`). The single parse path for raw ConnectIQ `[String: Any]` payloads is **`EventDocumentMapper`** — never parse event dicts anywhere else.
- **Immutable on sync**: `id` (doc key), `source`, and `createdAt` are set once at creation and must never be rewritten by a later app⇄watch sync. `FirestoreEventRepository.upsert` reloads the existing doc and preserves them. App-created payloads tag `source: "phone"`; a source-less payload arriving through the sync layer is treated as `"watch"`.
- **Active events ignore date**: `observeActiveEvents` has NO `scheduledAt >= today` filter, so a past-due but still-active event stays visible on Home instead of being orphaned.

### ConnectIQ ⇄ app settings sync
- Two-way: watch→Firestore via `applyRemoteSettings`; app→watch via `sendSettings()` / `getSettingsPayload()` (message `sync_settings`). Call `sendSettings()` after any app-side settings mutation.
- **Gait unit/value boundary**: the watch speaks `ft`/`m` and sends step length as a String (`"2.5"`); the app stores full words `Feet`/`Meters` and a `Double`. Convert only at the boundary — `settingDouble` (lenient number), `appGaitUnit` (in), `watchGaitUnit` (out). Internal gait unit is always `"Feet"`/`"Meters"` (matches `AppSegmentedControl` keys).
- `AuthManager` runs a **live Firestore profile listener** (`startProfileListener`) that keeps `userDetails` current, so watch→Firestore changes appear without relaunch. Screens re-sync their VM on `AuthManager.shared.userDetails` change (see `ProfileScreen`).

### ActivityType carried end-to-end
- `ActivityType` (`run`/`walking`/`cycling`/`other`) exposes `.title` (header text) and `.icon` (asset). `EventDocument.eventType` is a typed accessor over the stored `activityType` string; `ActivityData.eventType` carries it to the UI (set by `EventDocumentMapper`). Drives the EventDetails title and the Home/History activity-row icons.

### Home is a single native `List`
- Home is one `List` — a self-sizing header row + upcoming events as rows with native `.swipeActions`. This replaced a `ScrollView` + custom gesture row. History uses the same `List` + `.swipeActions` pattern (the reference for smooth scroll + swipe).
- **Never put a `GeometryReader` inside a `List`/collection cell** — the unstable self-sizing height crashes with `UICollectionView … recursive layout loop`. Size deterministically (e.g. from `UIScreen.main.bounds.width`).
- **Buttons inside a `List` row need `.buttonStyle(.borderless)` / `.plain`**, otherwise the row swallows the tap (this is why `runActionGrid` and the metric capsules set an explicit button style).

### EventDetails map
- Show the route map only when `hasRouteData` == **≥ 2 valid, non-`(0,0)` coordinates**. `routeCoordinates` filters invalid/placeholder points the watch/Firebase send; a single point can't draw a polyline.

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
firebase deploy --only hosting                              # email sign-in landing page
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

**`onOpenURL` handler priority chain**: (1) Firebase reCAPTCHA → (2) Email sign-in link → (3) ConnectIQ `connect://` scheme.

### Navigation — Router Pattern

The app uses a **singleton `Router`** (`@Observable`, `@MainActor`) injected via SwiftUI's `@Environment`:

| Concept | Detail |
|---|---|
| **Push navigation** | `NavigationStack(path: $router.path)` with `Destinations` enum |
| **Root switching** | `router.setRoot(_:)` swaps the entire root flow with a `CATransition` on the key window |
| **Root flows** | `RootFlow` enum: `.splash`, `.welcome`, `.auth`, `.authenticating`, `.accountCreation`, `.dashboard` |
| **Duplicate protection** | `isNavigating` flag prevents rapid double-tap pushes (400ms cooldown) |
| **Back navigation** | `router.pop()` or `router.popToRoot()` |

> **Important**: Never instantiate a new `Router` — always use `Router.shared`. Views access it via `@Environment(Router.self)`.

**Destinations Enum** (all push-navigable screens):
```swift
enum Destinations: Hashable {
    case verify(AuthViewModel)
    case newRun
    case editEvent(ActivityData)
    case favorites
    case eventDetail(ActivityData)
    case analyticsDetail(AnalyticsSummary)
    case editProfile
    case updateGait
    case manageWatch
    case settings
    case terms
    case privacy
    case about
    case notifications
}
```
Each destination maps to its screen in `Router+Destination.swift` via `@ViewBuilder func destinationView(for:)`.

### Singleton Graph

All singletons are `@Observable @MainActor`:

| Singleton | Purpose |
|---|---|
| `Router.shared` | Navigation state |
| `AuthManager.shared` | Firebase Auth + profile fetch |
| `UserProfileRepository.shared` | Firestore `users` CRUD |
| `EventRepository.shared` | Firestore `events` CRUD + real-time listeners |
| `FavoriteRepository.shared` | Firestore `favorites` CRUD |
| `ConnectIQManager.shared` | Garmin watch communication |
| `ToastManager.shared` | Global toast notifications |
| `AppSessionManager.shared` | UserDefaults wrapper |

---

## Module Organization

```
PaceApp-ios/
├── PaceApp.swift                 # @main entry
├── AppDelegate.swift             # Firebase + APNs + font registration
├── Router/                       # Navigation (Router, Destinations, RootFlow)
│   ├── Router.swift              # Singleton, NavigationStack path, root switching
│   ├── Destinations.swift        # Push destinations enum
│   ├── Router+Destination.swift  # Destination → Screen mapping
│   └── Router+Roots.swift        # RootFlow enum + rootView()
├── Model/                        # Domain models
│   ├── UserModel.swift           # User profile (computed: fullName, isProfileCompleted, contactInfo)
│   ├── ActivityData.swift        # Event/run (computed: formattedGoalTime, totalGoalSeconds)
│   ├── RunSegment.swift          # Segment with HR/pace/cadence arrays
│   ├── RunInterval.swift         # Walk/run interval config
│   ├── GaitUserData.swift        # Gait metrics (pace + cadence per gait type)
│   ├── EventDocument.swift       # Event document helpers
│   ├── HomeMetric.swift          # Dashboard metric display
│   ├── NotificationItem.swift    # Push notification model
│   ├── ProfileMenuItem.swift     # Profile menu item model
│   ├── SettingsMenuItem.swift    # Settings menu item model
│   ├── WatchDevice.swift         # Garmin device model
│   └── Enums/                    # All enums (see Enums section)
├── Modules/                      # Feature screens
│   ├── Auth/                     # Authentication flow
│   ├── CreateAccount/            # Multi-step onboarding wizard
│   └── Dashboard/                # Main app (TabBarScreen + tabs)
│       ├── Home/                 # Events list, NewRun, EditEvent, Favorites
│       ├── History/              # Completed events, EventDetail
│       ├── Analytics/            # Charts, trends, stats (own Models + Repository)
│       ├── Profile/              # User profile, ManageWatch, UpdateGait, EditProfile
│       ├── Settings/             # App settings, Terms, Privacy, About
│       └── Notifications/        # Push notification UI
├── DesignSystem/                 # Shared UI layer
│   ├── AppGradients.swift        # Background, border, button gradients
│   ├── Components/               # AppButton, AppTextField, AppAlert, Toasts, etc.
│   ├── Font/                     # Gilroy font registration + AppFonts type scale
│   └── Styles/                   # ButtonGlassStyle, PlainSelectedButtonStyle
├── Utility/
│   ├── Constant/                 # AppConstant, Keys, GarminConfig, NetworkURLs
│   ├── Extensions/               # View, Color, String, Date, Double, Font, Binding, Collection
│   ├── Helpers/                  # Logger, Debouncer, ValidationProvider
│   ├── Manager/
│   │   ├── Auth/                 # AuthManager + PhoneAuthUIDelegate
│   │   ├── Firestore/            # Full repository pattern (see Data Layer)
│   │   ├── App Session/          # AppSessionManager + AppSessionKey (UserDefaults)
│   │   └── ConnectIQ/            # ConnectIQManager (Garmin watch SDK)
│   └── Modifier/                 # Animations (Shake, SlideTransition, Pulse)
├── Resources/
│   ├── Assets.xcassets           # Images
│   ├── Colors.xcassets           # Named colors
│   ├── Fonts/                    # Gilroy .ttf files
│   └── Localizable.xcstrings    # Localization
├── firebase-hosting/             # Email sign-in landing page
│   └── public/
│       ├── index.html            # Deep link redirect back to app
│       └── 404.html
├── firestore.rules               # Security rules (owner-only access)
├── firestore.indexes.json        # Composite indexes
├── firebase.json                 # Firebase config
└── GoogleService-Info.plist      # Firebase credentials
```

---

## Data Layer — Firestore Repository Pattern

### Architecture

```
View → ViewModel → Repository (Protocol) → Repository (Singleton) → Mapper → Firestore Document Model → Firestore
```

### Repository Structure

```
Utility/Manager/Firestore/
├── Interfaces/                        # Protocol definitions
│   ├── EventRepositoryProtocol.swift
│   ├── UserProfileRepositoryProtocol.swift
│   └── FavoriteRepositoryProtocol.swift
├── Repositories/                      # Concrete implementations (singletons)
│   ├── EventRepository.swift
│   ├── UserProfileRepository.swift
│   └── FavoriteRepository.swift
├── Models/                            # Firestore document structs (Codable)
│   ├── FirestoreEventDocument.swift
│   ├── FirestoreUserDocument.swift
│   ├── EventSegmentDocument.swift
│   └── FirestoreFavoriteDocument.swift
├── Mappers/                           # Bidirectional domain ↔ Firestore conversion
│   ├── EventMapper.swift
│   ├── UserProfileMapper.swift
│   ├── SegmentMapper.swift
│   └── FavoriteMapper.swift
└── FirestoreCollections.swift         # Collection path constants
```

### Collection Paths

| Collection | Path | Purpose |
|---|---|---|
| `users` | `users/{uid}` | User profiles + gait data (nested `gait` map) + settings (flat fields) |
| `events` | `events/{eventId}` | Run/walk events; **segments are embedded on the doc**, plus `routePolyline`, `status`, `syncStatus`, `source` (see Recent Architecture Notes) |
| ~~`segments`~~ | ~~`events/{eventId}/segments`~~ | **Deprecated** — segments now live as an embedded `[RunSegment]` array on the event document (single-doc write) |
| `favorites` | `favorites/{favoriteId}` | User favorited events |

### Repository Interfaces

**EventRepositoryProtocol:**
```swift
protocol EventRepositoryProtocol {
    func createEvent(_ event: ActivityData) async throws
    func updateEvent(_ event: ActivityData) async throws
    func deleteEvent(_ eventId: String) async throws
    func fetchEvents(for userId: String) async throws -> [ActivityData]
    func listenToEvents(for userId: String, onChange: @escaping ([ActivityData]) -> Void) -> ListenerRegistration
    func fetchEventSegments(eventId: String) async throws -> [RunSegment]
    func saveEventSegments(eventId: String, segments: [RunSegment]) async throws
}
```

**UserProfileRepositoryProtocol:**
```swift
protocol UserProfileRepositoryProtocol {
    func createUserProfile(user: UserModel) async throws
    func fetchUserProfile(userId: String) async throws -> UserModel?
    func updateUserProfile(_ user: UserModel) async throws
    func deleteUserProfile(userId: String) async throws
    func listenToUserProfile(userId: String, onChange: @escaping (UserModel?) -> Void) -> ListenerRegistration
}
```

**FavoriteRepositoryProtocol:**
```swift
protocol FavoriteRepositoryProtocol {
    func toggleFavorite(eventId: String, userId: String) async throws
    func fetchFavorites(userId: String) async throws -> [ActivityData]
    func listenToFavorites(userId: String, onChange: @escaping ([ActivityData]) -> Void) -> ListenerRegistration
}
```

### Mapper Pattern

Each mapper has static `toDocument(_:)` and `toDomain(_:)` methods:
- **EventMapper**: Maps `ActivityData ↔ FirestoreEventDocument`, handles optional `intervals` array
- **UserProfileMapper**: Maps `UserModel ↔ FirestoreUserDocument`, handles nested `gait` map + optional fields
- **SegmentMapper**: Maps `RunSegment ↔ EventSegmentDocument`, handles HR/pace/cadence/distance arrays
- **FavoriteMapper**: Maps favorites with event data

> **Type conversions handled**: `Date ↔ Timestamp`, `enum ↔ String`, `Optional` fields, nested maps.

### Firestore Document Models

**FirestoreEventDocument:**
```swift
struct FirestoreEventDocument: Codable {
    var eventId: String
    var userId: String
    var eventName: String
    var date: Timestamp
    var distance: Double
    var distanceUnit: String
    var goalHours: Int
    var goalMinutes: Int
    var goalSeconds: Int
    var syncType: String          // "scheduled", "inProgress", "completed", "synced"
    var intervals: [FirestoreIntervalDocument]?
    var createdAt: Timestamp
    var updatedAt: Timestamp
}
```

**FirestoreUserDocument:**
```swift
struct FirestoreUserDocument: Codable {
    var userId: String
    var firstName: String
    var lastName: String
    var email: String?
    var phone: String?
    var gender: String
    var dateOfBirth: Timestamp?
    var weight: Double
    var weightUnit: String
    var heightFeet: Int?
    var heightInches: Int?
    var heightCM: Double?
    var heightUnit: String
    var gait: FirestoreGaitDocument?
    var distanceUnit: String
    var profileCompleted: Bool
    var createdAt: Timestamp
    var updatedAt: Timestamp
}
```

### Firestore Security Rules

```
users/{userId}      → read/write: auth.uid == userId
events/{eventId}    → read/write: auth.uid == resource.data.userId
                       create: auth.uid == request.resource.data.userId
  segments/{segId}  → read/write: authenticated
favorites/{favId}   → read/write: auth.uid == resource.data.userId
                       create: auth.uid == request.resource.data.userId
```

### Composite Indexes

| Collection | Fields | Purpose |
|---|---|---|
| `events` | `userId` ASC + `date` DESC | User's events by date |
| `events` | `userId` ASC + `syncType` ASC + `date` DESC | Filtered events (e.g., completed only) |
| `favorites` | `userId` ASC + `createdAt` DESC | User's favorites by recency |

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
3. On auth state change: fetches Firestore user profile (creates if new user)
4. Calls `router.setupRootNavigation()` to set appropriate root flow
5. `autoLogin()` — checks `Auth.auth().currentUser`, restores session

### Auth Flow Screens

```
SplashScreen → (autoLogin) → Dashboard OR Welcome
WelcomeScreen → AuthScreen (Phone/Email tabs)
AuthScreen → VerifyScreen (Phone OTP) OR "check email" toast (Email)
VerifyScreen → AuthenticatingScreen → Dashboard OR CreateAccount
```

### Key Auth Rules

- **PhoneAuthUIDelegate** must be held strongly on `AuthManager` during `verifyPhoneNumber` — don't let it deallocate
- **Email link different device**: If `Keys.emailForSignIn` is empty when link arrives, show error and redirect to `.auth`
- **`continueURL`**: Must be path-qualified (`https://thepaceapp.firebaseapp.com/emailSignIn`), not bare domain root
- **`linkDomain`**: Must not be set for `.firebaseapp.com` domains

---

## Dynamic Forms System

### Overview

The app uses two form patterns:
1. **Multi-step wizard** (CreateAccount) — indexed steps with per-step validation
2. **Single-page forms** (NewRun, EditEvent, EditProfile, UpdateGait) — standard form with centralized validation

### Form Component Stack

| Component | Purpose | Location |
|---|---|---|
| `AppTextField` | Text input with floating label, error state, validation styling | `DesignSystem/Components/` |
| `AppSegmentedControl` | Generic enum-based toggle/selection with glass styling | `DesignSystem/Components/` |
| `AppButton` | Primary CTA with gradient, loading, disabled states | `DesignSystem/Components/` |
| `GlassButton` | Secondary CTA with translucent glass effect | `DesignSystem/Components/` |
| `OTPTextField` | 6-digit OTP with individual character boxes, auto-advance | `DesignSystem/Components/` |
| `ProgressStepIndicator` | Multi-step progress bar with step markers | `DesignSystem/Components/` |
| `DatePicker` | Native wheel picker for date selection | SwiftUI native |
| `GaitInputCard` | Specialized card for gait metrics input | `Profile/Components/` |

### Validation Stack

```
ValidationProvider (static utility)  →  ViewModel.isValid (computed)  →  AppTextField.errorMessage (UI)
                                                                     →  ShakeModifier (animation)
                                                                     →  ToastManager (global errors)
```

**ValidationProvider methods:**
| Method | Purpose |
|---|---|
| `isValidEmail(_:)` | Regex email validation |
| `isValidPhone(_:)` | US phone format |
| `isNotEmpty(_:)` | Trimmed non-empty |
| `isValidNumber(_:)` | Numeric string |
| `isValidDecimal(_:)` | Decimal number |
| `isInRange(_:min:max:)` | Numeric range check |
| `isValidName(_:)` | Alphabetic, min 2 chars |
| `isValidWeight(_:unit:)` | Unit-aware (lbs: 50-500, kg: 20-230) |
| `isValidHeight(feet:inches:)` | Feet/inches range |
| `isValidHeightCM(_:)` | CM range (50-250) |
| `isValidPace(_:)` | MM:SS format |
| `isValidCadence(_:)` | 50-250 spm |
| `isValidGoalTime(hours:minutes:seconds:)` | At least one non-zero |

### Multi-Step Wizard — CreateAccount

**Files:**
```
CreateAccount/
├── Screen/CreateAccountScreen.swift      # Step container + progress indicator + nav buttons
├── ViewModel/CreateAccountViewModel.swift # All form state + validation + save
└── StepView/                             # Individual step views
    ├── FullNameStepView.swift             # Step 0: firstName, lastName
    ├── GenderStepView.swift              # Step 1: Gender enum selection
    ├── DOBStepView.swift                 # Step 2: Date wheel picker
    ├── WeightStepView.swift              # Step 3: weight + unit toggle (lbs/kg)
    ├── HeightStepView.swift              # Step 4: ft+in OR cm (dynamic based on unit)
    ├── GaitStepView.swift                # Step 5: 3×2 grid (walk/jog/run × pace/cadence)
    └── PaceGoalStepView.swift            # Step 6: goal time (H:M:S) + distance + unit
```

**Pattern:**
- `CreateAccountViewModel` holds all form fields as `@Observable` properties
- `currentStep: Int` (0-6) tracks progress, `totalSteps: 7`
- `isCurrentStepValid: Bool` — computed per-step validation using `ValidationProvider`
- `next()` / `previous()` for step navigation (linear, no skipping)
- `createAccount()` — assembles `UserModel`, saves via `UserProfileRepository.shared.createUserProfile(user:)`, navigates to `.dashboard`
- Unit toggles dynamically change form layout (height: ft/in ↔ cm)
- Each `StepView` takes `@Bindable var viewModel` for two-way binding

**ViewModel Fields:**
```swift
// Step 0 — Name
firstName: String, lastName: String

// Step 1 — Gender
selectedGender: Gender?

// Step 2 — DOB
dateOfBirth: Date?

// Step 3 — Weight
weight: String, weightUnit: WeightUnit (.lbs/.kg)

// Step 4 — Height
heightFeet: String, heightInches: String, heightUnit: HeightUnit (.feetInches/.cm), heightCM: String

// Step 5 — Gait
walkPace: String, jogPace: String, runPace: String
walkCadence: String, jogCadence: String, runCadence: String

// Step 6 — Goal
goalHours: String, goalMinutes: String, goalSeconds: String
goalDistance: String, distanceUnit: DistanceUnit (.miles/.km)
```

### Single-Page Forms

**NewRun / EditEvent:**
- Fields: event name, date, time, distance, goal pace, interval settings
- `IntervalSettingsView` for configuring walk/run intervals
- NewRun: saves via `EventRepository.shared.createEvent(_:)`
- EditEvent: pre-populates from existing `ActivityData`, updates via `EventRepository.shared.updateEvent(_:)`

**EditProfile:**
- Same fields as CreateAccount but pre-populated from current `UserModel`
- Updates via `UserProfileRepository.shared.updateUserProfile(_:)`

**UpdateGait:**
- Walk/jog/run pace + cadence grid using `GaitInputCard` components
- Saves gait data to Firestore user document's nested `gait` map

### Form Best Practices (Follow These)

1. **ViewModel owns all form state** — never use `@State` for form fields in views
2. **Validation is centralized** in the ViewModel via computed properties
3. **Use `AppTextField`** for all text inputs — never raw `TextField`
4. **Use `AppSegmentedControl`** for enum-based selections
5. **Use `@Bindable var viewModel`** in step/sub views for binding, but **never declare `@Bindable` inside `body`**
6. **Keyboard types** must be set per field (`.numberPad`, `.decimalPad`, `.default`)
7. **Unit toggles** should dynamically change layout when applicable
8. **Save operations** always go through repository layer, never raw Firestore calls
9. **Error display**: Use `AppTextField.errorMessage` for inline errors, `ToastManager` for global errors
10. **Loading state**: Use `AppButton.isLoading` during async save operations

---

## Design System

### Color Palette (from `Colors.xcassets`)

| Token | Usage |
|---|---|
| `.darkSeaBlue` | Primary background dark |
| `.traditionalNavyBlue` | Background gradient end |
| `.neonAquaBlue` | Accent / highlight |
| `.fluorescentMint` | Secondary accent |
| `.radiantBlue` | App tint, active states |
| `.slateGrey` | Muted text, dividers |
| `.pureWhite` | Primary text |
| `.softWhite` | Secondary text |

### Gradients (`AppGradients`)

| Gradient | Purpose |
|---|---|
| `AppGradients.background` | Full-screen background (darkSeaBlue → traditionalNavyBlue) |
| `AppGradients.button` | Primary CTA buttons |
| `AppGradients.border` | Glass card/button borders |

### Typography — Gilroy Font System

Registered via `FontRegistration.registerFonts()` in AppDelegate.

**Font Tokens** (via `Font` extension):
```
.light12 … .light20
.regular12 … .regular20
.medium12 … .medium20
.semiBold12 … .semiBold24
.bold14 … .bold34
.extraBold24 … .extraBold48
```

> **Never** use `Font.system(...)` or `Font.custom("Gilroy-...", size:)` directly. Always use tokens.

### UI Constants (`Constant`)

| Constant | Value |
|---|---|
| `Constant.UI.defaultCornerRadius` | 12pt |
| `Constant.UI.cornerRadius16` | 16pt |
| `Constant.UI.buttonHeight` | 52pt |
| `Constant.UI.textFieldHeight` | 48pt |
| `Constant.UI.cardPadding` | 16pt |
| `Constant.UI.screenHorizontalPadding` | 20pt |
| `Constant.Animation.defaultDuration` | 0.3s |
| `Constant.Animation.springDamping` | 0.8 |
| `Constant.Animation.toastDuration` | 3.0s |

### Components API Reference

**AppButton:**
```swift
AppButton(title: "Continue", isLoading: vm.isLoading, isEnabled: vm.isValid) {
    vm.submit()
}
```

**AppTextField:**
```swift
AppTextField(
    title: "First Name",           // Floating label
    text: $vm.firstName,
    placeholder: "Enter first name",
    keyboardType: .default,
    errorMessage: vm.firstNameError // nil = no error, String = error shown
)
```

**AppSegmentedControl:**
```swift
AppSegmentedControl(
    selection: $vm.selectedGender,
    options: Gender.allCases
)
```

**ToastManager:**
```swift
ToastManager.shared.present(.error("Something went wrong"))
ToastManager.shared.present(.success("Profile updated"))
ToastManager.shared.present(.info("Check your email"))
```

**AppAlert:**
```swift
AppAlert(
    title: "Delete Account",
    message: "This action cannot be undone.",
    primaryButton: AlertButton(title: "Delete", role: .destructive) { vm.deleteAccount() },
    secondaryButton: AlertButton(title: "Cancel", role: .cancel) { }
)
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

### Animation Modifiers

| Modifier | Purpose |
|---|---|
| `ShakeModifier` | Horizontal shake on validation error (bound to `Bool`) |
| `SlideTransitionModifier` | Slide transition for screen changes (configurable direction) |
| `PulseModifier` | Repeating pulse/glow for active indicators |

### Button Styles

| Style | Purpose |
|---|---|
| `ButtonGlassStyle` | Glass effect with blur + gradient border |
| `PlainSelectedButtonStyle` | Selected/unselected states for tabs/filters |

---

## Enums Reference

Enums live in `Model/Enums/` (conformances vary — check the file; not all are `Codable`/`CustomStringConvertible`):

| Enum | Cases | Usage |
|---|---|---|
| `GaitType` | `.walking` (`"Walking"`), `.running` (`"Running"`) | Gait mode; `.label` = "Walk"/"Run", `.title` = "Walking"/"Running" |
| `ActivityType` | `.run`, `.walking`, `.cycling`, `.other` | Event activity; `.title` (header), `.icon` (asset), `.watchString` (wire) |
| `EventStatus` | `.active`, `.completed`, `.deleted` | Event lifecycle (the `status` field on `EventDocument`) |
| `PaceTab` | `.home`, `.history`, `.analytics`, `.profile` | Tab bar tabs |
| `Gender` | `.male`, `.female`, `.other`, `.preferNotToSay` | User profile |
| `LoginType` | `.phoneNumber`, `.email` | Auth method toggle |
| `WeightUnit` | `.lbs`, `.kg` | Weight display/input |
| `HeightUnit` | `.feetInches`, `.cm` | Height display/input |
| `DistanceUnit` / `MeasureUnit` | miles/km | Distance display/input |
| `RootFlow` | `.splash`, `.welcome`, `.auth`, `.authenticating`, `.accountCreation`, `.dashboard` | Root navigation states |

> Gait step-length unit is stored as the full word `"Feet"`/`"Meters"` (not `ft`/`m` — that's only the watch wire format; see Recent Architecture Notes).

---

## Tab Bar & ViewModel Ownership

### TabBarScreen Structure

4 tabs: **Home** → **History** → **Analytics (Stats)** → **Profile**

```swift
// Tab ViewModels lifted to TabBarScreen as @State to prevent re-creation
@State private var homeVM = HomeViewModel()
@State private var historyVM = HistoryViewModel()
@State private var analyticsVM = AnalyticsViewModel()
```

Each tab view is held as `@State` to maintain identity across tab switches.

> **Never construct ViewModels inline in `body` or inside tab views** — they will reinitialize on every tab switch or NavigationStack path change.

### Module → ViewModel → Repository Flow

| Module | ViewModel | Repository | Operations |
|---|---|---|---|
| Home | `HomeViewModel` | `EventRepository.shared` | Fetch events, real-time listener, delete, toggle favorite |
| Home/NewRun | `NewRunViewModel` | `EventRepository.shared` | Create event with validation |
| Home/EditEvent | `EditEventViewModel` | `EventRepository.shared` | Update event (pre-populated) |
| Home/Favorites | `FavoritesViewModel` | `FavoriteRepository.shared` | Fetch/toggle favorites |
| History | `HistoryViewModel` | `EventRepository.shared` | Fetch completed events, group by date |
| History/Detail | `EventDetailsViewModel` | `FirestoreEventRepository.shared` / `FirestoreFavoritesRepository.shared` | Show event + embedded segments; toggle favorite; map gated on `hasRouteData` |
| Analytics | `AnalyticsViewModel` | `AnalyticsRepository` | Aggregate data by period (week/month/year/all) |
| Analytics/Detail | `AnalyticsDetailViewModel` | `AnalyticsRepository` | Detailed trends and charts |
| Profile | `ProfileViewModel` | `UserProfileRepository.shared` | Fetch user profile |
| Profile/Edit | `EditProfileViewModel` | `UserProfileRepository.shared` | Update profile (pre-populated form) |
| Profile/Gait | `UpdateGaitViewModel` | `UserProfileRepository.shared` | Update gait data |
| Profile/Watch | `ManageWatchViewModel` | `ConnectIQManager.shared` | Pair/unpair Garmin devices |
| Settings | `SettingsViewModel` | `AuthManager.shared`, `UserProfileRepository.shared` | Logout, delete account, toggle settings |
| Notifications | `NotificationViewModel` | — | Push notification display |

---

## ConnectIQ / Garmin Integration

- `ConnectIQManager.shared` — handles all watch communication via Garmin ConnectIQ SDK
- **Background mode**: `bluetooth-central` in `UIBackgroundModes`
- **URL scheme**: `connect://` registered for ConnectIQ callbacks
- **Queries scheme**: `gcm-ciq` in `LSApplicationQueriesSchemes`
- **Cold launch**: `restoreSessionIfNeeded()` + `resyncPendingEvents()`
- **Key operations**: `initialize()`, `pairDevice()`, `unpairDevice()`, `sendMessage(_:)`, `handleOpenURL(_:)`

---

## Extensions Reference

| File | Key Extensions |
|---|---|
| `View+Ext.swift` | `.appBackground()`, `.dismissKeyboardOnTap()`, `.installToast()`, `.installAppAlert()`, `.cardStyle()`, `.shimmer()`, `.onFirstAppear(_:)` |
| `Color+Ext.swift` | Named color accessors (`.darkSeaBlue`, `.neonAquaBlue`, `.radiantBlue`, etc.) |
| `String+Ext.swift` | `.trimmed`, `.isBlank`, `.toPhoneFormat()`, `.formattedPace()` |
| `Date+Ext.swift` | `.formatted(as:)`, `.timeAgo()`, `.startOfDay`, `.endOfDay`, `.isToday`, `.isThisWeek` |
| `Double+Ext.swift` | `.formattedDistance(unit:)`, `.formattedPace()`, `.formattedDuration()`, `.roundedTo(_:)` |
| `Font+Ext.swift` | All Gilroy font tokens (`.light12` through `.extraBold48`) |
| `Binding+Ext.swift` | Binding transform helpers |
| `Collection+Ext.swift` | Safe subscript and grouping helpers |

---

## Session Management

**AppSessionManager** (`UserDefaults` wrapper):
- `hasCompletedOnboarding: Bool`
- `lastSyncDate: Date?`
- `selectedTabIndex: Int`

**Keys** (static string constants):
- `Keys.emailForSignIn` — stored email for email link auth completion
- `Keys.verificationID` — phone auth verification ID
- `Keys.hasCompletedOnboarding` — onboarding completion flag
- `Keys.lastSyncDate` — last Garmin sync timestamp

> **User settings** (gait, units, preferences) are stored on the **Firestore user document**, NOT in UserDefaults.

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
| ViewModels | `*ViewModel` in `ViewModel/` subdirectory | `HomeViewModel`, `SettingsViewModel` |
| Enums | PascalCase, in `Model/Enums/` | `GaitType`, `PaceTab` |
| Font tokens | `weight + size` | `.semiBold16`, `.bold24` |
| Color assets | camelCase named colors | `.darkSeaBlue`, `.neonAquaBlue` |
| Constants | `Constant.Config.*`, `Constant.UI.*` | `Constant.UI.defaultCornerRadius` |
| Storage keys | `Keys.*` static strings | `Keys.emailForSignIn` |
| Gradients | `AppGradients.*` | `AppGradients.background` |
| Repositories | `*Repository` singleton | `EventRepository.shared` |
| Protocols | `*Protocol` suffix | `EventRepositoryProtocol` |
| Firestore docs | `Firestore*Document` | `FirestoreEventDocument` |
| Mappers | `*Mapper` with static methods | `EventMapper.toDocument(_:)` |

---

## Critical Rules

1. **Never use `ObservableObject`/`@Published`** — the project uses Swift's `@Observable` macro exclusively.
2. **Never create new Router instances** — always use `Router.shared` and `@Environment(Router.self)`.
3. **Always use tab indentation** — match the existing codebase style.
4. **Preserve all `// MARK: -` sections** and file header comments. Never remove inline comments or block comments.
5. **Firestore operations must go through the Repository layer** — never write raw Firestore calls in ViewModels or Views.
6. **New screens** must follow the `*Screen` naming convention and be added to both `Destinations` enum and `Router+Destination.swift`.
7. **New root flows** must be added to `RootFlow` enum in `Router+Roots.swift` and handled in `Router.rootView()`.
8. **Colors**: Use named color assets from `Colors.xcassets` — never hardcode hex values inline.
9. **Fonts**: Always use the `Font` extension tokens (`.semiBold16`, etc.) — never use `Font.custom("Gilroy-...", size:)` directly in views.
10. **Bundle ID**: `net.paceapp`. Do not confuse with `com.garmin.paceapp`, which is only the `CFBundleURLName` for the ConnectIQ `connect://` URL type in `PaceApp-Info.plist`.
11. **Keyboard dismissal**: Applied globally via `.dismissKeyboardOnTap()` at the NavigationStack level — don't add per-screen.
12. **Firestore cache**: 500 MB persistent cache configured in AppDelegate — don't reconfigure elsewhere.
13. **Never declare `@Bindable var viewModel` inside `body`** — always derive `Binding<T>` from a `@State` property to prevent @Observable re-registration feedback loops.
14. **`navigationDestination` placement** — must never be placed inside lazy containers (`TabView`, `List`, `LazyVStack`, `ScrollView`). Must be above the `TabView` boundary.
15. **ActivityData stable IDs** — never use `let id = UUID()` on model types in lists. Use stable, deterministic IDs (Firestore document ID or sync ID).
16. **Timer and `@Observable`** — `Timer.scheduledTimer` fires off MainActor. Mutations to `@Observable` state must be dispatched to `@MainActor` explicitly.
17. **Firestore user settings** — use flat fields + nested map on the user document, not subcollections. Avoids doubling Firestore read costs on launch.
18. **`continueURL` for Firebase email link** — must be path-qualified (e.g., `https://thepaceapp.firebaseapp.com/emailSignIn`), not a bare domain root.
19. **Form validation** — always centralize in ViewModel, never inline in views. Use `ValidationProvider` methods.
20. **New forms** — use `AppTextField` and `AppSegmentedControl` from the design system. Never create ad-hoc form components.
21. **Comment discipline** — write **single-line** `//` comments; include a short example or flow only when it genuinely helps (e.g. `// watch "2.5" ft → 2.5 Feet`); **never stack more than two comment lines together** in one place (`// MARK: -` headers are exempt). If a block needs more, simplify the code. Preserve existing `// MARK: -` sections and author headers.
22. **Sole-author commits** — commits always have a single author (the git logged-in user). **Never** add a `Co-Authored-By:` trailer or any second author.

---

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| **TabBarScreen ViewModel loop** | Tab screens held as `@State`. ViewModels owned at `TabBarScreen` scope as `@State` and injected — never constructed inline. |
| **`@Bindable` feedback loop** | Never use `@Bindable var viewModel` inside `body`. Use stable `Binding<T>` computed properties derived from `@State`. |
| **Double navigation** | `Router.navigate(to:)` has 400ms debounce guard — don't bypass it. |
| **reCAPTCHA delegate lifetime** | `PhoneAuthUIDelegate` must be held strongly on `AuthManager` during `verifyPhoneNumber`. |
| **Email link different device** | If `Keys.emailForSignIn` is empty when email link arrives, show error and redirect to `.auth`. |
| **ActivityData UUID identity** | Using `let id = UUID()` causes SwiftUI to destroy/rebuild every list row on Firestore snapshot. Use stable IDs. |
| **Timer threading** | `Timer.scheduledTimer` fires off `@MainActor`. Wrap mutations in `Task { @MainActor in ... }`. |
| **Mapper field loss** | When editing mappers, ensure computed fields (`formattedGoalTime`, `totalGoalSeconds`, `isProfileCompleted`, `contactInfo`) are preserved — they're easily silently dropped. |
| **Form field loss on tab switch** | ViewModel must be owned at parent scope (`@State`) and injected. Never constructed inline in views. |
| **`GeometryReader` in a `List` cell** | Crashes at launch: `UICollectionView … recursive layout loop`. Size deterministically (e.g. `UIScreen.main.bounds.width`), never via `GeometryReader` inside a self-sizing row. |
| **Un-tappable button in a `List` row** | The row swallows the tap. Give buttons `.buttonStyle(.borderless)` / `.plain` so each stays independently tappable. |
| **`source`/`id` flipping on sync** | `EventDocument.source`, `id`, `createdAt` are write-once. Rely on `FirestoreEventRepository.upsert` preserving them — don't rewrite them from an echoed watch payload. |
| **Gait unit shows wrong / segment inactive** | Watch sends `ft`/`m` + String numbers; convert with `appGaitUnit`/`watchGaitUnit`/`settingDouble`. App stores `"Feet"`/`"Meters"`. |

---

## Dependencies (Swift Packages)

| Package | Modules | Purpose |
|---|---|---|
| **Firebase** | `FirebaseAuth`, `FirebaseFirestore`, `FirebaseCore` | Auth + database |
| **ConnectIQ** | `ConnectIQ` | Garmin Connect IQ iOS SDK |
| **FITSwiftSDK** | `FITSwiftSDK` | Garmin FIT file parsing (pre-existing unresolved build error) |
| **swift-log** | `Logging` | Structured logging (`Logger.app`) |
| **CountryPicker** | `CountryPicker` | Country/dial-code picker for phone auth (SURYAKANTSHARMA/CountryPicker) |

> All dependencies are Swift Package Manager. SPM repos: `firebase/firebase-ios-sdk`, `garmin/connectiq-companion-app-sdk-ios`, `apple/swift-log`, `SURYAKANTSHARMA/CountryPicker`.

---

## Firebase Hosting

```
firebase-hosting/public/
├── index.html    # Email sign-in deep link landing page (redirects back to app)
└── 404.html      # Custom 404
```

**APNs**: Required for silent push phone verification.
**Reversed client ID**: `app-1-652638681487-ios-0bf0155356db81a4d6f3fa` (URL scheme for reCAPTCHA).

---

## Workflow Conventions

### Pre-Edit Workflow

1. **Read all relevant files** before making changes.
2. **Fix root causes** rather than symptoms.
3. **Prefer complete file rewrites** over incremental partial fixes when conflicting or redundant code is the source of confusion.

### Adding a New Feature Checklist

1. Create screen in `Modules/{Feature}/Screen/` following `*Screen` naming
2. Create ViewModel in `Modules/{Feature}/ViewModel/` following `*ViewModel` naming
3. If new Firestore data: add Protocol → Repository → Document Model → Mapper
4. Add destination to `Destinations` enum and `Router+Destination.swift`
5. Use `AppTextField`, `AppSegmentedControl`, `AppButton` from DesignSystem
6. Add validation methods to `ValidationProvider` if new field types
7. Apply `.appBackground()` and use font tokens

### Adding a New Form Checklist

1. Create ViewModel with all form fields as `@Observable` properties
2. Add `isValid` computed property using `ValidationProvider`
3. Create screen using `AppTextField` + `AppSegmentedControl` from DesignSystem
4. Own ViewModel as `@State` in the screen (or parent for multi-step)
5. Pass `@Bindable` to sub-views for two-way binding
6. Save via appropriate repository singleton
7. Show loading via `AppButton.isLoading`, errors via `ToastManager`

### Build Verification

After each batch of file writes: `BuildProject` → `GetBuildLog` with `severity: error`.

### Git Commits

Conventional commits style — **sole author, no `Co-Authored-By:` trailer**:
```
feat(scope): impactful non-technical summary

- detail line 1
- detail line 2
```

---

## In-Progress & On the Horizon

### Model Consolidation (In Progress)

| Firestore Document | App Model | Status |
|---|---|---|
| `EventSegmentDocument` | `RunSegment` | Pending |
| `FirestoreEventDocument` | `ActivityData` | Pending |
| `FirestoreUserDocument` | `UserModel` | Pending |

> **⚠️ Critical**: During consolidation, these computed/derived fields must be preserved:
> - `formattedGoalTime`, `totalGoalSeconds`, `isProfileCompleted`, `contactInfo`

### Analytics & History Firestore Wiring

Full MVVM Firestore wiring with `AnalyticsRepository`, period bucketing, and composite index on `userId + syncType + date` — **verify status** before assuming complete.

### Firestore Security Rules

Rules are functional. Ongoing refinement needed as new collections/subcollections are added.

### User Settings Migration

User settings (gait data, interval toggles, preferred distance unit) migrated from `UserDefaults` to Firestore — stored as nested `gait` map + flat scalar fields on user document.
