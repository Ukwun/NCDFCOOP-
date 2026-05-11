# Coop Commerce - Design System Quick Reference

## Color Palette (Copy-Paste Ready)

### Primary
```
#4F46E5 - Main Primary (Deep Indigo)
#6366F1 - Primary Light
#4338CA - Primary Dark
#F0F0FF - Primary Container (light bg)
```

### Secondary
```
#10B981 - Secondary (Emerald)
#34D399 - Secondary Light
#059669 - Secondary Dark
#D1FAE5 - Secondary Container
```

### Accents & Special
```
#F3951A - Accent Orange
#C9A227 - Gold
#F59E0B - Tertiary Amber
```

### Semantic
```
#EF4444 - Error
#22C55E - Success
#EAB308 - Warning
#3B82F6 - Info
```

### Neutral
```
#FAFAFA - Background
#FFFFFF - Surface/White
#F5F5F5 - Surface Variant
#1F2937 - Text Primary
#6B7280 - Text Secondary/Light
#9CA3AF - Text Tertiary
#E0E0E0 - Border/Divider
```

### Dark Mode
```
#121212 - Dark Background
#1E1E1E - Dark Surface
#2A2A2A - Dark Card
#FFFFFF - Dark Text
#B0B0B0 - Dark Text Light
#3A3A3A - Dark Border
```

---

## Spacing System (4px Base)

| Name | Value | 
|------|-------|
| XS | 4px |
| SM | 8px |
| MD | 12px |
| LG | 16px |
| XL | 20px |
| XXL | 24px |
| XXXL | 32px |
| HUGE | 40px |

---

## Border Radius

```
4px - XS (small elements)
8px - SM
12px - MD (standard, buttons, inputs)
16px - LG (cards)
20px - XL
100px - FULL (circles)
```

---

## Typography Scale

### Headings
| Level | Size | Weight | Usage |
|-------|------|--------|-------|
| H1 | 32px | Bold | Page titles |
| H2 | 28px | Bold | Section heads |
| H3 | 24px | Bold | Subsections |
| H4 | 20px | Bold | Component titles |
| H5 | 18px | Bold | Card headers |
| H6 | 16px | Bold | Sub-headers |

### Body
| Type | Size | Weight | Usage |
|------|------|--------|-------|
| Body Large | 16px | Normal | Main body |
| Body Medium | 14px | Normal | Standard text |
| Body Small | 12px | Normal | Helper text |
| Label Large | 14px | Medium | Button text |
| Label Medium | 12px | Medium | Small labels |
| Label Small | 11px | Medium | Badges |

---

## Component Specs

### Buttons
- **Primary CTA**: `#4F46E5` bg, white text, 12px radius
- **Padding**: 16px horizontal, 12px vertical
- **Text Style**: Label Large
- **Disabled**: Gray with opacity

### Cards
- **Background**: White (`#FFFFFF`)
- **Border**: 1px `#E0E0E0`
- **Radius**: 16px
- **Shadow**: 0 2px 4px rgba(0,0,0,0.12)
- **Padding**: 12-16px

### Input Fields
- **Background**: White/`#F9F9F9`
- **Border**: 1px `#E0E0E0`
- **Focus Border**: 2px `#4F46E5`
- **Radius**: 12px
- **Padding**: 16px H, 12px V

### Product Card
- **Size**: Square or 3:4 aspect ratio
- **Image**: Top 60%, rounded top, bg `#FAFAFA`
- **Details**: Bottom 40%
- **Badge**: Top-left corner, orange, 11px text
- **Price**: Indigo primary, gray strikethrough secondary
- **Button**: "Add to Cart", full width, 32px height

### Navigation Bar (Bottom)
- **Height**: 70px
- **Items**: 5 (Home, Offer, Message, Cart, My NCDFCOOP)
- **Active Color**: `#4F46E5`
- **Inactive Color**: Gray
- **Background**: White with top border
- **Badge**: Red circle for counts

### App Bar (Top)
- **Background**: White
- **Text**: Black, H4 weight
- **Elevation**: None
- **Height**: 56px+ with safe area

---

## Shadows

```css
subtle: 0 1px 2px rgba(0, 0, 0, 0.12)
sm: 0 2px 4px rgba(0, 0, 0, 0.12)
md: 0 4px 8px rgba(0, 0, 0, 0.12)
lg: 0 6px 12px rgba(0, 0, 0, 0.12)
xl: 0 8px 16px rgba(0, 0, 0, 0.24)
```

---

## Layout Grid

- **Screen Padding**: 16px horizontal (left/right)
- **Section Gap**: 24-32px vertical
- **Item Gap**: 12-16px vertical in lists
- **Max Width**: Responsive (no hard limit)
- **Aspect Ratios**:
  - Product Card: Square or 1.33:1
  - Featured Banner: 16:9 or full width
  - Avatar: 1:1 (circular)

---

## Responsive Breakpoints (Suggested)

```
Mobile: 0-599px (primary breakpoint)
Tablet: 600-1023px
Desktop: 1024px+

Grid Columns:
- Mobile: 2 columns (product grid)
- Tablet: 3 columns
- Desktop: 4-5 columns
```

---

## Status Color Mapping

| Status | Color | Hex |
|--------|-------|-----|
| Pending | Amber | `#F59E0B` |
| Confirmed | Blue | `#3B82F6` |
| Processing | Violet | `#8B5CF6` |
| Shipped | Indigo | `#6366F1` |
| Delivered | Green | `#10B981` |
| Cancelled | Red | `#EF4444` |
| Returned | Amber | `#F59E0B` |

---

## Material Design 3 Features

✓ Rounded corners throughout  
✓ Subtle shadows (no elevation numbers)  
✓ Color scheme from seed color  
✓ Dynamic color adaptation  
✓ Consistent typography scale  
✓ Default sans-serif (Roboto equivalent)  

---

## Key Principles

1. **Hierarchy**: Size & color create clear visual hierarchy
2. **Contrast**: Primary indigo on white = 14:1 ratio
3. **Spacing**: Always multiples of 4px
4. **Consistency**: Same patterns repeated across app
5. **Accessibility**: Colors used with supporting text/icons
6. **Dark Mode Ready**: All colors have dark equivalents
7. **Commerce Focus**: Clear pricing, action buttons, badges

---

## Implementation Checklist

- [ ] Set CSS variables for all colors
- [ ] Define spacing utility classes
- [ ] Create button component (primary, outlined, text)
- [ ] Style card component with border + shadow
- [ ] Create input component with focus states
- [ ] Build product card with price display
- [ ] Implement bottom navigation
- [ ] Add dark mode toggle/system preference detection
- [ ] Test color contrast ratios
- [ ] Ensure touch targets ≥ 44px
- [ ] Responsive grid layout (2/3/4 columns)
- [ ] Typography scale (use CSS custom properties)

---

## Hex Color Swatches (Easy Copy)

```
Primary: #4F46E5
Primary Light: #6366F1
Primary Dark: #4338CA
Secondary: #10B981
Accent: #F3951A
Error: #EF4444
Success: #22C55E
Warning: #EAB308
Info: #3B82F6
Background: #FAFAFA
Surface: #FFFFFF
Text: #1F2937
Text Light: #6B7280
Border: #E0E0E0
Dark BG: #121212
Dark Surface: #1E1E1E
```

---

**Last Updated**: April 5, 2026  
**Platform**: Flutter App → Web Version  
**Material Design Version**: 3
