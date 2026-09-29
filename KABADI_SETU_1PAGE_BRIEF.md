# Kabadi Setu (कबाडी सेतू) — 1-Page Master Briefing
**Smart India Hackathon | PS 26229 | Ministry of Mines & JNARDDC**
*Theme: Circular Economy, Secondary Raw Material & Critical Mineral Recovery from E-Waste*

---

### 1. The Crisis & The Human Hook
- **The Reality**: India generates **3.2 MT** of e-waste/year; **78%** is trapped in the unorganized informal sector.
- **The Story (Raju's Dilemma)**: Raju collects 5 kg of populated PCBs. The local scrap middleman pays him **₹30/kg (₹150)** and burns them in open acid. A CPCB-certified recycler 4 km away offers **₹195/kg (₹975)** with eco-safe hydrometallurgical recovery. Raju loses ₹825 because no one gave him a price board.
- **The Core Mission**: Eliminate predatory middlemen, safeguard collector health, and channel critical minerals (Gold, Copper, Lithium) directly into formal refineries.

---

### 2. The Solution & Key Pillars
| Feature | What It Does | Why the Jury Cares |
|---|---|---|
| **Vernacular Audio Rate Board** | Daily floor rates for 10 categories; speaks in **Marathi, Hindi, English** via native TTS. | Eliminates illiteracy barriers for 1.5M informal workers. |
| **Hazard Interstitial Screen** | Auto-blocks flow with a red hazard protocol if item has hazard rating $\ge 2$ (Li-ion, CRT). | Occupational health compliance & fire prevention. |
| **Fair Price Comparison** | Side-by-side comparison: Local Dealer Estimate (55%) vs. Authorised Recyclers with green **"+ ₹X Gain"** callout. | Transparent price discovery that proves immediate economic uplift. |
| **Air-Gapped Handover QR** | Encodes entire manifest (`lotId`, items, weight, value) into a standard 2D QR; decoded at recycler gate scanner. | **Zero-network proof of custody** and instant digital receipt (#KS-XXXX). |
| **Air-Gapped Rate Card QR** | Recyclers edit buy-rates and export a QR; collectors scan it to update local floor rates offline. | Dynamic price distribution without internet, SMS, or servers. |
| **Circular Impact Accounting** | Converts lot weight into **g Copper, mg Gold/Silver, and kg $\text{CO}_2$ offsets** on receipts. | Direct alignment with **National Critical Minerals Mission**. |

---

### 3. Architecture, Tech Stack & Feasibility
- **100% Offline-First (Airplane Mode)**: Zero backend, zero cloud latency, zero database locking. Built for network-dead scrap yards and basements.
- **Tech Stack**: **Flutter / Dart**, **Provider** (`AppState` single source of truth), **`shared_preferences`** (local ledger & rate overrides), **`flutter_tts`** (offline speech), **`mobile_scanner` & `qr_flutter`** (QR transport layer).
- **Lightweight & Stable**: MinSdk 23 (Android 6.0+), **65.9 MB Release APK**, **0 issues on `flutter analyze`**.

---

### 4. Viability, EPR & Measurable Impact
- **Financial Viability**: **₹0.00 infrastructure cost**. No servers, cloud databases, or SMS gateways.
- **EPR Alignment**: Enables Producer Responsibility Organisations (PROs) under **E-Waste Rules 2022** to audit and verify informal chain-of-custody data to meet annual recycling quotas.
- **Scale Impact**: Diverting just 20% of informal scrap to formal channels secures **~₹5,000 Cr/yr** in secondary raw materials and prevents hundreds of tons of toxic lead/mercury emissions.

---

### 5. Claude Pitch Deck Prompt (Copy-Paste Ready)
```text
Act as an elite pitch coach. Create a 10-slide high-impact presentation for "Kabadi Setu" (SIH PS 26229 — Ministry of Mines / JNARDDC). It is a 100% offline-first vernacular Android app (Flutter) bridging 1.5M informal e-waste collectors to CPCB-authorised recyclers without internet, using dynamic QR codes as the transport layer. Features: Vernacular TTS Rate Board (Marathi/Hindi), Hazard Interstitial Safety Cards, Fair Price Comparison (+₹ Gain vs middlemen), Gate Pass QR Scanner, Recycler Offline Rate Card broadcast, and JNARDDC Critical Minerals Accounting (Gold, Copper, CO2). For each slide provide: 1) Punchy Title, 2) Visual Layout, 3) 3-4 Bullet points, 4) 30-sec Speaker Script, 5) Tough Jury Trap Q&A Defense.
```
