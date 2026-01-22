# Assets Guide for COOP Commerce

## Required Assets

### Images
Place your image files in `assets/images/`:

1. **NCDF_logo1.png** (Required)
   - The NCDF cooperative logo shown on the welcome screen
   - Recommended size: 280x280 or larger (will scale to 140x140)
   - Format: PNG or JPG with transparency preferred
   - Location: `assets/images/NCDF_logo1.png`

### Icons
Place your icon files in `assets/icons/`:

1. **signal.png** (Status bar icon)
   - Cell signal strength indicator
   - Size: 12x12
   - Location: `assets/icons/signal.png`

2. **wifi.png** (Status bar icon)
   - WiFi indicator
   - Size: 12x12
   - Location: `assets/icons/wifi.png`

3. **battery.png** (Status bar icon)
   - Battery indicator
   - Size: 16x16
   - Location: `assets/icons/battery.png`

## Steps to Add Assets

1. Copy your image files to the respective directories
2. Run `flutter pub get` to refresh the asset references
3. Run `flutter clean` if assets aren't loading
4. Rebuild the app with `flutter run`

## Asset Organization

```
assets/
├── images/
│   ├── NCDF_logo1.png          ← Add NCDF logo here
│   ├── product_placeholder.png ← For product images
│   └── ... (other product images)
└── icons/
    ├── signal.png               ← Status bar icons
    ├── wifi.png
    ├── battery.png
    └── ... (other icons)
```

## Notes

- All asset paths in code are case-sensitive
- Make sure files are actually in the directories before running the app
- If assets don't show, try `flutter clean && flutter pub get && flutter run`
- For best results, use vector-based formats (SVG converted to PNG) for icons
- Images should be 2x or 3x resolution for better quality on different devices

## Current Implementation

The WelcomeScreen currently references:
- `assets/images/NCDF_logo1.png` - Main logo
- `assets/icons/signal.png` - Signal icon
- `assets/icons/wifi.png` - WiFi icon
- `assets/icons/battery.png` - Battery icon

**Status**: Waiting for these files to be added to the assets directories.
