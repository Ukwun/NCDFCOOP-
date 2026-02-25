# Firestore Setup Checklist

**Quick reference during Firebase Console setup**

---

## ✅ Firebase Console Steps

### 1. Collections Creation
- [ ] Open Firebase Console → Select Project
- [ ] Go to **Firestore Database** → **Data** tab
- [ ] Click **Create collection**

### 2. Members Collection
- [ ] Collection ID: `members`
- [ ] Create Document 1:
  - [ ] ID: `user_test_001`
  - [ ] Add fields (use JSON code mode):
    ```
    userId, email, name, phone
    membershipTier, tierName, points, pointsToNextTier
    totalSpent, joinDate, memberDiscountPercent
    memberBenefits (array), isActive
    createdAt, updatedAt
    ```
  - [ ] **Save**
  
- [ ] Create Document 2:
  - [ ] ID: `user_test_002`
  - [ ] Add fields (same structure as above)
  - [ ] **Save**

### 3. Products Collection (Detailed Step-by-Step)

#### Step 3.1: Create the Collection
1. In Firebase Console Firestore, click **Create collection** button
2. **Collection ID:** Type exactly: `products`
3. Click **Next**
4. A dialog appears asking for first document
5. Skip it for now - click **Cancel** or just proceed (we'll add docs next)

#### Step 3.2: Add Product 1 - Basmati Rice

**In Firestore Console:**
1. Click into the `products` collection (should be empty)
2. Click **Add document** button (blue button at top)
3. **Document ID field:** Type exactly: `prod_basmati_rice_1kg`
4. In the **Field** section, look for a button marked `{} ` (code/JSON mode) near the top
   - Click that button to enter JSON code mode
5. **Delete any pre-filled text**, then **paste this entire JSON:**

```json
{
  "category": "Grains & Rice",
  "contractPrice": null,
  "createdAt": "2025-01-01T08:00:00Z",
  "description": "Long grain white basmati rice, perfect for biryani and pilaf",
  "discountPercentage": 10,
  "id": "prod_basmati_rice_1kg",
  "imageUrl": "https://via.placeholder.com/300?text=Basmati+Rice",
  "isMemberExclusive": false,
  "memberGoldPrice": 3150.00,
  "memberPlatinumPrice": 2800.00,
  "name": "Premium Basmati Rice 1kg",
  "regularPrice": 3500.00,
  "retailPrice": null,
  "stock": 150,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

6. Click **Save** button (blue button at bottom right)
7. ✅ First product added!

---

#### Step 3.3: Add Product 2 - Olive Oil

1. In `products` collection, click **Add document** again
2. **Document ID:** `prod_olive_oil_500ml`
3. Click `{}` code mode button
4. **Delete** and **paste this JSON:**

```json
{
  "category": "Oils & Condiments",
  "contractPrice": null,
  "createdAt": "2025-01-05T08:00:00Z",
  "description": "Cold-pressed extra virgin olive oil from Spain",
  "discountPercentage": 15,
  "id": "prod_olive_oil_500ml",
  "imageUrl": "https://via.placeholder.com/300?text=Olive+Oil",
  "isMemberExclusive": false,
  "memberGoldPrice": 7650.00,
  "memberPlatinumPrice": 6800.00,
  "name": "Extra Virgin Olive Oil 500ml",
  "regularPrice": 8500.00,
  "retailPrice": null,
  "stock": 80,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. Click **Save**
6. ✅ Product 2 added!

---

#### Step 3.4: Add Product 3 - Tomato Paste

1. Click **Add document**
2. **Document ID:** `prod_tomato_paste_400g`
3. Click `{}` code mode
4. **Paste this JSON:**

```json
{
  "category": "Sauces & Pastes",
  "contractPrice": null,
  "createdAt": "2025-01-08T08:00:00Z",
  "description": "Pure organic tomato paste with no additives",
  "discountPercentage": 10,
  "id": "prod_tomato_paste_400g",
  "imageUrl": "https://via.placeholder.com/300?text=Tomato+Paste",
  "isMemberExclusive": false,
  "memberGoldPrice": 1620.00,
  "memberPlatinumPrice": 1440.00,
  "name": "Organic Tomato Paste 400g",
  "regularPrice": 1800.00,
  "retailPrice": null,
  "stock": 200,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. **Save**
6. ✅ Product 3 added!

---

#### Step 3.5: Add Product 4 - Cheddar Cheese

1. Click **Add document**
2. **Document ID:** `prod_cheddar_cheese_250g`
3. Click `{}` code mode
4. **Paste this JSON:**

```json
{
  "category": "Dairy & Cheese",
  "contractPrice": null,
  "createdAt": "2025-01-12T08:00:00Z",
  "description": "Aged cheddar cheese with rich, sharp flavor",
  "discountPercentage": 12,
  "id": "prod_cheddar_cheese_250g",
  "imageUrl": "https://via.placeholder.com/300?text=Cheddar+Cheese",
  "isMemberExclusive": false,
  "memberGoldPrice": 3780.00,
  "memberPlatinumPrice": 3360.00,
  "name": "Mature Cheddar Cheese 250g",
  "regularPrice": 4200.00,
  "retailPrice": null,
  "stock": 120,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. **Save**
6. ✅ Product 4 added!

---

#### Step 3.6: Add Product 5 - Wheat Bread

1. Click **Add document**
2. **Document ID:** `prod_wheat_bread_500g`
3. Click `{}` code mode
4. **Paste this JSON:**

```json
{
  "category": "Bakery",
  "contractPrice": null,
  "createdAt": "2025-01-15T08:00:00Z",
  "description": "Freshly baked whole wheat bread with seeds",
  "discountPercentage": 10,
  "id": "prod_wheat_bread_500g",
  "imageUrl": "https://via.placeholder.com/300?text=Wheat+Bread",
  "isMemberExclusive": false,
  "memberGoldPrice": 2160.00,
  "memberPlatinumPrice": 1920.00,
  "name": "Whole Wheat Bread 500g",
  "regularPrice": 2400.00,
  "retailPrice": null,
  "stock": 300,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. **Save**
6. ✅ Product 5 added!

---

#### Step 3.7: Add Product 6 - Almond Butter

1. Click **Add document**
2. **Document ID:** `prod_almond_butter_400g`
3. Click `{}` code mode
4. **Paste this JSON:**

```json
{
  "category": "Nuts & Spreads",
  "contractPrice": null,
  "createdAt": "2025-01-18T08:00:00Z",
  "description": "Creamy almond butter with no sugar or salt added",
  "discountPercentage": 15,
  "id": "prod_almond_butter_400g",
  "imageUrl": "https://via.placeholder.com/300?text=Almond+Butter",
  "isMemberExclusive": true,
  "memberGoldPrice": 5220.00,
  "memberPlatinumPrice": 4640.00,
  "name": "Natural Almond Butter 400g",
  "regularPrice": 5800.00,
  "retailPrice": null,
  "stock": 60,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. **Save**
6. ✅ Product 6 added!

---

#### Step 3.8: Add Product 7 - Greek Yogurt

1. Click **Add document**
2. **Document ID:** `prod_greek_yogurt_500ml`
3. Click `{}` code mode
4. **Paste this JSON:**

```json
{
  "category": "Dairy & Cheese",
  "contractPrice": null,
  "createdAt": "2025-01-20T08:00:00Z",
  "description": "Thick and creamy Greek yogurt, high in protein",
  "discountPercentage": 10,
  "id": "prod_greek_yogurt_500ml",
  "imageUrl": "https://via.placeholder.com/300?text=Greek+Yogurt",
  "isMemberExclusive": false,
  "memberGoldPrice": 2880.00,
  "memberPlatinumPrice": 2560.00,
  "name": "Greek Yogurt (Plain) 500ml",
  "regularPrice": 3200.00,
  "retailPrice": null,
  "stock": 180,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. **Save**
6. ✅ Product 7 added!

---

#### Step 3.9: Add Product 8 - Green Lentils

1. Click **Add document**
2. **Document ID:** `prod_green_lentils_1kg`
3. Click `{}` code mode
4. **Paste this JSON:**

```json
{
  "category": "Grains & Rice",
  "contractPrice": null,
  "createdAt": "2025-01-22T08:00:00Z",
  "description": "Organic green lentils, high in fiber and protein",
  "discountPercentage": 10,
  "id": "prod_green_lentils_1kg",
  "imageUrl": "https://via.placeholder.com/300?text=Green+Lentils",
  "isMemberExclusive": false,
  "memberGoldPrice": 2520.00,
  "memberPlatinumPrice": 2240.00,
  "name": "Green Lentils 1kg",
  "regularPrice": 2800.00,
  "retailPrice": null,
  "stock": 140,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. **Save**
6. ✅ Product 8 added!

---

#### Step 3.10: Add Product 9 - Honey

1. Click **Add document**
2. **Document ID:** `prod_honey_500ml`
3. Click `{}` code mode
4. **Paste this JSON:**

```json
{
  "category": "Condiments & Sweeteners",
  "contractPrice": null,
  "createdAt": "2025-01-25T08:00:00Z",
  "description": "Pure raw honey from local beekeepers",
  "discountPercentage": 12,
  "id": "prod_honey_500ml",
  "imageUrl": "https://via.placeholder.com/300?text=Raw+Honey",
  "isMemberExclusive": false,
  "memberGoldPrice": 4050.00,
  "memberPlatinumPrice": 3600.00,
  "name": "Raw Honey 500ml",
  "regularPrice": 4500.00,
  "retailPrice": null,
  "stock": 100,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. **Save**
6. ✅ Product 9 added!

---

#### Step 3.11: Add Product 10 - Quinoa

1. Click **Add document**
2. **Document ID:** `prod_quinoa_500g`
3. Click `{}` code mode
4. **Paste this JSON:**

```json
{
  "category": "Grains & Rice",
  "contractPrice": null,
  "createdAt": "2025-02-01T08:00:00Z",
  "description": "Complete protein superfood from Peru",
  "discountPercentage": 15,
  "id": "prod_quinoa_500g",
  "imageUrl": "https://via.placeholder.com/300?text=Quinoa",
  "isMemberExclusive": true,
  "memberGoldPrice": 5850.00,
  "memberPlatinumPrice": 5200.00,
  "name": "Organic Quinoa 500g",
  "regularPrice": 6500.00,
  "retailPrice": null,
  "stock": 75,
  "updatedAt": "2025-02-22T08:00:00Z",
  "wholesalePrice": null
}
```

5. **Save**
6. ✅ Product 10 added!

---

#### ✨ Verification

After adding all 10 products:
1. Go back to **Firestore Data** tab
2. Click **products** collection
3. You should see all 10 documents listed:
   - ✅ prod_basmati_rice_1kg
   - ✅ prod_olive_oil_500ml
   - ✅ prod_tomato_paste_400g
   - ✅ prod_cheddar_cheese_250g
   - ✅ prod_wheat_bread_500g
   - ✅ prod_almond_butter_400g
   - ✅ prod_greek_yogurt_500ml
   - ✅ prod_green_lentils_1kg
   - ✅ prod_honey_500ml
   - ✅ prod_quinoa_500g

4. **Time to add all:** ~10-15 minutes (mostly copy-paste)
5. **Difficulty:** Easy (just copy-paste JSON)

### 4. Analytics Collections (Optional)
- [ ] Create `user_activities_analytics` (leave empty, auto-populates)
- [ ] Create `recommendation_analytics` (leave empty, auto-populates)

---

## 🧪 Testing Steps

### 1. App Startup
- [ ] Run `flutter run`
- [ ] Wait for app to load
- [ ] Verify no errors in console

### 2. Login Test
- [ ] Tap **Login**
- [ ] Email: `member1@test.com` (or your email from members collection)
- [ ] Use your Firebase password
- [ ] **Expected:** Login succeeds

### 3. Member Profile Test
- [ ] After login, you should see member info:
  - [ ] Loyalty points (e.g., 2450)
  - [ ] Tier badge (GOLD or PLATINUM)
  - [ ] Member benefits list
- [ ] **If not:** Check that userId matches Firebase Auth UID

### 4. Products Display
- [ ] Navigate to **Shop** or **Products** page
- [ ] **Expected:** See 10+ products with:
  - [ ] Product names
  - [ ] Prices (member-specific if logged in)
  - [ ] Categories
  - [ ] Stock status
- [ ] **If not:** Verify products in Firestore have correct fields

### 5. Activity Logging
- [ ] Click on a product → View details
- [ ] **Expected:** Product view action logged
- [ ] Click **Add to Cart**
- [ ] **Expected:** Cart activity logged
- [ ] Click heart icon → Save to wishlist
- [ ] **Expected:** Wishlist add logged
- [ ] (Verify in Firestore user_activities subcollection)

### 6. Recommendations
- [ ] Go to **Home** screen
- [ ] Look for **"Recommended For You"** section
- [ ] **Expected:** Shows 5-10 products
- [ ] (May show trending initially if no activity history)

### 7. Purchase Test (Optional)
- [ ] Add 2-3 products to cart
- [ ] Click **Checkout**
- [ ] Follow checkout flow → Payment
- [ ] Complete payment
- [ ] **Expected:** 
  - [ ] Order confirmation
  - [ ] Purchase activity logged to Firestore

---

## 🚨 Common Issues & Fixes

### Issue: "No products showing"
- [ ] ✓ Check `products` collection exists
- [ ] ✓ Verify documents have `id` field
- [ ] ✓ Check required fields: name, category, regularPrice
- [ ] ✓ Restart app with `flutter run`

### Issue: "Member profile shows 'Not Found'"
- [ ] ✓ Verify login email matches member document
- [ ] ✓ Check Firebase Auth UID matches member `userId`
- [ ] ✓ Firestore rules allow read access (check security rules)

### Issue: "Recommendations section missing"
- [ ] ✓ Check `PersonalizedRecommendationsSection` imported in home_screen.dart
- [ ] ✓ May need 5-10 activities first before recommendations appear
- [ ] ✓ Check debug console for recommendation service errors

### Issue: "Activities not logging"
- [ ] ✓ Verify Firestore `user_activities` collection exists
- [ ] ✓ Check Firestore rules allow write access
- [ ] ✓ Check network connection (Firebase write requires internet)

---

## 📱 Fields Reference

### Member Document Sample (user_test_001)
```
userId: "user_test_001"
email: "member1@test.com"
name: "Test Member 1"
membershipTier: "gold"
points: 2450
totalSpent: 12500.00
memberDiscountPercent: 10
```

### Product Document Sample (prod_basmati_rice_1kg)
```
id: "prod_basmati_rice_1kg"
name: "Premium Basmati Rice 1kg"
category: "Grains & Rice"
regularPrice: 3500.00
memberGoldPrice: 3150.00
memberPlatinumPrice: 2800.00
stock: 150
```

---

## 📝 Notes

- **Time to Complete:** ~30 minutes
- **Effort:** Copy-paste JSON, click Save x 12
- **Difficulty:** Easy (no coding required)
- **Prerequisites:** Firebase project set up, app running

---

## ✨ Success Criteria

- [ ] App loads without errors
- [ ] Can login with member email
- [ ] See member loyalty info
- [ ] Products display correctly
- [ ] Can add/remove from cart
- [ ] Can add/remove from wishlist
- [ ] Can complete checkout
- [ ] See recommendations (after activity)
- [ ] All activities appear in Firestore

**If all checked:** 🎉 **System is fully functional!**

---

**Created:** February 22, 2026  
**Reference:** See [FIRESTORE_COLLECTIONS_SETUP_GUIDE.md](./FIRESTORE_COLLECTIONS_SETUP_GUIDE.md) for detailed instructions
