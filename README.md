# G A Laundry Shop (merged project)

This repo combines both parts of the team's work:

- `lib/frontend/` - Irish's UI (screens, models, state, theme, navigation). Copied unchanged from `laundry_shop_app`. `app.dart` is her old `main.dart`, with two lines marked `// BACKEND HOOK`.
- `lib/main.dart`, `lib/services/`, `lib/models/`, `lib/backend/`, `functions/` - Lance's backend (Firebase, Hive, offline queue, sync, Cloud Function).
- `lib/screens/`, `lib/widgets/`, `lib/theme/` - Lance's earlier admin screens. They are NOT used by the running app (the frontend's screens replace them). Keep as reference while connecting the frontend's `state.dart` to `services/`, then delete.

Next step: replace the mock lists in `lib/frontend/state.dart` with calls to `FirestoreService` / `SyncService`, one feature at a time.

---

# G A Laundry Shop — Fernandez Phases (2, 7, 9, 10, 11)

Updated to match the shared UI kit (colors, Poppins type, radii) and
your teammate's full data dictionary. Field/collection names now follow
that dictionary exactly, so both of your Firestore code stays
compatible on the same project.

## 1–4. Setup (unchanged)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutterfire configure
cd functions && npm install
firebase functions:config:set semaphore.key="YOUR_API_KEY" semaphore.sender="YOUR_SENDER_ID"
firebase deploy --only functions
```

## 5. Run on an emulator

```bash
flutter emulators --launch <id>
flutter run
```

## Addressing the revised proposal suggestions

Your "Revised Suggestion" doc's 6 points, mapped to what's actually
yours to build:

| # | Suggestion | Status |
| --- | --- | --- |
| 1 | Automated SMS Gateway | ✅ `functions/index.js` (Phase 7) |
| 2 | Digital queueing engine | ✅ `lib/services/queue_service.dart` — architecture only, see below |
| 3 | Offline-first + auto-sync | ✅ `sync_service.dart`, `hive_service.dart` (Phase 10) |
| 4 | Batching calculator | ✅ `lib/models/batch_model.dart` — architecture only, see below |
| 5 | Expense & inventory tracking | ✅ `expense_model.dart`, `inventory_item_model.dart` (Phase 9) |
| 6 | Objective wording | Not app code — that's paper/proposal text for the doc itself |

Points 2 and 4 are UI on your teammate's screens (New Order form,
Order board — Phases 5–6), but the underlying logic is data-model
architecture, which is your Phase 2. What's here:

- **`BatchRecommendation.forWeight(weightKg, isThickHeavy: ...)`** —
  the weight-based calculator itself: Small/Medium/Large load size,
  suggested wash cycle, detergent grams, cycle duration.
- **`QueueService.planNewOrder(...)`** — one call that returns the
  next queue number, the batch recommendation, an assigned machine
  (smallest one that fits, to leave bigger machines free), and an
  estimated completion time based on current machine load. Hand this
  method to your teammate — it's the whole "Digital Order Queueing
  Engine" in one function call for her New Order form to use.

## What's implemented, mapped to the data dictionary

| File | Data category | Phase |
| --- | --- | --- |
| `lib/theme/app_theme.dart` | Color System / Typography / Buttons from the UI kit | — |
| `lib/models/order_model.dart` | Order Data | 2 |
| `lib/models/payment_model.dart` | Payment Data | 2 / 9 |
| `lib/models/expense_model.dart` | Expense Data | 2 / 9 |
| `lib/models/inventory_item_model.dart` | Inventory Data | 2 / 9 |
| `lib/services/hive_service.dart`, `sync_service.dart` | Offline Transaction Data / Sync Queue Data | 10 |
| `functions/index.js` | Notification Data (SMS) | 7 |
| `lib/screens/payment/payment_screen.dart` | Payment Data | 9 |
| `lib/screens/inventory/expense_log_screen.dart` | Expense Data | 9 |
| `lib/screens/inventory/inventory_stock_screen.dart` | Inventory Data | 9 |
| `lib/screens/admin/dashboard_screen.dart` | Sales Data / Profit Report Data | 11 |
| `lib/screens/admin/services_pricing_screen.dart` | Service Pricing Data | 11 |
| `lib/models/machine_model.dart`, `lib/screens/admin/machine_floor_screen.dart` | Machine Data / Machine Availability Data | 11 |

## Aligned with Irish's AI Studio prototype

Two things were pulled in from that prototype, recolored to the light
theme instead of its dark navy one:
- **Order status now has 6 steps**, not 4: Received → Sorting →
  Washing → Drying → Ready for Pickup → Claimed (`OrderStatus` in
  `order_model.dart`).
- **Commercial machine floor** — a live washer/dryer status panel on
  the dashboard, with a full manage screen to add machines and flip
  their status. This wasn't in the original data dictionary as your
  scope, but the prototype puts it on the admin screen, so it's here.

Not pulled in (belongs to your teammate's screens): the loyalty stamp
card, the weight-based batching calculator with machine/cycle
auto-recommendation on the New Order form, and Firebase Auth role
switching. If those need backing data models later, coordinate with
Irish since Batch Data and Wash Recommendation Data live in her
phases (5–6), not yours.

## Data categories intentionally out of scope here

These belong to your teammate's phases (login, order creation/tracking,
customer records) or to shared/system-level setup, so they're not
built in this document: Customer Data, Staff/Admin Data, Laundry Shop
Data, Machine Data, Machine Availability Data, Laundry Category Data,
Queue Data, Order Status/History Data, Batch Data, Wash Recommendation
Data, System Settings Data, System Logs. Coordinate with your teammate
on the actual `customers` collection shape — the SMS Cloud Function
here reads `customers/{customerId}.contactNumber`, so make sure that
field name matches whatever they build.

## Design system reference

Colors, type scale, button/card radii, and spacing all come straight
from the shared UI kit — see `lib/theme/app_theme.dart` for the single
source of truth. If the kit changes, update that file and every screen
picks it up automatically.
