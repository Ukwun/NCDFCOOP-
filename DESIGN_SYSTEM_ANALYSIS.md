# Coop Commerce - Design System Analysis

## Overview
The Coop Commerce Flutter app uses a modern, Material Design 3-based system with a **primary Indigo/Purple color palette** and clean, accessible typography. The design emphasizes clarity, hierarchy, and commerce-focused components.

---

## 1. COLOR PALETTE

### Primary Colors
- **Primary (Deep Indigo)**: `#4F46E5` - Used for buttons, links, key actions
- **Primary Light**: `#6366F1` - Hover/active states
- **Primary Dark**: `#4338CA` - Darker variant for contrast
- **Primary Container**: `#F0F0FF` - Light background for primary-related content

### Secondary Colors (Accent)
- **Secondary (Emerald Green)**: `#10B981` - For success states, available badges
- **Secondary Light**: `#34D399` - Lighter variant
- **Secondary Dark**: `#059669` - Darker variant
- **Secondary Container**: `#D1FAE5` - Light background

### Accent & Special
- **Accent (Orange/Gold)**: `#F3951A` - For exclusive badges, highlights
- **Gold**: `#C9A227` - For premium/membership tiers
- **Tertiary (Amber)**: `#F59E0B` - Warnings, alerts

### Semantic Colors
- **Error**: `#EF4444` (with light: `#FCA5A5`, dark: `#DC2626`)
- **Success**: `#22C55E` (with light: `#86EFAC`, dark: `#16A34A`)
- **Warning**: `#EAB308` (with light: `#FCD34D`, dark: `#C9A227`)
- **Info**: `#3B82F6` (with light: `#93C5FD`, dark: `#1D4ED8`)

### Neutral/Background
- **Background**: `#FAFAFA` - Page background
- **Surface**: `#FFFFFF` - Card/surface background
- **Surface Variant**: `#F5F5F5` - Secondary surface
- **Outline**: `#E0E0E0` - Borders, dividers
- **Text**: `#1F2937` - Primary text
- **Text Light**: `#6B7280` - Secondary/muted text
- **Text Tertiary**: `#9CA3AF` - Very light text
- **Text Disabled**: `#D1D5DB` - Disabled text

### Status Colors (Order-Related)
- **Pending**: `#F59E0B` (Amber)
- **Confirmed**: `#3B82F6` (Blue)
- **Processing**: `#8B5CF6` (Violet)
- **Shipped**: `#6366F1` (Indigo)
- **Delivered**: `#10B981` (Green)
- **Cancelled**: `#EF4444` (Red)
- **Returned**: `#F59E0B` (Amber)

### Dark Mode
- **Dark Background**: `#121212`
- **Dark Surface**: `#1E1E1E`
- **Dark Card**: `#2A2A2A`
- **Dark Text**: `#FFFFFF`
- **Dark Text Light**: `#B0B0B0`
- **Dark Divider**: `#3A3A3A`

---

## 2. TYPOGRAPHY

### Heading Styles (H1-H6)
| Style | Font Size | Weight | Line Height | Usage |
|-------|-----------|--------|-------------|-------|
| H1 | 32px | Bold | 1.2 | Page titles, main headings |
| H2 | 28px | Bold | 1.3 | Section headings |
| H3 | 24px | Bold | 1.4 | Subsections |
| H4 | 20px | Bold | 1.5 | Component titles, app bar |
| H5 | 18px | Bold | 1.5 | Card headers |
| H6 | 16px | Bold | 1.5 | Sub-headers |

### Body Text Styles
| Style | Font Size | Weight | Line Height | Letter Spacing | Usage |
|-------|-----------|--------|-------------|-----------------|-------|
| Body Large | 16px | Normal | 1.5 | 0.15px | Main body text |
| Body Medium | 14px | Normal | 1.5 | 0.25px | Standard body text |
| Body Small | 12px | Normal | 1.4 | 0.4px | Helper text, captions |
| Label Large | 14px | Medium (500) | 1.4 | 0.1px | Button text, labels |
| Label Medium | 12px | Medium (500) | 1.4 | 0.5px | Small labels |
| Label Small | 11px | Medium (500) | 1.4 | 0.5px | Very small labels, badges |

### Font Family
- **Default**: System font (Roboto equivalent)
- **Weight**: Mix of Normal (400), Medium (500), and Bold (700)

---

## 3. SPACING SYSTEM

**Base unit: 4px**

| Token | Value | Usage |
|-------|-------|-------|
| XS | 4px | Tiny gaps, inline spacing |
| SM | 8px | Small padding, button padding (vertical) |
| MD | 12px | Standard padding, card padding |
| LG | 16px | Large padding, screen padding, button full padding |
| XL | 20px | Extra large spacing |
| XXL | 24px | Section spacing |
| XXXL | 32px | Major section spacing |
| HUGE | 40px | Large gaps between major areas |

---

## 4. BORDER RADIUS

| Token | Value | Usage |
|-------|-------|-------|
| XS | 4px | Small elements (badges, chips) |
| SM | 8px | Small rounded corners |
| MD | 12px | Standard rounded corners (buttons, inputs) |
| LG | 16px | Large rounded corners (cards, containers) |
| XL | 20px | Extra large rounded corners |
| Full | 100px | Circular elements (avatars) |

---

## 5. SHADOW SYSTEM

| Level | Blur | Offset | Usage |
|-------|------|--------|-------|
| Subtle | 2px | (0, 1) | Minimal elevation |
| SM | 4px | (0, 2) | Cards, standard elements |
| MD | 8px | (0, 4) | Elevated cards |
| LG | 12px | (0, 6) | Modal dialogs |
| XL | 16px | (0, 8) | Floating elements |

**Color**: Black 12% opacity

---

## 6. COMPONENT DESIGN PATTERNS

### Product Card
- **Layout**: Vertical card with image (60%) and details (40%)
- **Image Area**: Background `#FAFAFA`, icon placeholder `#E0E0E0`
- **Badge** (top-left): Orange accent, small text, rounded corners
- **Content**:
  - Product name (2-line max, ellipsis)
  - **Member Price** (Bold, Indigo, large)
  - **Market Price** (Gray, strikethrough)
  - "Add to Cart" button (Full width, Indigo, 32px height)
- **Elevation**: Small shadow
- **Border Radius**: Large (16px)

### Buttons
- **Elevated Button**: Indigo background, white text, 16px padding H, 12px padding V, 12px radius
- **Outlined Button**: Indigo border, Indigo text, 16px padding H, 12px padding V
- **Text Button**: Indigo text, minimal padding
- **States**:
  - Disabled: Gray background/text
  - Loading: Opacity reduced

### Input Fields
- **Background**: `#F9F9F9` or white
- **Border**: `#E0E0E0` (1px)
- **Focus**: Indigo border (2px)
- **Padding**: 16px H, 12px V
- **Radius**: 12px
- **Label Text**: Body Medium, gray
- **Hint Text**: Body Medium, light gray

### Cards
- **Background**: White
- **Elevation**: 0 (minimal/subtle shadow instead)
- **Border**: `#E0E0E0` (1px)
- **Radius**: 16px

### Navigation (Bottom Tab Bar)
- **Height**: 70px (includes safe area)
- **Background**: White with top border
- **Items**: 5 main items (Home, Offer, Message, Cart, My NCDFCOOP)
- **Active Color**: Indigo
- **Inactive Color**: Gray
- **Badge**: Red circle for cart/message counts

### Header/App Bar
- **Background**: White
- **Text Color**: Black
- **Elevation**: 0
- **Prefix/Title Style**: H4

### Search Bar
- **Style**: Outlined input with search icon
- **Padding**: 16px H, 12px V
- **Border Radius**: 8px
- **Placeholder Color**: Light gray

---

## 7. LAYOUT & GRID STRUCTURE

### Screen Layouts
- **Safe Area**: Top and bottom padding respects device safe zones
- **Content Padding**: 16px horizontal padding on most screens
- **Max Width**: No specific constraint (responsive to device width)
- **Orientation**: Portrait-first design (mobile-optimized)

### Home Screen Structure
1. **Header Section** (16px padding)
   - Welcome greeting (H1 style, Indigo)
   - Subtitle (Body style, gray)

2. **Search Bar** (16px M horizontal, 12px M vertical)
   - Center-aligned, interactive

3. **Featured Carousel**
   - Full-width PageView
   - 200px height
   - Rounded corners (12px)
   - Dark gradient overlay

4. **Category Grid**
   - Responsive grid layout
   - Equal-sized items

5. **Recent Orders Section**
   - Stacked list-like cards
   - 60px height each

6. **Recommended Products**
   - Horizontal scrollable list or grid

### Spacing Between Sections
- Major sections: **24px-32px** vertical gap
- Within section items: **12px-16px** gap

---

## 8. COLOR USAGE BY CONTEXT

### Commerce Elements
- **Product Price**: Indigo (`#4F46E5`)
- **Original Price**: Gray, strikethrough
- **Discount Badge**: Orange (`#F3951A`)
- **In Stock** Badge: Green (`#10B981`)
- **Out of Stock**: Gray

### Action Elements
- **Primary CTA** (Add to Cart, Checkout, Save): Indigo button
- **Secondary Action** (View Details): Text link, Indigo
- **Destructive** (Delete, Cancel): Red text/outline

### Status Badges
- **Pending**: Amber
- **Confirmed**: Blue
- **Delivered**: Green
- **Cancelled**: Red

### Interactive States
- **Hover**: Lighter shade or slight shadow increase
- **Pressed**: Darker shade
- **Disabled**: Gray with reduced opacity

---

## 9. DARK MODE

Dark mode uses similar hues but adjusts for readability:

| Light | Dark |
|-------|------|
| `#FAFAFA` bg | `#121212` bg |
| `#FFFFFF` surface | `#1E1E1E` surface |
| `#1F2937` text | `#FFFFFF` text |
| `#6B7280` text light | `#B0B0B0` text light |
| `#E0E0E0` border | `#3A3A3A` border |
| `#F9F9F9` input | `#2A2A2A` input |

**Primary colors remain the same** — Indigo/Green/Orange are brightness-agnostic in the palette.

---

## 10. MATERIAL DESIGN 3 COMPLIANCE

- **System**: Material Design 3 enabled (`useMaterial3: true`)
- **Color Scheme**: Generated from seed color (Deep Purple `#4F46E5`)
- **Typography**: Follows Material 3 scale (headlineLarge, titleMedium, etc.)
- **Rounded Corners**: Consistent use of border-radius (no sharp corners)
- **Elevation/Shadows**: Subtle shadows for depth

---

## 11. RESPONSIVE DESIGN NOTES

- **Mobile-First**: App designed for portrait orientation on mobile
- **Breakpoints**: Not explicitly defined; uses flexible layouts
- **Scrollable Sections**: Page View for carousels, SingleChildScrollView for vertical content
- **Adaptive Padding**: Uses consistent spacing tokens rather than fixed values
- **Text Scaling**: Uses fontSize tokens, responsive to Material 3 scale

---

## 12. ACCESSIBILITY FEATURES

- **Color Contrast**: Primary text (`#1F2937`) on white (`#FFFFFF`) = 14:1 ratio ✓
- **Touch Targets**: Buttons minimum 48px (often implemented as 32px inline)
- **Disabled States**: Clear visual distinction
- **Semantic Colors**: Status conveyed via color + shape/text
- **Focus States**: 2px border highlight on inputs for keyboard navigation

---

## Implementation Guidelines for Web Version

### CSS Variables / Design Tokens
```css
:root {
  --color-primary: #4F46E5;
  --color-primary-light: #6366F1;
  --color-primary-dark: #4338CA;
  --color-secondary: #10B981;
  --color-accent: #F3951A;
  --color-error: #EF4444;
  --color-success: #22C55E;
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 12px;
  --space-lg: 16px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.12);
}
```

### Key Web Patterns
1. **Product Grid**: CSS Grid / Flexbox with 2-4 columns responsive
2. **Navigation**: Top navbar + bottom footer with 5 main links
3. **Cards**: Shadow + border approach, avoid elevation
4. **Buttons**: 12px radius, 16px padding, no text-transform
5. **Forms**: 12px radius inputs, focus state with 2px border
6. **Typography**: Use system fonts (Segoe UI, Helvetica, sans-serif)
7. **Spacing**: Multiples of 4px base unit
8. **Color**: Use Indigo as primary, Green/Orange as accents

---

## Files to Reference in Flutter App
- `lib/theme/app_colors.dart` - Complete color palette
- `lib/theme/app_text_styles.dart` - Typography definitions
- `lib/theme/app_theme.dart` - Theme data, spacing, shadows, radius
- `lib/theme/theme_extension.dart` - Dark mode color mappings
- `lib/widgets/product_card.dart` - Product card component
- `lib/widgets/price_tag.dart` - Price display component
- `lib/features/home/consumer_home_screen.dart` - Main layout example

---

## Summary Checklist for Web Developer
- [ ] Primary color system: Indigo `#4F46E5`
- [ ] Secondary system: Green `#10B981` + Orange `#F3951A`
- [ ] Spacing base: 4px (sm=8px, md=12px, lg=16px, xl=20px, xxl=24px)
- [ ] Border radius: 12-16px standard
- [ ] Shadows: SMall card shadow with 2-4px blur
- [ ] Typography: Clean sans-serif, Material 3 scale
- [ ] Bottom navigation: 5 items with active/inactive states
- [ ] Cards: White bg, 1px border, 12-16px radius, zero elevation
- [ ] Buttons: Indigo fill, white text, 12px radius
- [ ] Dark mode: Background `#121212`, Surface `#1E1E1E`, same colors
