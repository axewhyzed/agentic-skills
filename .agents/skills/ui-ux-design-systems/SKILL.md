---
name: ui-ux-design-systems
description: >-
  Comprehensive operational framework and design intelligence for modern UI/UX design,
  design systems, visual hierarchy, design tokens, component architecture, high-density financial
  terminal aesthetics, accessibility (WCAG 2.2 AAA/AA), mobile ergonomics, data visualization,
  and complete interface revamps. Use this skill whenever auditing, designing, refactoring,
  building, or restyling user interfaces, dashboards, design systems, layouts, forms, data tables,
  animations, and micro-interactions.
---

# UI/UX Engineering & Modern Product Design Systems

A rigorous, institutional-grade operational guide for user interface engineering, UX architecture, design tokens, component libraries, and product aesthetic transformations.

---

## 1. Core Operating Principles

1. **Information Density with Breathing Room**: High-density layouts (Linear, Bloomberg, Stripe, TradingView) present maximum signal per viewport pixel without clutter. This is achieved through deliberate contrast, compact typographic scales, 1px subtle borders, and consistent spacing grids (4px / 8px).
2. **Rejection of "AI Slop"**: Reject generic AI aesthetics:
   - ❌ *No oversaturated purple/indigo gradients.*
   - ❌ *No unreadable low-contrast gray-on-gray text (`text-gray-400` on white or `text-zinc-600` on black).*
   - ❌ *No emoji icons instead of crisp vector SVGs (Lucide / Radix).*
   - ❌ *No giant empty floating cards with massive radii (`rounded-3xl`) and tiny unaligned text.*
   - ❌ *No missing keyboard focus states or mouse-only interactions.*
   - ✔️ *Use purposeful color palettes, subtle 1px borders (`border-slate-800`), monospace tabular figures (`font-mono tabular-nums`), crisp micro-badges, and accessible contrast ratios ($>4.5:1$).*
3. **Domain-Specific Color Semantics**:
   - In financial / quantitative applications, color carries high-stakes semantic meaning.
   - Green (`#10B981` / `#22C55E`): Positive alpha, profitability, buy signals, upward growth.
   - Red (`#EF4444` / `#F43F5E`): Losses, drawdowns, forensic risks, sell signals, negative cash flow.
   - Amber / Yellow (`#F59E0B`): Caution, triage required, neutral regime, warning flags.
   - Blue / Cyan (`#3B82F6` / `#06B6D4`): Informational states, focus rings, primary action buttons, neutral trends.
   - *Color-blind accessibility*: Never rely on color alone. Pair color indicators with directional glyphs (`▲`, `▼`, `—`), status badges, or tooltips.
4. **Predictable Perceived Performance**:
   - Zero layout shifts (CLS < 0.1): Reserve skeleton space for lazy-loaded charts and tables.
   - Optimistic feedback: Instant active states (<50ms feedback) on button clicks and filter switches.
   - Skeletons over full-page spinners: Retain page layout and navigation chrome while data hydrates.

---

## 2. Design Token Architecture

A robust design system is structured in three explicit token tiers:

```mermaid
graph TD
    Primitive["1. Primitive Tokens<br>(Raw values: slate-900, emerald-500, font-size-14, 8px)"]
    Semantic["2. Semantic Tokens<br>(Intent: surface-background, text-primary, border-subtle, status-success)"]
    Component["3. Component Tokens<br>(Scaped: table-header-bg, badge-pill-padding, chart-grid-stroke)"]

    Primitive --> Semantic --> Component
```

### 2.1 Color Token Matrix (Institutional Dark & Light Themes)

| Semantic Token | Dark Mode Value | Light Mode Value | Usage |
| :--- | :--- | :--- | :--- |
| `bg-app` | `#0B0F17` (Deep Obsidian) | `#F8FAFC` (Slate Tint) | Root viewport background |
| `bg-surface` | `#111827` (Rich Zinc/Slate) | `#FFFFFF` (Pure White) | Cards, panels, modal dialogs |
| `bg-surface-hover` | `#1E293B` (Muted Blue-Gray) | `#F1F5F9` (Light Slate) | Table row hover, menu item hover |
| `border-subtle` | `#1E293B` (1px clean border) | `#E2E8F0` | Card borders, table dividers |
| `border-accent` | `#334155` | `#CBD5E1` | Focused inputs, active tab borders |
| `text-primary` | `#F8FAFC` (High contrast, 16:1) | `#0F172A` | Primary headings, table data values |
| `text-secondary` | `#94A3B8` (Slate 400, 7:1) | `#475569` | Metric labels, descriptions, timestamps |
| `text-muted` | `#64748B` (Slate 500, 4.5:1) | `#64748B` | Footers, disabled states, shortcut hints |
| `accent-primary` | `#2563EB` (Royal Blue) | `#2563EB` | Primary CTA buttons, active radio tabs |
| `status-bullish` | `#10B981` (Emerald) | `#059669` | Gains, Buy conviction, Positive CAGR |
| `status-bearish` | `#EF4444` (Rose/Red) | `#DC2626` | Drawdowns, Disqualifications, High Debt |
| `status-caution` | `#F59E0B` (Amber) | `#D97706` | Stale data, Needs Review, Moderate Flags |

### 2.2 Typography Scale & Numerical Formatting

```css
/* Essential for financial terminals & high-density tables */
.tabular-numbers {
  font-family: var(--font-mono), monospace;
  font-variant-numeric: tabular-nums;
  letter-spacing: -0.02em;
}
```

- **Headings (Display/Title)**: Semi-bold / Bold (600/700), tight tracking (`letter-spacing: -0.03em`), line-height 1.2.
- **Body & Controls**: 13px–14px (`text-sm`), medium (500) for interactive labels, regular (400) for text.
- **Micro Labels & Badges**: 11px–12px (`text-xs`), bold/semibold (600/700), uppercase with `tracking-wider`.
- **Numbers & Metrics**: Monospace tabular font (`JetBrains Mono`, `Roboto Mono`, or `Inter` with `tabular-nums`), right-aligned in all tables.

---

## 3. High-Density Financial Terminal & Table UX

Data tables are the core engine of financial and analytical workflows. Follow these non-negotiable rules:

1. **Alignment Rules**:
   - Text, symbols, and company names: **Left-aligned**.
   - Numerical metrics (Price, P/E, ROCE, CAGR, Scores, Dates): **Right-aligned**.
   - Status badges, actionable flags, icons: **Center-aligned**.
2. **Sticky Column & Multi-Row Headers**:
   - Header row must stick during vertical scrolling (`sticky top-0 bg-surface z-10`).
   - Sticky identifier column (Company Name / Symbol) on horizontal scroll for mobile and ultra-wide tables.
3. **Visual Structure**:
   - Row height: Compact (36px–40px) or standard (44px) with subtle zebra striping or crisp 1px borders (`border-b border-slate-800/60`).
   - Instant row hover highlighting (`hover:bg-slate-800/40 cursor-pointer`).
   - Direct inline badge pills (`bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded text-xs font-semibold`).
4. **Interactive Controls**:
   - Sort indicator arrows (`▲` active ascending, `▼` active descending, muted `⇅` sortable).
   - Instant search with clear button (`X`), active filter count chips (`Filters (3)`), and pagination controls with total count (`Showing 1–50 of 1,060`).

---

## 4. Usability & Interaction Architecture (Nielsen Norman Heuristics)

```mermaid
flowchart LR
    A["Recognition over Recall<br>(Breadcrumbs, Sticky Headers, Saved Filters)"] --> B["User Control & Freedom<br>(Quick Clear, Esc to close, Undo)"]
    B --> C["System Status Visibility<br>(Optimistic UI, Loading Skeletons, Timestamps)"]
    C --> D["Efficiency of Use<br>(Keyboard Shortcuts, Command Palette Cmd+K)"]
```

1. **Visibility of System Status**:
   - Always display "As of [Market Date/Time]" on financial data so the user knows if the market is live or closed.
   - When requests take >100ms, display localized skeletons rather than blank screens or blocking spinners.
2. **User Control & Freedom**:
   - Filter bars must have a one-click "Reset All Filters" button when any non-default filter is active.
   - Modals and drawers must close on `Escape` key and backdrop click.
3. **Consistency & Component Hierarchy**:
   - **Primary Action**: Solid high-contrast fill (`bg-blue-600 hover:bg-blue-500 text-white`). Exactly one primary CTA per view.
   - **Secondary Action**: Bordered / subtle fill (`bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700`).
   - **Ghost Action**: Transparent (`hover:bg-slate-800 text-slate-400 hover:text-slate-100`).
   - **Destructive Action**: Red-tinted warning (`bg-rose-600/10 hover:bg-rose-600/20 text-rose-400 border border-rose-500/30`).
4. **Accessibility (WCAG 2.2 AA / AAA)**:
   - Text-to-background contrast ratio $\ge 4.5:1$ for normal body text, $\ge 3:1$ for large text and UI components.
   - All interactive elements must have visible `:focus-visible` focus rings (`ring-2 ring-blue-500 ring-offset-2 ring-offset-slate-900`).
   - Minimum clickable touch targets: $44 \times 44$px on touch devices.

---

## 5. UI/UX Revamp Playbook (Phase-Wise Execution)

When tasked with redoing or modernizing an existing application's UI/UX, follow this 4-step execution strategy:

### Step 1: Design System Foundation & Token Extraction
- Establish the color palette, typography scale, spacing variables, and border radius hierarchy in CSS/Tailwind (`globals.css` / `tailwind.config.js`).
- Introduce institutional dark mode tokens and semantic color classes.

### Step 2: Component Primitives Modernization
- Refactor core reusable UI primitives:
  - `Button`: Primary, secondary, ghost, destructive, with loading spinners.
  - `Badge` / `Tag`: Semantic colored pills for status, tiers, and momentum.
  - `Card` / `Panel`: Clean borders, rounded corners (`rounded-lg` or `rounded-xl`), subtle backgrounds.
  - `DataTable`: Header sorting, right-aligned numbers, sticky header, hover rows.
  - `Modal` / `Drawer`: Backdrop blur, focus trap, smooth entrance animations.
  - `Tooltip`: Informative explanations for complex metrics (e.g. EV/EBITDA, CANSLIM score).

### Step 3: Layout & Navigation Overhaul
- Modernize top navigation bar / sidebar with clear active route indicators, company search bar, system status indicator (e.g., market session date, API health).
- Eliminate layout jank and page jump on route transitions.

### Step 4: High-Value Page Modernization
- Revamp the critical user-facing views:
  - **Dashboard**: Executive summary tiles, market pulse, top gainers/losers, regime heatmaps.
  - **Conviction / Screener**: High-density table with fast search, sortable columns, metric pills, and quick detail drawer.
  - **Company Workspace / Detail**: Interactive charts with timeframe pills (1M, 6M, 1Y, 5Y, All), clean financial tabs (P&L, Balance Sheet, Cash Flow, Forensics, Valuation).
