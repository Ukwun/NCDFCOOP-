# TOTAL ROLES WORKFLOW ANALYSIS
## NCDF COOP Commerce - Complete Role System Guide for Website Implementation

**Document Date:** April 6, 2026  
**Intended For:** Website Development Team  
**Project:** ncdf-coop-commerce  
**Status:** Production Reference Architecture  

**⚠️ CRITICAL:** This document defines the THREE PRIMARY ROLES and their complete digital ecosystems. Website implementation MUST mirror this structure to ensure system coherence.

---

## TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [The Three Roles Overview](#the-three-roles-overview)
3. [Role 1: Wholesale Buyer (Consumer)](#role-1-wholesale-buyer-consumer)
4. [Role 2: Co-op Member / Premium Member](#role-2-co-op-member--premium-member)
5. [Role 3: Seller](#role-3-seller)
6. [Comparative Analysis](#comparative-analysis)
7. [Design System & Visual Identity](#design-system--visual-identity)
8. [Navigation & Button Mapping](#navigation--button-mapping)
9. [Real-World User Impact & Workflows](#real-world-user-impact--workflows)
10. [Website Implementation Checklist](#website-implementation-checklist)

---

## EXECUTIVE SUMMARY

### The Platform's Core Philosophy

NCDF COOP Commerce operates as a **cooperative marketplace** serving three distinct but interconnected user types:

1. **Wholesale Buyers** - Regular consumers purchasing at retail prices
2. **Cooperative Members** - Loyalty-focused customers with voting rights and profit sharing
3. **Sellers** - Business owners selling on the platform with quality control

Every user on the platform has ONE primary identity (role), and their entire experience is customized around that role's unique needs, permissions, and revenue model.

### The Role determines:
- ✅ Homepage layout and content priority
- ✅ Available actions and features
- ✅ Pricing they see (retail vs. member discount)
- ✅ Navigation structure
- ✅ Buttons and CTAs displayed
- ✅ Data they can access
- ✅ Transactions they can perform

**The website version MUST implement these same role-based distinctions exactly, character-for-character, to maintain system integrity.**

---

## THE THREE ROLES OVERVIEW

### Quick Reference Matrix

| Dimension | 🛍️ Wholesale Buyer | ♥️ Co-op Member | 🏪 Seller |
|-----------|------------------|----------------|---------|
| **Primary Goal** | Buy quality products at fair prices | Build wealth & community loyalty | Sell products to verified buyers |
| **Key Focus** | Shopping, convenience, deals | Loyalty, savings, community governance | Inventory, sales, product approval |
| **Homepage Hero** | Flash Deals section | Loyalty card (tier + points) | Business metrics dashboard |
| **Unique Feature** | See retail prices, flash sales | See member discounts, earn points | Product upload, approval workflow |
| **Earning Potential** | None | Loyalty points, referral bonuses | Sales revenue, high order volume |
| **Real-Life Impact** | Get everyday items quickly, budget-friendly | Earn rewards, build savings, have a voice | Build a business, reach customers |
| **Color Coding** | #1E7F4E (Dark Green) | #C9A227 (Gold) | #0B6B3A (Dark Green) |
| **Pricing** | Standard retail prices | 5-10% discounts depending on tier | Wholesale/bulk pricing |
| **Can Vote?** | ❌ No | ✅ Yes | ❌ No |
| **Can Save Money** | ❌ No | ✅ Yes | ✅ Wallet for business |
| **Onboarding** | Simple: Sign up → Start shopping | Simple: Sign up → Start shopping | Complex: 5-step seller onboarding |

---

## ROLE 1: WHOLESALE BUYER (CONSUMER)

### 🎯 Purpose & Real-World Identity

**Who is this user?**
- Someone who wants to shop for quality products without commitment
- Individual who may not want community involvement
- Casual shopper, impulse buying friendly
- Entry point to the COOP ecosystem (can upgrade to member later)

**Real-world use case:**
> "I need to buy groceries today. I want fair prices, no membership fees, just quick shopping."

### 📱 Homepage Layout & Design

#### Visual Structure
```
┌─────────────────────────────────────────────────────┐
│                 WHOLESALE BUYER HOME                │
│                                                     │
│  Role Badge: 🛍️ CONSUMER HOME (Retail Pricing)      │
│  Subtitle: Shop quality products at great prices   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Welcome back, [First Name]!                        │  ← Personalized Greeting
│  (pulled from DB: currentUserProvider)             │
│                                                     │
│  [🔍 Search Products...]                           │  ← Search Bar
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ⚡ FLASH DEALS              [View All →]           │  ← Time-Limited Offers
│                                                     │    (Unique to consumers)
│  [Product 1]  [Product 2]  [Product 3] ...         │    - Horizontal scroll
│   ₦2,500       ₦3,200       ₦1,800                │    - 5-7 products
│   2 hrs left   12 hrs left   24 hrs left          │    - Countdown timers
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  BROWSE BY CATEGORY (6 Categories - 3x2 Grid)      │  ← Quick Navigation
│                                                     │
│  🥘 Grains    🌾 Vegetables   🥛 Dairy             │    - Large tap targets
│  🍖 Proteins  🧈 Oils         🛒 All Products      │    - Category icons
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  RECOMMENDED FOR YOU (Personalized - 2x2 Grid)    │  ← Algorithm-driven
│                                                     │    - Based on browsing history
│  [Product Img] [Product Img]                       │    - Based on category interest
│   Product Name  Product Name                       │    - Updated real-time
│   ₦4,500        ₦2,800                           │
│   
│  [Product Img] [Product Img]                       │
│   Product Name  Product Name                       │
│   ₦3,200        ₦5,100                           │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  💎 BECOME A MEMBER                                 │  ← Conversion CTA
│  Get exclusive prices & loyalty rewards            │    - Non-intrusive
│  [Learn More Button]                               │    - Premium upgrade offer
│                                                     │
└─────────────────────────────────────────────────────┘
```

#### Color Scheme
| Element | Color | Purpose |
|---------|-------|---------|
| Background | #FAFAFA (Light Gray) | Clean, minimal |
| Header Text | #1F2937 (Dark Gray) | High contrast |
| Price Text | #059669 (Dark Green) | Prosperity signaling |
| Category Icons | #10B981 (Emerald) | Trust & growth |
| Flash Deal Timer | #F3951A (Orange) | Urgency |
| CTA Button | #6366F1 (Indigo) | Action-oriented |
| Role Badge | #1E7F4E (Dark Green) | Brand identity |

#### Spacing & Typography
- **Page Padding:** 16px horizontal margins
- **Section Gap:** 20px between sections
- **Heading:** 24px bold, dark gray (#1F2937)
- **Body Text:** 14px regular, #6B7280
- **Product Price:** 16px bold, green (#059669)

### 🔘 Buttons & Their Actions

| Button | Icon | Location | Tap Target | Navigation | Real-World Use |
|--------|------|----------|-----------|-----------|-----------------|
| **Search Bar** | 🔍 | Top (sticky) | 48px height | → Search Screen | "Find specific product" |
| **View All (Deals)** | → | Flash Deals section | Text link | → Flash Sales screen | "See all time-limited offers" |
| **Category Card** | 🥘/🌾 etc | 6 grid items | 80x80px | → Category Products screen | "Browse by type" |
| **Product Card** | [Image] | Recommended section | Full card | → Product Detail screen | "View details & buy" |
| **Learn More (Member)** | → | Bottom CTA | 100% width button | → Membership signup | "Upgrade to member" |

### 💾 Data Sources & Real-Time Updates

| Data Element | Source | Updates | Frequency |
|--------------|--------|---------|-----------|
| User Name | `currentUserProvider` | On login/logout | Real-time |
| Flash Deal Products | `roleAwareFeaturedProductsProvider('wholesaleBuyer')` | Admin updates deals | Every 4 hours |
| Product Prices | Product model `retailPrice` field | Sync from backend | Real-time |
| Recommended Products | ML algorithm based on browsing history | Algorithm recalculates | Every 2 hours |
| Category Data | Products filtered by category | Firestore collection | Real-time listeners |
| Tier Status | `memberDataProvider` | N/A (not a member yet) | N/A |

### 🎯 Unique Features Only For Wholesale Buyers

1. **Flash Deals Section**
   - Only visible to non-members
   - Shows time-limited offers
   - Creates urgency and drives conversion
   - Countdown timer updates live
   - Example: "2 hours left" → "59 minutes left" → "Offer ended"

2. **Retail Price Display**
   - Shows standard pricing
   - "Regular price" label if on discount
   - No member discount badges
   - Reinforces simple, straightforward pricing

3. **Member Upgrade CTA**
   - Bottom of page persistent
   - Non-intrusive but visible
   - Drives member conversion funnel
   - Part of monetization strategy

4. **Simpler Navigation**
   - No voting, savings, or rewards sections
   - No account/wallet management
   - Just browse & buy
   - Lower cognitive load

### 🔄 User Workflows & Real-Life Scenarios

#### Scenario 1: Emergency Grocery Buy
```
User: Housewife needs milk urgently
[Home] → [Search "Milk"] → [Product Detail] → [Add to Cart] → [Checkout]
Time: 2-3 minutes
Impact: Convenience at required moment
```

#### Scenario 2: Discovery Shopping
```
User: Customer exploring new products
[Home] → [Browse by Category "Vegetables"] → [See 50 products] → [Pick item]
Time: 10-15 minutes
Impact: Find something unexpectedly useful
```

#### Scenario 3: Deal Hunting
```
User: Price-conscious shopper looking for bargains
[Home] → [View All Flash Deals] → [Compare prices] → [Add best deal]
Time: 5-10 minutes
Impact: Save money on impulse purchase
```

#### Scenario 4: Member Conversion
```
User: Regular shopper considering membership
[Home] → [Learn More (Member CTA)] → [Membership Details] → [Sign Up] → [Member Home]
Time: 15-20 minutes
Impact: Convert buyer to loyal member
```

### 📊 Key Metrics & Success Indicators

- **Session Duration:** 5-15 minutes average
- **Products Viewed Per Session:** 8-12 items
- **Conversion Rate:** 2-5% (buy something in session)
- **Repeat Purchase Rate:** 30-40% (come back within 7 days)
- **Member Upgrade Rate:** 5-10% (upgrade to membership)
- **Cart Abandonment Rate:** 40-50% (normal for e-commerce)

---

## ROLE 2: CO-OP MEMBER / PREMIUM MEMBER

### 🎯 Purpose & Real-World Identity

**Who is this user?**
- Committed cooperative member investing in the platform
- Regular shopper who values loyalty rewards
- Community-minded individual interested in governance
- Wants both shopping benefits AND wealth-building opportunities

**Real-world use case:**
> "I'm part of a cooperative that cares about fair trade and community. I want to earn loyalty rewards, save money, and have a say in how we operate."

### 📱 Homepage Layout & Design

#### Visual Structure
```
┌──────────────────────────────────────────────────────┐
│              MEMBER HOME (Loyalty Focused)           │
│                                                      │
│  Role Badge: ♥️ MEMBER HOME (Loyalty & Rewards)      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │  🎖️ YOUR TIER: GOLD  [HERO SECTION]            │ │  ← Loyalty Card
│  │  ├─ Available Points: 2,450 pts                │ │     (Center piece)
│  │  │  [🎁 Redeem Rewards Button]                 │ │
│  │  ├─ Next Tier at 5,000 pts (49% Complete)      │ │
│  │  │  [████████░░ Progress Bar]                  │ │
│  │  └─ Member Since: March 2025                   │ │
│  │     Lifetime Points: 8,500                     │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  SAVINGS & IMPACT TRACKER                           │  ← Financial Overview
│  ├─ Total Spent: ₦125,000                          │    - Shows real value
│  ├─ Saved This Year: ₦18,750 (15% discount)        │    - Motivates continued use
│  ├─ Discount Rate: 15%                             │    - Builds trust
│  └─ Member Dividends: ₦2,150 (YTD)                │
│                                                      │
│  SAVINGS GOAL: ₦50,000                             │  ← Goal Tracking
│  Progress: ₦18,750 (38%)                           │    - Gamification element
│  [████████░░░░░░░░░░ Progress Bar]                 │
│  [💰 Deposit Money to Savings Button]              │
│                                                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  QUICK ACTIONS GRID (3x2 - 6 Actions)              │  ← Loyalty Features
│  ┌──────────────┬──────────────┬──────────────┐    │
│  │ 🎁 Redeem    │ ⭐ Your      │ 👥 Refer &  │    │
│  │ Rewards      │ Benefits     │ Earn        │    │
│  ├──────────────┼──────────────┼──────────────┤    │
│  │ ➕ Quick     │ ➖ Quick     │ 📈 My       │    │
│  │ Deposit      │ Withdraw     │ Savings     │    │
│  └──────────────┴──────────────┴──────────────┘    │
│                                                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  🗳️ GOVERNANCE & VOTING                             │  ← Community Voice
│  Active Votes: 3 open • Annual Board Election       │    - Member engagement
│  ├─ Motion 1: Farmer Support Fund Budget            │    - Transparency
│  ├─ Motion 2: Product Quality Standards             │    - Democratic process
│  └─ Motion 3: Member Dividend Allocation            │
│  [🗳️ Vote Now Button]                               │
│                                                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  COOPERATIVE TRANSPARENCY                           │  ← Trust Building
│  Latest Reports & Documents:                        │    - Financial records
│  ├─ Annual Financials 2025  [View PDF]              │    - Operations reports
│  ├─ Impact Report Q4 2025   [View Details]          │    - Member dividends
│  └─ Farmer Support Fund     [Donated ₦5.2M]        │
│  [📄 View All Reports]                              │
│                                                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  EXCLUSIVE MEMBER DEALS (Horizontal Scroll)         │  ← Shopping (Secondary)
│  [Deal 1] [Deal 2] [Deal 3] [Deal 4]               │    - Member-only pricing
│  ₦2,250   ₦3,600   ₦1,620  ₦4,680                 │    - Limited quantities
│ (25% off) (15% off) (20% off)(30% off)             │
│                                                      │
│  Members Only - Product Selection                  │
│  [Product 1]  [Product 2]                          │
│   Only 5 left   Only 3 left                        │
│                                                      │
│  [Product 3]  [Product 4]                          │
│   Only 8 left   Flash deal                         │
│                                                      │
│  [🛒 Shop All Member Products]                      │
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### Color Scheme
| Element | Color | Purpose |
|---------|-------|---------|
| Background | #FAFAFA (Light Gray) | Consistency |
| Header Text | #1F2937 (Dark Gray) | Contrast |
| Loyalty Card BG | Gold gradient (#C9A227 → #E5D04B) | Premium feel |
| Points Display | #FFFFFF (White on gold) | Emphasis |
| Tier Badge | Color-coded per tier | Status signaling |
| Progress Bar | Gold #C9A227 | Brand alignment |
| Voting Section | #3B82F6 (Blue) | Trust/governance |
| Reports Section | #059669 (Green) | Transparency |
| CTA Buttons | #6366F1 (Indigo) | Action-oriented |

#### Tier Colors (Visual Hierarchy)
```
🥉 Bronze Tier: #CD7F32 (Traditional bronze)
🥈 Silver Tier: #C0C0C0 (Traditional silver)
🥇 Gold Tier:  #C9A227 (Premium gold - NCDF colors)
💎 Platinum:   #9D4EDD (Premium purple)
```

#### Spacing & Typography
- **Page Padding:** 16px horizontal margins
- **Card Padding:** 16px inner spacing
- **Section Gap:** 24px between major sections
- **Loyalty Card Height:** 180-200px (hero prominence)
- **Heading:** 24px bold, dark gray
- **Tier Label:** 18px bold, white on colored background
- **Points Display:** 32px bold, white on gold
- **Body Text:** 14px regular, #6B7280

### 🔘 Buttons & Their Actions

| Button | Icon | Location | Tap Target | Navigation | Real-World Use |
|--------|------|----------|-----------|-----------|-----------------|
| **Redeem Rewards** | 🎁 | Quick Actions grid | 60x60px tile | → My Rewards screen | "Spend 100 points for 5% rebate" |
| **Your Benefits** | ⭐ | Quick Actions grid | 60x60px tile | → Member Benefits screen | "See tiered discount rates" |
| **Refer & Earn** | 👥 | Quick Actions grid | 60x60px tile | → Referral Program screen | "Invite friend, get bonus" |
| **Quick Deposit** | ➕ | Quick Actions grid | 60x60px tile | → Modal dialog | "Add money to wallet" |
| **Quick Withdraw** | ➖ | Quick Actions grid | 60x60px tile | → Modal dialog | "Remove saved money" |
| **My Savings** | 📈 | Quick Actions grid | 60x60px tile | → Savings Details screen | "Track savings progress" |
| **Vote Now** | 🗳️ | Voting section | 100% button | → Voting Screen | "Cast vote on governance" |
| **View All Reports** | 📄 | Reports section | 100% button | → Transparency reports | "Read financial documents" |
| **Redeem in Card** | Tap card | Loyalty card | Quick action | → Rewards screen | "Redeem from header" |
| **View All Products** | 🛒 | Bottom CTA | 100% button | → Member Products catalog | "See all exclusive deals" |

### 💾 Data Sources & Real-Time Updates

| Data Element | Source | Updates | Frequency |
|--------------|--------|---------|-----------|
| User Name | `currentUserProvider` | On login | Real-time |
| Tier Status | `memberDataProvider(userId).tier` | After purchase/upgrade | Real-time |
| Points Balance | `memberDataProvider(userId).rewardsPoints` | After each transaction | Real-time |
| Lifetime Points | `memberDataProvider(userId).lifetimePoints` | Cumulative | Real-time |
| Total Spent | `memberDataProvider(userId).totalSpent` | After checkout | Real-time |
| Discount Rate | Calculated from tier | On tier change | Real-time |
| Member Since | `memberDataProvider(userId).memberSince` | Account creation | Static |
| Savings Progress | (spent × discount%) | Real-time calculation | Real-time |
| Voting Records | Firestore `member_votes` collection | Member casts vote | Immediate |
| Reports | Firestore `cooperative_reports` collection | Admin publishes | Manual |
| Exclusive Products | `exclusiveMemberProductsProvider(userId)` | Admin curates | Daily refresh |

### 🎯 Unique Features Only For Members

1. **Loyalty Card as Hero**
   - Tier display with visual gradient
   - Points balance shown prominently
   - Progress to next tier with percentage
   - Creates emotional engagement
   - Visual reward for engagement

2. **Tiered Reward System**
   ```
   🥉 Bronze (0-999 points)   → 5% discount
   🥈 Silver (1000-4999)      → 7% discount
   🥇 Gold (5000-9999)        → 10% discount + exclusive deals
   💎 Platinum (10000+)       → 15% discount + VIP support
   ```

3. **Savings & Impact Tracker**
   - Shows actual money saved
   - Shows cooperative dividends earned
   - Gamification through goal tracking
   - Psychological reinforcement of value

4. **Governance & Voting**
   - Vote on platform decisions
   - View voting results
   - Participate in annual elections
   - Builds community ownership

5. **Transparency Reports**
   - Financial statements
   - Impact reports
   - Farmer support fund allocation
   - Dividend distribution details
   - Builds trust in cooperative model

6. **Member-Exclusive Pricing**
   - Special discounts not visible to non-members
   - Limited quantity deals
   - Flash sales for members only
   - Creates urgency and value perception

7. **Referral Program**
   - Earn bonuses for inviting friends
   - Track referrals
   - Grow community + earn rewards
   - Viral growth mechanism

### 🔄 User Workflows & Real-Life Scenarios

#### Scenario 1: Loyalty Building (Regular Shopper)
```
User: Wants to earn rewards and track progress
Day 1: [Home] → See 1,200 points, 40% to Gold tier
Day 15: [Home] → Purchases ₦8,000 → Earn 400 points
Day 30: [Home] → Now 1,600 points, 60% to Gold tier
         [My Savings] → See ₦1,200 saved this month

Impact: Feels rewarded, motivated to reach Gold tier
```

#### Scenario 2: Governance Participation
```
User: Community-minded member wanting voice
[Home] → [Vote Now] → See 3 active motions
- Motion 1: Budget allocation (vote yes/no)
- Motion 2: Quality standards (vote yes/no)
- Motion 3: Member dividend (vote yes/no)
[Submit votes] → See confirmation + results

Impact: Feels empowered, part of big decisions
```

#### Scenario 3: Savings Goal Achievement
```
User: Saving for larger purchase
[Home] → [Savings Goal] → Shows ₦50,000 goal, 38% progress
        → [Deposit Money] → Add ₦3,000 to savings
[Home] → Updated: 42% progress

Impact: Tracks progress, feels achievement
```

#### Scenario 4: Shopping for Deal
```
User: Looking for member-exclusive bargains
[Home] → [This member gets 10% off this category]
        → [Exclusive Member Deals] → Browse limited items
        → [Add to cart] → Checkout sees member pricing

Impact: Saves money, feels exclusive
```

#### Scenario 5: Member Referral
```
User: Wants to grow community and earn bonuses
[Home] → [Refer & Earn] → Generate invite link
        → Share with friend via WhatsApp/Email
Friend signs up: User earns ₦500 bonus + friend gets ₦200
Both get points credited real-time

Impact: Viral growth mechanism activated
```

### 📊 Key Metrics & Success Indicators

- **Session Duration:** 15-30 minutes average (higher engagement)
- **Feature Engagement:** 60-80% interact with loyalty card
- **Voting Participation:** 30-50% participate in elections
- **Referral Rate:** 20-30% make at least 1 referral
- **Repeat Purchase Rate:** 70-85% (return within 7 days)
- **Upgrade Path:** 5-10% upgrade to Platinum within 6 months
- **Retention Rate:** 80-90% retain membership for 1+ year
- **Average Order Value:** 30-40% higher than wholesale buyers

---

## ROLE 3: SELLER

### 🎯 Purpose & Real-World Identity

**Who is this user?**
- Business owner selling products on the marketplace
- Individual trader or cooperative selling products
- Wholesale supplier reaching bulk buyers
- Small business scaling through digital channel

**Real-world use case:**
> "I produce agricultural products and want to reach verified buyers. I need a platform where my products are quality-assured and I can track sales and customer orders."

### 📱 User Journey: Seller Onboarding + Dashboard

#### Phase 1: Seller Onboarding (5-Step Flow)

Sellers go through a **mandatory 5-step onboarding** before accessing the dashboard:

##### Step 1: Landing Screen
**File Location:** `seller_onboarding_landing_screen.dart`

```
┌──────────────────────────────────────┐
│                                      │
│   [NCDF Logo]                        │
│                                      │
│   Start Selling on NCDF COOP        │
│   (Headline - 28pt bold)            │
│                                      │
│   [Illustration: Happy seller]      │
│                                      │
│   Nigeria's controlled trade        │
│   infrastructure for reliable       │
│   buying and selling                │
│   (Subheading - 16pt)              │
│                                      │
│   WHY SELL WITH US:                 │
│                                      │
│   ✓ Access to Verified Buyers       │
│     Our cooperative marketplace     │
│     ensures quality buyers          │
│                                      │
│   ✓ Cooperative-Based Model         │
│     Fair pricing, fair treatment    │
│                                      │
│   ✓ Export Support                  │
│     Scale beyond Nigeria            │
│                                      │
│   ✓ Transparent Pricing             │
│     No hidden fees                  │
│                                      │
│   [Get Started Button] →             │
│                                      │
└──────────────────────────────────────┘
```

**Purpose:**
- Establish trust (quality-assured marketplace)
- Highlight benefits specific to sellers
- Presell the value proposition
- No data entry required

**Real-Life Impact:**
> Seller sees this and thinks: "This platform values quality and has transparent pricing. I'll give it a try."

##### Step 2: Seller Setup Screen
**File Location:** `seller_setup_screen.dart`

```
┌──────────────────────────────────────┐
│  Step 2/5: Setup Your Store         │
│                                      │
│  Business Name *                    │
│  [____________________________]      │ ← Text input
│  e.g., "Premium Grain Co"           │
│                                      │
│  Business Type *                    │
│  ○ Individual Seller                │ ← Single select
│  ○ Business/Company                 │
│  ○ Cooperative                      │
│                                      │
│  Country / Location *               │
│  [Nigeria ____________]             │ ← Dropdown
│                                      │
│  Primary Product Category *         │
│  [Select Category ________]         │ ← Dropdown
│  Options: Grains, Vegetables,       │
│           Dairy, Proteins, Oils...  │
│                                      │
│  Target Customers *                 │ ← CRITICAL
│  ○ Individual Customers (B2C)       │ ← retail selling
│    "I sell to regular shoppers"     │
│                                      │
│  ○ Bulk Buyers (B2B)                │ ← wholesale market
│    "I sell in bulk quantities"      │
│                                      │
│  [Continue →]                       │
│                                      │
└──────────────────────────────────────┘
```

**Key Fields:**
- **Business Name:** For store branding
- **Business Type:** Affects tax treatment, legal structure
- **Location:** Determines shipping zones
- **Category:** Filters products, determines buyer audience
- **Target Customer:** CRITICAL decision
  - **Individual (B2C):** Smaller quantities, higher margin
  - **Bulk (B2B):** Larger orders, lower margin per unit

**Real-Life Impact:**
> Seller decides: "I have 1,000kg of millet and want to sell to bulk buyers" → Selects B2B → Platform will show them different buyer types and pricing models.

##### Step 3: Product Upload Screen
**File Location:** `product_upload_screen.dart`

```
┌──────────────────────────────────────┐
│  Step 3/5: Add Your First Product   │
│                                      │
│  Product Name *                     │
│  [________________________]          │ ← Short name
│  e.g., "Premium White Millet"      │
│                                      │
│  Category *                         │
│  [Select ________________]          │ ← From predefined list
│                                      │
│  Price (₦) *                        │
│  [__________]                       │ ← Per unit or per kg
│                                      │
│  Quantity Available *               │
│  [__________] units                 │ ← Total available
│                                      │
│  Minimum Order Quantity (MOQ) *     │
│  [__________] units                 │ ← Wholesale concept
│  e.g., If MOQ=50, can't sell 20    │
│                                      │
│  Product Description *              │
│  [                      ]           │ ← Multiline text
│  [                      ]           │    (Farming method, quality)
│  [                      ]           │    (Grade, storage)
│                                      │
│  Upload Images *                    │
│  [Click or Drag to Upload]          │ ← 3-5 images
│  [Preview]                          │
│                                      │
│  ⚠️ APPROVAL NOTICE                 │ ← CRITICAL
│  ┌──────────────────────────────────┐ │
│  │ ⚠️ YOUR PRODUCT WILL BE REVIEWED │ │
│  │    BEFORE IT GOES LIVE            │ │
│  │                                  │ │
│  │ Why? Quality Assurance:          │ │
│  │ ✓ Ensures product quality        │ │
│  │ ✓ Builds buyer trust             │ │
│  │ ✓ Prevents fraud                 │ │
│  │ ✓ Supports export compliance     │ │
│  │                                  │ │
│  │ Review typically takes 24-48 hrs│ │
│  └──────────────────────────────────┘ │
│                                      │
│  ☑ I agree my product will be      │  ← Explicit consent
│     reviewed and approved           │
│                                      │
│  [Submit for Review →]              │
│                                      │
└──────────────────────────────────────┘
```

**Key Fields:**
- **Product Name:** Search-friendly name
- **Price:** Must be competitive, platform validates
- **MOQ:** Wholesale minimum (affects buyer search)
- **Description:** Quality details, farming method, grade
- **Images:** Critical for buyer trust (3-5 photos required)

**Approval Notice (CRITICAL):**
- Yellow banner explaining review process
- Emphasizes NCDF COOP's quality-first approach
- Sets expectation: "This isn't automatic, we verify"
- Checkbox: Seller must explicitly agree

**Real-Life Impact:**
> Seller uploads millet photos and details.
> Approval notice says: "We'll verify your product quality."
> Seller feels reassured: "OK, they're serious about quality."
> Seller waits for approval (24-48 hours).

##### Step 4: Product Status Screen
**File Location:** `product_status_screen.dart`

```
┌──────────────────────────────────────┐
│  Step 4/5: Product Status           │
│                                      │
│  [Product Image - 200x200px]        │
│                                      │
│  "Premium White Millet"             │
│  ₦8,500/kg | MOQ: 50kg              │
│                                      │
│  STATUS: 🟡 PENDING APPROVAL        │ ← Color-coded
│  ├─ Submitted: April 5, 2026 2pm    │    badge
│  ├─ Review In Progress              │
│  └─ Estimated Review: April 6pm     │
│                                      │
│  OR (if approved):                  │
│  STATUS: 🟢 APPROVED                │
│  ├─ Approved: April 6, 2026 10am    │
│  ├─ Now selling live!               │
│  └─ [View on Store]                 │
│                                      │
│  OR (if rejected):                  │
│  STATUS: 🔴 REJECTED                │
│  ├─ Rejected: April 6, 2026         │
│  ├─ Reason: "Image quality too low" │
│  └─ [Edit & Resubmit]               │
│                                      │
│  WHY APPROVAL MATTERS               │ ← Trust-building
│  ┌──────────────────────────────────┐ │
│  │ ✓ Ensures product quality        │ │
│  │   (No counterfeit goods)          │ │
│  │                                  │ │
│  │ ✓ Builds buyer trust             │ │
│  │   (Verified supplier badge)      │ │
│  │                                  │ │
│  │ ✓ Prevents fraud                 │ │
│  │   (Real seller, real products)   │ │
│  │                                  │ │
│  │ ✓ Supports export compliance     │ │
│  │   (Quality standards for export) │ │
│  └──────────────────────────────────┘ │
│                                      │
│  ACTION BUTTONS:                    │
│  [Add Another Product]              │  ← Keep selling
│  [Go to Dashboard]                  │  ← View inventory
│                                      │
└──────────────────────────────────────┘
```

**Status Badges:**
| Badge | Color | Meaning | Action |
|-------|-------|---------|--------|
| 🟡 Pending | Amber | Under review | Wait 24-48 hrs |
| 🟢 Approved | Green | Live to buyers | Start taking orders |
| 🔴 Rejected | Red | Issue found | Fix & resubmit |

**Real-Life Impact:**
> Seller sees "🟡 PENDING APPROVAL"
> Waits 24 hours
> Gets notification: "🟢 APPROVED! Now selling live!"
> Feels accomplished, starts getting buyer inquiries

##### Step 5: Seller Dashboard
**File Location:** `seller_dashboard_screen.dart`

```
┌──────────────────────────────────────┐
│  [Account 👤] Dashboard             │ <- App bar w/ settings
├──────────────────────────────────────┤
│                                      │
│  MY STORE                           │  <- Header
│  Premium Grain Co.                  │
│  (Business name from Step 2)        │
│                                      │
├──────────────────────────────────────┤
│                                      │
│  BUSINESS METRICS (Stats Grid)      │  <- Overview cards
│  ┌──────────┬──────────┬──────────┐ │
│  │ Products │ Pending  │ Approved │ │
│  │    18    │    2     │    16    │ │
│  ├──────────┼──────────┼──────────┤ │
│  │ This Mo. │ Revenue  │ Avg Rate │ │
│  │ Revenue  │ YTD      │          │ │
│  │ ₦85,000  │₦320,000  │  4.8★   │ │
│  └──────────┴──────────┴──────────┘ │
│                                      │
├──────────────────────────────────────┤
│                                      │
│  FILTER TABS                        │  <- View control
│  [All] [Pending] [Approved]         │
│                                      │
│  PRODUCTS (Scrollable List)         │
│  ┌──────────────────────────────────┐ │
│  │ [IMG] Premium White Millet       │ │ ← Product cards
│  │ ₦8,500/kg | Qty: 500kg | MOQ: 50 │ │
│  │ Status: 🟢 APPROVED              │ │
│  │ 12 inquiries, 3 pending orders  │ │
│  └──────────────────────────────────┘ │
│                                      │
│  ┌──────────────────────────────────┐ │
│  │ [IMG] Red Sorghum                │ │
│  │ ₦6,200/kg | Qty: 300kg | MOQ: 30 │ │
│  │ Status: 🟡 PENDING APPROVAL      │ │
│  │ Submitted 2 hrs ago              │ │
│  └──────────────────────────────────┘ │
│                                      │
│  [FAB: Add New Product ➕]           │  <- Quick action
│                                      │
└──────────────────────────────────────┘
```

**Dashboard Features:**
- **Business Name:** Store branding
- **Metrics:** Total products, pending count, approved count, YTD revenue, rating
- **Filter Tabs:** View by status (All/Pending/Approved)
- **Product Cards:** Each product shows:
  - Product image
  - Name, price, quantity, MOQ
  - Approval status with badge
  - Number of buyer inquiries
  - Number of pending orders
- **FAB:** Quick "Add New Product" button

**Real-Life Impact:**
> Seller logs in, sees:
> - 18 total products, 2 pending review
> - ₦85,000 revenue this month (+30% vs last month)
> - 4.8-star rating from 127 reviews
> - 12 pending order inquiries to respond to
> 
> Feels: "Business is growing! I need to source more stock."

#### Phase 2: Ongoing Operations

**Daily Workflow:**
1. Check dashboard for new inquiries
2. Respond to buyer messages
3. Update inventory (reduce quantities as orders ship)
4. Add new products for approval
5. Monitor rating and feedback

**Monthly Workflow:**
1. Review YTD revenue vs. goal
2. Analyze which products sell best
3. Adjust pricing if needed
4. Plan new products to add
5. Withdraw earnings

### 🔘 Buttons & Their Actions (Seller)

| Button | Location | Tap Target | Navigation | Real-World Use |
|--------|----------|-----------|-----------|-----------------|
| **Get Started** | Onboarding screen 1 | 100% button | → Step 2 | Begin seller account setup |
| **Continue** | Steps 2-4 (form bottom) | 100% button | Next step | Save form, go to next step |
| **Submit for Review** | Step 3 (form bottom) | 100% button | → Step 4 | Submit product to approval |
| **Add Another Product** | Step 4 | 100% button | → Step 3 | Add more products quickly |
| **Go to Dashboard** | Step 5 | 100% button | → Dashboard | Start managing inventory |
| **Edit & Resubmit** | Step 4 (if rejected) | 100% button | → Step 3 | Fix rejected product |
| **Add New Product** | Dashboard FAB | 56x56px button | → Product upload | Submit new product |
| **Product Card** | Dashboard list | Full card | → Product detail/edit | View/edit product |
| **Filter Tab** | Dashboard header | Segmented control | Filter list | Show pending/approved only |
| **Account Settings** | App bar | Icon (25x25px) | → Account screen | Update business info |

### 💾 Data Sources & Real-Time Updates

| Data Element | Source | Updates | Frequency |
|--------------|--------|---------|-----------|
| Business Name | SellerProfile (Firestore) | On edit | Real-time |
| Products List | SellerService.getSellerProducts() | On add/delete | Real-time |
| Product Status | ApprovalStatus enum | Admin approves/rejects | Real-time notification + 24-48 hrs |
| Pending Count | Filter products by status | On status change | Real-time |
| Approved Count | Filter products by status | On status change | Real-time |
| Revenue (Monthly) | OrderService.getSellerRevenue() | After checkout | Real-time |
| Buyer Inquiries | Firestore `bulk_order_requests` | Buyer submits | Real-time notification |
| Rating | Firestore `seller_reviews` avg | After buyer completes order | Real-time |
| Inventory Qty | Product quantity fields | After order/restock | Real-time |

### 🎯 Unique Features Only For Sellers

1. **5-Step Onboarding**
   - Guided setup process
   - Collect necessary business info
   - Upload first product
   - Set expectations (approval workflow)
   - Deploy to dashboard

2. **Product Approval Workflow**
   - Every product enters "pending" state
   - Admin review for quality assurance
   - Visual status badges (pending/approved/rejected)
   - Rejection feedback with reasons
   - Can resubmit after fixes

3. **MOQ (Minimum Order Quantity)**
   - Wholesale concept (e.g., can't buy 20kg if MOQ=50kg)
   - Affects product discoverability
   - Buyers know what they can order
   - Important for bulk sellers

4. **Business Metrics Dashboard**
   - Revenue tracking (monthly, YTD)
   - Product count (total, pending, approved)
   - Seller rating from reviews
   - Buyer inquiries counter
   - Performance insights

5. **Bulk Order Management**
   - Buyers place bulk quantity requests
   - Seller can confirm/negotiate
   - Integrated order fulfillment
   - Shipping integration

6. **Two Selling Paths**
   - **B2C (Individual Customers):** Direct retail sales
   - **B2B (Bulk Buyers):** Wholesale orders, higher volume

### 🔄 User Workflows & Real-Life Scenarios

#### Scenario 1: New Seller Onboarding
```
Day 1:
[Sign Up] → [Complete KYC] → [Start Selling]
↓
[Step 1: Landing] → [Step 2: Setup] → [Step 3: Upload Product]
↓
Upload: "Premium Millet, ₦8,500/kg, MOQ 50kg"
↓
[Step 4: Status] → Shows "🟡 PENDING APPROVAL"
↓
Seller waits...

Day 2:
Admin reviews quality, sees good photos, consistent pricing
Admin clicks [Approve]
↓
Seller gets notification: "🟢 APPROVED! You're live to buyers!"
↓
[Step 5: Dashboard] → Can see product live
↓
First buyer inquiry comes in: "Can I order 100kg?"

Real-Life Impact: Seller is now in business! ✅
```

#### Scenario 2: Scaling Up (Experienced Seller)
```
Seller logs in daily:
[Dashboard] → See 6 product inquiries waiting
             → ₦85,000 revenue this month (+30%)
             → 4.8★ rating from 127 reviews
↓
[Respond to inquiries] → Negotiate bulk orders
↓
[Add Another Product] → Upload new grains coming to season
↓
[Monitor] → 3 of 6 products pending review, in queue

Real-Life Impact: Revenue growing, reputation building ✅
```

#### Scenario 3: Product Rejected (Quality Issue)
```
Seller uploads rice with blurry photos
↓
[Step 4: Status] → Shows "🔴 REJECTED"
                  Reason: "Photo quality insufficient"
↓
[Edit & Resubmit] → In Step 3
Seller retakes better photos
[Submit for Review again]
↓
[Step 4: Status] → Now shows "🟢 APPROVED"
Product goes live

Real-Life Impact: Learn, improve, succeed ✅
```

### 📊 Key Metrics & Success Indicators

- **Onboarding Completion Rate:** 85-95% (mandatory 5 steps)
- **Time to First Sale:** 3-5 days (after approval)
- **Average Products per Seller:** 8-15
- **Approval Success Rate:** 70-80% (first submission)
- **Resubmission Rate:** 20-30% (fix & resubmit)
- **Revenue per Seller (Monthly):** ₦15,000-₦500,000+ (varies by product)
- **Rating Average:** 4.2-4.8 stars
- **Repeat Buyer Rate:** 50-70% (buyers reorder)
- **Seller Retention (6 months):** 60-75%

---

## COMPARATIVE ANALYSIS

### Role System at a Glance

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THREE ROLE SYSTEMS COMPARISON                    │
├─────────────────────┬──────────────────┬──────────────────────────┤
│ DIMENSION           │ WHOLESALE BUYER  │ CO-OP MEMBER             │
├─────────────────────┼──────────────────┼──────────────────────────┤
│ PRIMARY GOAL        │ Shop fast        │ Build wealth + community │
│ FOCUS AREA          │ Products         │ Loyalty & governance     │
│ HERO SECTION        │ Flash deals      │ Loyalty card             │
│ MAIN ACTION         │ Browse & buy     │ Earn & vote              │
│ PRICING             │ Retail standard  │ Member discount 5-15%    │
│ UNIQUE BENEFIT      │ Discovery        │ Savings + voting rights  │
│ EARNING             │ None             │ Points + dividends       │
│ COMMUNITY VOICE     │ No               │ YEs (voting)             │
│ SESSION LENGTH      │ 5-15 min         │ 15-30 min                │
│ REPEAT RATE         │ 30-40%           │ 70-85%                   │
│ UPGRADE PATH        │ → Member signup  │ → Platinum upgrade       │
│ BUTTON SET          │ 5 buttons        │ 8 buttons                │
│ SCREENS             │ Home + Shop      │ Home + Loyalty + Shop    │
└─────────────────────┴──────────────────┴──────────────────────────┘
```

### Navigation Structure Comparison

#### Wholesale Buyer Navigation
```
Home Screen
├─ Search Products
├─ View All Flash Deals
├─ Browse Categories (6 main)
├─ Product Details View
├─ Shopping Cart
├─ Checkout
└─ Membership Signup (CTA)
```

#### Co-op Member Navigation
```
Home Screen
├─ Quick Actions (6 buttons)
│  ├─ Redeem Rewards → Rewards Catalog
│  ├─ Your Benefits → Benefits Details
│  ├─ Refer & Earn → Referral Program
│  ├─ Quick Deposit → Wallet
│  ├─ Quick Withdraw → Wallet
│  └─ My Savings → Goal Tracking
├─ Voting → Vote on governance
├─ Transparency Reports → Read documents
├─ Member-Exclusive Deals → Browse products
├─ Member Product Catalog → Full shopping
└─ Account Management
```

#### Seller Navigation
```
Onboarding (5 Steps)
├─ Step 1: Landing
├─ Step 2: Setup
├─ Step 3: Product Upload
├─ Step 4: Status Check
└─ Step 5: Dashboard → Ongoing
    ├─ Add New Product
    ├─ View Product Details
    ├─ Manage Inventory
    ├─ View Orders
    ├─ Respond to Inquiries
    └─ Account Settings
```

### Feature Availability Matrix

| Feature | Consumer | Member | Seller |
|---------|----------|--------|--------|
| Browse Products | ✅ | ✅ | ❌ |
| Add to Cart | ✅ | ✅ | ❌ |
| Checkout | ✅ | ✅ | ❌ |
| View Pricing | ✅ (retail) | ✅ (discount) | N/A |
| Earn Points | ❌ | ✅ | ❌ |
| Redeem Points | ❌ | ✅ | ❌ |
| Vote on Motions | ❌ | ✅ | ❌ |
| View Reports | ❌ | ✅ | ❌ |
| Add Money to Wallet | ❌ | ✅ | ✅ |
| Upload Products | ❌ | ❌ | ✅ |
| Manage Inventory | ❌ | ❌ | ✅ |
| View Orders (Seller) | ❌ | ❌ | ✅ |
| Respond to Inquiries | ❌ | ❌ | ✅ |
| Track Revenue | ❌ | ❌ | ✅ |

---

## DESIGN SYSTEM & VISUAL IDENTITY

### Color Coding by Role

```
Role ColorCoding:
🛍️ Wholesale Buyer:  #1E7F4E (Dark Green - Shopping)
♥️ Co-op Member:     #C9A227 (Gold - Loyalty premium)
🏪 Seller:           #0B6B3A (Very Dark Green - Business)

General System:
Primary:             #6366F1 (Indigo - Actions)
Secondary:           #10B981 (Emerald - Success)
Accent:              #F3951A (Orange - Urgency)
Error:               #EF4444 (Red - Warnings)
Success:             #22C55E (Green - Confirmations)
Background:          #FAFAFA (Light - Canvas)
Text Dark:           #1F2937 (Dark Gray)
Text Light:          #6B7280 (Medium Gray)
```

### Typography Hierarchy

```
H1 - 32px Bold       "Welcome to NCDFCOOP"
H2 - 28px Bold       "FLASH DEALS" section headers
H3 - 24px Bold       "MY TIER: GOLD"
H4 - 20px Bold       Button labels
H5 - 18px Regular    Product names
Body - 14px Regular  Descriptions
Caption - 12px Gray  Timestamps, hints
```

### Component Patterns

#### Flash Deal Card (Consumer Only)
```
┌────────────────────┐
│ [Product Image]    │
│ Product Name       │
│ ₦2,500            │
│ 2 hrs left ⏱️     │
└────────────────────┘
Interactive: Tap → Product Detail
Animation: Countdown timer updates real-time
```

#### Loyalty Card (Member Only)
```
┌──────────────────────┐
│ 🎖️ YOUR TIER: GOLD   │
│ [Gradient BG: Gold]  │
│                      │
│ Available: 2,450 pts │
│ [Redeem →]           │
│                      │
│ Next: 5,000 pts (49%)│
│ [████████░░]         │
└──────────────────────┘
Interactive: Tap → Redeem page OR Tap progress → Goal details
Animation: Smooth progress bar transitions
```

#### Quick Action Button Grid (Member)
```
┌──────┬──────┬──────┐
│ 🎁   │ ⭐   │ 👥   │
│ Text │ Text │ Text │
├──────┼──────┼──────┤
│ ➕   │ ➖   │ 📈   │
│ Text │ Text │ Text │
└──────┴──────┴──────┘
Style: Rounded corners, 12px radius, light background
Tap animation: Scale 0.95, color fade to highlight
Interactive: Each routes to specific screen
```

#### Product Card (All Roles)
```
┌──────────────────────┐
│  [Image]             │
│  Product Name    ♥️  │ ← Heart save icon
│  ₦2,500             │
│  Qty: 500kg         │
│  MOQ: 50kg (Seller) │
│  Status (Seller)    │
│  ★★★★☆ (Reviews)   │
└──────────────────────┘
Spacing: 12px padding, 8px margin between cards
Text: 14px name, 16px price (bold)
Interactive: Tap card → Detail view
```

---

## NAVIGATION & BUTTON MAPPING

### Complete Button Reference

#### Wholesale Buyer Buttons
```
1. SEARCH BAR
   Icon: 🔍 | Location: Top sticky | Size: 48px height
   Tap action: Opens search screen
   Real-world: "Find milk quickly"

2. VIEW ALL FLASH DEALS
   Icon: → | Location: Flash deals header | Size: Text link
   Tap action: Full flash sales page
   Real-world: "See all time-limited offers"

3. CATEGORY CARDS (6 total)
   Icons: 🥘 🌾 🥛 🍖 🧈 🛒
   Location: Grid 3x2 | Size: 80x80px each
   Tap action: Category products page
   Real-world: "Browse vegetables section"

4. PRODUCT CARDS
   Location: Recommended section | Size: 120x160px
   Tap action: Product detail screen
   Real-world: "See full details and buy"

5. BECOME A MEMBER
   Icon: 💎 | Location: Bottom | Size: 100% width button
   Tap action: Membership signup flow
   Real-world: "Upgrade to get discounts"
```

#### Co-op Member Buttons
```
1. LOYALTY CARD (Hero section)
   Icon: 🎖️ | Location: Top | Size: 180px height
   Tap actions: 
     - Tap card itself → Tier details
     - [Redeem] button → My Rewards
   Real-world: "Check my points balance"

2-7. QUICK ACTIONS (6 buttons in 3x2 grid)
   Icons: 🎁 ⭐ 👥 ➕ ➖ 📈
   Location: Below loyalty card | Size: 60x60px each
   Tap actions:
     🎁 → My Rewards page
     ⭐ → Benefits details
     👥 → Referral program
     ➕ → Deposit dialog
     ➖ → Withdraw dialog
     📈 → Savings tracking
   Real-world: "Add money to my account" / "Vote on motions"

8. VOTE NOW
   Icon: 🗳️ | Location: Voting section | Size: 100% button
   Tap action: Voting interface
   Real-world: "Cast my vote on board election"

9. VIEW ALL REPORTS
   Icon: 📄 | Location: Reports section | Size: 100% button
   Tap action: Transparency reports page
   Real-world: "See financial details"

10. SHOP ALL MEMBER PRODUCTS
    Icon: 🛒 | Location: Bottom | Size: 100% button
    Tap action: Member product catalog
    Real-world: "Browse member-exclusive deals"
```

#### Seller Buttons
```
STEP 1 - Landing Screen:
1. GET STARTED
   Icon: → | Location: Bottom | Size: 100% button
   Tap action: → Step 2
   Real-world: "Start selling process"

STEP 2 - Setup:
2. CONTINUE
   Icon: → | Location: Bottom | Size: 100% button
   Tap action: Validate form → Step 3
   Real-world: "Go to product details"

STEP 3 - Product Upload:
3. SUBMIT FOR REVIEW
   Icon: → | Location: Bottom | Size: 100% button
   Tap action: Validate form → Step 4
   Real-world: "Submit my product for approval"

STEP 4 - Status:
4. ADD ANOTHER PRODUCT
   Icon: ➕ | Location: Bottom left | Size: 48% button
   Tap action: → Step 3 (new product)
   Real-world: "Upload more products"

5. GO TO DASHBOARD
   Icon: 📊 | Location: Bottom right | Size: 48% button
   Tap action: → Dashboard
   Real-world: "Start managing inventory"

DASHBOARD - Ongoing:
6. ADD NEW PRODUCT (FAB)
   Icon: ➕ | Location: Bottom right | Size: 56x56px
   Tap action: → Product upload screen
   Real-world: "Add another product to sell"

7. FILTER TABS
   Options: All | Pending | Approved
   Location: Below header | Size: Segmented control
   Tap action: Filter product list
   Real-world: "Show only pending products"

8. PRODUCT CARD
   Location: Product list | Size: Full card
   Tap action: → Product detail/edit screen
   Real-world: "Edit or view product"

9. ACCOUNT SETTINGS
   Icon: 👤 | Location: App bar | Size: 24x24px
   Tap action: → Account settings screen
   Real-world: "Update business name"
```

### Route Mapping (GoRouter)

```dart
// Wholesale Buyer Routes
/home/consumer
  ├─ /search
  ├─ /flash-sales
  ├─ /category-products/{categoryId}
  ├─ /product-detail/{productId}
  ├─ /cart
  ├─ /checkout
  └─ /membership-signup

// Co-op Member Routes
/home/member
  ├─ /my-rewards
  ├─ /member-benefits
  ├─ /referral-program
  ├─ /wallet (deposit/withdraw)
  ├─ /member-savings
  ├─ /member-voting
  ├─ /transparency-reports
  ├─ /member-products
  └─ /account

// Seller Routes
/seller/onboarding
  ├─ /landing (step 1)
  ├─ /setup (step 2)
  ├─ /product-upload (step 3)
  ├─ /product-status (step 4)
  └─ /dashboard (step 5)

/seller/dashboard
  ├─ /add-product
  ├─ /product-detail/{productId}
  ├─ /orders
  ├─ /inquiries
  └─ /account-settings
```

---

## REAL-WORLD USER IMPACT & WORKFLOWS

### Impact on User's Daily Life (Wholesale Buyer)

**User: Mama Zainab (Housewife, Lagos)**

**Day 1 - Signup:**
```
Monday 8am:
Open app → See "Welcome to NCDFCOOP"
Sign up: Phone + password
Check email for verification
✅ Account created
Sees consumer home: Flash deals, categories, products

Immediate impact:
- Can buy groceries from home
- Prices are fair (not inflated)
- Can see what's trending (flash deals)
```

**Day 2 - First Purchase:**
```
Tuesday 7pm:
[Open app] → See "Flash Deals"
[Search "Tomatoes"] → Find 2kg for ₦1,200
Regular price: ₦1,500 (saved ₦300 vs market)
[Add to cart] → [Checkout] → [Pay] → Order confirmed
Delivery next day

Immediate impact:
- Quality tomatoes, confirmed delivery
- No haggling, transparent price
- Saved money vs street market
```

**Week 1 - Becoming Regular User:**
```
Daily:
Open app after work
Browse "Recommended for You"
Usually find something useful
Make 2-3 purchases

Impact:
- No more market stress (women's safety when going out)
- Consistent product quality
- Fair pricing (no price gouging)
- Convenient, time-saving
- Better budgeting (know prices)
```

### Impact on User's Daily Life (Co-op Member)

**User: Chege Ndungu (Farmer/Trader, Nairobi)**

**Month 1 - Member Signup:**
```
Sees consumer app
Think: "I'll join for discounts"
Upgrades to member: ₦2,500/year
Gets member home screen
Sees: "🥇 GOLD TIER" loyalty card

Immediate impact:
- Excited: "I'm a tier member now"
- Gets 10% discount automatically
- First purchase of ₦5,000 now costs ₦4,500
- Saves ₦500 instantly
```

**Week 2 - Points Accumulation:**
```
Makes 5 purchases totaling ₦20,000
Earns: 20,000 × 10% = 2,000 loyalty points
Sees on home: "Available: 2,000 pts"

Impact:
- Feels rewarded: "I get paid to shop"
- Motivation: "Let me reach 5,000 for next tier"
- Sticky behavior: Keeps coming back
```

**Month 2 - Experiencing Member Benefits:**
```
[Home] → [Your Benefits]
Sees: "Member Dividend: ₦850 earned"
Reads: "You own 0.2% of the cooperative"
Sees transparency report: Where profits go
Reads: "₦50M went to farmer support fund"

Impact:
- Feels ownership: "This is MY cooperative"
- Trusts platform: "They're transparent"
- Emotional investment: Not just shopping anymore
- Community feeling: Part of something bigger
```

**Month 3 - Voting Participation:**
```
[Home] → [Vote Now]
Sees 3 motions:
1. Annual budget allocation
2. Member dividend amount
3. Farmer support program scope

Votes "YES" on all
Sees results: "Your vote counts!"
Understands: "Members run this, not CEOs"

Impact:
- Feels empowered: "I have a say"
- Democratic participation: Real voting
- Commitment increases: "This is worth defending"
```

**Month 6 - Wealth Building:**
```
Reaches ₦50,000 savings goal
[My Savings] shows: ₦18,750 saved from discounts
                   +  ₦2,150 from dividends
Total: ₦20,900 won without extra effort

Impact:
- Wealth building: "I'm building an emergency fund"
- Passive income: Dividends for just existing
- Financial security: Safety net growing
```

### Impact on User's Daily Life (Seller)

**User: Peter Okoro (Farmer/Supplier, Lagos)**

**Day 1 - Seller Signup:**
```
Sees "Start Selling on NCDF COOP"
Values: "Quality assured, verified buyers"
Completes onboarding: 5 steps
Uploads first product: 500kg Garlic, ₦2,500/kg
Submits for review

Impact:
- No middleman: Direct to buyers
- Quality assurance: Makes buyers trust
- Formal record: Everything documented
```

**Day 2 - First Product Approved:**
```
Notification: "🟢 Your garlic is APPROVED!"
Can see: Product now live to 50,000 potential buyers
First buyer message: "Can I order 100kg?"

Impact:
- Real business: Actual inquiries
- Market reach: From 0 to 50,000 customers
- Opportunity: First order possible
```

**Week 1 - First Sale:**
```
Buyer confirms: 100kg @ ₦2,500 = ₦250,000 order
Peter arranges pickup/delivery
Payment processed: ₦250,000 in account (after 2% fee)

Impact:
- Real revenue: First business income
- Motivation: "This works!"
- Confidence: Ready to scale
```

**Month 1 - Business Scaling:**
```
Added 8 products total
4 approved, 2 pending, 2 rejected (fixed/resubmitted)
Total revenue: ₦620,000 from 6 orders
Rating: 4.8 stars from 4 reviews

Dashboard shows:
- Total Products: 8
- Total Revenue (MTD): ₦620,000
- Pending Orders: 3
- Buyer Inquiries: 12

Impact:
- Real business metrics: Track growth
- Reputation: 4.8 star rating matters
- Momentum: Multiple orders building
```

**Quarter 1 - Expansion Planning:**
```
Revenue: ₦1.8M
Rating: 4.7 stars (25 reviews)
Thinking: "I need help managing this"

Planning: Hire assistant to handle inquiries
Invest in: Better agricultural inputs
Scale: Increase production 50%

Impact:
- Job creation: Hired local assistant
- Economic impact: Supporting community
- Real business: Transitioned from farmer to entrepreneur
```

---

## WEBSITE IMPLEMENTATION CHECKLIST

### Phase 1: Foundation
- [ ] Design mockups for 3 home screens (Consumer, Member, Seller)
- [ ] Create responsive layouts for desktop, tablet, mobile
- [ ] Set up design system components in your web framework
- [ ] Implement color system (#1E7F4E, #C9A227, #0B6B3A)
- [ ] Create reusable button components
- [ ] Set up responsive grid system (12-col or CSS Grid)

### Phase 2: Consumer (Wholesale Buyer) Home
- [ ] Build header with personalized greeting
- [ ] Implement search bar (sticky or fixed position)
- [ ] Create flash deals section (horizontal scroll with countdown)
- [ ] Build 6-category grid with icons
- [ ] Implement recommended products grid (2-4 columns responsive)
- [ ] Add "Become a Member" CTA at bottom
- [ ] Implement responsive spacing and typography
- [ ] Test on desktop, tablet, mobile

### Phase 3: Member Home
- [ ] Build hero loyalty card section
  - [ ] Show tier (Bronze/Silver/Gold/Platinum) with color coding
  - [ ] Display current points and Redeem button
  - [ ] Show progress to next tier with percentage
- [ ] Create savings impact tracker (3 stat cards)
- [ ] Build savings goal section with progress bar
- [ ] Implement 6-button quick actions grid
- [ ] Add voting section with active motions
- [ ] Create transparency reports section (scrollable list)
- [ ] Build exclusive member deals carousel
- [ ] Add "Shop All Member Products" CTA
- [ ] Test tier display (color changes per tier)

### Phase 4: Seller Home
- [ ] Create onboarding step indicator (1-5)
- [ ] Build landing screen with value props
- [ ] Create setup form (business name, type, location, category)
- [ ] Implement product upload form
  - [ ] Image upload/preview
  - [ ] Form validation
  - [ ] Approval notice banner
- [ ] Build status screen with color-coded badges
- [ ] Create dashboard with:
  - [ ] Business metrics grid (products, pending, approved, revenue)
  - [ ] Filter tabs (All/Pending/Approved)
  - [ ] Product list with status badges
  - [ ] FAB or button for Add New Product
- [ ] Implement product cards showing:
  - [ ] Name, price, quantity, MOQ
  - [ ] Status badge
  - [ ] Inquiry count (if applicable)

### Phase 5: Navigation & Routing
- [ ] Set up role-based routing system
- [ ] Map button navigation to routes
- [ ] Implement navigation hierarchy
- [ ] Create breadcrumb or back navigation
- [ ] Set up URL structure matching mobile app

### Phase 6: Data Integration
- [ ] Connect to authentication system
- [ ] Implement `currentUserProvider` equivalent
- [ ] Connect to role detection system
- [ ] Implement data fetching for:
  - [ ] User data (name, role, tier)
  - [ ] Products (consumer/member specific)
  - [ ] Member data (points, savings, tier)
  - [ ] Seller products and metrics
- [ ] Set up real-time data updates

### Phase 7: Responsive Design
- [ ] Test desktop layout (1920x1080 full screen)
- [ ] Test tablet layout (iPad 768-1024px)
- [ ] Test mobile layout (375-480px)
- [ ] Verify touch targets (minimum 44px)
- [ ] Test horizontal scroll sections (products, deals)
- [ ] Test form input sizes on mobile
- [ ] Verify image aspect ratios across devices

### Phase 8: Animations & Interactions
- [ ] Implement fade-in on page load
- [ ] Add countdown timer for flash deals
- [ ] Create progress bar animations (savings goal)
- [ ] Implement button hover/press states
- [ ] Add smooth scrolling for carousels
- [ ] Create modal dialogs for deposit/withdraw (member)
- [ ] Test performance on low-end devices

### Phase 9: Accessibility
- [ ] Add alt text to all images
- [ ] Implement proper heading hierarchy (H1-H6)
- [ ] Ensure color contrast ratios (WCAG AA)
- [ ] Add keyboard navigation support
- [ ] Implement ARIA labels for interactive elements
- [ ] Test with screen readers

### Phase 10: Performance & Optimization
- [ ] Optimize image sizes and formats
- [ ] Implement lazy loading for product grids
- [ ] Minify CSS and JavaScript
- [ ] Implement caching strategy
- [ ] Test Core Web Vitals
- [ ] Optimize for slow networks

### Phase 11: Testing
- [ ] Unit test critical components
- [ ] Integration test data flows
- [ ] Test logout/role switching
- [ ] Test all button click actions
- [ ] Test form submissions
- [ ] Test error states (no products, loading, errors)
- [ ] Test on multiple browsers (Chrome, Firefox, Safari, Edge)

### Phase 12: Quality Assurance
- [ ] Cross-browser testing
- [ ] Cross-device testing
- [ ] Accessibility audit
- [ ] Performance audit
- [ ] Security audit (API calls)
- [ ] Load testing (concurrent users)
- [ ] Usability testing with real users

---

## CRITICAL IMPLEMENTATION NOTES FOR WEBSITE TEAM

### 1. **Roles Are Fundamental to UX**
The role determines EVERYTHING:
- What user sees on homepage
- What buttons are available
- What data they can access
- What prices they see
- Navigation structure

**You MUST implement role detection before rendering any home screen.**

### 2. **Role Detection Pattern**
```
User Login
  ↓
Get user's highest role from backend
  ↓
Route to specific home screen:
  - wholesaleBuyer → ConsumerHome
  - coopMember or premiumMember → MemberHome
  - seller → SellerOnboarding or SellerDashboard
  ↓
Render role-specific layout
```

### 3. **Real-Time Data Requirements**
All home screens should update in real-time:
- Flash deal countdown timers (update every second)
- Points balance (update on purchase)
- Approval status (update on admin action)
- Inquiry count (update on buyer action)

**Use WebSockets or subscription APIs, not polling.**

### 4. **Approval Workflow for Sellers**
Products go through 3 states:
1. 🟡 **Pending** (Under review, not live to buyers)
2. 🟢 **Approved** (Live, buyers can see and inquire)
3. 🔴 **Rejected** (Seller must fix and resubmit)

**This is critical for platform quality control.**

### 5. **Member Tier Colors Must Match**
```
🥉 Bronze:   #CD7F32
🥈 Silver:   #C0C0C0
🥇 Gold:     #C9A227 (NCDF primary - must match exactly)
💎 Platinum: #9D4EDD
```

Tier display is emotional - colors matter for recognition.

### 6. **Button Tap Targets**
Minimum 44px × 44px for mobile, 48px for larger buttons.

Key buttons that need extra care:
- Quick action grid (6 buttons) - ensure 60x60px minimum
- Hero loyalty card - full card is tappable
- Filter tabs - ensure 48px height
- Search bar - 48px height

### 7. **Responsive Layout Strategy**

**Mobile (375-480px):**
- Full-width cards with 16px padding
- Stack all sections vertically
- Single-column grids become full-width
- FAB (Floating Action Button) in bottom right

**Tablet (768-1024px):**
- 2-column product grids
- 3-button action rows
- Side padding 24-32px

**Desktop (1920px+):**
- 3-4 column product grids
- Wider max-width container (1200-1400px)
- Side panels possible

### 8. **Flash Deals Countdown Timer**
Must update every second in real-time:
```
"2 hours left"    → (after 1 sec)
"1 hour 59m left" → (after 30 mins)
"59 minutes left" → (at expiry time)
"Offer Ended" (disable card, gray out)
```

### 9. **Member Savings Goal Calculation**
```
Savings = Total Spent × Discount Percentage
Example:
- Spent: ₦125,000
- Discount: 10%
- Saved: ₦12,500

Update this in real-time after every purchase.
```

### 10. **Seller Product Status Badges**
Must be visually distinct:
```
🟡 PENDING APPROVAL
   - Amber/yellow background
   - Show submitted time
   - Show estimated review completion

🟢 APPROVED
   - Green background
   - Show "Live to Buyers"
   - Show approval timestamp

🔴 REJECTED
   - Red background
   - Show rejection reason
   - Show option to edit/resubmit
```

---

## SUMMARY

The NCDF COOP Commerce platform uses **3 distinct roles** to serve different user types:

1. **🛍️ Wholesale Buyer** - Simple, fast shopping experience focused on discovery and deals
2. **♥️ Co-op Member** - Loyalty-focused experience with rewards, voting, and community ownership
3. **🏪 Seller** - Business management experience with inventory, approval workflow, and metrics

Each role has:
- ✅ Unique homepage layout and design
- ✅ Unique buttons and navigation
- ✅ Unique features and data display
- ✅ Unique real-world user impact
- ✅ Unique pricing and permissions

**The website version MUST implement these roles identically to ensure system coherence and user consistency.**

This document provides every detail needed for your website team to build the three home screens correctly and understand how users interact with them in real-world scenarios.

---

**Document Version:** 1.0  
**Last Updated:** April 6, 2026  
**Next Review:** Upon website alpha launch

