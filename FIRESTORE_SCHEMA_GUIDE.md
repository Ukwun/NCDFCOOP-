# 🔥 Firestore Schema & Backend Sync Documentation

## Overview

This document defines the complete Firestore collection structure needed for production to sync user activities, orders, carts, and personalization data from the app.

**Status**: RED - Schema partially defined, implementation needs completion

---

## Collections Structure

### Root Collections

```
Firestore Database
├── users/
├── products/
├── orders/
├── shopping_carts/
├── user_activities_analytics/
├── categories/
└── system_config/
```

---

## Detailed Collection Schemas

### 1. `users/` Collection

**Document ID**: Firebase Auth UID

```json
{
  "userId": "user123",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+234XXXXXXXXX",
  "profileImageUrl": "https://...",
  "membershipTier": "gold",
  "joinedDate": {
    ".type": "Timestamp",
    ".value": "2024-01-15T10:30:00Z"
  },
  "lastLoginDate": {
    ".type": "Timestamp",
    ".value": "2026-02-22T14:45:00Z"
  },
  "isEmailVerified": true,
  "isActive": true,
  
  "subcollections": {
    "profile": {
      "personal": {
        "firstName": "John",
        "lastName": "Doe",
        "dateOfBirth": "1990-05-15",
        "gender": "M"
      }
    },
    "rewards": {
      "data": {
        "rewardsPoints": 5000,
        "lifetimePoints": 25000,
        "ordersCount": 42,
        "totalSpent": 250000.00,
        "lastRewardDate": {
          ".type": "Timestamp"
        },
        "redeemedRewards": ["reward1", "reward2"]
      }
    },
    "preferences": {
      "data": {
        "favoriteCategories": ["Grains", "Cooking Oils", "Spices"],
        "favoriteBrands": ["BrandA", "BrandB"],
        "notificationsEnabled": true,
        "emailNotificationsEnabled": true,
        "preferredLanguage": "en",
        "preferredCurrency": "NGN"
      }
    },
    "addresses": {
      "home": {
        "type": "residential",
        "street": "123 Main Street",
        "city": "Lagos",
        "state": "Lagos",
        "postalCode": "100001",
        "country": "Nigeria",
        "isDefault": true
      },
      "work": {
        "type": "commercial",
        "street": "45 Business Ave",
        "city": "Lagos",
        "state": "Lagos",
        "postalCode": "100002",
        "country": "Nigeria",
        "isDefault": false
      }
    },
    "activities": {
      "event_id_1": {
        "id": "event_id_1",
        "userId": "user123",
        "type": "product_view",
        "timestamp": {
          ".type": "Timestamp"
        },
        "productId": "prod_001",
        "productName": "Premium Rice",
        "metadata": {},
        "deviceId": "device123",
        "sessionId": "session123"
      }
    }
  }
}
```

**Indices Required:**
- `lastLoginDate` (Ascending)
- `membershipTier` (Ascending)
- `joinedDate` (Descending)

---

### 2. `products/` Collection

**Document ID**: Product ID (e.g., "prod_001")

```json
{
  "id": "prod_001",
  "name": "Premium Rice - 50kg",
  "description": "High-quality long-grain rice",
  "category": "Grains",
  "basePrice": 15000,
  "coopPrice": 12000,
  "imageUrl": "https://cdn.example.com/rice.jpg",
  "stock": 500,
  "rating": 4.5,
  "reviewCount": 245,
  "tags": ["bulk", "staple", "organic"],
  "sku": "RICE-50KG-001",
  "unit": "kg",
  "isActive": true,
  "isFeatured": false,
  "onSale": false,
  "saleDiscount": 0,
  "createdAt": {
    ".type": "Timestamp"
  },
  "updatedAt": {
    ".type": "Timestamp"
  },
  
  "subcollections": {
    "reviews": {
      "user123": {
        "userId": "user123",
        "rating": 5,
        "text": "Excellent quality!",
        "timestamp": {
          ".type": "Timestamp"
        }
      }
    }
  }
}
```

**Indices Required:**
- `category` + `isActive` (Ascending)
- `rating` + `isActive` (Descending)
- `createdAt` (Descending)
- `stock` (Ascending)

---

### 3. `shopping_carts/` Collection

**Document ID**: User ID (one cart per user)

```json
{
  "userId": "user123",
  "items": [
    {
      "id": "item_1",
      "productId": "prod_001",
      "productName": "Premium Rice - 50kg",
      "memberPrice": 12000,
      "marketPrice": 15000,
      "quantity": 2,
      "imageUrl": "https://...",
      "unit": "kg"
    },
    {
      "id": "item_2",
      "productId": "prod_005",
      "productName": "Garlic Powder - 2kg",
      "memberPrice": 6400,
      "marketPrice": 8000,
      "quantity": 1,
      "imageUrl": "https://...",
      "unit": "kg"
    }
  ],
  "itemCount": 3,
  "subtotal": 30400,
  "totalMarketPrice": 38000,
  "totalSavings": 7600,
  "deliveryFee": 0,
  "lastUpdated": {
    ".type": "Timestamp"
  }
}
```

**Indices Required:**
- None (single document per user)

---

### 4. `orders/` Collection

**Document ID**: Order ID (auto-generated or OrderNumber)

```json
{
  "orderId": "ORD-2026-022-001",
  "userId": "user123",
  "status": "confirmed",
  "items": [
    {
      "productId": "prod_001",
      "productName": "Premium Rice - 50kg",
      "quantity": 2,
      "unitPrice": 12000,
      "totalPrice": 24000
    },
    {
      "productId": "prod_005",
      "productName": "Garlic Powder - 2kg",
      "quantity": 1,
      "unitPrice": 6400,
      "totalPrice": 6400
    }
  ],
  "subtotal": 30400,
  "delivery": {
    "fee": 0,
    "address": {
      "street": "123 Main Street",
      "city": "Lagos",
      "state": "Lagos",
      "postalCode": "100001",
      "country": "Nigeria"
    },
    "estimatedDeliveryDate": {
      ".type": "Timestamp"
    }
  },
  "payment": {
    "method": "card",
    "status": "completed",
    "reference": "PAY-123456",
    "gateway": "paystack",
    "amountPaid": 30400,
    "paidAt": {
      ".type": "Timestamp"
    }
  },
  "total": 30400,
  "orderDate": {
    ".type": "Timestamp"
  },
  "createdAt": {
    ".type": "Timestamp"
  },
  "updatedAt": {
    ".type": "Timestamp"
  },
  
  "subcollections": {
    "timeline": {
      "confirmed": {
        "status": "confirmed",
        "timestamp": {
          ".type": "Timestamp"
        },
        "message": "Order confirmed"
      },
      "processing": {
        "status": "processing",
        "timestamp": {
          ".type": "Timestamp"
        },
        "message": "Order being prepared"
      },
      "shipped": {
        "status": "shipped",
        "timestamp": {
          ".type": "Timestamp"
        },
        "message": "Order shipped"
      }
    }
  }
}
```

**Indices Required:**
- `userId` + `orderDate` (Descending)
- `status` + `orderDate` (Descending)
- `orderDate` (Descending)

---

### 5. `user_activities_analytics/` Collection

**Document ID**: Event ID (auto-generated)

```json
{
  "id": "event_abc123def456",
  "userId": "user123",
  "type": "product_view",
  "timestamp": {
    ".type": "Timestamp",
    ".value": "2026-02-22T10:30:00Z"
  },
  "productId": "prod_001",
  "productName": "Premium Rice - 50kg",
  "metadata": {},
  "deviceId": "device123",
  "sessionId": "session123"
}
```

**ACTIVITY TYPES:**
- `product_view` - User viewed a product
- `cart_add` - User added item to cart
- `cart_remove` - User removed item from cart
- `wishlist_add` - 👤 User wishlisted item
- `wishlist_remove` - User removed from wishlist
- `purchase` - User completed purchase
- `review` - User reviewed product
- `search` - User searched

**Indices Required:**
- `type` + `timestamp` (Descending)
- `userId` + `timestamp` (Descending)
- `productId` + `timestamp` (Descending)

---

### 6. `categories/` Collection

**Document ID**: Category Name

```json
{
  "id": "Grains",
  "name": "Grains",
  "description": "Rice, beans, and other grains",
  "imageUrl": "https://...",
  "isActive": true,
  "displayOrder": 1,
  "createdAt": {
    ".type": "Timestamp"
  }
}
```

---

## Firestore Security Rules

Deploy these rules to Firestore Console:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only access their own user document
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      // Subcollections: activities, addresses, rewards, preferences
      match /{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
    
    // Everyone can read products, admins can write
    match /products/{document=**} {
      allow read: if true;
      allow write: if request.auth.token.admin == true;
    }
    
    // Users can only access their own cart
    match /shopping_carts/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Users can only access their own orders
    match /orders/{orderId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    // User activities (analytics) - write by user, read by any
    match /user_activities_analytics/{document=**} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
    
    // Categories are public
    match /categories/{document=**} {
      allow read: if true;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

---

## Migration from Current State

### What Exists
- ✅ Some user data in local storage
- ✅ Cart in-memory state
- ✅ Activities in local SharedPreferences
- ❌ NOT in Firestore

### What Needs to Happen

#### Phase 1: Data Preparation
1. Create Firestore collections if not exist
2. Create admin panel/script to import initial products
3. Create user data migration script

#### Phase 2: Service Implementation
1. Implement ActivityTrackingService ✅ (DONE)
2. Implement Products Service ✅ (EXISTS)
3. Implement UserDataService ✅ (EXISTS)
4. Implement CartPersistenceService ✅ (DONE)

#### Phase 3: Provider Integration
1. Update activity_provider to use ActivityTrackingService
2. Update home_providers to use real UserDataService
3. Update product providers to use ProductsService
4. Update cart_provider to use CartPersistenceService

#### Phase 4: Testing & Validation
1. Test activity logging end-to-end
2. Test cart persistence end-to-end
3. Test user profile loading from Firestore
4. Monitor Firestore usage

---

## Implementation Checklist

- [ ] **Firestore Collections Created**
  - [ ] users/
  - [ ] products/
  - [ ] shopping_carts/
  - [ ] orders/
  - [ ] user_activities_analytics/
  - [ ] categories/

- [ ] **Firestore Security Rules Deployed**
  - [ ] All collections have proper rules
  - [ ] Tested with real user data

- [ ] **Services Implemented**
  - [x] ActivityTrackingService (DONE)
  - [x] ProductsService (EXISTS)
  - [x] UserDataService (EXISTS)
  - [x] CartPersistenceService (DONE)

- [ ] **Providers Updated**
  - [ ] activity_provider
  - [ ] home_providers
  - [ ] products_provider
  - [ ] cart_provider

 - [ ] **End-to-End Tests Passing**
  - [ ] User can login and profile loads from Firestore
  - [ ] User can view products from Firestore
  - [ ] User can add to cart and it persists to Firestore
  - [ ] User activities sync to Firestore
  - [ ] Cart syncs across devices

---

## Data Volume Expectations

### User Collection
- **Growth**: 1 user/day → 100/day at scale
- **Document size**: ~2KB base + subcollections
- **Indices**: 3 (last login, tier, joined date)

### Products Collection
- **Size**: ~5000 products at launch
- **Document size**: ~1KB per product
- **Indices**: 4 (category+active, rating, created, stock)

### Orders Collection
- **Growth**: 10-100/day depending on success
- **Document size**: ~2-5KB per order
- **Indices**: 3 (user+date, status+date, date)

### Activities Analytics
- **Growth**: 100-1000/day (multiple events per user)
- **Document size**: ~500B per event
- **Indices**: 3 (type+timestamp, userId+timestamp, productId+timestamp)
- **Cleanup**: Recommend archiving events > 30 days old

---

## Estimated Firestore Costs (Monthly)

**At 100 DAU with 10 orders/day:**

| Operation | Count | Cost |
|-----------|-------|------|
| Reads | 500K | $2.50 |
| Writes | 100K | $0.50 |
| Deletes | 0 | $0 |
| Storage | 10GB | $1 |
| **Total** | — | **$4** |

**Scales to:**
- At 1000 DAU: ~$15-20/month
- At 10K DAU: ~$60-80/month

---

## Firestore CLI Commands

### Deploy Rules
```bash
firebase deploy --only firestore:rules
```

### Backup Data
```bash
gcloud firestore export gs://your-bucket/backups
```

### Query Database
```bash
firebase firestore:query "products"
firebase firestore:query "users" --limit 10
```

### Monitor Usage
```bash
firebase functions:log
gcloud firestore describe
```

---

## Troubleshooting

### Issue: Activities not syncing
**Check:**
1. ActivityTrackingService is being called
2. Firebase Auth user is logged in
3. Firestore Rules allow write to user_activities_analytics
4. Network connectivity is good

### Issue: Cart disappears after logout
**Check:**
1. Cart was properly saved to Firestore
2. On login, cart is reloaded from Firestore
3. User is queried correctly in Firestore

### Issue: Products showing stale data
**Check:**
1. Stream is active (not just one-time read)
2. Product documents updated correctly
3. Correct indices exist in Firestore

---

## Next Steps

1. **Deploy this schema** to Firestore (create collections)
2. **Deploy security rules** from above section
3. **Create initial data**: Products, categories (use admin script)
4. **Integrate services** into providers
5. **Test end-to-end** with real user flow
6. **Monitor Firestore** via Analytics dashboard
7. **Optimize as needed** based on usage patterns

---

**Status**: 🔴 RED - Schema defined, implementation in progress
**Last Updated**: February 22, 2026
