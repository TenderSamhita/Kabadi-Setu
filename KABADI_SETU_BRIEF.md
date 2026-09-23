# Kabadi Setu — Complete App Brief
### Smart India Hackathon 2024 | Problem Statement 26229 | Ministry of Mines / JNARDDC

---

## 🧵 The Story — Meet Raju

> *It's 7 AM in Nagpur's Beltarodi colony. Raju Meshram straps a 40-kg gunny sack onto his cycle-rickshaw and starts his rounds. By noon he has collected three types of e-waste — old circuit boards, tangled cables, and a busted laptop. He stops at the local scrap dealer.*
>
> *"Yeh sab? Teen sau rupaiye." (All this? ₹300.)*
>
> *Raju doesn't know that a certified recycler 4 km away would have paid him ₹820 for the same lot — and that the PCB boards he sold for ₹30 contain recoverable gold worth ₹180/kg. He doesn't know, because no one told him. There is no app. There is no price board. There is only the middleman, and the middleman always wins.*
>
> *Kabadi Setu is built for Raju.*

---

## 👥 Who Is Whom — The Three Roles

```
┌─────────────────────────────────────────────────────────────────┐
│                     E-WASTE VALUE CHAIN                          │
│                                                                   │
│  [Household]──►[Informal Collector]──►[Middleman]──►[Recycler]  │
│                        RAJU              (cut)       VIDARBHA    │
│                                                                   │
│  Kabadi Setu REMOVES the middleman and connects Raju directly    │
│  to the authorised recycler with full price transparency.        │
└─────────────────────────────────────────────────────────────────┘
```

### 🧑‍🔧 Role 1 — Informal Collector (Kabadiwala)
**Who:** Raju and ~1.5 million like him across India's towns and cities.
**Pain:** No price information, no proof of handover, no access to authorised recyclers, paid far below fair value, exposed to hazardous materials without safety warnings.
**What the app gives them:**
- Live rate board in their language (Marathi / Hindi)
- Voice readout of prices (TTS) — works even if they can't read
- Photo-capture → AI-stub category guess → weight → fair price quote
- QR-based handover record = their first ever digital receipt
- Ledger = running weekly income tracker

### 🏭 Role 2 — Authorised Recycler (Depot)
**Who:** CPCB-registered e-waste processors like Attero, E-Parisaraa, Eco Recycling Ltd.
**Pain:** Informal collectors sell to middlemen. Recyclers get low volumes, can't trace origin of material, can't prove chain of custody to auditors.
**What the app gives them:**
- QR gate scanner — one-tap lot confirmation
- Traceable handover record with reference code
- Can broadcast updated buy-prices to collectors via Rate Card QR — no internet needed
- Digital ledger of all intakes

### 🏛️ Role 3 — Regulator / Ministry (Background)
**Who:** Ministry of Mines, JNARDDC, CPCB, State Pollution Control Boards.
**Pain:** India generates ~3.2 MT of e-waste/year. Only ~22% reaches authorised recyclers. The rest is processed informally — burning cables, acid-washing PCBs — releasing lead, mercury, cadmium.
**What the app enables (roadmap):** A verifiable, traceable chain of custody from collector → recycler → processor. Every QR handover is a data point that can feed compliance dashboards.

---

## 🎯 Problem Statement — The Three Gaps

| Gap | Description | Kabadi Setu's Answer |
|-----|-------------|---------------------|
| **Information Gap** | Collectors don't know fair prices | Rate Board + TTS price readout |
| **Trust Gap** | No proof of handover — disputes common | QR handover → 6-char reference code |
| **Access Gap** | Collectors don't know which recyclers are authorised | Recycler match screen with CPCB badge + distance score |

---

## 📱 Tech Stack

```
┌──────────────────────────────────────────────────────────┐
│                    KABADI SETU APK                        │
│                                                           │
│  Language:  Dart (Flutter stable channel)                 │
│  Platform:  Android only, minSdk 23 (Android 6.0+)       │
│                                                           │
│  ┌─────────────────────────────────────────────────┐     │
│  │              UI LAYER (Flutter Widgets)          │     │
│  │  14 screens • design tokens • 64dp buttons       │     │
│  └────────────────────┬────────────────────────────┘     │
│                        │                                   │
│  ┌─────────────────────▼──────────────────────────┐      │
│  │           STATE LAYER (Provider / ChangeNotifier)│     │
│  │  AppState — single source of truth               │     │
│  │  • categories, recyclers (seed)                  │     │
│  │  • draftLot, ledger                              │     │
│  │  • rateOverrides (from QR or recycler edit)      │     │
│  └────────────────────┬────────────────────────────┘     │
│                        │                                   │
│  ┌─────────────────────▼──────────────────────────┐      │
│  │           PERSISTENCE LAYER                      │     │
│  │  shared_preferences: ledger, rate overrides       │     │
│  │  assets/seed/*.json: categories, recyclers (RO)  │     │
│  └─────────────────────────────────────────────────┘     │
│                                                           │
│  KEY PACKAGES                                             │
│  • provider          — state management                   │
│  • shared_preferences— local persistence (no network)    │
│  • flutter_tts       — voice readout (accessibility)     │
│  • qr_flutter        — QR code generation                │
│  • mobile_scanner    — QR code scanning                  │
└──────────────────────────────────────────────────────────┘
```

### Why Flutter?
- **Single codebase** for the two roles (collector + recycler) — one APK, one role toggle
- **Offline by design** — Flutter apps are self-contained; no CDN, no runtime fetches
- **Dart is fast** — 60 fps UI even on low-end Android devices (the target demographic uses ₹5,000–₹8,000 phones)
- **Accessibility built-in** — TTS integration with `flutter_tts` works with system language packs already on the device

---

## 🏗️ Architecture

### Offline-First Principle
```
                Network = NEVER USED
                        │
          ┌─────────────┴─────────────┐
          │       DATA SOURCES        │
          │                           │
          │  assets/seed/             │
          │    categories.json  ──►   │  Read-only at startup
          │    recyclers.json   ──►   │  Bundled in APK
          │                           │
          │  shared_preferences ──►   │  Read/Write at runtime
          │    kabadi_ledger_v1       │  Lot history
          │    kabadi_recycler_rates  │  Recycler price overrides
          │    kabadi_category_rates  │  Floor rate overrides (from QR)
          └───────────────────────────┘
```

### State Flow — Collector Journey
```
LaunchScreen (language)
    │
    ▼
RoleScreen (collector / recycler toggle)
    │
    ▼
CollectorHomeScreen ──► Rate Board (grid of 10 categories)
    │                        │
    │                        └─ tap tile → TTS speaks price
    │                        └─ scan icon → Rate Card QR scan
    │
    ▼
CaptureScreen (camera photo)
    │
    ▼
CategoryGuessScreen
    │  [PLACEHOLDER — not a real ML model, by design]
    │  Shows 1.2s loading, then 3 fixed category tiles
    │
    ▼
SafetyInterstitialScreen (only if hazardLevel ≥ 2)
    │
    ▼
WeighScreen (stepper, 0.5 kg steps)
    │
    ▼
QuoteScreen (weight × rate, ±15% range, note-stack visual)
    │
    ▼
RecyclerMatchScreen (haversine sort + rate score)
    │
    ▼
HandoverScreen (QR with lot JSON payload)
    │
    ▼
ReceiptScreen (reference code, mark paid)
    │
    ▼
LedgerScreen (weekly total, history)
```

### State Flow — Recycler Journey
```
RecyclerHomeScreen ──► Intake stats (weight, lots, cash pending)
    │
    ├──► [Update My Rates] ──► RateEditorScreen
    │                               │
    │                               ▼
    │                          RateCardQrScreen
    │                          (QR for collector to scan)
    │
    └──► [Open Gate Scanner] ──► RecyclerGateScreen
                                     │
                                     ▼
                                 mobile_scanner detects QR
                                     │
                                     ▼
                                 One-tap confirm → ledger entry
```

### Price Update Architecture (New Feature)
```
RECYCLER PHONE                      COLLECTOR PHONE
─────────────────                   ─────────────────
RateEditorScreen                    CollectorHomeScreen
     │                                      │
     │ adjusts rates                        │ taps scan icon
     │ via ± steppers                       │
     ▼                                      ▼
AppState                            _RateCardScanPage
.updateRecyclerRates()              (MobileScanner)
     │                                      │
     ▼                                      │ detects QR
shared_preferences                         │ reads JSON payload
(kabadi_recycler_rates_v1)                │ checks type == "rate_update"
     │                                      │
     ▼                                      ▼
RateCardQrScreen                    AppState
(qr_flutter encodes:                .applyRateUpdateFromQr()
 {type: "rate_update",                      │
  recyclerId: "r1",                         ▼
  rates: {pcb: 210, ...},          shared_preferences
  effectiveFrom: ISO8601})         (kabadi_category_rates_v1)
                                            │
         ← Collector scans QR →            ▼
                                   Rate board refreshes
                                   "Updated" badge on tiles
```

**Zero network calls. QR code is the transport layer.**

---

## ✅ Feasibility

| Question | Answer |
|----------|--------|
| Can it be built? | **Yes — it already runs.** Release APK: 65.8 MB |
| Does it work offline? | **Yes — tested in airplane mode** |
| Low-end device support? | minSdk 23 = Android 6.0 (2015). Runs on ₹5,000 phones |
| Literacy not required? | **Yes — TTS reads every price aloud** in Marathi/Hindi |
| Camera required? | Yes — virtually all Android phones since 2016 have one |
| Internet during handover? | **No** — entire flow is local. QR = physical data transfer |
| Training required for collector? | Minimal — 4-step flow, large fonts, one primary button per screen |

---

## 💰 Viability

### Why it survives after the hackathon

**Short term (Government pilot):**
- JNARDDC / Ministry of Mines can distribute the APK via state-run kiosks or WhatsApp broadcast to existing kabadiwala networks
- No server cost. No cloud bill. Zero infrastructure overhead.
- Works on any Android phone a collector already owns

**Medium term (PRO ecosystem integration):**
- India's E-Waste Management Rules (2022) mandate Producer Responsibility Organisations (PROs) to collect e-waste targets
- PROs currently struggle to source from informal channels
- Kabadi Setu gives PROs a direct, traceable, digitally-receipted supply chain to collectors
- PROs pay per kg collected — app provides the weight + handover proof they need

**Long term (Revenue model options):**
| Model | Who pays | For what |
|-------|----------|----------|
| PRO subscription | Producer/PRO | Access to verified collector network + handover data |
| Recycler listing | Authorised recycler | Premium placement in match screen |
| Government grant | JNARDDC / MeitY | Deployment to underserved districts |

---

## 🌍 Impact & Benefits

### Environmental Impact
- **E-waste diverted from informal processing** — every ton of PCBs processed formally vs. informally prevents ~1.3 kg of lead from entering soil (Basel Action Network, 2019)
- **Hazard warnings built in** — Li-ion batteries and CRT glass show a mandatory safety card before the collector handles them
- **Traceable chain of custody** — each QR handover is a digital record; aggregated, this becomes audit data for CPCB compliance reports

### Economic Impact for Collectors
- A collector selling PCBs at ₹30/kg (middleman rate) vs ₹180/kg (authorised recycler rate) = **6× income increase** on that material
- Weekly ledger helps collectors plan — know when to hold, when to sell
- Reference code = first ever proof of work/income for credit access

### Social Impact
- **Language inclusivity** — Marathi and Hindi, with TTS for low-literacy users
- **Dignity** — a digital receipt transforms an informal transaction into a documented one
- **Safety** — hazard interstitials are likely the only safety information most collectors ever receive

### Scale Potential
```
India's informal e-waste collectors:  ~1.5 million people
Annual e-waste generated (India):     ~3.2 million tonnes (2023)
Currently reaching authorised recyclers: ~22%
If Kabadi Setu moves this to 40%:    ~576,000 additional tonnes formalised
Value of additional formalised waste: ~₹4,000–₹8,000 crore / year
```

---

## 📚 Research & References

| # | Fact used in app | Source |
|---|-----------------|--------|
| 1 | India generates ~3.2 MT e-waste/year | CPCB Annual Report on E-Waste 2022–23 |
| 2 | Only ~22% reaches authorised recyclers | Global E-Waste Monitor 2024, ITU/UNITAR |
| 3 | ~1.5 million informal e-waste workers in India | Toxics Link, "E-Waste in India" (2019) |
| 4 | PCB boards contain 200–400g gold per tonne | UNEP, "Recycling — From E-Waste to Resources" (2009) |
| 5 | Informal processing releases lead, mercury, cadmium | WHO Report on e-waste and child health (2021) |
| 6 | E-Waste Management Rules 2022 (PRO mandate) | MoEFCC Gazette Notification, Nov 2022 |
| 7 | Haversine formula for distance calculation | Sinnott, R.W., "Virtues of the Haversine", Sky and Telescope (1984) |
| 8 | ±15% price range reflects real scrap market variance | Field interviews, Toxics Link Delhi scrap market study (2021) |
| 9 | QR codes as offline data transfer for low-connectivity settings | UIDAI Offline Aadhaar QR specification (2019) — same principle |
| 10 | Vernacular TTS effectiveness for low-literacy users | MIT Media Lab — "Voice-based interfaces for low-literacy users in India" (2018) |

---

## 🔑 Design Decisions — Explained

### "Why no backend at all?"
The target user (a kabadiwala in rural Maharashtra) may have **2G connectivity or none**. A backend dependency would mean the app fails exactly when and where it's needed most. The offline-first constraint isn't a limitation — it's a feature.

### "Why QR for price updates instead of a broadcast?"
- Requires zero infrastructure (no FCM, no server)
- The physical act of scanning creates a **trust moment** — the collector chooses to accept the recycler's rate, not have it pushed silently
- Works at 0 kbps
- The QR is also a natural demo moment on stage

### "Why TTS?"
NSSO data (2017–18) shows ~25% of India's urban informal workers have below-secondary literacy. A rate board that can only be *read* excludes a quarter of the target users. Speaking the price aloud removes that barrier entirely.

### "Why one ChangeNotifier instead of Riverpod/Bloc?"
Complexity budget. This is a 2-day hackathon prototype. A single `AppState` with `notifyListeners()` is auditable in minutes. Riverpod or Bloc would add indirection with zero benefit at this scale.

---

## 🎤 One-Line Pitch

> **"Kabadi Setu gives India's 1.5 million informal e-waste collectors a price board, a fair match, and a digital receipt — entirely offline, in their own language."**

---

*Built for SIH 2024 | Problem Statement 26229 | Ministry of Mines / JNARDDC*
*Flutter · Android · Offline-First · No Backend · Open for Government Deployment*
