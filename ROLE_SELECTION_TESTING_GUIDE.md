# Role Selection Onboarding - Testing Guide

## 🧪 Test Scenario: Complete Signup → Role Selection Flow

### Prerequisites
- ✅ APK built and installed on device
- ✅ App ready to test
- ✅ User email + password ready for signup test

---

## Test Case 1: Complete Signup to Role Selection

### What to Test
1. User creates new account
2. Redirected to role selection screen
3. Can select one of three roles
4. Continues to home with selected role

### Steps to Execute

**Step 1: Launch App**
```
adb shell am start -n com.example.coop_commerce/.MainActivity
```

Expected: App opens to welcome screen

---

**Step 2: Click "Sign Up"**
- Look for "Sign Up" button on welcome screen
- User should see signup form

Expected: Signup form appears

---

**Step 3: Fill Signup Form**
Use test data:
- **Name:** Test User
- **Email:** test+role@example.com  
- **Phone:** +234 901 234 5678
- **Password:** TestPass123
- **Confirm Password:** TestPass123
- **Agree to terms:** Check box

Expected: All fields accept input

---

**Step 4: Click "Sign Up" Button**
- Click the blue "Sign Up" button
- App should process registration

Expected: 
- Spinner/loading indicator appears
- Success message shown briefly
- User redirected to **Role Selection Screen**

---

**Step 5: Verify Role Selection Screen**

Check that you see:
- ✓ Title: "Choose Your Experience"
- ✓ Subtitle: "Welcome, Test User!"  
- ✓ Description text about personalizing experience
- ✓ Three role cards visible:
  1. **🛍️ Regular Shopper** (top)
  2. **🤝 Cooperative Member** (middle)
  3. **🏢 Wholesale Buyer** (bottom)

For each card, verify:
- Icon visible and correct
- Title visible
- Subtitle visible
- Description text about the role
- 4-6 benefit bullet points
- Radio button selector (unfilled circle)
- Proper color coding

Expected: All three cards display correctly with proper styling

---

**Step 6: Select Regular Shopper Role**

Actions:
1. Tap on "🛍️ Regular Shopper" card
2. Observe the radio button in top-right
3. Observe the card's styling changes

Expected:
- ✓ Radio button fills with checkmark
- ✓ Card border becomes bolder
- ✓ Card background gets slight color tint
- ✓ Card is visually highlighted

---

**Step 7: Tap "Continue" Button**

Actions:
1. Tap blue "CONTINUE" button at bottom
2. Wait for processing (should show spinner)

Expected:
- ✓ Spinner appears briefly
- ✓ App navigates to **Home Screen**
- ✓ App shows regular consumer home (standard shopping interface)

---

### ✅ Test Case 1 - PASS Criteria
- [x] Sign up form accepts all inputs
- [x] Account created successfully
- [x] User redirected to role selection screen
- [x] All three role options display correctly
- [x] Role selection UI works smoothly
- [x] Selected role is visually indicated
- [x] Continue button works and navigates to home
- [x] Home screen shows appropriate consumer interface

---

## Test Case 2: Select Cooperative Member Role

### Steps
1. Repeat Steps 1-5 above
2. In Step 6, **tap on "🤝 Cooperative Member" card instead**
3. Proceed with Step 7

Expected: Redirects to **Member Home Screen** with:
- Cooperative branding (gold/brown colors)
- Loyalty points display
- Exclusive member pricing visible
- Team/bulk ordering features
- Cooperative benefits highlighted

---

## Test Case 3: Select Wholesale Buyer Role

### Steps
1. Repeat Steps 1-5 above
2. In Step 6, **tap on "🏢 Wholesale Buyer" card instead**
3. Proceed with Step 7

Expected: Redirects to **Wholesale/Institutional Home Screen** with:
- B2B branding and layout
- Bulk pricing calculator
- PO creation options
- Multiple location shipping
- Wholesale-specific features

---

## Test Case 4: Skip for Now

### Steps
1. Complete Steps 1-5
2. Click "Skip for now" link at bottom
3. Do **NOT** select a role

Expected:
- ✓ Skips role selection
- ✓ Redirects to home screen
- ✓ User assigned **consumer role by default**
- ✓ Regular shopping interface shown

---

## Test Case 5: No Role Selected Error

### Steps
1. Complete Steps 1-5
2. Click "Continue" WITHOUT selecting a role

Expected:
- ✓ Error message appears: "Please select a role to continue"
- ✓ User stays on role selection screen
- ✓ Can then select a role and continue

---

## Test Case 6: Quick User Flow - All Three Roles

### Purpose
Test that each role leads to correct home screen

### Steps
1. Create 3 test accounts (or use same one multiple times):
   - test.consumer@example.com → Select Regular Shopper
   - test.member@example.com → Select Cooperative Member  
   - test.wholesale@example.com → Select Wholesale Buyer

2. For each account:
   - Complete signup
   - Select corresponding role
   - Verify correct home screen displays
   - Check navigation menu looks appropriate
   - Check product pricing matches role

Expected:
- Regular Shopper: Standard retail prices, basic nav
- Cooperative Member: Wholesale prices 10-30% off, member benefits nav
- Wholesale Buyer: Bulk pricing, B2B features, PO nav

---

## 🐛 Known Issues to Check

### Visual Issues
- [ ] Cards not rendering properly
- [ ] Text overflowing in role descriptions
- [ ] Colors not displaying correctly
- [ ] Radio buttons not working
- [ ] Cards not responding to taps

### Navigation Issues
- [ ] "Continue" button not responsive
- [ ] Screen doesn't navigate after selection
- [ ] "Skip for now" doesn't work
- [ ] Stuck on role selection screen

### Data Issues
- [ ] Role not saved to user
- [ ] Wrong home screen shows for selected role
- [ ] Role information lost after restart
- [ ] Can't login after signup

---

## 📊 Test Results Template

```
Device: _______________________
OS Version: ___________________
App Build: ____________________
Test Date: ____________________

Test Case 1 (Sign Up → Role Selection): [ ] PASS [ ] FAIL
  - Notes: _________________________________

Test Case 2 (Select Cooperative): [ ] PASS [ ] FAIL
  - Notes: _________________________________

Test Case 3 (Select Wholesale): [ ] PASS [ ] FAIL
  - Notes: _________________________________

Test Case 4 (Skip for Now): [ ] PASS [ ] FAIL
  - Notes: _________________________________

Test Case 5 (Error Handling): [ ] PASS [ ] FAIL
  - Notes: _________________________________

Overall Status: [ ] PASS [ ] FAIL
Issues Found: ______________________
```

---

## 🚀 After Testing

### If All Tests PASS
- ✅ New onboarding flow is working
- ✅ Role selection is intuitive
- ✅ Home screens adapt correctly
- ✅ Ready to deploy to production

### If Tests FAIL
- Detail which test case failed
- Screenshot the issue
- Check app logs for errors:
  ```
  adb logcat | grep -i "error\|exception"
  ```
- Report specific error message

---

## 📝 Key Features to Verify

After role selection, check these features work for each role:

### Consumer Role
- [ ] Browse products at retail prices
- [ ] Add to cart
- [ ] Checkout
- [ ] View loyalty options (read-only)

### Member Role  
- [ ] See wholesale prices (10-30% off)
- [ ] View loyalty points
- [ ] Access team ordering
- [ ] See member exclusive deals
- [ ] Bulk order features visible

### Wholesale Role
- [ ] See B2B pricing
- [ ] Access PO creation
- [ ] Multiple delivery addresses
- [ ] Invoice billing visible
- [ ] Bulk order calculator

---

## 🎯 Success Criteria

✅ **The Old Way is Gone**
- No more email-based role assignment
- Users explicitly choose their role
- Clear options with benefits listed

✅ **The New Way Works**
- Role selection screen appears after signup
- Three clear options with visuals
- User can select their preference
- Home screen adapts to selection
- Each role shows appropriate features

✅ **User Experience is Good**
- Flow is intuitive and fast (< 3 steps)
- Clear explanations of options
- No confusion about what each role means
- Feels like Jumia's role selection model

This validates that the app now properly handles user role selection like a professional multi-segment platform!
