# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CARDinal is a native iOS app built with SwiftUI that manages digital business cards. Users can create their own card, share it via QR code, scan and receive cards from others, and export cards to Apple Wallet.

## Architecture

### Core Data Flow

- **CardStore** (`CARDinal/ViewModels/CardStore.swift`): Central `@MainActor` ObservableObject managing all card data
  - Owns `myCard` (user's personal card) and `receivedCards` (cards from others)
  - Persists to UserDefaults using JSON encoding
  - Provides methods: `saveMyCard()`, `addReceivedCard()`, `deleteReceivedCard()`, `updateMyCard()`
  - Injected into view hierarchy via `.environmentObject()` in `CARDinalApp.swift`

### Model Layer

- **BusinessCard** (`CARDinal/Models/BusinessCard.swift`): Core data model
  - Conforms to `Identifiable`, `Codable`, `Hashable`
  - Contains contact info (name, email, phone, social links) and customization (accent color, material type)
  - **Color handling**: Uses computed properties for `accentColor` (Color) and `accentColorHex` (String) that sync bidirectionally
  - Custom `Codable` implementation handles color hex/Color conversion and URL string encoding
  - `CardMaterial` enum defines card visual styles (glass, neon, metal, frosted, holographic, matte)

### View Architecture

- **ContentView**: Root TabView with 4 main tabs (My Card, Received, Nearby, Settings)
- **MyCardView**: Displays user's card with share/edit actions
- **ReceivedCardsView**: List of received cards
- **CardDetailView**: Full details for a received card
- **EditCardView**: Form for editing user's card
- **GlassCardView**: Reusable card rendering component with glassmorphic design
  - Uses `MaterialBackground` for visual effects based on `CardMaterial`
  - Displays contact info, social icons, and resume indicator
  - Supports `compact` mode for different contexts
  - Can be enhanced with `.tiltable()` modifier for gyroscope-based parallax
- **TiltableCardModifier**: View modifier that adds gyroscope-based tilt animation
  - Uses MotionManager to track device orientation
  - Applies 3D rotation based on pitch (forward/backward) and roll (left/right)
  - Smooth spring animations with configurable sensitivity and max tilt angle
- **PDFViewer**: Full-featured PDF viewer for displaying resumes within the app
  - Uses PDFKit for native PDF rendering
  - Supports pinch-to-zoom, scrolling through pages
  - Includes share functionality for exporting PDFs
  - Displays when user taps "View" on cards with attached resume data
- **NearbyUsersView**: Peer-to-peer card exchange interface
  - Discovers nearby devices running CARDinal via MultipeerConnectivity
  - Shows discovered and connected peers with status badges
  - "Request Card" button to initiate card transfer
  - Separate retry buttons for card and resume transfers
  - Progress indicators for resume downloads
  - Sheet presentation for received cards with save/dismiss options

### QR Code System

- **QRCodeShareView**: Generates QR code from user's card (encoded as JSON)
- **QRScannerSheet**: Camera-based QR scanner using AVFoundation
  - UIViewControllerRepresentable wrapper around custom AVCaptureSession
  - Handles camera permissions with async/await
  - Provides haptic feedback on successful scan
- **Deep linking** (`CARDinalApp.swift:19-48`): Handles `cardinal://addcard?data=...` URLs for receiving cards scanned outside the app

### Utilities

- **WalletPassManager** (`CARDinal/Utils/WalletPassManager.swift`): Apple Wallet integration
  - Currently stubbed out with 2-second delay simulation
  - Production would generate .pkpass files server-side with card data and QR code
- **MotionManager** (`CARDinal/Utils/MotionManager.swift`): CoreMotion integration for device tilt detection
  - ObservableObject that publishes roll and pitch values from device gyroscope
  - Updates at 60 Hz for smooth animations
  - Used by TiltableCardModifier for parallax card effects
- **MultipeerManager** (`CARDinal/Utils/MultipeerManager.swift`): Peer-to-peer device discovery and card exchange
  - Uses MultipeerConnectivity framework for local network discovery
  - Manages advertising, browsing, and sessions
  - Handles card and resume data transfer separately
  - Implements retry logic for failed transfers
  - Tracks transfer progress and status per peer
- **Extensions** (`CARDinal/Extensions.swift`): String convenience methods (`isBlank`, `orEmpty`)

## Development Commands

### Building
```bash
# Build from command line
xcodebuild -project CARDinal.xcodeproj -scheme CARDinal -configuration Debug build

# Or open in Xcode
open CARDinal.xcodeproj
```

### Testing
```bash
# Run tests from command line
xcodebuild test -project CARDinal.xcodeproj -scheme CARDinal -destination 'platform=iOS Simulator,name=iPhone 15'

# Run single test (using Swift Testing framework)
xcodebuild test -project CARDinal.xcodeproj -scheme CARDinal -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CARDinalTests/CARDinalTests/example
```

Note: Project uses Swift Testing framework (not XCTest). Tests are in `CARDinalTests/CARDinalTests.swift`.

### Running
- Build and run in Xcode (⌘R) or select a simulator and use `xcodebuild` with `-destination`
- App requires iOS simulator or physical device with camera for QR scanning

## Key Implementation Patterns

### App-Wide Settings
- **Dark mode only**: App forces `.preferredColorScheme(.dark)` in CARDinalApp
- All backgrounds use dark gradients (black to dark gray)

### State Management
- Single source of truth: `CardStore` accessed via `@EnvironmentObject`
- Views update reactively to `@Published` properties
- All UI updates run on `@MainActor`

### Persistence
- UserDefaults with JSON encoding for local storage
- Keys: `"MyBusinessCard"`, `"ReceivedBusinessCards"`
- No external database or networking (all local)

### Color Encoding
When working with BusinessCard colors:
- Always use `accentColor` (Color type) in views
- `accentColorHex` automatically syncs when setting `accentColor`
- Custom Codable implementation handles persistence
- Extension methods `Color.toHex()` and `Color(hex:)` in `BusinessCard.swift:140-176`

### Camera Permissions
QR scanner requires camera access:
- Check authorization status before presenting scanner
- Handle `.notDetermined`, `.authorized`, `.denied` states
- Use async/await for permission requests (`AVCaptureDevice.requestAccess`)

### Resume Handling
BusinessCard supports two types of resume storage:
- **resumeData** (Data?): Embedded PDF file attached to the card
- **resumeURL** (String): External URL to resume hosted elsewhere
- `hasResume` computed property returns true if either is present
- CardDetailView automatically displays in-app PDF viewer for attached resumes
- Falls back to opening external URL if only resumeURL is provided

### Multipeer Connectivity
Peer-to-peer card exchange using local network:
- **Service Type**: "cardinal-card" (for discovery)
- **Security**: Required encryption for all sessions
- **Transfer Strategy**: Card data sent first (without resume), then resume sent separately
- **Retry Mechanism**: Separate retry for card and resume transfers
- **Auto-Accept**: Invitations are automatically accepted
- Both devices must have the Nearby tab open to discover each other
- Works over WiFi and Bluetooth (no internet required)

## Common Pitfalls

1. **Don't forget @MainActor**: CardStore and WalletPassManager require MainActor context
2. **Color sync**: When modifying card colors, set `accentColor` (not `accentColorHex` directly) to ensure proper encoding
3. **Optional phone field**: `BusinessCard.phone` is optional; check for nil/empty before displaying
4. **Deep link scheme**: Use `cardinal://` (not `cardinals://` or other variants)
5. **Resume attachments**: `resumeData` and `resumeFileName` are separate from `resumeURL` (which is a string, not URL)
