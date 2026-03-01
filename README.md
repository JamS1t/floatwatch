# 💙 FloatWatch

> **Your GCash outlet, always in check.**

FloatWatch is a mobile app built for GCash Partner Outlet (GPO) operators in the Philippines. It tracks daily transactions, calculates markup income, monitors float balance, detects discrepancies, and supports both solo owners and owners with staff — all from their phone.

---

## 📱 Screenshots

> _Coming soon — app is currently in active development._

---

## ✨ Features

### Core

- 📷 **Batch Receipt Upload** — Upload GCash screenshots in bulk. OCR reads each one automatically.
- 🧮 **Smart Markup Calculation** — Supports percentage, fixed, and per-bracket (per ₱500) markup rates per transaction type.
- 📊 **Float Balance Tracking** — Tracks GCash and cash on hand movement in real time.
- 🟢🟡🔴 **Discrepancy Detection** — Compares expected vs actual closing balance and flags mismatches instantly.
- 📋 **Daily Reports** — Full end-of-day summary with profit breakdown, transaction history, and status indicators.

### Security & Access

- 🔐 **Owner PIN** — 6-digit PIN protects all owner-level data.
- 👤 **Staff PIN** — Each staff member has their own 4-digit PIN set by the owner.
- 🔒 **Simple & Strict Mode** — Toggle between a fast daily workflow or full authorization controls.
- 🚨 **Foul Play Detection** — Manual entries are logged with reasons and flagged for owner review.
- 🔔 **Low Float Alerts** — Push notifications when GCash or cash balance drops below your set threshold.

### Multi-User

- 👥 **Staff Accounts** — Add multiple staff members, each with their own PIN and audit trail.
- 🏪 **Multi-Store Ready** — Architecture supports multiple stores under one owner account.
- 📡 **Remote Monitoring** — Owner can check store status, profit, and discrepancies from anywhere _(Premium — coming soon)_.

### Premium Features _(coming soon)_

- 📤 Export reports to PDF and Excel
- 📈 Weekly and monthly analytics with graphs
- ☁️ Cloud sync and remote monitoring via Firebase
- 🏪 Multiple store management
- 🔓 Reopen closed day

---

## 🏗️ Tech Stack

| Layer            | Technology                                      |
| ---------------- | ----------------------------------------------- |
| Framework        | Flutter (latest stable)                         |
| Local Database   | SQLite via `sqflite`                            |
| State Management | Provider                                        |
| OCR              | Google ML Kit                                   |
| Image Handling   | `image_picker`                                  |
| Charts           | `fl_chart`                                      |
| Notifications    | `flutter_local_notifications`                   |
| PDF Export       | `pdf` package _(premium)_                       |
| Cloud Sync       | Firebase _(architecture ready, not yet active)_ |
| Security         | SHA-256 PIN hashing                             |

---

## 🏛️ Architecture

FloatWatch uses a **Repository Pattern** so the data layer can swap between SQLite and Firebase without touching UI code.

```
UI (Screens)
  ↓
Providers (ViewModels)
  ↓
Repositories (Interfaces)
  ↓
Local SQLite ──► Firebase (future)
```

Two central service classes drive cross-cutting concerns:

- **SecurityService** — Handles PIN hashing, verification, OTP generation, and simple/strict mode checks.
- **SubscriptionService** — Controls all premium feature access from one place.

---

## 📁 Project Structure

```
lib/
├── main.dart
├── app.dart
├── routes.dart
│
├── core/
│   ├── constants/        # Colors, text styles, app constants
│   ├── services/         # SecurityService, SubscriptionService
│   └── utils/            # Currency formatter, markup calculator
│
├── data/
│   ├── database/         # DatabaseHelper, SyncLogHelper
│   ├── models/           # All data models
│   └── repositories/
│       ├── interfaces/   # Repository contracts
│       └── local/        # SQLite implementations
│
├── providers/            # All ChangeNotifier providers
│
└── ui/
    ├── screens/
    │   ├── onboarding/
    │   ├── auth/
    │   ├── owner/
    │   ├── staff/
    │   ├── shared/
    │   ├── reports/
    │   └── settings/
    └── widgets/
        ├── common/       # PrimaryButton, PinPad, StatusBadge
        └── dashboard/    # Float status card, profit summary
```

---

## 💾 Database Schema

FloatWatch uses 9 SQLite tables:

| Table             | Purpose                                             |
| ----------------- | --------------------------------------------------- |
| `owners`          | Owner accounts and PINs                             |
| `stores`          | Store profiles and security mode                    |
| `staff`           | Staff accounts, PINs, and lockout state             |
| `markup_settings` | Per-store, per-transaction markup rates             |
| `daily_float`     | Opening and closing balances per day                |
| `transactions`    | All transaction records with full audit trail       |
| `daily_reports`   | End-of-day summaries                                |
| `one_time_pins`   | Temporary PINs for staff manual entry authorization |
| `sync_log`        | Tracks all writes for future Firebase sync          |

> All monetary values are stored as **INTEGER (centavos)** to avoid floating point errors.
> All tables include a `sync_id` (UUID) field for Firebase sync readiness.

---

## 🧮 Business Logic

### GCash Balance Movement

| Transaction Type | GCash        | Cash         |
| ---------------- | ------------ | ------------ |
| Cash In          | ⬇️ Decreases | ⬆️ Increases |
| Cash Out         | ⬆️ Increases | ⬇️ Decreases |
| Bills Payment    | ⬇️ Decreases | ⬆️ Increases |
| Load / Others    | ⬇️ Decreases | ⬆️ Increases |

### Discrepancy Status

| Range      | Status     |
| ---------- | ---------- |
| ₱0 – ₱10   | 🟢 Clean   |
| ₱11 – ₱200 | 🟡 Warning |
| ₱201+      | 🔴 Flagged |

### Markup Types

| Type        | Formula                                          |
| ----------- | ------------------------------------------------ |
| Percentage  | `amount × rate`                                  |
| Fixed       | `flat amount` regardless of transaction size     |
| Per Bracket | `ceil(amount ÷ bracket_size) × rate_per_bracket` |

---

## 🚀 Getting Started

### Prerequisites

```bash
# Check versions
java --version        # JDK 17+
flutter --version     # 3.x.x stable
flutter doctor        # All green
git --version         # 2.x.x
node --version        # 18.x.x+
```

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/floatwatch.git
cd floatwatch

# Install dependencies
flutter pub get

# Run on device or emulator
flutter run
```

### Enable Developer Mode on Android (for physical device testing)

```
Settings → About Phone →
tap "Build Number" 7 times →
Developer Options → Enable USB Debugging
```

---

## 🗺️ Roadmap

### MVP (In Progress)

- [x] Project architecture and database schema
- [ ] Owner and staff authentication (PIN system)
- [ ] Opening balance flow (simple + strict mode)
- [ ] Manual transaction entry
- [ ] Batch receipt upload with OCR
- [ ] OCR review and confirmation screen
- [ ] Markup calculation engine
- [ ] End of day flow with discrepancy detection
- [ ] Daily reports screen
- [ ] Staff management and permissions
- [ ] Push notifications
- [ ] Settings and security mode toggle

### v1.1

- [ ] Firebase cloud sync
- [ ] Remote monitoring for absentee owners
- [ ] PDF and Excel export
- [ ] Weekly and monthly analytics

### v2.0

- [ ] Multi-store dashboard
- [ ] Maya and other e-wallet support
- [ ] Staff performance reports
- [ ] Subscription billing integration

---

## 🔐 Security Notes

- PINs are **never stored in plain text** — all PINs are hashed using SHA-256 before saving to the database.
- Staff accounts lock after **3 failed PIN attempts** and the owner is notified immediately.
- One-time PINs for manual entry authorization **expire after 5 minutes** and are single-use only.
- Staff cannot view markup earnings, float balances, or daily reports — only owners can.

---

## 🤝 Contributing

This project is currently in private development. Contribution guidelines will be published when the MVP is released.

---

## 📄 License

This project is proprietary software. All rights reserved.

© 2026 FloatWatch. Built in the Philippines 🇵🇭

---

## 👨‍💻 Built By

**Job** — BSIT Student, Content Creator, and aspiring indie developer.

> _"Built for every GPO operator who deserves better than a notebook."_
