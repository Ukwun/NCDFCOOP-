# Product Browsing Integration Test Plan

**Date:** January 29, 2026  
**Feature:** Product Browsing (100% Complete - Ready for Testing)  
**Screens Tested:** ProductsListingScreen, ProductDetailScreen, SearchScreen  
**Services Used:** ProductService, AuditService  
**Status:** Ready for Integration Testing

---

## Test Objectives

1. **Verify category filtering** - Filter by category parameter
2. **Verify sort functionality** - Sort by popularity, price, rating, newest, name
3. **Verify product data display** - Real Product model data from service
4. **Verify search functionality** - Real-time search integration
5. **Verify navigation** - Between listing → detail → related products
6. **Verify add-to-cart** - UI interactions and feedback

---

## Test Cases

### TC-01: Products Listing Screen - Initial Load
**Steps:**
1. Navigate to products listing screen (no category)
2. Observe initial product grid loading

**Expected Results:**
- ✅ Loading spinner shows during data fetch
- ✅ Grid displays real products from `allProductsProvider`
- ✅ Each product card shows: image, name, price, rating, stock status
- ✅ No compilation errors in console

**Acceptance Criteria:**
- Products load within 2 seconds
- All product data fields populated
- UI is responsive and not frozen

---

### TC-02: Category Filtering
**Steps:**
1. From products listing, observe category selection UI (if available)
2. Navigate to listing with category parameter (e.g., 'Groceries')
3. Observe product grid update

**Expected Results:**
- ✅ Products filtered to selected category via `productsByCategoryProvider(category)`
- ✅ Only products in that category display
- ✅ Product count reflects category subset
- ✅ Category name displays in header/filter chips

**Acceptance Criteria:**
- Filter parameter correctly passed to provider
- UI updates to show filtered results
- Sort options still work on filtered results

---

### TC-03: Sort Options
**Steps:**
1. On products listing, observe sort option pills
2. Click "Popularity" pill
3. Click "Price" pill
4. Click "Rating" pill
5. Click "Newest" pill
6. Click "Name" pill

**Expected Results:**
- ✅ Selected sort option highlighted (different color)
- ✅ Products reorder based on selected sort
- ✅ Each sort applies correctly:
  - Popularity: Default order from service
  - Price: Low to high (ascending)
  - Rating: High to low (descending)
  - Newest: Most recent first
  - Name: Alphabetically (A-Z)

**Acceptance Criteria:**
- Sort state persists during session
- Products visibly reorder
- No console errors during sort

---

### TC-04: Product Card Interactions
**Steps:**
1. Tap on any product card in grid view
2. Observe navigation to product detail

**Expected Results:**
- ✅ Navigation to ProductDetailScreen with productId
- ✅ Route: `context.pushNamed('product-detail', extra: product.id)`
- ✅ Transition is smooth (no lag)
- ✅ Detail screen loads without error

**Acceptance Criteria:**
- Navigation happens immediately
- Product detail screen displays
- No back button issues

---

### TC-05: Product Detail Screen - Data Display
**Steps:**
1. From listing, tap on a product to view details
2. Observe all product information

**Expected Results:**
- ✅ Product image loads (NetworkImage from product.imageUrl)
- ✅ Product name displays
- ✅ Full description shows
- ✅ Retail price displays prominently
- ✅ Wholesale price shows (if applicable)
- ✅ Savings badge shows % discount
- ✅ Star rating displays (1-5 stars)
- ✅ Stock status shows ("X in stock" or "Out of Stock")
- ✅ Product details table shows (ID, Category, Stock, MOQ)
- ✅ "Why Buy From Us?" benefits section displays
- ✅ "Related Products" carousel shows 6 related items

**Acceptance Criteria:**
- All product fields are visible
- No missing/null values shown
- Related products carousel is scrollable
- Network image loads successfully

---

### TC-06: Related Products Carousel
**Steps:**
1. On product detail screen, scroll to "Related Products" section
2. Scroll horizontally through related products
3. Tap on a related product

**Expected Results:**
- ✅ Carousel displays 6 related products
- ✅ Each card shows: image, name, price
- ✅ Horizontal scroll works smoothly
- ✅ Tapping navigates to that product's detail screen
- ✅ Back button returns to previous product

**Acceptance Criteria:**
- Carousel scrolls without lag
- Related products are actually related (same category)
- Navigation between related products works

---

### TC-07: Quantity Selector & Add to Cart
**Steps:**
1. On product detail screen, scroll to bottom
2. Observe quantity selector (- button, number, + button)
3. Click - button multiple times (until quantity = 1)
4. Click + button multiple times (increase quantity)
5. Click "Add to Cart" button
6. Observe feedback

**Expected Results:**
- ✅ Quantity selector starts at 1
- ✅ - button doesn't go below 1
- ✅ + button increases quantity
- ✅ Add to Cart button shows SnackBar: "X x [Product Name] added to cart"
- ✅ Button text changes if stock = 0: "Out of Stock"
- ✅ Button is disabled if stock = 0

**Acceptance Criteria:**
- Quantity logic is correct
- SnackBar displays correctly
- Stock-dependent button state works
- No crashes on button click

---

### TC-08: Search Screen - Initial State
**Steps:**
1. Navigate to search screen
2. Observe initial state

**Expected Results:**
- ✅ Search field is empty
- ✅ No results displayed (empty state message)
- ✅ Keyboard may appear focused on search field
- ✅ No compilation errors

**Acceptance Criteria:**
- Screen loads without error
- Search field is ready for input
- No console warnings

---

### TC-09: Search Screen - Real-Time Search
**Steps:**
1. On search screen, type in search field: "rice"
2. Observe results update in real-time
3. Wait 1-2 seconds
4. Observe API call happens (check network tab if available)
5. Clear search and type: "flour"
6. Observe results update again

**Expected Results:**
- ✅ Search results update as you type
- ✅ Results show products matching search query
- ✅ Each result shows: image, name, price, rating, stock status
- ✅ Search is case-insensitive
- ✅ Results reset when clearing search field
- ✅ No duplicate results

**Acceptance Criteria:**
- Search responds within 500ms of typing
- Results are relevant to query
- No API spam (batched/debounced requests)
- Results display correctly

---

### TC-10: Search Results - Navigation & Add to Cart
**Steps:**
1. Search for a product (e.g., "rice")
2. Tap on a search result
3. Verify navigation to detail screen
4. On detail screen, add to cart
5. Use back button to return to search

**Expected Results:**
- ✅ Tapping search result navigates to detail screen
- ✅ Detail screen shows correct product
- ✅ Add to cart works
- ✅ Back button returns to search screen
- ✅ Search field still contains previous query

**Acceptance Criteria:**
- Navigation is smooth
- Product details are correct
- Add to cart functionality works
- Back navigation preserves state

---

### TC-11: Search Screen - Empty Results
**Steps:**
1. Search for: "xyznonexistent123"
2. Observe results

**Expected Results:**
- ✅ No products display
- ✅ "No products found" message displays
- ✅ User can still modify search query

**Acceptance Criteria:**
- Error handling works
- User-friendly message displays
- Search remains functional

---

### TC-12: Search Screen - Error State
**Steps:**
1. Simulate network error (offline mode if possible)
2. Try to search
3. Observe error handling

**Expected Results:**
- ✅ Error message displays clearly
- ✅ User can retry search
- ✅ App doesn't crash

**Acceptance Criteria:**
- Graceful error handling
- User-friendly error message
- Retry mechanism available

---

### TC-13: Navigation Flow - Complete Journey
**Steps:**
1. Start on Products Listing Screen
2. Apply category filter (e.g., 'Groceries')
3. Select sort option (e.g., 'Price')
4. Tap on product A
5. View Product A detail
6. Tap on Related Product B
7. View Product B detail
8. Go back to Product A
9. Go back to listing screen
10. Verify listing still has category filter + sort applied

**Expected Results:**
- ✅ All navigation transitions smooth
- ✅ Each screen loads correct data
- ✅ Back navigation works correctly
- ✅ Filter/sort state persists in listing screen
- ✅ No memory leaks (no lag after multiple navigations)

**Acceptance Criteria:**
- Complete journey works without errors
- State management is correct
- Navigation is intuitive
- Performance is acceptable

---

### TC-14: Pagination (If Implemented)
**Steps:**
1. On products listing, scroll to bottom
2. Observe if more products load
3. Continue scrolling

**Expected Results:**
- ✅ If pagination implemented: More products load as you scroll
- ✅ If not implemented: All products load initially (acceptable)
- ✅ Loading indicator shows during load more
- ✅ No duplicate products

**Acceptance Criteria:**
- Pagination works smoothly OR products load completely
- No performance degradation
- No duplicate data

---

### TC-15: Wishlist (Simplified)
**Steps:**
1. On product detail screen, tap heart/wishlist button
2. Observe feedback

**Expected Results:**
- ✅ SnackBar displays: "Added to wishlist"
- ✅ Button changes state (if visual feedback implemented)
- ✅ Can tap again (shows different message or toggles)

**Acceptance Criteria:**
- Feedback is provided to user
- Button is responsive
- No console errors

---

## Performance Benchmarks

| Metric | Target | Acceptable | Unacceptable |
|--------|--------|-----------|--------------|
| Listing screen load | <1s | <2s | >3s |
| Product detail load | <1s | <2s | >3s |
| Search response | <500ms | <1s | >2s |
| Navigation transition | <300ms | <500ms | >1s |
| Related products load | <500ms | <1s | >2s |
| Add to cart feedback | Immediate | <200ms | >500ms |

---

## Device Testing

**Primary Test Device:**
- Device Type: Emulator or Physical Device
- Android Version: 10+ recommended
- Screen Size: Phone (6" preferred)

**Optional Additional Testing:**
- Tablet (10"+ screen)
- Different Android versions (9, 11, 12+)
- Network conditions (4G, 3G, poor connection)

---

## Bug Tracking Template

**Format:** [Bug ID] - Brief Title

**Example Bug Report:**
```
BUG-001: Category filter not persisting after navigation
- Severity: HIGH
- Steps to Reproduce:
  1. Apply category filter to 'Groceries'
  2. Tap product to view detail
  3. Go back to listing
- Expected: Category filter still applied
- Actual: Category filter cleared
- Console Error: None
- Device: Pixel 4, Android 12
```

---

## Success Criteria (Overall)

✅ **All 15 test cases pass without errors**
✅ **All performance benchmarks met**
✅ **Zero compilation errors**
✅ **Zero console runtime errors**
✅ **Navigation is smooth and intuitive**
✅ **Product data displays correctly**
✅ **Search works in real-time**
✅ **Add to cart provides feedback**
✅ **Filters and sort persist correctly**
✅ **Related products carousel works**

---

## Sign-Off

**Feature:** Product Browsing Integration (100% Complete)
**Ready for Testing:** ✅ YES
**Expected Test Duration:** 30-45 minutes
**Date:** January 29, 2026

---

## Notes

- All screens are now service-integrated (no mock data)
- Compilation is clean (0 errors, 0 warnings)
- Navigation is properly wired with GoRouter
- State management uses Riverpod providers
- Error handling is implemented
- Loading states are visible

**Next Phase:** After integration testing passes:
1. Performance optimization (if needed)
2. Final UAT with stakeholders
3. Launch to beta testers
4. Production deployment

