# 📋 FIRESTORE TEST DATA SETUP - Visual Guide

## Where We Are
You're in Firebase Console → Firestore Database → Members Collection

You should see a form that looks like:
```
[Document ID field]
+ Add field
```

---

## STEP-BY-STEP: Creating Test Document 1

### ✅ Step 1: Set Document ID

**What you see:**
```
📄 Auto ID
   ┌─────────────────────┐
   │ [Document ID field] │
   └─────────────────────┘
```

**What to do:**
- Click the dropdown that says "Auto ID"
- Select "Custom ID"
- Type: `user_test_001`
- Click outside to confirm

**Result:**
```
Document ID: user_test_001 ✓
```

---

### ✅ Step 2: Add Fields

You should see a button that says **"+ Add field"**

Click it 6 times to add 6 fields (one for each property):
1. `tier`
2. `rewardsPoints`
3. `lifetimePoints`
4. `ordersCount`
5. `totalSpent`
6. `memberSince`

---

## How to Fill Each Field

For each click of "+ Add field", you'll see:

```
┌────────────────────┬──────────────┬──────────────┐
│ Field Name ▼       │ Type ▼       │ Value        │
├────────────────────┼──────────────┼──────────────┤
│ [empty]            │ [dropdown]   │ [empty]      │
└────────────────────┴──────────────┴──────────────┘
```

---

## EXACT VALUES FOR DOCUMENT 1 (user_test_001)

### Field 1: tier
```
Field Name: tier
Type: String
Value: platinum
```

**How to fill:**
1. In "Field Name" box, type: `tier`
2. Click "Type" dropdown, select: **String**
3. In "Value" box, type: `platinum`
4. Press Tab or click elsewhere to save

---

### Field 2: rewardsPoints
```
Field Name: rewardsPoints
Type: Number
Value: 12000
```

**How to fill:**
1. Click "+ Add field" again
2. In "Field Name" box, type: `rewardsPoints`
3. Click "Type" dropdown, select: **Number**
4. In "Value" box, type: `12000` (no quotes, it's a number)

---

### Field 3: lifetimePoints
```
Field Name: lifetimePoints
Type: Number
Value: 45000
```

**How to fill:**
1. Click "+ Add field"
2. Field Name: `lifetimePoints`
3. Type: **Number**
4. Value: `45000`

---

### Field 4: ordersCount
```
Field Name: ordersCount
Type: Number
Value: 25
```

**How to fill:**
1. Click "+ Add field"
2. Field Name: `ordersCount`
3. Type: **Number**
4. Value: `25`

---

### Field 5: totalSpent
```
Field Name: totalSpent
Type: Number
Value: 150000
```

**How to fill:**
1. Click "+ Add field"
2. Field Name: `totalSpent`
3. Type: **Number**
4. Value: `150000`

---

### Field 6: memberSince
```
Field Name: memberSince
Type: Timestamp
Value: 2024-01-01 (or any date)
```

**How to fill:**
1. Click "+ Add field"
2. Field Name: `memberSince`
3. Type: **Timestamp**
4. Value: Click the calendar, select January 1, 2024

---

## ADD THESE TOO (Optional but Recommended)

### Field 7: isActive
```
Field Name: isActive
Type: Boolean
Value: true
```

### Field 8: discountPercentage
```
Field Name: discountPercentage
Type: Number
Value: 20
```

---

## ✅ Document 1 Complete!

Your completed document should look like:

```
Document: user_test_001
├── tier: "platinum" (string)
├── rewardsPoints: 12000 (number)
├── lifetimePoints: 45000 (number)
├── ordersCount: 25 (number)
├── totalSpent: 150000 (number)
├── memberSince: Jan 1, 2024 (timestamp)
├── isActive: true (boolean)
└── discountPercentage: 20 (number)
```

Click **"Save"** button (bottom right)

---

## 🔄 CREATE DOCUMENT 2 (user_test_002)

Now create a second document with different values:

### Document ID: user_test_002

| Field | Type | Value |
|-------|------|-------|
| tier | String | silver |
| rewardsPoints | Number | 3500 |
| lifetimePoints | Number | 12000 |
| ordersCount | Number | 8 |
| totalSpent | Number | 45000 |
| memberSince | Timestamp | 2024-06-15 |
| isActive | Boolean | true |
| discountPercentage | Number | 10 |

**Repeat the same process:**
1. Create new document (click "Add document" button)
2. Set ID to `user_test_002`
3. Add 8 fields with values above
4. Click Save

---

## 🎯 Visual Reference (What It Looks Like)

After completing both documents, your Firestore should show:

```
Firestore Database
└── Collections
    └── members
        ├── 📄 user_test_001
        │   ├── tier: "platinum"
        │   ├── rewardsPoints: 12000
        │   ├── lifetimePoints: 45000
        │   ├── ordersCount: 25
        │   ├── totalSpent: 150000
        │   ├── memberSince: 2024-01-01
        │   ├── isActive: true
        │   └── discountPercentage: 20
        │
        └── 📄 user_test_002
            ├── tier: "silver"
            ├── rewardsPoints: 3500
            ├── lifetimePoints: 12000
            ├── ordersCount: 8
            ├── totalSpent: 45000
            ├── memberSince: 2024-06-15
            ├── isActive: true
            └── discountPercentage: 10
```

---

## 🚨 Important Notes

### Type Dropdown Options
When you click "Type", you should see these options:
- **String** - For text (tier, names, etc.)
- **Number** - For integers and decimals (points, prices)
- **Boolean** - For true/false
- **Timestamp** - For dates
- **Array** - For lists
- **Map** - For nested objects
- **Null** - For empty

---

### Common Mistakes

❌ **WRONG:**
```
Field Name: rewardsPoints
Type: String
Value: "12000"  ← This is a string, not a number!
```

✅ **RIGHT:**
```
Field Name: rewardsPoints
Type: Number
Value: 12000  ← No quotes, it's a number
```

---

### Where's the "+ Add field" Button?

**Location 1:** At the top of the document form
```
[Document ID: user_test_001]
+ Add field  ← Click here for first field
```

**Location 2:** After you add one field
```
Field 1: tier = "platinum"
+ Add field  ← Click here for second field
```

---

## ✅ Checklist

After creating both documents:

- [ ] Document 1 ID: `user_test_001`
- [ ] Document 1 has 8 fields with correct values
- [ ] Document 2 ID: `user_test_002`
- [ ] Document 2 has 8 fields with different values
- [ ] Both documents show "platinum" vs "silver" tiers
- [ ] Both documents saved (click Save button)
- [ ] Firestore shows both documents in members collection

---

## 🎬 Next Step

Once both documents are created and saved:

1. Run the app: `flutter run`
2. Test Phase 1:
   - Log in as user with ID matching `user_test_001`
   - Should see: "PLATINUM" tier, "12000" points
   - NOT: Hardcoded "gold" or "5000"
3. Log in as user with ID matching `user_test_002`
   - Should see: "SILVER" tier, "3500" points
   - Different from user 1!

---

## 📞 Still Confused?

**Which exact box am I clicking?**

In Firebase Console, look for these boxes in order:

```
    1️⃣ Auto ID dropdown
    ↓ (Change to Custom ID, type document ID)
    
    2️⃣ + Add field button
    ↓ (Click to add fields)
    
    3️⃣-8️⃣ Field boxes (repeat for each field)
    ├── [Field Name box] ← Type field name here
    ├── [Type dropdown] ← Select String/Number/Timestamp
    └── [Value box] ← Type the value here
```

---

**Tell me once both documents are created!** Then we test Phase 1. 🚀
