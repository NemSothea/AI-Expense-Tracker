# AI Expense Tracker — SwiftUI

An AI-powered expense tracking app built with SwiftUI, Firebase, and Apple Vision. Supports iOS, iPadOS, and macOS with offline-first architecture and bilingual UI (English / Khmer).

---

## Table of Contents

- [Features](#features)
- [Business Flow](#business-flow)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Setup](#setup)
- [Project Structure](#project-structure)
- [Localization](#localization)
- [References](#references)

---

## Features

| Feature | Description |
|---|---|
| Dashboard | Animated pie/bar charts — total spent, avg transaction, top category |
| Expense List | Filter · Sort · Search · Infinite scroll · CRUD |
| Export | CSV (with total footer), styled PDF report, plain text — via native share sheet |
| Receipt Scanner | On-device OCR via Apple Vision — no API key required |
| AI Assistant | ChatGPT text + voice chat with function calling to log expenses |
| Offline Support | SwiftData local-first, auto-sync to Firestore when online |
| Widget | Home screen widget showing last recorded expense |
| Siri Shortcut | "Open AI Expense" App Intent |
| Localization | English + Khmer (ភាសាខ្មែរ) with Battambang font |
| Multi-platform | iPhone tab view · iPad/macOS split view |

---

## Business Flow

### 1. App Entry

```
Launch → LaunchScreenView → ContentView
                                ├── iPhone  → TabView (Home · Expense · Scanner · Profile)
                                └── iPad/macOS → NavigationSplitView
```

### 2. Dashboard

```
Firestore snapshot → SyncManager → SwiftData @Query
        ↓
FirebaseDashboardViewModel
        ↓
AnimatedDashboardHomeView
    ├── Summary cards  (Total Spent · Avg Transaction · Top Category)
    ├── Animated Pie Chart  (spending by category)
    └── Recent Expenses list
```

### 3. Expense Management

```
LogListContainerView
    ├── FilterCategoriesView   — filter by one or more categories
    ├── SelectSortOrderView    — sort by Date / Amount / Name, asc/desc
    └── LogListView
            ├── Search bar     — real-time filter by name, category, amount
            ├── Grouped list   — sectioned by month, infinite scroll
            └── Context menu   — Copy · Share · Edit · Delete

Toolbar:
    ├── [↑] Export Menu
    │       ├── Export as CSV  (with Total footer row)
    │       ├── Export as PDF  (styled A4 report via UIGraphicsPDFRenderer)
    │       └── Export as Text
    └── [+] Add Expense → LogFormView
```

**Write path:**
```
User fills LogFormView
    → LogFormViewModel.save()
    → DatabaseManager.add(log:)          ← instant, writes to SwiftData
    → SyncManager.syncPendingChanges()   ← background push to Firestore
```

**Delete / Edit path:**
```
User action
    → DatabaseManager.delete() / update()   ← marks record pendingDelete / pendingUpload
    → SyncManager.syncPendingChanges()      ← syncs to Firestore in background
```

### 4. Receipt Scanner

```
VisionReceiptScannerView
    ├── Take Photo (camera)  OR  Choose from Library (PhotosPicker)
    ↓
VisionReceiptScannerViewModel
    └── VNRecognizeTextRequest  (Apple Vision, on-device, free)
            ↓
        ReceiptTextParser.parse()
            ↓
        VisionScanResult  (items + prices extracted)
            ↓
VisionAddReceiptConfirmationView
    └── User reviews items → confirm → DatabaseManager.add()
```

### 5. AI Assistant

```
AIAssistantView
    ├── Text chat  (AIAssistantTextChatViewModel)
    └── Voice chat (AIAssistantVoiceChatViewModel)
            ↓
    ChatGPT API (gpt-4o)  +  Function Calling
            ↓
    FunctionsManager
        └── Tool: add_expense_log
                ↓
            Confirmation card shown in chat
                ├── Confirm → DatabaseManager.add(log:)
                └── Cancel  → dismissed
```

### 6. Offline / Sync Architecture

```
Write path:
    User action → DatabaseManager → SwiftData (instant, syncStatus = pendingUpload)
                                          ↓  (background)
                                    SyncManager → Firestore

Read path:
    Firestore real-time listener → SyncManager → SwiftData → @Query → UI

Network events:
    NetworkMonitor (NWPathMonitor)
        └── device comes online → SyncManager.syncPendingChanges()
        └── offline banner shown via .offlineBanner() view modifier
```

### 7. Widget & Shortcuts

```
On every expense write:
    DatabaseManager → UserDefaults (App Group) → WidgetCenter.reloadTimelines()
                                                        ↓
                                                Home screen widget (last expense)

Siri / Spotlight:
    AiExpenseIntent (AppIntents) → opens app
```

---

## Architecture

**Pattern:** MVVM + Local-first

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI Views                 │
│  ContentView · Dashboard · LogList · Scanner    │
│  AIAssistant · Profile                          │
└──────────────────┬──────────────────────────────┘
                   │ @Query / @Binding / @State
┌──────────────────▼──────────────────────────────┐
│               ViewModels (@Observable)           │
│  LogListViewModel · FirebaseDashboardViewModel  │
│  AIAssistantTextChatViewModel                   │
│  VisionReceiptScannerViewModel                  │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│             DatabaseManager (singleton)          │
│   add / update / delete → SwiftData first       │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│              SyncManager (singleton)             │
│   SwiftData ↔ Firestore  (pendingUpload /       │
│   pendingDelete / synced)                       │
└─────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI · SwiftData · Charts |
| Database (local) | SwiftData (`LocalExpenseLog`) |
| Database (remote) | Firebase Firestore |
| AI | OpenAI GPT-4o — text + voice + function calling |
| OCR | Apple Vision Framework (`VNRecognizeTextRequest`) |
| Networking | Combine · NWPathMonitor |
| Widget | WidgetKit · App Groups |
| Shortcuts | AppIntents |
| Packages | ChatGPTSwift · ChatGPTUI |
| Fonts | Battambang (Khmer) |
| Export | UIGraphicsPDFRenderer · ShareLink |

---

## Setup

### 1. Firebase
```bash
# Install Firebase CLI
brew install firebase-cli

# Start local emulator (development)
firebase emulators:start
```

Add `GoogleService-Info.plist` to the project target.

### 2. OpenAI API Key
Get your key from: https://platform.openai.com/settings/organization/api-keys

Set it in the app's Profile or environment config.

### 3. Run
Open `AIExapenseTracker.xcodeproj` in Xcode 16+, select a simulator or device, and run.

---

## Project Structure

```
AIExapenseTracker/
├── AppShortCut/            Siri App Intents
├── AIAssistance/
│   ├── Models/             FunctionTools, FunctionResponse
│   ├── ViewModels/         Text & Voice chat VMs
│   └── Views/              AIAssistantView, response cards
├── Helper/
│   ├── ExportManager.swift CSV · PDF · Plain text generation
│   └── fonts/              Battambang (Khmer)
├── Localization/
│   └── LocalizationManager.swift  LK keys — EN + KM
├── Models/                 ExpenseLog, Category, SortType
├── Offline/
│   ├── LocalExpenseLog.swift  SwiftData model
│   ├── SyncManager.swift      Firestore ↔ SwiftData sync engine
│   ├── NetworkMonitor.swift   NWPathMonitor wrapper
│   └── OfflineBannerView.swift
├── Profile/                ProfileView
├── ReceiptScanner/
│   ├── VisionReceiptScannerView.swift
│   ├── VisionReceiptScannerViewModel.swift
│   ├── ReceiptTextParser.swift
│   ├── CameraImagePicker.swift
│   └── VisionAddReceiptConfirmationView.swift
├── ViewModels/             LogList · LogForm · Dashboard · Profile
├── Views/                  Dashboard · LogList · Charts · Forms
├── DatabaseManager.swift   Write gateway (local-first)
└── ContentView.swift       Root — TabView / SplitView
```

---

## Localization

The app supports **English** and **Khmer (ភាសាខ្មែរ)**. All UI strings are defined as `LK` keys in `LocalizationManager.swift`. Switching language applies immediately without restarting the app.

Khmer uses the **Battambang** font family (Black, Bold, Regular, Light) for correct rendering.

---

## References

| Resource | Link |
|---|---|
| GitHub Repo | https://github.com/NemSothea/Build-an-AI-Assistant-Expense-Tracker-SwiftUI-App |
| Firebase CLI | https://firebase.google.com/docs/cli#macos |
| OpenAI Platform | https://platform.openai.com/settings/organization/api-keys |
| Commit Emoji Guide | https://gitmoji.dev |

### Process Flow Diagrams

| Phase | Diagram |
|---|---|
| Phase 1 — Project Setup | ![](https://raw.githubusercontent.com/NemSothea/AI-Expense-Tracker/main/Processflow/process_01.png) |
| Phase 2 — Firebase Integration | ![](https://raw.githubusercontent.com/NemSothea/AI-Expense-Tracker/main/Processflow/process_02.png) |
| Phase 3 — OpenAI Integration | ![](https://raw.githubusercontent.com/NemSothea/AI-Expense-Tracker/main/Processflow/process_03.png) |
| Phase 4 — Advanced Features | ![](https://raw.githubusercontent.com/NemSothea/AI-Expense-Tracker/main/Processflow/process_04.png) |

---

### Git Tips

```bash
# See uncommitted changes
git status

# Stop tracking a file (e.g. Xcode user state)
git rm --cached AIExapenseTracker.xcodeproj/project.xcworkspace/xcuserdata/sothea007.xcuserdatad/UserInterfaceState.xcuserstate

git commit -m "Removed file that shouldn't be tracked"
```
