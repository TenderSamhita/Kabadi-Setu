---
name: Field Utility
colors:
  surface: '#f8faf6'
  surface-dim: '#d8dbd7'
  surface-bright: '#f8faf6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f0'
  surface-container: '#eceeea'
  surface-container-high: '#e7e9e5'
  surface-container-highest: '#e1e3df'
  on-surface: '#191c1a'
  on-surface-variant: '#4f4535'
  inverse-surface: '#2e312f'
  inverse-on-surface: '#eff1ed'
  outline: '#817663'
  outline-variant: '#d3c5af'
  surface-tint: '#7b5900'
  primary: '#7b5900'
  on-primary: '#ffffff'
  primary-container: '#c2911e'
  on-primary-container: '#422e00'
  inverse-primary: '#f5be4a'
  secondary: '#51625c'
  on-secondary: '#ffffff'
  secondary-container: '#d4e7df'
  on-secondary-container: '#576862'
  tertiary: '#2a6a4a'
  on-tertiary: '#ffffff'
  tertiary-container: '#67a682'
  on-tertiary-container: '#003922'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdea4'
  primary-fixed-dim: '#f5be4a'
  on-primary-fixed: '#261900'
  on-primary-fixed-variant: '#5d4200'
  secondary-fixed: '#d4e7df'
  secondary-fixed-dim: '#b8cbc3'
  on-secondary-fixed: '#0f1f1a'
  on-secondary-fixed-variant: '#3a4a45'
  tertiary-fixed: '#aff1c9'
  tertiary-fixed-dim: '#94d5ae'
  on-tertiary-fixed: '#002112'
  on-tertiary-fixed-variant: '#0b5134'
  background: '#f8faf6'
  on-background: '#191c1a'
  surface-variant: '#e1e3df'
  board: '#1B2B26'
  boardDeep: '#132019'
  chalk: '#F1F3EC'
  paper: '#ECEEEA'
  card: '#F7F8F4'
  ink: '#1A231F'
  inkSoft: '#4E5A53'
  rule: '#CBD2CB'
  brass: '#C2911E'
  signal: '#2F6E4E'
  alert: '#A93325'
typography:
  display-hero:
    fontFamily: Noto Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
  display-hero-mobile:
    fontFamily: Noto Sans
    fontSize: 38px
    fontWeight: '700'
    lineHeight: 46px
  numeral-lg:
    fontFamily: Noto Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
  numeral-md:
    fontFamily: Noto Sans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
  headline-lg:
    fontFamily: Noto Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Noto Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
  body-lg:
    fontFamily: Noto Sans
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-base:
    fontFamily: Noto Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  label-primary:
    fontFamily: Noto Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  label-secondary:
    fontFamily: Noto Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 22px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.375rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system serves informal e-waste collectors operating in direct, harsh sunlight under demanding physical conditions. The aesthetic is warm, plain, and utilitarian—recalling an honest, durable co-op ledger or workshop register rather than a Silicon Valley fintech dashboard. 

The visual design eliminates all frivolous decoration: no diffuse multi-layer drop shadows, no glossy glassmorphic overlays, no tracked-out decorative uppercase subtitles, and no micro-copy paragraphs. Information hierarchy is stark, direct, and immediate. The UI is built to function under direct glare and dust, prioritizing high structural contrast, tangible touch zones, and clear visual anchoring. 

Text is accompanied by visual iconography and speech cues to empower users across varying literacy levels and languages (Hindi, Marathi, and English). Visual weight is concentrated on tangible physical metrics: kilograms, piece counts, and currency payout values.

## Colors

The palette is tuned for high outdoor contrast and reduced glare:
- **`paper` (#ECEEEA)** forms the base surface tone, replacing harsh digital white with an unbleached, paper-like matte warmth that remains readable under intense sun.
- **`card` (#F7F8F4)** provides elevated content surfaces, separated by crisp `rule` (#CBD2CB) outlines rather than fuzzy drop shadows.
- **`board` (#1B2B26)** and **`boardDeep` (#132019)** are reserved for fixed structural elements: persistent top headers, launch workflows, batch finalization, and handoff screens. When dark mode surfaces appear, **`chalk` (#F1F3EC)** supplies high-contrast legible text.
- **`brass` (#C2911E)** is the singular action color: solid, decisive, and unmistakable against dark board headers and light card surfaces alike.
- **`signal` (#2F6E4E)** indicates completed transactions, verified weigh-ins, and successful syncs.
- **`alert` (#A93325)** denotes battery/chemical hazards, critical verification warnings, and device issues—warm, brick-like, and commanding without creating panic.

## Typography

Typography relies on a unified, high-legibility sans-serif with native Devanagari support (**Noto Sans**). Every glyph is rendered with optical clarity and open counters to withstand screen glare and low-resolution Android hardware.

Key typographical rules:
1. **Absolute Minimum Size:** 18sp for base body text. Micro-text (10sp–14sp) is strictly prohibited.
2. **Numeral Dominance:** Numerical values (currency, kilogram readings, tally units) dominate screen hierarchy visually using 30sp to 48sp bold glyphs.
3. **Bilingual Pairing:** Where labels appear, English and Devanagari script (Hindi or Marathi) sit side-by-side or stacked cleanly at uniform baseline proportions.
4. **No Decorative Letter-Spacing:** Letter tracking remains natural or neutral (0) to optimize legibility for fast scanning.

## Layout & Spacing

The layout is built for handheld single-hand or two-thumb field operations on ruggedized or budget Android hardware.

- **Layout Grid:** A fluid 4-column layout on mobile devices with `16px` (1rem) side margins and `16px` gutters. Elements span 2 or 4 columns.
- **Physical Touch Target Minimums:** Every interactive element must fulfill a minimum physical boundary of `48dp × 48dp`. High-frequency inputs (category tiles, scale triggers) scale to `72dp+`.
- **Primary Sticky Footer:** Every action-oriented screen features exactly one full-width sticky or grounded primary action button that is `64dp` tall.
- **Vertical Rhythm:** Content cards stack with `space-md` (16px) separation. Internal card padding is consistently `space-md` or `space-lg`.

## Elevation & Depth

This system avoids blurred raster drop shadows, which wash out in bright sunlight and tax low-end device GPUs. Visual hierarchy and layering are established via **physical structural contrast**:

1. **Card Separation:** Elevated containers use surface color contrast (`card` #F7F8F4 placed against `paper` #ECEEEA) bordered by a crisp `1.5px` solid outline of `rule` (#CBD2CB).
2. **Deep Anchoring:** Sticky bottom action drawers and critical headers utilize solid `board` (#1B2B26) to cleanly frame and contrast the workspace.
3. **Active/Pressed States:** Rather than soft shadow elevations, tapping a card or button transitions the border to a `2px` solid highlight (`brass` or `ink`) or swaps the background to an inset dark tone, providing tactile, instantaneous feedback.

## Shapes

The interface embraces a disciplined, soft-geometric architecture (`roundedness: 1`). Corners are neither razor-sharp nor pill-shaped:

- Standard cards, tiles, and input containers have a corner radius of `6px` to `8px`.
- Large bottom action buttons use a subtle `8px` corner radius or sit flush (`0px`) against the screen edges.
- Audio trigger buttons and utility badges feature slightly rounder contours (`8px` to `12px`), maintaining a consistent, sturdy, tool-like footprint.

## Components

### Primary Action Button
- **Height & Width:** Exactly 64dp tall, full width (minus 16dp outer margins or docked flush to viewport bottom).
- **Style:** Solid `brass` (#C2911E) background with `ink` (#1A231F) or `boardDeep` (#132019) bold 20sp typography.
- **Content:** Large icon (28dp) + clear bilingual text (e.g., "वज़न जोड़ें / ADD WEIGHT").
- **Pressed State:** Darkens to high-contrast deep brass (#9D7414).

### Category & Tally Tiles
- **Grid Layout:** 2 columns of large square/rectangular touch cards (minimum 96dp height).
- **Contents:** Heavy vector icon (40dp), primary numeral readout (32sp), short bold bilingual label.
- **Border:** `1.5px` solid `rule` (#CBD2CB) on `card` (#F7F8F4) background.

### Audio Cue Buttons
- **Purpose:** Positioned adjacent to any price, weight, scrap classification, or vendor name to trigger text-to-speech voice playback in Hindi/Marathi.
- **Appearance:** A compact 48dp × 48dp tactile button featuring a high-contrast speaker icon in `ink` (#1A231F) with a subtle `rule` border and active brass feedback state.

### Input Fields (Weight & Rate)
- **Structure:** Solid `card` (#F7F8F4) background, 60dp minimum field height, surrounded by a 2px `rule` border. On focus, border deepens to `board` (#1B2B26).
- **Numerals:** Large 32sp digits centered or right-aligned. Unit indicators ("किलो / KG", "₹") are locked into the field in bold 20sp.

### Hazard & Alert Banners
- **Style:** Solid background in `alert` (#A93325) or card with a thick 4px left alert accent bar.
- **Typography:** `chalk` (#F1F3EC) text on dark backgrounds or `alert` text paired with high-contrast warning icons.

### Offline Status Strip
- **Position:** Docked below top navigation bar.
- **Styling:** Inset `board` background with clear signal indicators showing offline cache status and pending sync count.