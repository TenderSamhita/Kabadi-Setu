# Price Update Mechanism — Offline-Safe Solution

## Problem
The app's material prices are baked into the APK (`assets/seed/categories.json` and `recyclers.json`). When real-world scrap prices change, collectors see stale rates — but the app **must never make a network call** (airplane-mode rule in AGENTS.md).

---

## Solution: Two-Layer Offline Price Override

The idea is to let the **Recycler role** push price updates to Collectors **without any internet** — using the QR code infrastructure already in the app.

### Layer 1 — Recycler edits their own rates in the app
The Recycler home screen gets an **"Update My Rates"** button. The Recycler can raise or lower their per-category `ratesByCategory` values. Changes are saved to `shared_preferences` — they override the bundled seed values at runtime, but never touch the seed JSON files.

### Layer 2 — Rate Card QR broadcast (peer-to-peer price sync)
After updating rates, the Recycler taps **"Share Rate Card"** which generates a special QR code whose payload is:

```json
{
  "type": "rate_update",
  "recyclerId": "r1",
  "rates": { "pcb_populated": 210, "cable": 50 },
  "effectiveFrom": "2026-09-23T18:00:00Z"
}
```

When a Collector opens the app and scans this QR (via an existing scan button on the home screen), the app:
1. Detects `"type": "rate_update"` in the payload
2. Saves the new rates to `shared_preferences` under key `kabadi_rates_override_v1`
3. Shows a toast: *"Rates updated from Vidarbha E-Waste Recyclers"*
4. The rate board on the Collector home screen immediately reflects the new rates

**Zero network calls. Fully offline. Works in airplane mode.**

---

## What changes where

### New key in `shared_preferences`
- `kabadi_rates_override_v1` → JSON map of `{ recyclerId → { categoryId → int } }`
- `kabadi_category_rates_override_v1` → JSON map of `{ categoryId → int }` (floor rate overrides, set by recycler broadcast)

---

## Proposed Changes

### AppState — [`app_state.dart`](file:///c:/Users/Ayush%20Thakur/kabadi_setu/lib/app_state.dart)

#### [MODIFY] [`app_state.dart`](file:///c:/Users/Ayush%20Thakur/kabadi_setu/lib/app_state.dart)
- Add `Map<String, Map<String, int>> recyclerRateOverrides` — overrides per recycler loaded from prefs
- Add `Map<String, int> categoryRateOverrides` — floor rate overrides
- Add `effectiveRateForCategory(String categoryId)` helper — returns override if present, else seed value
- Add `effectiveRecyclerRate(String recyclerId, String categoryId)` helper
- Add `updateRecyclerRates(String recyclerId, Map<String, int> rates)` — saves to prefs + notifies
- Add `applyRateUpdateFromQr(Map<String, dynamic> payload)` — called by scanner when it detects `type: rate_update`
- Load both override keys in `init()`

---

### New Screen — Rate Editor (Recycler Role)

#### [NEW] [`lib/screens/rate_editor_screen.dart`](file:///c:/Users/Ayush%20Thakur/kabadi_setu/lib/screens/rate_editor_screen.dart)
- Lists all 10 categories with their current effective rate
- Each row has `−` / `+` steppers (±₹5 increments)
- Big **"Save & Generate Rate Card QR"** primary button at bottom
- On save: calls `AppState.updateRecyclerRates()`, then navigates to Rate Card QR screen

#### [NEW] [`lib/screens/rate_card_qr_screen.dart`](file:///c:/Users/Ayush%20Thakur/kabadi_setu/lib/screens/rate_card_qr_screen.dart)
- Displays the QR code for the rate update payload using `qr_flutter` (already in pubspec)
- Shows "Ask the collector to scan this" instruction
- A timestamp showing when the rate was last updated

---

### Recycler Home — [`recycler_home_screen.dart`](file:///c:/Users/Ayush%20Thakur/kabadi_setu/lib/screens/recycler_home_screen.dart)

#### [MODIFY] [`recycler_home_screen.dart`](file:///c:/Users/Ayush%20Thakur/kabadi_setu/lib/screens/recycler_home_screen.dart)
- Add **"Update My Rates"** button → navigates to `RateEditorScreen`

---

### Collector Home — [`collector_home_screen.dart`](file:///c:/Users/Ayush%20Thakur/kabadi_setu/lib/screens/collector_home_screen.dart)

#### [MODIFY] [`collector_home_screen.dart`](file:///c:/Users/Ayush%20Thakur/kabadi_setu/lib/screens/collector_home_screen.dart)
- Add **"Scan Rate Card"** icon button in the app bar
- Opens `mobile_scanner` (already in pubspec); if payload `type == "rate_update"`, calls `applyRateUpdateFromQr()` and shows a snackbar confirmation
- Rate board tiles already read from `AppState.categories` — update `ratePerKg` display to use `effectiveRateForCategory()` so tiles auto-refresh

---

## Data Flow Diagram

```
Recycler edits rates
        │
        ▼
AppState.updateRecyclerRates()
        │
        ├──► shared_preferences  (persisted)
        │
        ▼
Rate Card QR generated (qr_flutter)
        │
   [Collector scans QR]
        │
        ▼
AppState.applyRateUpdateFromQr()
        │
        ├──► shared_preferences  (persisted)
        │
        ▼
Rate board refreshes via notifyListeners()
```

---

## Verification Plan

### Automated
```bash
flutter analyze
```

### Manual (on-device)
1. Open app in Recycler role → tap "Update My Rates" → raise PCB rate from ₹180 → ₹210 → tap Save
2. QR code screen appears → screenshot it
3. Switch to Collector role on the same device (or second device) → tap "Scan Rate Card" → scan the QR
4. Rate board should now show PCB at ₹210 instead of ₹180
5. Kill and relaunch the app — overridden rate must still show (persisted in prefs)
6. Enable airplane mode → confirm the whole flow still works

---

> [!IMPORTANT]
> This stays strictly within the rules in AGENTS.md:
> - ✅ No network calls — QR is the transport layer
> - ✅ No new packages — uses `qr_flutter` + `mobile_scanner` already in pubspec
> - ✅ `shared_preferences` for persistence
> - ✅ Seed JSON is never written — only overrides are stored in prefs
> - ✅ One app, one codebase — same scan button detects both lot QRs and rate-update QRs by checking the `type` field

> [!NOTE]
> **Hackathon narrative**: *"Recyclers can broadcast updated prices to collectors peer-to-peer — no internet needed. A collector just scans the recycler's Rate Card QR and their price board updates instantly."*  
> This is a strong, differentiating demo moment.
