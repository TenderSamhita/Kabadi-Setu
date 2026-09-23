# Implementation Plan — Kabadi Setu Hackathon Build

Status: All Milestones (1–7) complete! Hackathon build ready.
Read `AGENTS.md` first — it has the non-negotiables, stack, design tokens, and data shape referenced below. Work through milestones in order. Do not start a milestone until the previous one's verification step passes.

## Milestone 1 — Project skeleton
- [x] `flutter create` the project, set the package name, confirm it builds and runs on an emulator or connected device
- [x] Add packages: `provider`, `shared_preferences`, `flutter_tts`, `qr_flutter`, `mobile_scanner`
- [x] Set up `ThemeData` using the design tokens in AGENTS.md
- [x] Create `assets/seed/categories.json` (10 categories) and `assets/seed/recyclers.json` (5 recyclers) per the shapes in AGENTS.md, wire both into `pubspec.yaml`
- [x] Create `AppState` (ChangeNotifier) holding: current role (`collector` / `recycler`), the in-progress draft lot, completed ledger entries. Wrap the app in a `ChangeNotifierProvider`.

**Verification:** app launches to a themed blank screen, no console errors, `flutter analyze` is clean.

## Milestone 2 — Launch, role toggle, rate board
- [x] Launch screen: language choice (Marathi / Hindi). A simple `Map<String, Map<String,String>>` string lookup is enough — full localization infrastructure is not needed at this scope.
- [x] Role screen: two buttons, "Collector" and "Recycler," sets `AppState.role`
- [x] Collector home — rate board: a grid of the 10 category tiles from seed data, name + rate on each; tapping a tile speaks the name and rate aloud via `flutter_tts` in the selected language
- [x] One primary action at the bottom of the home screen: "Add material" → capture screen

**Verification:** can switch language, switch role, see all 10 rates on the board, hear at least one spoken aloud.

## Milestone 3 — Capture → categorise → weigh → quote
- [x] Capture screen: open the device camera, take a photo, store its path on the draft lot
- [x] After capture, show a ~1.2 second loading state, then reveal 3 category tiles pulled from seed data. This is a fixed placeholder, not a real classifier — say so in a code comment at this call site.
- [x] Weigh screen: stepper in 0.5 kg increments, large numeral display
- [x] Quote screen: `weight × category.ratePerKg`, shown as a ±15% range, as a numeral, and as a simple stack of note icons; "Add another item" returns to capture and appends to the same draft lot

**Verification:** build a 2-item lot end to end — two photos, two categories, two weights — and see one combined quote for the lot.

## Milestone 4 — Match to a recycler
- [x] Write a plain haversine distance function — no package needed for five fixed points
- [x] Match screen: list the 5 seeded recyclers, sorted by a score that weighs distance and offered rate; show name, distance, an "authorised" badge, and — as the largest figure on the card — a "net in pocket" number (offered value minus an assumed transport cost proportional to distance)
- [x] Selecting a recycler moves the draft lot to `matched` and unlocks the handover screen

**Verification:** editing a recycler's rate or coordinates in the seed JSON visibly changes the ranking order.

## Milestone 5 — Handover (QR) and recycler confirm
- [x] Collector handover screen: serialize the lot (id, items, total weight, agreed price, timestamp) to JSON, render it as a QR with `qr_flutter`, show a 6-character reference code beneath it
- [x] Recycler "gate" screen: `mobile_scanner` reads the QR, decodes the payload, shows the lot for a one-tap confirm, writes a payment record marked cash-pending
- [x] Collector receipt screen: reference code, confirmation state, a "mark paid (cash)" action

**Verification:** run collector role on one device and recycler role on a second, complete a full scan-and-confirm cycle, both sides show the same reference code.

## Milestone 6 — Ledger and safety card
- [x] Ledger screen: completed lots from `shared_preferences`, a running weekly total at the top, tapping a row reads it aloud
- [x] Safety interstitial: when a lot contains a category with `hazardLevel >= 2`, show a one-screen card (icon + one line, optional TTS) before the quote screen

**Verification:** complete a lot and see it in the ledger with the correct running total; trigger the safety card with a battery-category item.

## Milestone 7 — Polish pass
- [x] Every screen follows the design tokens and the one-primary-action, 64dp-button rule
- [x] The full 7-step flow works with the device in airplane mode, confirmed by actually enabling it
- [x] Fix any crash or dead end found running the flow five times in a row
- [x] `flutter build apk --release` succeeds

**Verification:** someone who hasn't seen the app before completes one full lot, unaided, start to finish.

## Parking lot
Log anything tempting-but-out-of-scope noticed while building here instead of building it.

- (empty)
