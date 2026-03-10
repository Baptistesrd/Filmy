# Filmy — Design System

## Aesthetic Direction

**Mood**: Cinematic, editorial, dark luxury — A24 meets Letterboxd meets a high-end streaming platform.
The UI should feel like a premium object. Every element earns its place.

**Accent color rationale**: Amber-gold (`#e8a020`) — the color of projected light hitting a cinema screen,
Kodak film stock, the warm glow of a projector lamp. Unexpected against near-black. Never gaudy.

---

## 1. Color Palette

### CSS Custom Properties (defined in `config/_colors.scss`)

```scss
// Backgrounds
--color-bg:          #0a0a0f;   // Near-black — primary page background
--color-bg-elevated: #111118;   // Slightly lifted — cards, panels
--color-bg-surface:  #1a1a24;   // Higher surface — inputs, modals
--color-bg-overlay:  rgba(10, 10, 15, 0.88); // For overlays, gradient fades

// Text
--color-text-primary:   #f5f0e8;  // Warm off-white — all body copy
--color-text-secondary: #9e9a93;  // Muted warm grey — timestamps, meta
--color-text-tertiary:  #5a5650;  // Dimmed — placeholders, disabled

// Accent
--color-accent:        #e8a020;   // Amber-gold — CTAs, highlights, badges
--color-accent-dim:    rgba(232, 160, 32, 0.15); // Subtle accent backgrounds
--color-accent-hover:  #f0b030;   // Lighter on hover

// Borders
--color-border:        rgba(255, 255, 255, 0.07);  // Default subtle border
--color-border-strong: rgba(255, 255, 255, 0.14);  // Stronger border on hover/focus

// Status
--color-success: #22c55e;
--color-error:   #ef4444;
--color-warning: #e8a020; // reuse accent

// Chat bubbles
--color-bubble-user:      #e8a020;        // User messages — accent fill
--color-bubble-user-text: #0a0a0f;        // Dark text on amber bubble
--color-bubble-ai:        #1a1a24;        // AI messages — surface fill
--color-bubble-ai-text:   #f5f0e8;        // Warm white text on dark bubble
```

### SCSS Variables (for Bootstrap override compatibility)

```scss
$body-bg:    #0a0a0f;
$body-color: #f5f0e8;
$accent:     #e8a020;
$accent-dim: rgba(232, 160, 32, 0.15);
```

---

## 2. Typography

### Google Fonts import (in `<head>`)

```html
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;0,700;1,400;1,600&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
```

### Font roles

| Role | Font | Use |
|---|---|---|
| Display / Hero | Cormorant Garamond 600–700 | Page titles, hero headings, film titles |
| Display Italic | Cormorant Garamond Italic 400 | Taglines, pull quotes |
| UI Body | DM Sans 400 | All body text, labels, chat messages |
| UI Medium | DM Sans 500 | Button labels, nav items |
| UI Semibold | DM Sans 600 | Section headings, card titles |

### Type Scale

```scss
// Display
$font-display-hero: clamp(3rem, 6vw, 5.5rem);     // Hero/landing title
$font-display-lg:   clamp(2rem, 4vw, 3.5rem);      // Page H1
$font-display-md:   clamp(1.5rem, 2.5vw, 2.25rem); // Section heading H2
$font-display-sm:   1.25rem;                        // Card title, H3

// UI
$font-ui-lg:   1.0625rem; // 17px — body readable
$font-ui-md:   0.9375rem; // 15px — secondary body
$font-ui-sm:   0.8125rem; // 13px — labels, meta
$font-ui-xs:   0.6875rem; // 11px — timestamps, badges

// Line heights
$lh-tight:   1.15;
$lh-snug:    1.35;
$lh-normal:  1.55;
$lh-relaxed: 1.75;

// Letter spacing
$ls-tight:   -0.03em; // Display headings
$ls-normal:  -0.01em;
$ls-wide:    0.08em;  // Uppercase labels/badges
```

---

## 3. Spacing Scale

Base unit: **4px**. All spacing is a multiple of 4.

```scss
$space-1:  4px;
$space-2:  8px;
$space-3:  12px;
$space-4:  16px;
$space-5:  20px;
$space-6:  24px;
$space-8:  32px;
$space-10: 40px;
$space-12: 48px;
$space-16: 64px;
$space-20: 80px;
$space-24: 96px;
```

---

## 4. Border Radius Scale

```scss
$radius-sm: 6px;    // Input fields, small chips
$radius-md: 10px;   // Buttons, small cards
$radius-lg: 16px;   // Panels, chat shell
$radius-xl: 24px;   // Film poster cards
$radius-full: 9999px; // Pills, avatar circles
```

---

## 5. Shadows

```scss
// Elevation — uses amber warmth in the shadow for "lit" feel
$shadow-sm:  0 1px 3px rgba(0, 0, 0, 0.4);
$shadow-md:  0 4px 16px rgba(0, 0, 0, 0.5);
$shadow-lg:  0 8px 32px rgba(0, 0, 0, 0.6);
$shadow-xl:  0 16px 64px rgba(0, 0, 0, 0.7);

// Accent glow — used on hover for poster cards, CTA buttons
$shadow-accent-sm: 0 0 12px rgba(232, 160, 32, 0.2);
$shadow-accent-md: 0 0 28px rgba(232, 160, 32, 0.3);
```

---

## 6. Motion

```scss
$transition-fast:   0.12s ease;
$transition-base:   0.22s ease;
$transition-slow:   0.4s ease;
$transition-spring: 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); // Slight overshoot

// Named animations
@keyframes fade-up {
  from { opacity: 0; transform: translateY(10px); }
  to   { opacity: 1; transform: translateY(0); }
}

@keyframes fade-in {
  from { opacity: 0; }
  to   { opacity: 1; }
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  20%       { transform: translateX(-6px); }
  40%       { transform: translateX(6px); }
  60%       { transform: translateX(-4px); }
  80%       { transform: translateX(4px); }
}

@keyframes typing-pulse {
  0%, 80%, 100% { opacity: 0.2; transform: scale(0.85); }
  40%            { opacity: 1;   transform: scale(1); }
}
```

---

## 7. Component Patterns

### 7.1 Chat Bubble — User

```
Background:  var(--color-accent)         #e8a020
Text:        var(--color-bubble-user-text) #0a0a0f
Border:      none
Radius:      $radius-lg top-right $radius-sm
Padding:     $space-3 $space-4
Animation:   fade-up 0.2s ease on append
```

### 7.2 Chat Bubble — AI

```
Background:  var(--color-bg-surface)     #1a1a24
Text:        var(--color-text-primary)   #f5f0e8
Border:      1px solid var(--color-border)
Radius:      $radius-lg top-left $radius-sm
Padding:     $space-3 $space-4
Animation:   fade-up 0.2s ease on append
```

### 7.3 Typing Indicator

Three dots inside an AI bubble. Each dot animates with `typing-pulse` at 0ms, 150ms, 300ms delay.
The entire bubble itself uses a subtle `fade-up` entry.

### 7.4 Film Poster Card

```
Structure:
  - Full-height poster image (aspect-ratio: 2/3)
  - Gradient overlay bottom 60%: transparent → rgba(10,10,15,0.95)
  - Content sits in overlay: title (Cormorant 600), year + rating badge, one-line blurb
  - Two action buttons: "Save" (accent outline) + "Tell me more" (ghost)
  - On hover: translateY(-4px), shadow-accent-md — the card "lifts"
  - Transition: $transition-spring

Border-radius: $radius-xl
Overflow: hidden (clips image to radius)
```

### 7.5 Buttons

```
Primary CTA:
  Background: var(--color-accent)
  Text: #0a0a0f (dark)
  Padding: $space-3 $space-6
  Radius: $radius-md
  Hover: color-accent-hover + $shadow-accent-sm + translateY(-1px)

Ghost:
  Background: transparent
  Border: 1px solid var(--color-border-strong)
  Text: var(--color-text-primary)
  Hover: border-color accent, text accent

Danger:
  As ghost but hover border/text: var(--color-error)

Pill:
  Any button + border-radius: $radius-full (used sparingly, nav only)
```

### 7.6 Form Inputs

```
Background: var(--color-bg-surface)
Border: 1px solid var(--color-border)
Text: var(--color-text-primary)
Placeholder: var(--color-text-tertiary)
Focus: border-color accent, box-shadow: 0 0 0 3px rgba(232,160,32,0.15)
Radius: $radius-sm
No Bootstrap glow ring
```

### 7.7 Badges / Tags

```
Uppercase, DM Sans 500, $font-ui-xs, $ls-wide
Background: var(--color-accent-dim)
Text: var(--color-accent)
Border: 1px solid rgba(232,160,32,0.25)
Padding: 2px $space-2
Radius: $radius-sm
```

### 7.8 Watch Session Card

```
Background: var(--color-bg-elevated)
Border: 1px solid var(--color-border)
Radius: $radius-lg
Hover: border-color var(--color-border-strong), $shadow-md
Transition: $transition-base
```

---

## 8. Layout Patterns

### Chat page (desktop)

```
|  sidebar 240px  |  chat column flex-1  |  film panel 320px  |
                     messages list
                     ────────────────
                     composer (sticky bottom)
```

### Chat page (mobile, < 768px)

```
Full width chat
───────────────
Film cards horizontal scroll strip (below chat)
```

### Landing hero

```
Full viewport height
Background: deep dark with subtle film-grain texture overlay (SVG noise)
Centered content: display title + tagline + CTA
No nav — just the logo and one button
```

### Sessions / Library grid

```
Auto-fill grid: grid-template-columns: repeat(auto-fill, minmax(220px, 1fr))
Poster-led cards
```

---

## 9. What NOT to do

- No `border-radius: 9999px` on large cards or panels (only pills)
- No solid white backgrounds anywhere — use elevated surfaces only
- No Inter font — DM Sans for UI, Cormorant Garamond for display
- No Bootstrap default blue (`#0d6efd`) — accent is amber only
- No purple gradients
- No `box-shadow: 0 0.5rem 1rem rgba(0,0,0,.15)` Bootstrap default
- No hover-only interactions — all interactive states also have focus states
- No unstyled `<a>` tags — all links are intentionally styled

---

## 10. File Map

```
app/assets/stylesheets/
  application.scss          ← imports only
  config/
    _colors.scss            ← CSS custom properties + SCSS vars
    _fonts.scss             ← Google Fonts + font-face rules
    _bootstrap_variables.scss ← Bootstrap overrides
  components/
    _index.scss             ← component imports
    _buttons.scss
    _chat.scss              ← bubbles, composer, typing indicator
    _film_card.scss         ← poster card, panel
    _sidebar.scss
    _navbar.scss
    _badges.scss
    _forms.scss
  pages/
    _index.scss
    _home.scss              ← hero, landing
    _chat.scss              ← chat page layout
    _watch_session.scss     ← session show + index grid
```
