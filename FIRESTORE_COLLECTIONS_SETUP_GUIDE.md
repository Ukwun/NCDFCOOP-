# Firestore Collections Setup Guide

Complete guide to create and populate Firestore collections for the Coop Commerce app.

## Overview

The app requires 4 main Firestore collections:

| Collection | Purpose | Status |
|-----------|---------|--------|
| `members/` | User member profiles, tier, points | **MUST CREATE** |
| `products/` | Product catalog with pricing | **MUST CREATE** |
| `user_activities_analytics/` | Activity aggregates for trending | **AUTO-POPULATED** |
| `recommendation_analytics/` | Recommendation click tracking | **AUTO-POPULATED** |

---

## 1. Create `members/` Collection

### Step 1: Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database** → **Data** tab

### Step 2: Create Collection
1. Click **Create collection**
2. Collection ID: `members`
3. Click **Next**

### Step 3: Add Test Member Documents

Create 2-3 test members with the following structure:

#### Document 1: `user_test_001`
```json
{
  "userId": "user_test_001",
  "email": "member1@test.com",
  "name": "Test Member 1",
  "phone": "+2349000000001",
  "membershipTier": "gold",
  "tierName": "Gold Member",
  "points": 2450,
  "pointsToNextTier": 550,
  "totalSpent": 12500.00,
  "joinDate": "2024-01-15 10:30:00",
  "memberDiscountPercent": 10,
  "memberBenefits": [
    "10% discount on all products",
    "Free shipping on orders over ₦5000",
    "Priority customer support",
    "Exclusive members-only deals"
  ],
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2025-02-22T10:30:00Z"
}
```

**To Add:**
1. Click **Add document** in the `members` collection
2. Document ID: `user_test_001`
3. Copy-paste the JSON fields above (click `{ }` icon for code mode)
4. Click **Save**

#### Document 2: `user_test_002`
```json
{
  "userId": "user_test_002",
  "email": "member2@test.com",
  "name": "Test Member 2",
  "phone": "+2349000000002",
  "membershipTier": "platinum",
  "tierName": "Platinum Member",
  "points": 5200,
  "pointsToNextTier": 0,
  "totalSpent": 45000.00,
  "joinDate": "2023-06-10 14:20:00",
  "memberDiscountPercent": 20,
  "memberBenefits": [
    "20% discount on all products",
    "Free shipping on all orders",
    "Concierge customer support",
    "Early access to new products",
    "Quarterly exclusive giftsGold"
  ],
  "isActive": true,
  "createdAt": "2023-06-10T14:20:00Z",
  "updatedAt": "2025-02-22T14:20:00Z"
}
```

**To Add:**
1. Click **Add document**
2. Document ID: `user_test_002`
3. Add the JSON data
4. Click **Save**

---

## 2. Create `products/` Collection

### Step 1: Create Collection
1. Click **Create collection**
2. Collection ID: `products`
3. Click **Next**

### Step 2: Add Test Products

Create at least 10-15 products with the following structure. Add as many as you like from the examples below:

#### Product 1: Basmati Rice (1kg)
```json
{
  "id": "prod_basmati_rice_1kg",
  "name": "Premium Basmati Rice 1kg",
  "description": "Long grain white basmati rice, perfect for biryani and pilaf",
  "category": "Grains & Rice",
  "regularPrice": 3500.00,
  "memberGoldPrice": 3150.00,
  "memberPlatinumPrice": 2800.00,
  "imageUrl": "https://via.placeholder.com/300?text=Basmati+Rice",
  "isMemberExclusive": false,
  "discountPercentage": 10,
  "stock": 150,
  "createdAt": "2025-01-01T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 2: Extra Virgin Olive Oil (500ml)
```json
{
  "id": "prod_olive_oil_500ml",
  "name": "Extra Virgin Olive Oil 500ml",
  "description": "Cold-pressed extra virgin olive oil from Spain",
  "category": "Oils & Condiments",
  "regularPrice": 8500.00,
  "memberGoldPrice": 7650.00,
  "memberPlatinumPrice": 6800.00,
  "imageUrl": "https://via.placeholder.com/300?text=Olive+Oil",
  "isMemberExclusive": false,
  "discountPercentage": 15,
  "stock": 80,
  "createdAt": "2025-01-05T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 3: Organic Tomato Paste (400g)
```json
{
  "id": "prod_tomato_paste_400g",
  "name": "Organic Tomato Paste 400g",
  "description": "Pure organic tomato paste with no additives",
  "category": "Sauces & Pastes",
  "regularPrice": 1800.00,
  "memberGoldPrice": 1620.00,
  "memberPlatinumPrice": 1440.00,
  "imageUrl": "https://via.placeholder.com/300?text=Tomato+Paste",
  "isMemberExclusive": false,
  "discountPercentage": 10,
  "stock": 200,
  "createdAt": "2025-01-08T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 4: Cheddar Cheese (250g)
```json
{
  "id": "prod_cheddar_cheese_250g",
  "name": "Mature Cheddar Cheese 250g",
  "description": "Aged cheddar cheese with rich, sharp flavor",
  "category": "Dairy & Cheese",
  "regularPrice": 4200.00,
  "memberGoldPrice": 3780.00,
  "memberPlatinumPrice": 3360.00,
  "imageUrl": "https://via.placeholder.com/300?text=Cheddar+Cheese",
  "isMemberExclusive": false,
  "discountPercentage": 12,
  "stock": 120,
  "createdAt": "2025-01-12T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 5: Whole Wheat Bread (500g)
```json
{
  "id": "prod_wheat_bread_500g",
  "name": "Whole Wheat Bread 500g",
  "description": "Freshly baked whole wheat bread with seeds",
  "category": "Bakery",
  "regularPrice": 2400.00,
  "memberGoldPrice": 2160.00,
  "memberPlatinumPrice": 1920.00,
  "imageUrl": "https://via.placeholder.com/300?text=Wheat+Bread",
  "isMemberExclusive": false,
  "discountPercentage": 10,
  "stock": 300,
  "createdAt": "2025-01-15T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 6: Almond Butter (400g)
```json
{
  "id": "prod_almond_butter_400g",
  "name": "Natural Almond Butter 400g",
  "description": "Creamy almond butter with no sugar or salt added",
  "category": "Nuts & Spreads",
  "regularPrice": 5800.00,
  "memberGoldPrice": 5220.00,
  "memberPlatinumPrice": 4640.00,
  "imageUrl": "https://via.placeholder.com/300?text=Almond+Butter",
  "isMemberExclusive": true,
  "discountPercentage": 15,
  "stock": 60,
  "createdAt": "2025-01-18T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 7: Greek Yogurt (500ml)
```json
{
  "id": "prod_greek_yogurt_500ml",
  "name": "Greek Yogurt (Plain) 500ml",
  "description": "Thick and creamy Greek yogurt, high in protein",
  "category": "Dairy & Cheese",
  "regularPrice": 3200.00,
  "memberGoldPrice": 2880.00,
  "memberPlatinumPrice": 2560.00,
  "imageUrl": "https://via.placeholder.com/300?text=Greek+Yogurt",
  "isMemberExclusive": false,
  "discountPercentage": 10,
  "stock": 180,
  "createdAt": "2025-01-20T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 8: Green Lentils (1kg)
```json
{
  "id": "prod_green_lentils_1kg",
  "name": "Green Lentils 1kg",
  "description": "Organic green lentils, high in fiber and protein",
  "category": "Grains & Rice",
  "regularPrice": 2800.00,
  "memberGoldPrice": 2520.00,
  "memberPlatinumPrice": 2240.00,
  "imageUrl": "https://via.placeholder.com/300?text=Green+Lentils",
  "isMemberExclusive": false,
  "discountPercentage": 10,
  "stock": 140,
  "createdAt": "2025-01-22T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 9: Honey (500ml)
```json
{
  "id": "prod_honey_500ml",
  "name": "Raw Honey 500ml",
  "description": "Pure raw honey from local beekeepers",
  "category": "Condiments & Sweeteners",
  "regularPrice": 4500.00,
  "memberGoldPrice": 4050.00,
  "memberPlatinumPrice": 3600.00,
  "imageUrl": "https://via.placeholder.com/300?text=Raw+Honey",
  "isMemberExclusive": false,
  "discountPercentage": 12,
  "stock": 100,
  "createdAt": "2025-01-25T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

#### Product 10: Quinoa (500g)
```json
{
  "id": "prod_quinoa_500g",
  "name": "Organic Quinoa 500g",
  "description": "Complete protein superfood from Peru",
  "category": "Grains & Rice",
  "regularPrice": 6500.00,
  "memberGoldPrice": 5850.00,
  "memberPlatinumPrice": 5200.00,
  "imageUrl": "https://via.placeholder.com/300?text=Quinoa",
  "isMemberExclusive": true,
  "discountPercentage": 15,
  "stock": 75,
  "createdAt": "2025-02-01T08:00:00Z",
  "updatedAt": "2025-02-22T08:00:00Z"
}
```

**To Add Products:**
1. Click **Add document** in the `products` collection
2. Document ID: Use the `id` field from the JSON (e.g., `prod_basmati_rice_1kg`)
3. Switch to code mode (`{ }` icon)
4. Paste the JSON data
5. Click **Save**
6. Repeat for all products

---

## 3. Create `user_activities_analytics/` Collection

This collection **auto-populates** as users interact with the app. However, you can seed it with some initial data for testing trending products:

### Step 1: Create Collection
1. Click **Create collection**
2. Collection ID: `user_activities_analytics`
3. Click **Next**

### Step 2: Add Analytics Data (Optional)

Each document represents aggregated activity for a product:

```json
{
  "productId": "prod_basmati_rice_1kg",
  "productName": "Premium Basmati Rice 1kg",
  "totalViews": 45,
  "totalCartAdds": 12,
  "totalPurchases": 8,
  "avgRating": 4.5,
  "lastUpdated": "2025-02-22T10:00:00Z"
}
```

**Note:** This collection updates automatically as users log activities. You can leave it empty initially.

---

## 4. Create `recommendation_analytics/` Collection

This collection tracks clicks on recommendations.

### Step 1: Create Collection
1. Click **Create collection**
2. Collection ID: `recommendation_analytics`
3. Click **Next** (or **Auto ID** if available)

**Note:** This collection auto-populates when users click on recommendations. You can leave it empty initially.

---

## Testing the Setup

### Step 1: Run the App
```bash
flutter run
```

### Step 2: Test Member Login
1. Launch the app
2. Sign in with email from members collection (e.g., `member1@test.com`)
3. **Expected:** Member profile loads with tier, points, and benefits

### Step 3: Browse Products
1. Navigate to **Shop** or **Products** page
2. **Expected:** 10 products appear with correct pricing

### Step 4: Test Activity Logging
1. **View Product:** Click on a product detail
   - Check Firestore → Collections **might show activity** (depends on real-time sync setup)
2. **Add to Cart:** Add product to cart and log the activity
3. **Add to Wishlist:** Click heart icon to save product

### Step 5: Test Recommendations
1. Navigate to **Home** screen
2. Look for **"Recommended For You"** section
3. **Note:** Might show "No recommendations" initially (needs activity history)

### Step 6: Test Purchase Logging
1. Add products to cart
2. Proceed to checkout
3. Complete payment
4. **Expected:** Order confirmation + activity logged

---

## Quick Reference: Field Descriptions

### Members Collection Fields

| Field | Type | Purpose |
|-------|------|---------|
| `userId` | String | Unique user ID (matches Firebase Auth UID) |
| `email` | String | User email for login |
| `name` | String | Display name |
| `membershipTier` | String | `gold` or `platinum` |
| `points` | Number | Loyalty points balance |
| `totalSpent` | Number | Total purchase amount (₦) |
| `memberDiscountPercent` | Number | Discount % for tier (10-20) |
| `isActive` | Boolean | Account active status |

### Products Collection Fields

| Field | Type | Purpose |
|-------|------|---------|
| `id` | String | Unique product ID |
| `name` | String | Product name |
| `category` | String | Product category |
| `regularPrice` | Number | Regular price (₦) |
| `memberGoldPrice` | Number | Gold member price |
| `memberPlatinumPrice` | Number | Platinum member price |
| `isMemberExclusive` | Boolean | Only for members |
| `stock` | Number | Current inventory |

---

## Troubleshooting

### Products Not Showing
- ✓ Check `products` collection exists
- ✓ Verify document IDs are set correctly
- ✓ Restart the app after adding products

### Member Data Not Loading
- ✓ Verify Firebase Auth user email matches member email
- ✓ Check `members/{userId}` document exists
- ✓ Ensure `userId` matches Firebase Auth UID

### Recommendations Not Showing
- ✓ System needs activity history first
- ✓ Try viewing/adding products to build activity
- ✓ Check `PersonalizedRecommendationsSection` in home screen

---

## Next Steps

1. ✅ Create `members/` collection with 2+ test users
2. ✅ Create `products/` collection with 10-15 products  
3. ✅ Test app login, product browsing, activity logging
4. ✅ Verify recommendations appear after activity
5. 🔜 Set up real Firebase project (if using emulator currently)
6. 🔜 Add more realistic product images
7. 🔜 Set up Firestore security rules for production

---

**Date Created:** February 22, 2026  
**Status:** Ready for testing
