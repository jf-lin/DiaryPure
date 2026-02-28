# DiaryPure

An iOS app for writing diary entries and signing consent agreements with partners.

## Tech Stack
- SwiftUI (iOS 17+)
- SwiftData (local persistence)
- Sign in with Apple (authentication)

## Features
- **Diary**: Create, edit, delete entries with optional mood tracking
- **Consent Agreements**: Create agreements, capture finger signatures from both parties
- **Auth**: Sign in with Apple

## Project Structure
```
DiaryPure/
├── DiaryPureApp.swift          # App entry point
├── ContentView.swift           # Tab navigation (Diary / Consent)
├── Models/
│   ├── DiaryEntry.swift        # SwiftData diary entry model
│   └── ConsentAgreement.swift  # SwiftData consent agreement model
├── Views/
│   ├── Auth/AuthView.swift     # Sign in with Apple screen
│   ├── Diary/
│   │   ├── DiaryListView.swift     # List of diary entries
│   │   └── DiaryEditorView.swift   # Create/edit entry
│   └── Consent/
│       ├── ConsentListView.swift   # List + detail of agreements
│       ├── ConsentCreateView.swift # Create new agreement
│       └── SignatureView.swift     # Finger signature canvas
├── Services/
│   └── AuthService.swift       # Apple ID auth + session management
└── Assets.xcassets
```

## Requirements
- Xcode 16+
- iOS 17+

## Setup
1. Open `DiaryPure.xcodeproj` in Xcode
2. Select a team for code signing
3. Build and run on a simulator or device
4. For Sign in with Apple, enable the capability in Xcode under Signing & Capabilities
