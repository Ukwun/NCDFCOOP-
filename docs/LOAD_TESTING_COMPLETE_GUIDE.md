# Load Testing Guide - Coop Commerce App

**Purpose:** Validate app performance and scalability under realistic load conditions  
**Target:** 1000+ concurrent users  
**Date Created:** February 23, 2026

---

## 📊 LOAD TESTING OVERVIEW

### What The Tests Measure

1. **Response Time** - How fast the app responds under load
2. **Throughput** - How many requests per second the system handles
3. **Error Rate** - What percentage of requests fail
4. **Resource Usage** - CPU, memory, database reads/writes
5. **Scalability** - How performance degrades with more users

### Key Metrics to Monitor

```
Target Metrics (MUST PASS):
✅ Home Screen Load: < 500ms (average)
✅ Search Query: < 300ms (average)
✅ Product Detail: < 400ms (average)
✅ Checkout: < 2s (average)
✅ Payment: < 3s (average)
✅ Error Rate: < 0.5% (less than 5 errors per 1000 requests)
✅ 95th Percentile Response: < 2s (for normal operations)

Scalability Target:
✅ 100 concurrent users: All metrics pass
✅ 500 concurrent users: All metrics pass  
✅ 1000 concurrent users: All metrics pass
✅ 5000 concurrent users: <5% degradation (after index optimization)
```

---

## 🧪 PHASE 1: MANUAL LOAD TESTING (Local Setup)

### 1.1 Install Apache JMeter

```bash
# Windows
choco install jmeter

# Or download from: https://jmeter.apache.org/download_jmeter.cgi
```

### 1.2 Create Test Plan

**File:** `load_test_plan.jmx` (saved in JMeter)

**Test Configuration:**

```
┌─ Thread Group 1: Home Screen Browsing
│  ├─ Number of Threads: 100 (users)
│  ├─ Ramp-up Time: 10 seconds
│  ├─ Loop Count: 10
│  └─ HTTP Request: GET /home (or Firestore equivalent)
│
├─ Thread Group 2: Product Search
│  ├─ Number of Threads: 100 (users)
│  ├─ Ramp-up Time: 10 seconds
│  ├─ Loop Count: 5
│  └─ HTTP Request: GET /search?q=products
│
├─ Thread Group 3: Add to Cart
│  ├─ Number of Threads: 50 (users)
│  ├─ Ramp-up Time: 10 seconds
│  ├─ Loop Count: 3
│  └─ HTTP Request: POST /cart
│
└─ Thread Group 4: Checkout (Payments)
   ├─ Number of Threads: 20 (users)
   ├─ Ramp-up Time: 10 seconds
   ├─ Loop Count: 1
   └─ HTTP Request: POST /checkout
```

### 1.3 Steady-State Load Test (Warming Phase)

```
Phase 1: Ramp Up (5 minutes)
- Start with 10 users
- Add 20 users every minute
- Reach 100 concurrent users

Phase 2: Steady State (10 minutes)
- Maintain constant 100 users
- Monitor metrics
- Check for memory leaks

Phase 3: Peak Load (5 minutes)
- Increase to 500 concurrent users quickly
- Observe how system responds
- Check if response times degrade

Phase 4: Ramp Down (5 minutes)
- Remove users gradually
- Verify cleanup properly
- Check for hanging connections
```

---

## 🔥 PHASE 2: FIREBASE-NATIVE LOAD TESTING

### 2.1 Using Firebase Load Testing Tool

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Select project
firebase use coop-commerce

# Create load test configuration
cat > firestore-load-test.json << 'EOF'
{
  "projectId": "coop-commerce",
  "testId": "load-test-phase1",
  "testConfig": {
    "duration": 300,  // 5 minutes in seconds
    "concurrency": 100,
    "operations": [
      {
        "name": "read_products",
        "operationsPerSecond": 50,
        "operationType": "READ",
        "collection": "products",
        "filter": "category == 'Grains'"
      },
      {
        "name": "read_user_orders",
        "operationsPerSecond": 30,
        "operationType": "READ",
        "collection": "orders",
        "filter": "userId == 'current_user'"
      },
      {
        "name": "write_activities",
        "operationsPerSecond": 20,
        "operationType": "WRITE",
        "collection": "user_activities",
        "data": {
          "userId": "test_user",
          "action": "product_view",
          "timestamp": "now()"
        }
      }
    ]
  }
}
EOF

# Run load test
firebase test firestore-load-test.json
```

### 2.2 Monitor Firebase Metrics During Test

**Open Firebase Console → Your Project → Firestore**

Watch these metrics in real-time:

```
Firestore Dashboard:
┌────────────────────────────────────────┐
│ Current Connections: 100               │
│ Active Operations: 500ops/sec           │
│ Database Writes: ▓▓▓▓░░░░░░ 400K/day   │
│ Database Reads: ▓▓▓▓▓▓▓░░░░ 800K/day   │
│ Storage: ▓░░░░░░░░░░░░░░░░░░ 2.5GB    │
└────────────────────────────────────────┘

Alert if:
❌ Dropped connections > 5%
❌ Latency > 2 seconds (p95)
❌ Error rate > 1%
❌ Quota exceeded
```

---

## 💻 PHASE 3: APP-LEVEL LOAD TESTING

### 3.1 Create Load Test Scenarios

**File:** `test/load_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coop_commerce/main.dart';

void main() {
  group('Load Testing', () {
    testWidgets('Handle 100 product loads', (tester) async {
      // Load app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Simulate 100 rapid product loads
      for (int i = 0; i < 100; i++) {
        // Load products
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle(Duration(milliseconds: 100));
      }

      // Assert no crashes
      expect(find.byType(MyApp), findsOneWidget);
    });

    testWidgets('Handle rapid cart operations', (tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Add/remove items 50 times rapidly
      for (int i = 0; i < 50; i++) {
        await tester.tap(find.byIcon(Icons.add_shopping_cart));
        await tester.pump(Duration(milliseconds: 50));
        await tester.tap(find.byIcon(Icons.remove_shopping_cart));
        await tester.pump(Duration(milliseconds: 50));
      }

      expect(find.byType(MyApp), findsOneWidget);
    });

    testWidgets('Memory stability check', (tester) async {
      // Monitor memory during extended use
      final memBefore = await getMemoryUsage();
      
      await tester.pumpWidget(const MyApp());
      
      // Simulate 30 minutes of usage
      for (int i = 0; i < 1800; i++) {
        await tester.pump(Duration(milliseconds: 1000));
      }
      
      final memAfter = await getMemoryUsage();
      final increase = memAfter - memBefore;
      
      // Memory shouldn't increase > 50MB
      expect(increase, lessThan(50 * 1024 * 1024));
    });
  });
}
```

### 3.2 Run Load Tests

```bash
# Run with verbose output
flutter test test/load_test.dart -v

# Run with profiling
flutter test test/load_test.dart --profile

# Run with memory tracking
flutter test test/load_test.dart --vmservice-out-dir=vmservice
```

---

## 📈 PHASE 4: NETWORK CONDITION TESTING

### 4.1 Test on Slow Networks

**Android Emulator Network Throttling:**

```bash
# Set to 3G network
adb shell settings put global airplane_mode_on 0
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false

# Simulate 3G network (slow)
telnet localhost 5554
gsm voice off
gsm data on
network speed gprs
```

### 4.2 Test Scenarios

```
Scenario 1: EDGE Network (2G - Slowest)
- Bandwidth: 236 kbps
- Latency: 400ms
- Test: Load app and see if it's still usable
- Expected: App loads, UI responsive, but slower

Scenario 2: 3G Network (Slower)
- Bandwidth: 400 kbps
- Latency: 100ms
- Test: Browse products, add to cart
- Expected: Pages load in 2-3 seconds

Scenario 3: 4G Network (Fast)
- Bandwidth: 25 Mbps
- Latency: 20ms
- Test: Full user journey
- Expected: All operations < 500ms

Scenario 4: WiFi Network (Fastest)
- Bandwidth: 100+ Mbps
- Latency: < 10ms
- Test: Load heavy screens
- Expected: All operations < 200ms
```

---

## 📊 PHASE 5: ANALYZE RESULTS

### 5.1 Sample Load Test Results (Expected)

```
════════════════════════════════════════════════════════════
                  LOAD TEST RESULTS SUMMARY
════════════════════════════════════════════════════════════

Test Duration: 300 seconds (5 minutes)
Concurrent Users: 100
Total Requests: 15,000

                REQUEST METRICS
────────────────────────────────────────────────────────────
Operation          Avg Time    Min     Max     P95     P99
────────────────────────────────────────────────────────────
Home Screen Load    280ms      100ms   500ms   450ms   480ms ✅
Search Query        250ms      80ms    400ms   380ms   395ms ✅
Product Detail      320ms      110ms   600ms   550ms   580ms ✅
Add to Cart         150ms      50ms    300ms   280ms   295ms ✅
Checkout            1800ms     1200ms  3000ms  2800ms  2950ms ✅
Payment             2100ms     1500ms  4000ms  3800ms  3950ms ✅

                RELIABILITY METRICS
────────────────────────────────────────────────────────────
Successful Requests:  14,925 (99.5%) ✅
Failed Requests:      75 (0.5%) ✅ (acceptable)
Error Rate:           0.5% ✅

                DATABASE METRICS
────────────────────────────────────────────────────────────
Firestore Reads:      8,000/sec (peak)
Firestore Writes:     2,500/sec (peak)
Read Quota: 50M/day   Using: 15% ✅
Write Quota: 50K/day  Using: 8% ✅

                SCALABILITY RESULTS
────────────────────────────────────────────────────────────
100 Users:   All metrics PASS ✅
500 Users:   All metrics PASS ✅ (2% slower)
1000 Users:  All metrics PASS ✅ (3% slower)
5000 Users:  Needs optimization (10% slower) ⚠️

RECOMMENDATION: Add database indexes before 5000+ users
═════════════════════════════════════════════════════════════
```

### 5.2 Identify Bottlenecks

```
If response times are slow:
❌ Problem: Queries without indexes
✅ Solution: Create Firestore indexes

If errors spike:
❌ Problem: Rate limiting hit
✅ Solution: Increase Firebase quota

If memory grows:
❌ Problem: Memory leak in app
✅ Solution: Check provider disposal

If database quota exceeded:
❌ Problem: Too many reads
✅ Solution: Add caching layer
```

---

## 🚀 OPTIMIZATION CHECKLIST

After initial load test, optimize:

```
□ Create missing Firestore indexes
□ Implement caching (see cache_manager.dart)
□ Reduce database reads by caching
□ Optimize image sizes and CDN
□ Enable gzip compression
□ Set up connection pooling
□ Implement pagination (already done)
□ Cache frequently accessed data
□ Use batch writes for multiple updates
```

---

## 📋 QUICK COMMANDS REFERENCE

```bash
# Build APK for testing
flutter build apk --debug

# Install on device
adb install -r build/app/outputs/apk/debug/app-debug.apk

# View Firebase logs
firebase functions:log --limit 100

# Monitor Firestore usage
firebase firestore:describe

# Set network throttle (Android)
adb shell settings put global airplane_mode_on 1
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE
```

---

## ✅ TESTING CHECKLIST

Before claiming production-ready:

```
□ Load Test with 100 users: PASS
□ Load Test with 500 users: PASS
□ Load Test with 1000 users: PASS
□ Network error handling: PASS
□ Payment failures handled: PASS
□ Offline mode works: PASS
□ Cache invalidation works: PASS
□ No memory leaks detected: PASS
□ No database quota exceeded: PASS
□ Error rate < 0.5%: PASS
□ Response times < targets: PASS
□ Scaling to 5000+ users possible: CONFIRMED
```

---

## 📞 Support

If load test fails:
1. Check Firebase quotas (may need upgrade)
2. Review error logs in Firebase Console
3. Verify database indexes exist
4. Check for infinite loops in code
5. Profile memory usage with DevTools
