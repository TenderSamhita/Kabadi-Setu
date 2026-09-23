# Stitch prompts — Kabadi Setu

## How to use this

1. Go to Stitch, start **one new project** for the whole app — generating every screen inside the same project is what keeps them visually consistent. Separate projects will drift.
2. Paste the full contents of `DESIGN.md` as your first message, before any screen prompt, so the system locks in before anything else gets generated.
3. Work through the prompts below in order. After each one, you can refine with a short follow-up ("make the price bigger", "move the button down") rather than regenerating from scratch.
4. Once the core screens exist, use Stitch's screen-linking / flow view to connect them and hit Play to sanity-check the sequence.
5. Export: open the export dialog and look for an **Antigravity** option (one-click handoff). If it's not there under that exact label, use **MCP** or the **AI Studio** share link — both open into Antigravity.
6. When you hand off, tell Antigravity explicitly: *"Integrate this UI into the existing `AppState`/provider structure from AGENTS.md — don't replace the project scaffold."* Stitch's export is presentational; your agent still needs to wire it to state, seed data, and navigation per `IMPLEMENTATION_PLAN.md`.

★ = highest priority — these are the screens judges will actually see live. Spend your refinement time here first.

---

### 1. Launch / language screen
> Launch screen for an Android app called Kabadi Setu. Full-bleed dark green background. Centered near the top, a simple line-art icon combining a recycling arrow and a handshake — no wordmark, no logo text. Below it, two large full-width buttons stacked vertically: one showing "मराठी", one showing "हिंदी", each with a small speaker icon on the right edge. Nothing else on screen.

### 2. Role toggle screen
> Screen shown right after language selection, for choosing a role. Same dark green background. Two large square tiles side by side, each about half the screen width: one with a simple hand-cart/collector icon and the label "Collector", the other with a warehouse/scale icon and the label "Recycler". Equal visual weight, a brass border on the selected state.

### 3. ★ Collector home — rate board
> Home screen for a collector, styled like a painted rate-board outside a scrap shop. Light background. A 2-column grid of 10 square tiles. Each tile shows: a simple line-icon for a material type (PCB, cable, battery, CRT glass, motor, mixed plastic, LCD panel, lead-acid battery, bare board, mixed cable), the material name in Devanagari script, a large bold price per kilogram, and a tiny 7-day trend arrow (up or down). Each tile has a small speaker icon in its corner. One full-width dark button fixed at the bottom: "Add material" with a camera icon, brass background.

### 4. Capture screen
> Full-screen camera viewfinder for photographing scrap material. A rounded rectangular framing guide centered on screen. A single large circular shutter button at the bottom center, brass. Small back arrow top-left. Minimal chrome.

### 5. Analyzing / category guess screen
> Screen shown right after taking a photo of scrap material. Top third shows the captured photo as a thumbnail. Below it, 3 large square tiles side by side, each with a material icon and a bilingual label (for example "Cable / तार"), with the first tile highlighted by a brass border as the suggested match. Below the 3 tiles, a smaller link-style row: a grid icon with "more options" for expanding to all categories.

### 6. Weigh screen
> Weight-entry screen. Center of the screen: an oversized numeral showing kilograms, for example "4.5 kg", taking up a large share of the vertical space. Below it, a horizontal stepper — a large brass minus button on the left, a large brass plus button on the right, the numeral between them. Below that, a row of 3 small pill-shaped shortcut chips: "2 kg", "5 kg", "10 kg". A floating microphone icon button in the bottom right. One full-width confirm button at the very bottom.

### 7. ★ Quote / value screen
> Value screen shown after weighing scrap. A large bold rupee range at the top center, for example "₹840–₹960", shown as a range rather than one number. Below it, a simple flat illustration of a small stack of banknotes. Below that, a short line-item list showing 2–3 materials with their individual sub-values. A speaker icon beside the top price. One full-width button at the bottom: "Find a recycler" with a location-pin icon.

### 8. ★ Match / recycler list screen
> List screen with 3–5 recycler cards stacked vertically on a light background. Each card shows: recycler name, a small green "authorised" checkmark badge, distance in kilometres, and — as the single largest number on the card — a "you keep" rupee figure after transport. Cards with pickup available show a small truck icon. Thin borders on cards, no heavy drop shadows. The top match is subtly highlighted.

### 9. ★ Handover screen (collector side)
> Full-screen handover screen, dark green background. A large QR code centered on a white card. Below the QR, a 6-character reference code in extra-large numerals. One short line of instruction text beneath, small type. A soft brass glow around the QR card suggesting "ready to scan".

### 10. Recycler gate / scan screen
> Scanner screen for the recycler role. Full-screen camera view with a square scan-target overlay in the center, brass corner brackets. A bottom sheet beneath the viewfinder reading "waiting for scan". Minimal and utilitarian.

### 11. Receipt / confirmation screen
> Confirmation screen after a successful handover. A large green checkmark inside a circle, centered. Below it, the 6-character reference code repeated, and the final rupee amount in large numerals. Two stacked buttons at the bottom: a primary brass button "Mark paid (cash)" and a secondary outlined button "Share receipt" with a share icon.

### 12. Ledger screen
> Earnings/ledger screen. At the top, a large card showing the current week's running total in rupees, brass accent. Below it, a reverse-chronological list of past transactions — each row a small material icon, weight, amount, and either a green checkmark or an amber clock for pending payment. A small speaker icon on each row.

### 13. Safety interstitial
> Full-screen safety card shown as an interruption before continuing. Warm alert-red accent, not alarm red. One large simple pictogram illustrating a single hazard, for example a battery with a "do not puncture" symbol. One short sentence of instruction beneath. A single full-width button at the bottom: "Got it, continue".
