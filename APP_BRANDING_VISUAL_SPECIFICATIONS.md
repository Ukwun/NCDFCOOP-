# Coop Commerce - App Branding & Visual Assets Specifications

---

## EXECUTIVE SUMMARY

This document provides detailed technical specifications for all app branding assets required for the Coop Commerce v1.0.0 launch. These assets include app icons, splash screens, adaptive icons, app bar branding, and related visual elements for iOS and Android platforms.

**Document Date:** February 17, 2026  
**Target Launch:** February 28, 2026  
**Design Status:** Specifications Ready → **Awaiting Designer Implementation**

---

## 1. COLOR PALETTE & BRAND GUIDELINES

### Primary Colors
```
Brand Green (Cooperative Primary):
- HEX: #2D8A3F
- RGB: 45, 138, 63
- Usage: Primary buttons, app bar, active states
- Accessibility: WCAG AAA with white text

White (Clean Background):
- HEX: #FFFFFF
- RGB: 255, 255, 255
- Usage: Backgrounds, card surfaces
- Contrast: High for all text

Neutral Dark (Text):
- HEX: #212121
- RGB: 33, 33, 33
- Usage: Primary text, headings
- Accessibility: WCAG AAA compliant
```

### Secondary Colors
```
Success Green (Confirmations):
- HEX: #4CAF50
- Usage: Success messages, order confirmed

Warning Yellow (Alerts):
- HEX: #FFC107
- Usage: Important notices, low stock

Error Red (Problems):
- HEX: #F44336
- Usage: Errors, cancellations

Info Blue (Information):
- HEX: #2196F3
- Usage: Information, tips
```

### Brand Accent
```
Member Gold (Loyalty Program):
- HEX: #D4AF37
- RGB: 212, 175, 55
- Usage: Member badges, loyalty tier indicators, special offers
- Apply sparingly for visual emphasis
```

### Accessibility-Compliant Gradients
```
For Background Elements:
Dark to Light Green:
- Start: #2D8A3F (100%)
- End: #E8F5E9 (10% opacity)
- Usage: Hero sections, member card backgrounds

Light to Dark (Buttons):
- Start: #2D8A3F
- End: #1B5E20
- Usage: Interactive button gradients
```

---

## 2. TYPOGRAPHY & FONTS

### Primary Font Family: **Roboto** (Open Source, Free)
```
- Source: Google Fonts (fonts.google.com/specimen/Roboto)
- License: Apache 2.0 (permissive, no attribution required in app)
- Weights Used: 
  - Regular (400) - Body text
  - Medium (500) - Subheadings
  - Bold (700) - Headings, buttons
  - Light (300) - Secondary text

Installation:
1. Download from Google Fonts
2. Add to project fonts/ directory
3. Declare in pubspec.yaml under fonts: section
```

### Font Sizes (Dart/Flutter)
```
Headings:
- H1 (Page Title): 32sp, Bold
- H2 (Section Title): 24sp, Bold
- H3 (Subsection): 20sp, Medium
- H4 (Card Title): 18sp, Medium

Body Text:
- Regular Body: 16sp, Regular
- Small Body: 14sp, Regular
- Helper Text: 12sp, Regular
- Caption: 11sp, Light

Buttons:
- Button Text: 16sp, Medium
- Small Button: 14sp, Medium

Special:
- Member Badge Text: 14sp, Bold (using Member Gold color)
- Price: 18sp, Bold (using primary green)
```

### Font Pairing
```
Headlines: Roboto Bold or Medium
Body: Roboto Regular
Buttons: Roboto Medium
Technical data: Roboto Mono (monospace option for order IDs)
```

---

## 3. ICON SPECIFICATIONS

### App Icon (Primary Launcher Icon)

#### Android Icon Specifications
All dimensions in pixels (at 1x density). Generate at actual size listed below.

```
REQUIRED DENSITIES:
1. LDPI (120 dpi):    36 × 36 px   [ldpi/ic_launcher.png]
2. MDPI (160 dpi):    48 × 48 px   [mipmap-mdpi/ic_launcher.png]
3. HDPI (240 dpi):    72 × 72 px   [mipmap-hdpi/ic_launcher.png]
4. XHDPI (320 dpi):   96 × 96 px   [mipmap-xhdpi/ic_launcher.png]
5. XXHDPI (480 dpi):  144 × 144 px [mipmap-xxhdpi/ic_launcher.png]
6. XXXHDPI (640 dpi): 192 × 192 px [mipmap-xxxhdpi/ic_launcher.png]

Plus Web:
7. Web Icon:          192 × 192 px [web/icons/Icon-192.png]
8. Web Large:         512 × 512 px [web/icons/Icon-512.png]
```

#### Icon Design Guidelines
```
Safe Area (Active Zone):
- Keep important content within center 72% of icon
- Safe area: Build margin of 10% from edges

Design Style:
- Flat, modern design (no 3D or skeuomorphism)
- Minimum line weight: 2px
- Color: Brand Green (#2D8A3F) primary, White secondary
- Shape: Rounded square (8px corner radius, device-dependent scaling)

Icon Concept Options:
Option A: Leaf + Shopping Bag
  - Green leaf (representing cooperative/sustainability)
  - Overlaid with stylized shopping bag
  - Represents: Community + Commerce

Option B: Connected Hands + Coin
  - Three hands forming circle
  - Coin in center
  - Represents: Community + Commerce + Fair Trade

Option C: Green Circle + Stylized "C"
  - Brand Green circle background
  - Modern "C" monogram (representing Coop)
  - White foreground shapes
  - Represents: Cooperative, Connected, Commerce

RECOMMENDED: Option A (Leaf + Bag) for visual uniqueness

Color Breakdown:
- Primary: Brand Green (#2D8A3F)
- Secondary: White (#FFFFFF)
- No gradients in main icon (solid colors for clarity)
- Shadow: Drop shadow 0.5px, 30% opacity (for depth on light backgrounds)
```

#### Icon Placement in Project
```
android/
└── app/
    └── src/
        └── main/
            └── res/
                ├── mipmap-ldpi/ic_launcher.png
                ├── mipmap-mdpi/ic_launcher.png
                ├── mipmap-hdpi/ic_launcher.png
                ├── mipmap-xhdpi/ic_launcher.png
                ├── mipmap-xxhdpi/ic_launcher.png
                ├── mipmap-xxxhdpi/ic_launcher.png
                └── mipmap-anydpi-v33/ic_launcher.xml (Adaptive)

web/
└── icons/
    ├── Icon-192.png
    └── Icon-512.png

ios/
└── Runner/
    └── Assets.xcassets/
        └── AppIcon.appiconset/
            ├── Icon-App-20x20@2x.png
            ├── Icon-App-20x20@3x.png
            ├── Icon-App-29x29@2x.png
            ├── Icon-App-29x29@3x.png
            ├── Icon-App-40x40@2x.png
            ├── Icon-App-40x40@3x.png
            ├── Icon-App-60x60@2x.png
            ├── Icon-App-60x60@3x.png
            ├── Icon-App-76x76@1x.png
            ├── Icon-App-76x76@2x.png
            ├── Icon-App-83.5x83.5@2x.png
            ├── Icon-App-1024x1024@1x.png
            └── Contents.json
```

### Adaptive Icon (Android 8+)

#### Adaptive Icon Specifications
```
Required Layers:
1. BACKGROUND LAYER: 108 × 108 px (can be solid color or pattern)
2. FOREGROUND LAYER: 108 × 108 px (transparent background)

Safe Area (Visible Zone):
- Circle masked at center
- Diameter: 72 px (center 2/3 of 108 × 108)
- Keep essential content within this circle

XML Configuration (anydpi-v33):
Location: android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml

Content:
```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
```

Background Recommendations:
- Solid Green: #2D8A3F (safest option)
- Benefits: Consistency with branding, high visibility

Foreground Recommendations:
- Simplified icon shape (leaf + bag)
- Pure white or Brand Green shapes
- Centered on canvas
- Leave 36px border transparent
```

#### Adaptive Icon Assets
```
Files to Generate:
1. ic_launcher_background.9.png (9-patch version)
   OR set as color in colors.xml: <color name="ic_launcher_background">#2D8A3F</color>
   RECOMMENDED: Use color (simpler, scalable)

2. ic_launcher_foreground.png (108 × 108)
   - Main icon design (25-30% actual content by area)
   - White with Brand Green accents
   - Centered composition
```

### Web Icon Specifications
```
PNG Format Requirements:
- Format: PNG with transparency (RGBA)
- Resolution: 192 × 192 px (standard), 512 × 512 px (large)
- Transparency: Required (not white background)
- Color space: sRGB (no embedded profile)

Placement in pubspec.yaml:
flutter:
  assets:
    - web/icons/
```

---

## 4. SPLASH SCREEN SPECIFICATIONS

### Android Splash Screen (Android 12+)

#### Splash Screen Design
```
OVERALL LAYOUT:
- Background: Brand Green (#2D8A3F) solid color
- Animation Duration: 500ms fade-in
- Safe Area: Center 80% of screen (margin for Android system UI)

ANIMATED ELEMENTS:
1. Logo Entrance (0-300ms): Logo fades in from 0.5x to 1x scale
2. Text Entrance (150-400ms): App name "Coop Commerce" fades in below logo
3. Branding Line (200-500ms): Green accent line underneath text slides in

DIMENSIONS:
Phone Portrait (default):
- Width: 1080 px
- Height: 1920 px
- Safe Zone: 200px margins on all sides

Phone Landscape:
- Width: 1920 px
- Height: 1080 px
- Safe Zone: Same proportional margins

Content Positioning:
- Logo: Centered horizontally, vertical center -10%
- App Name: Centered horizontally, -30% from vertical center
- Accent Line: Full width, bottom 40% of screen

Font and Text:
- App Name: "Coop Commerce"
- Font: Roboto Bold, 48sp
- Color: White (#FFFFFF)
- Alignment: Centered
```

#### Android XML Configuration
```xml
<!-- File: android/app/src/main/res/values-v31/styles.xml -->
<style name="SplashScreen" parent="Theme.MaterialComponents">
    <item name="android:windowBackground">@drawable/splash_bg</item>
    <item name="android:windowNoTitle">true</item>
    <item name="android:windowActionBar">false</item>
    <item name="android:windowFullscreen">false</item>
</style>

<!-- File: android/app/src/main/res/drawable/splash_bg.xml -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_bg" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_logo" />
    </item>
</layer-list>

<!-- Color Definition: android/app/src/main/res/values/colors.xml -->
<color name="splash_bg">#2D8A3F</color>
```

#### Required Splash Assets
```
1. splash_logo.png (centered logo)
   - Size: 400 × 400 px
   - Format: PNG with transparency
   - Content: Coop Commerce leaf + bag icon + app name text

2. splash_bg.xml (background definition)
   - Solid green color (#2D8A3F)
   - Layer-based composition

File Placement:
android/app/src/main/res/drawable/splash_logo.png
android/app/src/main/res/drawable/splash_bg.xml
```

### iOS Splash Screen

#### iOS Launch Screen Configuration
```
Xcode Requirements (Info.plist):
- Storyboard file: LaunchScreen.storyboard (Flutter default)
- iOS 11+: Uses safe areas automatically

Design Specifications:
- Background: Brand Green (#2D8A3F)
- Logo: 200 × 200 px, centered
- Safe Area: Avoid top 40px (status bar) and bottom 30px (notch/home indicator)
- Animation: System default fade-in (automatic)

Safe Area Dimensions:
Portrait:
- Top: 44px (status bar + safe area)
- Bottom: 34px (home indicator on notched devices)
- Sides: 0px (full width)

Landscape:
- Top: 24px
- Bottom: 24px  
- Left: 44px (notch)
- Right: 44px (notch)
```

#### iOS Images Required
```
1. LaunchImage@1x.png (320 × 480 px) - iPhone 5
2. LaunchImage@2x.png (640 × 960 px) - Early iPhone
3. LaunchImage@3x.png (750 × 1334 px) - Modern iPhone
4. LaunchImageIPad.png (768 × 1024 px) - iPad
5. LaunchImageIPad@2x.png (1536 × 2048 px) - iPad Retina

All images: Center logo, Brand Green background

File Placement:
ios/Runner/Assets.xcassets/LaunchImage.imageset/
```

---

## 5. APP BAR & NAVIGATION BRANDING

### App Bar (Header) Design

#### Android Material Design (Recommended)
```
Height: 56 dp (56px at mdpi density)
Background Color: Brand Green (#2D8A3F)
Elevation/Shadow: 4 dp shadow

Text Styling:
- Title Font: Roboto Bold, 20sp
- Title Color: White (#FFFFFF)
- Alignment: Left-aligned, 16dp margin from edge

Icon Styling:
- Size: 24 × 24 dp
- Color: White (#FFFFFF)
- Spacing: 8dp from edge

Content:
- Left: Menu/Back icon (if applicable)
- Center: App title or screen title
- Right: Action icons (Search, Add, Menu) as needed
```

#### App Title in Header
```
Option A (App-Wide):
Display "Coop Commerce" at top-left of every screen

Option B (Screen-Specific):
Display current screen name (e.g., "Products", "Orders", "Member")
RECOMMENDED: Option B (better UX, clearer navigation)

Implementation:
```dart
AppBar(
  backgroundColor: Color(0xFF2D8A3F), // Brand Green
  elevation: 4,
  title: Text(
    "Coop Commerce", // Or current screen name
    style: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  leading: IconButton(
    icon: Icon(Icons.menu),
    color: Colors.white,
    onPressed: () => Scaffold.of(context).openDrawer(),
  ),
)
```
```

### Navigation Drawer Branding
```
Header Section:
- Height: 172 dp
- Background: Brand Green (#2D8A3F) with member gold accent
- Logo: 80 × 80 dp, centered at top (20dp margin)
- User Name: Roboto Medium, 16sp, white
- Email: Roboto Regular, 14sp, white with 70% opacity
- Member Badge: If applicable, show tier (e.g., "Platinum Member")

Color Coding:
- Selected Item: Background light green (#E8F5E9)
- Selected Text: Brand Green (#2D8A3F)
- Unselected: Dark gray text
- Divider: Light gray (#EEEEEE)

Navigation Items:
- Home
- Products
- Orders
- Member (if member)
- Account Settings
- Contact Support
- Help
- Logout

Font:
- Item Label: Roboto Regular, 14sp
- Group Header: Roboto Medium, 12sp (all caps)
```

### Bottom Navigation Bar
```
Background: White (#FFFFFF) with 1px divider line
Height: 56 dp
Elevation: 8 dp (floating effect)
Active Color: Brand Green (#2D8A3F)
Inactive Color: Gray (#757575)

Tab Order (Left to Right):
1. Home (icon: home, label: "Home")
2. Shop (icon: shopping_bag, label: "Shop")
3. Orders (icon: receipt_long, label: "Orders")
4. Member (icon: card_membership, label: "Member")
5. Account (icon: person, label: "Account")

Font:
- Label: Roboto Medium, 12sp
- Spacing: 4dp between icon and label
- Icon Size: 24 × 24 dp
```

---

## 6. BUTTON & CTA BRANDING

### Primary Button (Call-to-Action)
```
Background: Brand Green (#2D8A3F)
Text: White (#FFFFFF), Roboto Medium, 16sp
Padding: 16px vertical, 24px horizontal
Border Radius: 4px
Elevation: 2 dp (subtle shadow)
Pressed State: Darker green (#1B5E20)
Disabled State: Gray (#CCCCCC)

Usage: "Add to Cart", "Checkout", "Place Order", "Confirm"

Ripple Effect:
- Use Material InkWell for ripple feedback
- Ripple Color: White with 30% opacity
- Radius: Extends 2px beyond button bounds
```

### Secondary Button (Alternative Action)
```
Background: Transparent
Border: 2px Brand Green (#2D8A3F)
Text: Brand Green (#2D8A3F), Roboto Medium, 16sp
Padding: 14px vertical, 24px horizontal
Pressed State: Light green background (#F1F8F5)
Disabled State: Gray border, gray text

Usage: "Cancel", "Learn More", "Continue Shopping"
```

### Tertiary Button (Less Emphasis)
```
Background: Transparent
Text: Brand Green (#2D8A3F), Roboto Regular, 14sp
No border
No elevation
Underline: Optional on hover
Padding: 8px vertical, 12px horizontal

Usage: "Skip", "Close", "Dismiss", small text links
```

### Member-Specific Button
```
Background: Member Gold gradient (into Brand Green)
Text: White, Roboto Bold, 16sp
Border Radius: 8px (more rounded than standard)
Icon: Star or member badge before text
Usage: "Unlock Member Benefits", "Join Member Program"
```

---

## 7. CARD & COMPONENT BRANDING

### Product Card Design
```
Background: White (#FFFFFF)
Border Radius: 8px
Elevation: 2 dp
Spacing: 16 dp padding inside, 8 dp between cards

Image Section:
- Aspect Ratio: 1:1 (square)
- Corners: Top corners 8px radius
- Overlay: "Sale" or "New" badge top-right

Content Section:
- Product Name: Roboto Medium, 16sp, dark gray
- Rating: 14sp, with star icon
- Price Line:
  - Regular Price: Strikethrough if on sale
  - Sale Price: Roboto Bold, 18sp, Brand Green
  - Member Price: Member Gold accent, smaller (14sp)

Bottom Action:
- "Add to Cart" button (primary style)
- Heart icon (wishlist toggle) top-right
```

### Member Card Design
```
Background: Gradient (Brand Green top → light green bottom)
Overlay: Semi-transparent dark overlay for text contrast
Corner Radius: 12px
Shadow: 4 dp elevation

Front Side:
- Logo: Coop Commerce logo, top-left
- Member Name: White, Roboto Bold, 20sp, left-aligned
- Membership Tier: Member Gold accent, Roboto Medium, 14sp
- Member ID: Monospace font, white, 12sp
- Bottom-right: Member benefits microcopy (white, 11sp)

Back Side (Tap to Reveal):
- Points Balance: "Points: 2,450", Roboto Bold, 32sp, center
- Tier Progress: Visual bar showing progress to next tier
- Validity: "Valid until December 31, 2026"
- Card Number (for reference): Monospace, 12sp

Animation: Smooth flip transition (300ms)
```

### Order Status Card
```
Background: White with left border (4px color-coded)
- Pending: Yellow (#FFC107)
- Processing: Blue (#2196F3)
- Shipped: Cyan (#00BCD4)
- Delivered: Green (#4CAF50)
- Cancelled: Red (#F44336)

Content:
- Order ID: Top-left, Roboto Medium, 14sp
- Order Date: Top-right, gray, 12sp
- Items: "3 items" text
- Total: Roboto Bold, 18sp, black
- Status: Colored tag, white text, 12sp rounded pill
- Action Button: Bottom-right (based on status)

Height: 120 dp minimum
Padding: 16 dp
```

---

## 8. BADGE & INDICATOR SPECIFICATIONS

### Member Tier Badges
```
Bronze Tier:
- Color: #CD7F32 (bronze)
- Icon: Single star outline
- Text: "Bronze Member" or just star icon

Silver Tier:
- Color: #C0C0C0 (silver)
- Icon: Double star outline
- Text: "Silver Member"

Gold Tier:
- Color: #D4AF37 (member gold)
- Icon: Triple star solid
- Text: "Gold Member" (most common)

Platinum Tier:
- Color: #E5E4E2 (platinum)
- Icon: Four-star crown
- Text: "Platinum Member" (top tier)

Badge Size Options:
- Small (inline): 24 × 24 px
- Medium (card heading): 32 × 32 px
- Large (avatar): 40 × 40 px
```

### Sale & Promo Badges
```
New Product Badge:
- Shape: Rounded pill
- Background: Brand Green (#2D8A3F)
- Text: "NEW", white, Roboto Bold, 10sp
- Padding: 4px × 8px
- Placement: Top-right corner of product image

Sale Badge:
- Shape: Ribbon (angled)
- Background: Error Red (#F44336)
- Text: "SALE", white, Roboto Bold, 11sp
- Placement: Top-right corner, overlaid on image

Member Exclusive:
- Shape: Rounded pill with gold border
- Background: Transparent
- Border: 2px Member Gold (#D4AF37)
- Text: "MEMBER ONLY", gold, Roboto Medium, 10sp
- Icon: Member star prefix

Featured Badge:
- Shape: Star burst
- Background: Member Gold (#D4AF37)
- Text/Icon: Solid gold star
- Placement: Top-left corner
```

---

## 9. ILLUSTRATION & IMAGERY STYLE

### Photography Style
```
Product Photos:
- White background (pure white, #FFFFFF)
- Consistent studio lighting
- 3/4 angle for dimensional feel
- High resolution (3000+ × 3000px source)
- Professional quality (no blurry or poorly lit images)
- Consistent shadow depth

User Avatar Defaults:
- Colored initials on gradient background
- 64 × 64 px minimum
- Color set: Varies by initial (avoid branding colors for individuality)
```

### Illustration Style
```
Empty States:
- **Style:** Simple, flat design with 1-2 colors
- **Color:** Brand Green + light gray
- **Lines:** Clean, simple shapes (circles, rounded squares, simple icons)
- **Emotion:** Friendly, approachable, motivating

Examples:
- Empty Cart: Simple shopping bag outline with "Shop Now" suggestion
- No Orders: Package icon with "Start Shopping" CTA
- Search Results: Magnifying glass with "Try different search"

Loading States:
- **Animation:** Subtle rotation or pulse (not jarring)
- **Duration:** ~1.2 second cycle
- **Color:** Brand Green animated element on light background
- **Style:** Use community shapes (green leaf pulse, gear rotation)

Error States:
- **Icon:** Simplified error symbol (exclamation mark in circle)
- **Color:** Error Red (#F44336)
- **Message:** Plain language explanation + contact support link
- **Recovery:** Clear action button to retry or go back

Success States:
- **Icon:** Checkmark in circle
- **Color:** Success Green (#4CAF50)
- **Message:** Confirmation message
- **Animation:** Brief pulse or bounce (100-300ms)
```

---

## 10. ANIMATION & MOTION SPECIFICATIONS

### Standard Transitions
```
Standard Duration: 300ms (Android Material Design default)
Easing: EaseInOut (smooth acceleration/deceleration)

Dartimplementation:
const Duration kDefaultAnimDuration = Duration(milliseconds: 300);
const Curve kDefaultAnimCurve = Curves.easeInOut;
```

### Specific Animations
```
Button Press Feedback:
- Ripple effect: 200ms fade-in, 600ms fade-out
- Color: White, 30% opacity
- Radius: 2px beyond button bounds

Screen Transitions:
- Default: Fade transition (300ms)
- Push/Pop: Slide from right to left (400ms)
- Modal: Slide up from bottom (300ms)

Loading Spinner:
- Rotation: 360° in 1.2 seconds, continuous
- Color: Brand Green #2D8A3F
- Size: 48 × 48 dp standard, 64 × 64 dp large

Member Card Flip:
- Duration: 600ms
- Curve: EaseInOut
- Full 3D rotation flip effect

List Item Discovery:
- Slide-in from left: 200ms on appear
- Staggered delay: 50ms per item
```

---

## 11. DARK MODE SUPPORT (Future Consideration)

### Dark Mode Colors
```
Background:
- Primary: #121212 (very dark gray)
- Secondary: #1E1E1E (slightly lighter)
- Surface: #202020 (cards, elevated)

Text:
- Primary: #FFFFFF (white)
- Secondary: #B3B3B3 (light gray)

Brand Colors (Adjusted):
- Brand Green: #4CAD5B (lighter shade for contrast)
- Member Gold: #E5C547 (adjusted for visibility)

Accessibility:
- Minimum contrast: 4.5:1 for body text
- Enhanced contrast: 7:1 for important elements
```

**Status: NOT REQUIRED for v1.0.0 launch (planned for v1.1)**

---

## 12. RESPONSIVE DESIGN BREAKPOINTS

### Screen Size Categories
```
Small Phones:
- Screen Width: 360-480 dp (portrait)
- Safe Margins: 16 dp sides
- Grid Columns: 1
- Font Sizes: Reduced 10% from standard

Standard Phones:
- Screen Width: 480-600 dp (portrait)
- Safe Margins: 16 dp sides
- Grid Columns: 1 or 2 (product grid)
- Font Sizes: Standard sizes

Large Phones:
- Screen Width: 600+ dp (portrait) / 800+ dp (landscape)
- Safe Margins: 24 dp sides
- Grid Columns: 2-3 (product grid)
- Font Sizes: Standard sizes

Tablets:
- Screen Width: 600+ dp (portrait) and landscape
- Safe Margins: 32 dp sides
- Grid Columns: 3-4 (product grid)
- Layout: Multi-column possible

Foldable Devices:
- Treat as large device with safety margins
- Use MediaQuery to detect hinge position
- Design for continuous content flow
```

---

## 13. ASSET DELIVERY FORMAT & CHECKLIST

### File Format Requirements
```
Icons:
- Format: PNG (RGBA, with transparency)
- Optimization: Compressed with pngquant or similar
- Color Profile: sRGB (or untagged)
- Naming: ic_launcher.png, ic_launcher_foreground.png, etc.

Splash Screens:
- Format: PNG or 9-patch (9.png)
- Optimization: Compressed
- Dimensions: As specified per section 4
- Naming: splash_logo.png, splash_bg.xml

Illustrations:
- Format: PNG (transparent) or SVG (scalable)
- Optimization: Compressed
- Naming: Descriptive (e.g., empty_state_cart.png)

Color Resources:
- Format: XML (colors.xml)
- Centralized in: android/app/src/main/res/values/colors.xml
- Example:
```xml
<color name="brand_green">#2D8A3F</color>
<color name="member_gold">#D4AF37</color>
```
```

### Delivery Package Structure
```
/branding_assets_v1.0.0/
│
├── /icons/
│   ├── app_icon_512x512.png (source - for backup)
│   ├── ic_launcher_ldpi.png (36x36)
│   ├── ic_launcher_mdpi.png (48x48)
│   ├── ic_launcher_hdpi.png (72x72)
│   ├── ic_launcher_xhdpi.png (96x96)
│   ├── ic_launcher_xxhdpi.png (144x144)
│   ├── ic_launcher_xxxhdpi.png (192x192)
│   ├── ic_launcher_foreground.png (108x108)
│   ├── ic_launcher_background.png (108x108, optional)
│   ├── Icon-192.png (web)
│   └── Icon-512.png (web)
│
├── /splash/
│   ├── splash_logo.png (400x400)
│   ├── splash_bg.xml
│   ├── LaunchImage_320x480.png (iOS)
│   ├── LaunchImage_750x1334.png (iPhone X/11/12)
│   └── LaunchImageIPad_1536x2048.png (iPad)
│
├── /illustrations/
│   ├── empty_state_cart.png
│   ├── empty_state_orders.png
│   ├── empty_state_search.png
│   └── [additional illustrations]
│
├── /colors/
│   ├── colors.xml (Android XML)
│   └── brand_guidelines.txt (hex codes reference)
│
├── BRANDING_GUIDELINES.md (this file)
├── FONT_INSTALLATION_GUIDE.md (Roboto setup)
└── IMPLEMENTATION_CHECKLIST.md
```

### Implementation Checklist
```
✅ Icons (Android):
- [ ] Copy all ic_launcher*.png to correct mipmap folders
- [ ] Configure ic_launcher_foreground.png for adaptive icon
- [ ] Test icon display on various Android versions
- [ ] Verify icon appears correctly in Play Store preview

✅ Icons (iOS):
- [ ] Generate all LaunchImage sizes
- [ ] Add to IconIcon.appiconset
- [ ] Update Contents.json with correct specifications
- [ ] Test icon display on various iOS devices

✅ Splash Screens:
- [ ] Copy splash_logo.png to drawable folder
- [ ] Create/update styles.xml for splash theme
- [ ] Test splash screen timing (< 1 second total)
- [ ] Verify no white flash before splash appears

✅ Colors:
- [ ] Create/update colors.xml with all brand colors
- [ ] Update AppBar backgroundColor references
- [ ] Update button color definitions
- [ ] Verify accessibility contrast ratios

✅ Fonts:
- [ ] Download Roboto from Google Fonts
- [ ] Add font files to fonts/ directory
- [ ] Update pubspec.yaml with font declarations
- [ ] Test font rendering on device

✅ Components:
- [ ] Update AppBar styling in main app
- [ ] Update button styles (primary, secondary, tertiary)
- [ ] Update card styling for product/order/member
- [ ] Verify consistent brand color usage throughout

✅ Navigation:
- [ ] Update Drawer header styling
- [ ] Update BottomNavigationBar colors/labels
- [ ] Test navigation across all screens
- [ ] Verify active state colors

✅ Testing:
- [ ] Run on API 21 (minimum supported)
- [ ] Run on latest API (33+)
- [ ] Test in Light Mode
- [ ] Check accessibility contrast ratios
- [ ] Test various screen sizes (phones, tablets, landscape)
- [ ] Verify animations are smooth (60 fps)

✅ PlayStore Submission:
- [ ] Icon displays correctly in Store listing
- [ ] Branding colors match marketing materials
- [ ] All assets are optimized (< 1MB individual files)
- [ ] No copyright/IP issues with assets
```

---

## 14. DESIGN TOOLS & RESOURCES

### Recommended Design Tools
1. **Figma** (Recommended)
   - Cloud-based, collaborative
   - Free tier available
   - Easy icon/asset export
   - Android/iOS specific plugins
   - Website: figma.com

2. **Adobe XD**
   - Professional tool
   - Comprehensive UI kit templates
   - Export to multiple formats
   - Website: adobe.com/products/xd

3. **Sketch** (Mac only)
   - Industry standard for iOS design
   - Extensive plugin library
   - Asset exporting tools
   - Website: sketch.com

4. **Photoshop** (Legacy option)
   - Compatible with all platforms
   - Extensive filters and effects
   - Slicing tools for icon generation
   - Website: adobe.com/products/photoshop

### Helpful Resources
```
Icon Inspiration:
- Google Material Icons: material.io/icons
- Material Design Guidelines: material.io
- Material You Design: https://m3.material.io

Color Tools:
- Contrast Checker: webaim.org/resources/contrastchecker/
- Color Palette Generator: coolors.co
- Material Color Tool: materialpalette.com

Android Specific:
- Android Design Guidelines: developer.android.com/design
- Density Calculator: pixplicity.com/dp-px-converter/
- Adaptive Icon Preview: romannurik.github.io/AndroidAssetStudio/icons-adaptive-web.html

iOS Specific:
- iOS Human Interface Guidelines: developer.apple.com/design/
- Xcode Asset Catalog Guide: developer.apple.com/library/archive/documentation/
- iOS Icon Sizes Reference: developer.apple.com/design/human-interface-guidelines/

Flutter Impact:
- Flutter Widget Styling: flutter.dev/docs/development/ui/widgets
- Material Design in Flutter: flutter.dev/docs/development/ui/material
- Safe Area on Flutter: flutter.dev/docs/development/ui/layout/building-adaptive-apps
```

---

## 15. NEXT STEPS & TIMELINE

### Designer Handoff (Days 1-2: Phase 1)
1. **Provide Specifications** ✅ (This document)
2. **Provide Brand Guidelines** ✅ (Color palette, typography, style)
3. **Designer Reviews** → Clarify any questions
4. **Initial Icon Concepts** → Approval choice (A, B, or C)

### Design Production (Days 2-3)
1. **Icon Design** → All densities at specified sizes
2. **Splash Screen** → Android + iOS versions
3. **Illustration Assets** → Empty states, loading, error states
4. **Color XML Files** → Ready for integration

### Development Integration (Days 3-4)
1. **Copy Assets** → To correct project directories
2. **Configure Styling** → Update styles.xml, pubspec.yaml, etc.
3. **Update Components** → AppBar, buttons, cards, navigation
4. **Testing** → Visual verification on devices

### Quality Assurance (Days 4-5: Phase 2)
1. **Visual Testing** → On multiple devices and Android versions
2. **Contrast Testing** → Accessibility compliance
3. **Performance Testing** → Icon/asset load times
4. **PlayStore Preview** → Verify in-store appearance

### Launch (Day 5+)
1. **Final Adjustments** → Any last-minute tweaks
2. **PlayStore Upload** → Asset submission
3. **PlayStore Review** → Approval process (24-72 hours)
4. **Launch Day** → App goes live

---

## 16. BRANDING CONSISTENCY GUIDELINES

### What Makes Coop Commerce Visually Recognizable
```
1. SIGNATURE COLOR: Brand Green (#2D8A3F)
   - Every primary button uses this color
   - AppBar always this color
   - Member tier badges include this color
   - Distinctly different from competitor apps

2. TYPOGRAPHY: Roboto Font Family
   - Consistent across all platforms (Flutter/web)
   - Weights used consistently (bold for headings, regular for body)
   - Never use other sans-serif fonts in app

3. MEMBER GOLD (#D4AF37) ACCENT
   - Used specifically for member-only features
   - Creates visual distinction for member benefits
   - Sparingly applied (don't overuse)

4. ROUNDED ELEMENTS
   - Cards: 8px border radius
   - Buttons: 4px border radius
   - Member features: 12px border radius (more rounded)
   - Modern, friendly aesthetic

5. WHITE SPACE & BREATHING ROOM
   - 16dp standard padding/margin
   - 24dp for larger layouts (tablets)
   - Cards separated by white space, not borders

6. ICON STYLE
   - Simple, flat design
   - Consistent stroke weight (2px)
   - Aligned to 4px grid
   - Friendly, approachable (not corporate)

7. PHOTOGRAPHY
   - Clean white backgrounds for products
   - Professional studio lighting
   - Consistent shadows at same angle
   - High-resolution source images
```

### Brand Compliance Checklist
Use this to verify consistency:
- [ ] AppBar is Brand Green (#2D8A3F)
- [ ] Primary buttons use Brand Green
- [ ] Text uses Roboto font family
- [ ] Buttons have 4px border radius
- [ ] Cards have 8px border radius
- [ ] Padding/margins follow 8dp/16dp grid
- [ ] Member-only features include gold accent
- [ ] Icons are simple and flat
- [ ] Product images on white background
- [ ] Color contrast meets WCAG AAA (4.5:1 minimum)

---

**Document Version:** 1.0.0  
**Created:** February 17, 2026  
**Prepared By:** Coop Commerce Design Team  
**Status:** Ready for Designer Implementation  
**Target Completion:** February 21, 2026 (Design)  
**Target Integration:** February 23, 2026 (Dev)  
**Launch Date:** February 28, 2026

---

## APPENDIX: QUICK REFERENCE COLORS

```
Primary Brand Color:    #2D8A3F (Brand Green)
Member Gold:            #D4AF37
Success:                #4CAF50
Warning:                #FFC107
Error:                  #F44336
Info:                   #2196F3
White:                  #FFFFFF
Dark Text:              #212121
Light Gray:             #757575
Very Light Gray:        #EEEEEE
Disabled:               #CCCCCC
Border:                 #E0E0E0
```

**All specifications in this document are design-ready and can be directly provided to designer tools or development teams for implementation.**
