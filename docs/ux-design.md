# ForkPlan UX & design

Canonical **product rules** stay in [`project-context.md`](project-context.md). This page describes **how the app should feel and look** — information architecture, screen intent, interaction patterns, visual tokens, and copy — as implemented in the current codebase.

Use it when changing UI, writing empty/error states, or extending the design system. Prefer matching neighboring screens over inventing new patterns.

---

## Product intent

ForkPlan helps someone decide **what to cook this week** from recipes they already keep on device.

| Goal | UX implication |
|------|----------------|
| Plan dinners fast | Two tabs only; Menu is the default home |
| Stay private / offline | No accounts, sync, or analytics surfaces |
| Trust cook history | Generating or re-rolling never bumps cook stats; only **Mark as cooked** does |
| Keep AI optional | Paste extract / suggest ingredients are additive; user always reviews before Save |

---

## Information architecture

```
RootTabsView
├── Menu (calendar)     ← default tab
│   ├── Empty / setup   (no Menu yet)
│   ├── Planned week    (latest Menu)
│   ├── New Plan sheet
│   └── Day recipe picker sheet
└── Recipes (book)
    ├── Empty library
    ├── Recipe list
    └── Add / Edit Recipe sheet
```

**Out-of-app:** App Intents / Shortcuts for today’s meal, weekly menu, and generate (see [Shortcuts](#shortcuts--siri)).

---

## Design principles (UX-DR)

Stable requirements referenced in code comments. Keep these when changing UI.

| ID | Principle | In practice |
|----|-----------|-------------|
| **UX-DR1** | Calm, native iOS | System materials/colors where possible; SF Symbols; standard `NavigationStack` / `List` / sheets |
| **UX-DR2** | One job per screen | Menu = plan & cook week; Recipes = library; Add/Edit = one recipe |
| **UX-DR3** | Empty states coach next action | Menu empty: “No menu yet” + day pickers + Generate; Recipes empty: “No Recipes” + tap **+** |
| **UX-DR4** | Destructive / irreversible → confirm | Regenerate menu; mark cooked from Menu; paste overwrite when form has content |
| **UX-DR5** | Validation is inline | Requirement and diet-pool messages sit near the Generate control — not a separate error screen |
| **UX-DR6** | Cook tracking is deliberate | Menu **Cooked** uses a confirmation alert; Recipes swipe “Cooked” is available without that alert (library shortcut) |
| **UX-DR7** | AI never auto-saves | Extract / suggest fill the draft only; Save remains explicit; show generated-content disclaimer |
| **UX-DR8** | Highlight orientation | Planned week emphasizes **Today** or **Up next** so the eye lands on the relevant day |
| **UX-DR9** | VoiceOver continuity | Stable `accessibilityIdentifier`s on interactive controls; identifiers are not an XCUITest contract |

---

## Visual design system

Source of truth: `Sources/DesignSystem/`. Preview canvas: `FpDesignSystemCanvas`. Apply theme at the root with `fpAppTheme()`.

### Color

| Token | Role | Notes |
|-------|------|--------|
| `fpAccent` | Brand tint / primary fills | Asset `AccentColor` — light ≈ `#8A4FFF`, dark ≈ `#A278FF` |
| `fpSecondary` | Secondary tags / chips | Asset `FPSecondaryColor` — light `#FFB86C`, dark `#FFC98E` |
| `fpBackground` | Screen background | `systemBackground` |
| `fpSurface` | Cards / inset panels | `secondarySystemBackground` |
| `fpSeparator` | Hairline strokes | `separator` |
| `fpLabel` / `fpSecondaryLabel` | Primary / secondary text | System label colors |
| `fpSuccess` / `fpWarning` / `fpError` | Status | System green / orange / red |

Accent is the global `.tint`. Prefer these tokens over raw `Color` literals in new UI.

### Typography (`FpTypography`)

| Style | Font | Use |
|-------|------|-----|
| `title` | `.title2` semibold | Design-system / hero titles |
| `heading` | `.headline` semibold | Section titles, primary/secondary button labels |
| `body` | `.body` regular | Recipe names, fields, list rows |
| `caption` | `.caption` regular | Coaching copy, day headers, secondary meta |

### Layout (`FpLayout`)

| Token | Value | Use |
|-------|-------|-----|
| `screenPadding` | 20 | Scroll / setup panels |
| `cardCornerRadius` | 16 | `FpSectionCard`, day-plan panel |
| `controlCornerRadius` | 12 | Primary/secondary buttons |
| `chipCornerRadius` | 999 (capsule) | Chips, highlight badges |
| `interItemSpacing` | 12 | Stacks inside cards |

### Controls

| Control | API | Behavior |
|---------|-----|----------|
| Primary button | `.fpPrimary()` | Full-width, min height 48, accent fill, white label |
| Secondary button | `.fpSecondary()` | Full-width outline in accent |
| Chip | `FpChip` | Capsule tag; selected uses accent wash |
| Section card | `FpSectionCard` | Surface fill + light stroke + heading |
| Recipe thumb | 44×44, 8pt radius | Surface + stroke; `photo` placeholder |

Lists that feel “card-like” use plain style + hidden scroll background on `fpBackground`, or inset-grouped for forms (Add/Edit Recipe).

### Motion

Keep motion light: button press opacity (~0.15s ease-in-out), ProgressView on generate / AI work. Do not add decorative animation that competes with content.

---

## Screens

### Menu — empty / first plan

**Intent:** Get the user to a weekly plan in one scroll.

1. Hero empty state (`MenuEmptyStateCopy`): title **No menu yet**, calendar symbol, coaching line.
2. **Select days** — Mon–Sun toggles; each on day has diet segments **Any / Veg / Vegan**.
3. Recipe count line (turns red below 7 recipes).
4. **Generate Menu** primary button (disabled until ≥1 day and ≥7 recipes).

### Menu — planned week

**Intent:** See the week at a glance; tweak one day without rebuilding everything.

- One section per planned day; recipe name as the row.
- Highlighted day: accent wash + **Today** or **Up next** capsule badge.
- Trailing swipe / context menu: **Re-roll**, **Choose**, **Cooked**.
- Toolbar **Regenerate** (confirm) — same days & diet settings; cook history unchanged.
- Footer **New Plan** secondary — opens setup sheet (no empty-state hero).

### Recipes — library

**Intent:** Browse and maintain the recipe pool that feeds generation.

- Empty: `ContentUnavailableView` “No Recipes” + fork.knife + “Tap + to add…”.
- Rows: thumb + name + one-line notes; tap opens Edit sheet.
- Swipe **Cooked** (green); context menu Cooked / Edit; standard delete.
- Toolbar **+** opens Add sheet.

### Add / Edit Recipe (sheet)

**Intent:** Capture one recipe safely; AI is assistive, never authoritative.

| Section | Add | Edit |
|---------|-----|------|
| Recipe | Name (required), Notes — **first** | Same |
| Photo | PhotosPicker + Image Playground when AI features shown | Same |
| Paste recipe | Paste field + Extract when AI features shown | Hidden |
| Diet | Standard / Vegetarian / Vegan segmented | Same |
| Ingredients | Lines + Suggest Missing Ingredients when AI features shown | Same |

- Cancel / Save in toolbar; Save disabled while saving or AI busy.
- Paste overwrite confirmation when the form already has content.
- Suggest Missing Ingredients appends rows into the draft list for review (delete unwanted lines before Save).
- Footer disclaimer on paste and ingredients when AI features are shown: *Always check Apple Intelligence suggestions before saving — they can be wrong or incomplete.*
- **Apple Intelligence unavailable** (device ineligible / model not ready / unknown): hide paste, suggest-missing-ingredients, and Image Playground controls entirely.
- **Apple Intelligence not enabled** (supported device, off in Settings): keep those controls visible, disable action buttons, and show a Settings enablement hint.
- Empty suggestions are neutral status, not an error.

---

## Key flows

### First-week happy path

```
Open app (Menu tab)
  → Add ≥ 7 recipes (Recipes tab)
  → Select days + optional Veg/Vegan
  → Generate Menu
  → Cook → Mark as cooked (updates future weighting)
```

### Day tweak (existing menu)

```
Swipe day → Re-roll | Choose recipe… | Cooked
  → Choose opens filtered picker (diet-aware)
  → Cooked asks confirmation (Menu tab)
```

### Paste → recipe

```
Add Recipe → paste text → Extract Recipe
  → confirm overwrite if needed
  → review fields → Save
```

---

## Copy & voice

- Short, instructional, second person (“Choose the days you need dinner…”).
- Prefer plain words: **Generate Menu**, **New Plan**, **Re-roll**, **Mark as cooked**.
- Errors and requirements stay near the control that failed (Generate, Save).
- AI progress copy names Apple Intelligence explicitly so the source is clear.

Canonical empty-menu strings live in `MenuEmptyStateCopy` — change there, not by hardcoding in the view.

---

## Accessibility

- Every interactive control should keep a stable `accessibilityIdentifier` (see table in [`project-context.md`](project-context.md)).
- Decorative images (thumbs, SF Symbol placeholders) should stay `accessibilityHidden` when the row already exposes the recipe name.
- Support Dynamic Type via system text styles (`FpTypography`); do not lock critical copy to fixed sizes.
- Snapshot baselines use Light / `en_US` / default Dynamic Type on iPhone 17 Pro — update baselines when intentional visual change lands.

---

## Shortcuts / Siri

| Shortcut | Phrases (examples) | System image |
|----------|--------------------|--------------|
| Today's meal | “What's for dinner in ForkPlan” | `fork.knife` |
| Weekly menu | “What's my menu this week in ForkPlan” | `calendar` |
| Generate menu | “Generate my menu in ForkPlan” | `arrow.triangle.2.circlepath` |

Destructive generate from Shortcuts must request confirmation before replacing the menu (architecture contract).

---

## Extending the UI

1. Reuse `fp*` tokens and existing list / sheet patterns before adding new chrome.
2. Put pure logic in `Helpers/`; keep views declarative; thin `@Observable` coordinators for transient UI only.
3. If you introduce a new empty, confirm, or AI surface, update this doc and the relevant UX-DR row.
4. Visual regressions: re-record snapshots per `Tests/__Snapshots__/iPhone17Pro-iOS26/README.md`.

Live component gallery: Xcode preview of `FpDesignSystemCanvas` (Light / Dark).
