# LENS Mobile Marketplace — Design System & Implementation Guide

```yaml
name: LENS Mobile Marketplace
colors:
  surface: '#f9f9fa'
  surface-dim: '#dadadb'
  surface-bright: '#f9f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f4'
  surface-container: '#eeeeef'
  surface-container-high: '#e8e8e9'
  surface-container-highest: '#e2e2e3'
  on-surface: '#1a1c1d'
  on-surface-variant: '#5b4137'
  inverse-surface: '#2f3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#907065'
  outline-variant: '#e4beb1'
  surface-tint: '#a83900'
  primary: '#a83900'
  on-primary: '#ffffff'
  primary-container: '#ff5a00'
  on-primary-container: '#511700'
  inverse-primary: '#ffb59a'
  secondary: '#5f5e60'
  on-secondary: '#ffffff'
  secondary-container: '#e5e1e4'
  on-secondary-container: '#656466'
  tertiary: '#5d5e66'
  on-tertiary: '#ffffff'
  tertiary-container: '#91919a'
  on-tertiary-container: '#292a32'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcf'
  primary-fixed-dim: '#ffb59a'
  on-primary-fixed: '#380d00'
  on-primary-fixed-variant: '#802900'
  secondary-fixed: '#e5e1e4'
  secondary-fixed-dim: '#c8c6c8'
  on-secondary-fixed: '#1c1b1d'
  on-secondary-fixed-variant: '#474649'
  tertiary-fixed: '#e3e1ec'
  tertiary-fixed-dim: '#c6c5cf'
  on-tertiary-fixed: '#1a1b22'
  on-tertiary-fixed-variant: '#46464e'
  background: '#f9f9fa'
  on-background: '#1a1c1d'
  surface-variant: '#e2e2e3'
typography:
  display:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.025em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.015em
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.03em
  price-display:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '800'
    lineHeight: 24px
    letterSpacing: -0.02em
rounded:
  sm: 0.5rem # 8px
  DEFAULT: 1rem # 16px
  md: 1.25rem # 20px (Cards)
  lg: 1.5rem # 24px (Large Cards, Bottom Sheet)
  full: 9999px # Buttons, Chips, Pills
spacing:
  gutter: 1rem # 16px
  gutter-sm: 0.75rem # 12px (Portfolio 2-col Grid)
  margin: 1rem # 16px
  space-xs: 0.25rem # 4px
  space-sm: 0.5rem # 8px
  space-md: 1rem # 16px
  space-lg: 1.5rem # 24px
  space-xl: 2rem # 32px
```

---

## 1. Brand & Style

This design system is tailored for a high-end photography booking and portfolio platform on mobile touchpoints. It pairs the exacting utility of iOS Human Interface Guidelines with the tactile warmth of marketplace leaders.

### Personality & Tone
- **Curated & Authoritative:** The interface serves as an unobtrusive exhibition frame, allowing high-resolution imagery to lead while maintaining strict typographic structure.
- **Immediate & Fluid:** Interactions are swift, frictionless, and responsive.
- **Warm Tactility:** Crisp hairline borders, glassmorphic floating overlays, and deep burnt-orange accents create a premium physical sensation.

---

## 2. Palette Architecture

The palette is deliberately restrained to highlight photography without competitive color noise.

| Token Name | Hex Code | Flutter Constant | Primary Role |
| :--- | :--- | :--- | :--- |
| **Primary Accent (Ember)** | `#FF5A00` | `AppColors.ember` | Primary action buttons, focused states, booking confirmations, active navigational pips. Must never be used for large backgrounds. |
| **Primary Text (Obsidian)** | `#09090B` | `AppColors.obsidian` | Deep neutral black for titles, primary body copy, and high-emphasis icons. |
| **Secondary Text (Steel)** | `#71717A` | `AppColors.steel` | Mid-tone neutral for metadata, timestamps, camera specs, subtitles. |
| **Canvas Base (Mist)** | `#F4F4F5` | `AppColors.mist` | Soft off-white backdrop that prevents eye strain. |
| **Sub-canvas (Fog)** | `#ECECEE` | `AppColors.fog` | Segmented control tracks, search field fills, structural grouping blocks. |
| **Surface (Snow / White)** | `#FFFFFF` | `AppColors.snow` | Surface cards, bottom sheets, modals. |
| **Borders (Pebble)** | `#D4D4D8` | `AppColors.pebble` | 1px subtle hairline borders across all cards, separators, and segmented states. |
| **Verified (Emerald)** | `#16A34A` | `AppColors.emerald` | Verified badges, confirmed bookings, escrow release badges. |
| **Destructive (Crimson)** | `#DC2626` | `AppColors.crimson` | Cancellations, destructive actions, error states. |

### Frosted Translucency (Glassmorphism)
All glassmorphism effects must use `BackdropFilter` with `GlassContainer`:
- **Header & Tab Bar:** `rgba(255, 255, 255, 0.8)` with `backdrop-filter: blur(20px)` and hairline border of `rgba(212, 212, 216, 0.6)` (`GlassContainer.translucentBar`).
- **Media Floating Badges:** `rgba(9, 9, 11, 0.48)` with `backdrop-filter: blur(12px)` and text in Pure White (`GlassContainer.mediaBadge`).
- **Floating Controls (Back, Heart, Share):** Glass frost `rgba(255, 255, 255, 0.75)` or dark `rgba(9, 9, 11, 0.5)`, with `backdrop-filter: blur(16px)` and inner 1px border (`GlassContainer.floatingControl`, min 44x44px).

---

## 3. Typography & Numbers

All typographic roles use Google Font **Inter** via `AppTypography`:
- **Numbers & Metrics:** Hourly rates, prices, ratings, focal lengths, aperture values MUST use `fontFeatures: [FontFeature.tabularFigures()]` (`AppTypography.priceDisplay` or `AppTypography.numeric`) for vertical scanning.
- **Letter Spacing:** Headlines must use tight negative tracking (`-0.03em` down to `-0.015em`).

---

## 4. Shapes & Geometry

- **Buttons & Chips:** Pill-shaped (`borderRadius: BorderRadius.circular(9999)` / `AppTokens.pillRadius`).
- **Cards & Media Tiles:** `20px` to `24px` (`AppTokens.cardRadius`, `AppTokens.largeCardRadius`).
- **Bottom Sheets & Floating Panels:** `24px` on top corners (`AppTokens.bottomSheetRadius`).
- **Nested Inner Badges:** `12px` (`AppTokens.nestedBadgeRadius`).

---

## 5. Elevation & Depth

> **Rule:** Depth is established primarily through hairline borders (`1px solid #D4D4D8`) and blurred translucent planes, NOT heavy drop shadows!

- **Level 0 (Base Canvas):** Background `#F4F4F5`, completely flat.
- **Level 1 (Surface Cards):** `#FFFFFF` surface enclosed by a 1px border of `#D4D4D8`. Ambient shadow: `AppTokens.surfaceShadow` (`0 1px 3px rgba(0, 0, 0, 0.04)`).
- **Level 2 (Interactive Floating Controls):** Glassmorphic frost with `blur(16px)`.
- **Level 3 (Modals & Bottom Sheets):** `#FFFFFF` surfaces with `AppTokens.modalShadow` (`0 -8px 32px rgba(0, 0, 0, 0.08)`).

---

## 6. Components Standard

### 1. Primary Action Buttons (`PrimaryButton`)
- Height: `52px` (`AppTokens.primaryButtonHeight`).
- Shape: Pill-shaped (`9999px`).
- Background: Solid Ember (`#FF5A00`), text in White (`#FFFFFF`).
- Micro-interaction: Active tap feedback scales to `0.97` with `transition: 0.15s ease`.

### 2. Secondary Action Buttons
- Height: `52px` (or `46px` compact).
- Shape: Pill-shaped (`9999px`).
- Background: Pure White (`#FFFFFF`), 1px Pebble (`#D4D4D8`) border, Obsidian (`#09090B`) text.

### 3. Filter Chips
- Height: `36px` (`AppTokens.filterChipHeight`), `rounded-full` (9999px).
- Default / Unselected: Fog (`#ECECEE`) background with Steel (`#71717A`) text.
- Selected: Obsidian (`#09090B`) background with White (`#FFFFFF`) text, or Ember (`#FF5A00`) for active date ranges.

### 4. Search Bar
- Height: `48px` (`AppTokens.searchBarHeight`), Pill-shaped (9999px).
- Default: Fog (`#ECECEE`) background, transparent border, Steel search icon (`#71717A`).
- Focused: White (`#FFFFFF`) background, 1px Pebble border (`#D4D4D8`).

### 5. Bottom Booking Bar
- Pinned bottom bar with frosted background (`rgba(255, 255, 255, 0.85)` + `backdrop-filter: blur(20px)`), 1px solid `#D4D4D8` top boundary.
- Rate breakdown on the left (with tabular figures) and 52px Ember pill button on the right.
- Insets strictly follow: `MediaQuery.of(context).padding.bottom + 12px`.
