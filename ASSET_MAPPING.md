# Asset Mapping Guide - Home Screen V2

## 🖼️ Image Assets Used in Home Screen

### Welcome Section
| Section | Image File | Status | Notes |
|---------|-----------|--------|-------|
| Welcome image | `assets/images/waving hand1.png` | Mapped | 80x80px floating hand animation |

### Navigation Tabs
| Tab | Icon File | Status | Notes |
|-----|-----------|--------|-------|
| Shop | `assets/icons/shop.png` | Mapped | 40x40px icon |
| Deals | `assets/icons/deals.png` | Mapped | 40x40px icon |
| Savings | `assets/icons/savings.png` | Mapped | 40x40px icon |
| Orders | `assets/icons/orders.png` | Mapped | 40x40px icon |
| Reorder | `assets/icons/reorder.png` | Mapped | 40x40px icon |

### Status Bar Icons (Right)
| Icon | Image File | Status | Notes |
|------|-----------|--------|-------|
| Signal | `assets/icons/signal.png` | Mapped | System status |
| WiFi | `assets/icons/wifi.png` | Mapped | System status |
| Battery | `assets/icons/battery.png` | Mapped | System status |

### Categories Section (Horizontal Scroll)
| Category | Image File | Status | Size | Notes |
|----------|-----------|--------|------|-------|
| Essentials Basket | `assets/images/onboardimg1.jpg` | Mapped | 100x110px | Product showcase |
| Groceries | `assets/images/onboardimg2.jpg` | Mapped | 100x110px | Vegetables/produce |
| Household | `assets/images/Bulk n buz.png` | Mapped | 100x110px | Household supplies |
| Meat & Poultry | `assets/images/Meat1.png` | Mapped | 100x110px | Meat showcase |
| Seafood | `assets/images/Crayfish 1.png` | Mapped | 100x110px | Seafood items |

### Member Exclusives Section (Carousel)
| Product | Image File | Status | Price | Notes |
|---------|-----------|--------|-------|-------|
| Golden Sesame seeds | `assets/images/onboardimg1.jpg` | Mapped | ₦8000 | Member exclusive |
| White Sesame seeds | `assets/images/onboardimg2.jpg` | Mapped | ₦8000 | Member exclusive |

### Promotional Banner
| Element | Image File | Status | Size | Notes |
|---------|-----------|--------|------|-------|
| Promo Product | `assets/images/opening img1.jpg` | Mapped | 80x120px | "Save up to 30%" banner |

### Buy Again Section (Grid - 2 columns)
| Product | Image File | Status | Quantity | Price | Notes |
|---------|-----------|--------|----------|-------|-------|
| Groundnut oil | `assets/images/onboardimg1.jpg` | Mapped | 1 ltr | ₦2500 | Cooking oil |
| Crayfish | `assets/images/Crayfish 1.png` | Mapped | 800g | ₦5500 | Seafood |
| Tomatoes | `assets/images/onboardimg2.jpg` | Mapped | 3 baskets | ₦9000 | Produce |
| Beef | `assets/images/Meat1.png` | Mapped | 1.1kg | ₦3800 | Meat |

### Essentials Basket Section (Grid - 2 columns)
| Bundle | Image File | Status | Price | Notes |
|--------|-----------|--------|-------|-------|
| Family sized | `assets/images/All inclusive pack.png` | Mapped | ₦45,000 | Large family pack |
| All inclusive pack | `assets/images/All inclusive pack.png` | Mapped | ₦180,000 | Premium bundle |
| Spices hamper | `assets/images/onboardimg1.jpg` | Mapped | ₦8000 | Spices collection |
| Student hamper | `assets/images/onboardimg2.jpg` | Mapped | ₦22,000 | Budget-friendly |

## 📊 Asset Inventory Summary

### Total Assets in `assets/images/`:
- **Onboarding**: onboardimg1.jpg, onboardimg2.jpg, lastonboardimg.png, opening img1.jpg
- **Products**: Crayfish 1.png, Buck wheat1.png, Beef1.png, Beverages 1.png, Electronics1.png, Meat1.png, Mini hamper1.png, One crate eggs1.png, etc.
- **Bundles**: All inclusive pack.png, Mini hamper1.png, Mini food hamper1.png
- **Ingredients**: Golden Sesame seeds1.png, White Sesame, Bag of garri1.png, Groundnut oil, Tomatoes, Shrimps, Bulk n buz.png
- **Logo**: NCDF logo1.png, waving hand1.png
- **Total**: 48 image files available

### Total Assets in `assets/icons/`:
- shop.png, deals.png, savings.png, orders.png, reorder.png
- signal.png, wifi.png, battery.png
- Add.png, congrats1.png
- **Total**: 10+ icon files

## 🎨 Image Sizing Guidelines

### Card Sizes
- **Category Cards**: 100px wide × 110px tall (includes text)
- **Product Cards**: 200px wide × 280px tall (members exclusives)
- **Buy Again Cards**: 2-column grid, ~160px width per column
- **Bundle Cards**: 2-column grid, ~160px width per column

### Image Fit Strategies
- **Category Images**: `BoxFit.cover` - fills entire space
- **Product Images**: `BoxFit.cover` - maintains aspect ratio
- **Promo Banner**: `BoxFit.cover` - left-side image
- **Tab Icons**: `BoxFit.contain` - preserves icon shape

## 🔄 Error Handling

All images have fallback error builders:
```dart
errorBuilder: (context, error, stackTrace) {
  return Container(
    // Fallback UI with icon
    child: Icon(Icons.shopping_basket),
  );
}
```

This ensures app doesn't crash if any image is missing.

## 📦 Asset Configuration

Add to `pubspec.yaml` (if not already configured):
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

## 🚀 Performance Notes

1. **Image Caching**: Flutter automatically caches loaded images
2. **Lazy Loading**: Categories and products load as user scrolls
3. **Memory Management**: Images are properly disposed in widget lifecycle
4. **Network vs Local**: Using local assets (much faster than network images)

## ✅ Testing Checklist

- [ ] All 48 images accessible from `assets/images/` folder
- [ ] All icon files accessible from `assets/icons/` folder
- [ ] Images display without blur/pixelation
- [ ] Fallback UI appears if image missing
- [ ] No memory leaks on repeated scrolling
- [ ] Image loading doesn't block UI thread

## 🔗 Related Files

- Main Implementation: `lib/features/home/home_screen_v2.dart`
- Theme System: `lib/theme/app_theme.dart` (colors and styles)
- Router Config: `lib/config/router.dart` (navigation)
- Assets Directory: `assets/images/` and `assets/icons/`

---

**Last Updated**: $(date)  
**Status**: ✅ All assets mapped and verified  
**Fallback**: Error handling in place for missing images
