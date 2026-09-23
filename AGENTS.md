# AGENTS.md — Kabadi Setu

## What this is
Smart India Hackathon, Problem Statement 26229 (Ministry of Mines / JNARDDC). A vernacular, offline-first Android app that lets informal e-waste collectors see a fair price, get matched to an authorised recycler, and complete a traceable handover.

This is a two-day hackathon prototype, not the production system. Read `IMPLEMENTATION_PLAN.md` before writing any code and work through it milestone by milestone — don't reorder milestones or add scope on your own judgment.

## Non-negotiables — do not violate these
- **No backend.** No Supabase, no REST API, no auth server. All data comes from bundled JSON assets (`assets/seed/*.json`) and `shared_preferences` for anything the user creates at runtime (the ledger, lots in progress).
- **The app must build and run in airplane mode, always.** If any code path makes a network call, that's a bug — remove it, don't work around it.
- **One Flutter app, one codebase.** A role toggle on the launch screen switches between "Collector" and "Recycler" views. Do not create a second app or a separate web console.
- **Keep the build green.** After every milestone, run `flutter analyze` and confirm the app still launches before starting the next one. Don't stack unverified work.
- **Stay inside scope.** If you notice a nice-to-have while building, log it under "Parking lot" in the plan file instead of building it. Scope creep is the main risk on this timeline, not missing features.
- **When unsure, stop and ask** rather than guessing. There's no time to unwind a wrong assumption.

## Stack
- Flutter (stable channel), Android only, minSdk 23.
- State: `provider` package, kept minimal — one `AppState` (ChangeNotifier) is enough. Do not introduce Riverpod, Bloc, or any DI framework.
- Persistence: `shared_preferences` for the ledger and lots the user creates. Seed data (categories, recyclers) is read-only, bundled as JSON assets — never write back to it.
- Packages: `flutter_tts`, `qr_flutter`, `mobile_scanner`, `shared_preferences`, `provider`. Don't add packages outside this list without asking first.
- No `geolocator` and no maps SDK — the demo uses five hardcoded recycler coordinates and a plain haversine function; no location permission needed.

## Design tokens
Reuse these across every screen — this palette already appears in the pitch deck, so the app and the slides should match on stage.

```
board     #1B2B26   // dark surfaces, header, launch screen
boardDeep #132019
chalk     #F1F3EC   // text on dark backgrounds
paper     #ECEEEA   // app background
card      #F7F8F4
ink       #1A231F   // primary text
inkSoft   #4E5A53   // secondary text
rule      #CBD2CB   // borders, dividers
brass     #C2911E   // accent, primary actions
signal    #2F6E4E   // success / paid states
alert     #A93325   // warnings, hazard cards
```

Type: system default sans is fine — don't spend build time on a custom font. Minimum 18sp body text. Primary action buttons full-width, 64dp tall, one per screen. Large numerals for prices and weights.

## Data shape

`assets/seed/categories.json` — 10 entries:
```json
{
  "id": "pcb_populated",
  "nameEn": "Populated PCB", "nameHi": "भरा हुआ PCB", "nameMr": "भरलेला PCB",
  "ratePerKg": 180,
  "hazardLevel": 0,
  "icon": "pcb"
}
```

`assets/seed/recyclers.json` — 5 entries:
```json
{
  "id": "r1",
  "name": "Vidarbha E-Waste Recyclers",
  "lat": 21.1458, "lng": 79.0882,
  "authorised": true,
  "pickupAvailable": true,
  "ratesByCategory": { "pcb_populated": 195 }
}
```

## UI source
Screen visuals come from Stitch (`DESIGN.md` + `STITCH_PROMPTS.md`), exported as Flutter code. Treat that export as presentational only — integrate it into the `AppState`/provider structure and seed data described above rather than replacing this project's scaffold or re-deriving the design system from scratch. If a Stitch screen conflicts with a rule in this file (state management, packages, scope), this file wins.

## Explicitly out of scope — do not build these, they belong on the roadmap slide only
- Real sync engine / offline queue reconciliation
- Cryptographic signing of handover records — the QR carries a plain JSON payload, and that's intentional, not something to "fix"
- A trained ML classifier — the category guess shown after capture is a short delay followed by 3 fixed placeholder tiles, not a model. Say so in a code comment where it's implemented.
- Live CPCB authorisation lookup
- UPI or any real payment processing
