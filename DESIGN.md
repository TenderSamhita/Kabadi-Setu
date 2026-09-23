# DESIGN.md — Kabadi Setu

## Product
Offline-first Android app for informal e-waste collectors (SIH PS 26229). Primary users have low literacy and are often working outdoors in bright sunlight. Every screen must be usable primarily through icons, large numerals, and voice — text is secondary, never the only carrier of meaning.

## Palette
- `board` #1B2B26 — dark surfaces, headers, the launch/handover screens
- `paper` #ECEEEA — app background
- `card` #F7F8F4 — cards, tiles
- `ink` #1A231F — primary text
- `inkSoft` #4E5A53 — secondary text
- `brass` #C2911E — accent, primary actions, highlights
- `signal` #2F6E4E — success / paid / confirmed states
- `alert` #A93325 — warnings, hazard cards (warm red, not alarm red)

## Typography
One system sans-serif family throughout — no display/serif pairing needed. Minimum 18sp for any body text. Large, bold numerals (32–48sp) for any price, weight, or count — these are the most important information on the screen and should dominate visually over labels.

## Layout rules
- Exactly one primary action per screen: full-width, minimum 64dp tall, high contrast (brass on dark, or dark ink on paper).
- Icon + short label together, always — never an icon alone, never text alone, on any tappable element.
- Any number or name that matters (a price, a recycler name, a category) sits next to a small speaker icon.
- Generous spacing, minimum 48dp tap targets, moderate corner radius on cards — not fully rounded/pill-shaped.
- No dense text blocks, no paragraphs. Short phrases only. Devanagari script (Hindi/Marathi) alongside English where a label appears.

## Tone
Warm and plain, like a well-run co-op counter — not a fintech dashboard. Avoid generic SaaS visual defaults: no soft drop shadows on every card, no gradient washes, no all-caps labels, no tracked-out eyebrow text above headings.
