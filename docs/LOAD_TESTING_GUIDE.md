# Real-Time Sync Load Testing Guide

## Overview

This guide covers load testing the real-time sync system to ensure it can handle concurrent users and high-frequency updates.

## Quick Start

### 1. Run Load Test

```bash
npm run load-test
```

This will:
- Simulate 100 concurrent users
- Run for 5 minutes
- Measure Firestore performance
- Generate a detailed report

### 2. Monitor Firestore Quota

While the test runs, monitor in Cloud Console:

```
https://console.cloud.google.com/firestore/quotas
```

Check:
- ✓ Concurrent connections
- ✓ Read operations count
- ✓ Write operations count
- ✓ Database bandwidth

### 3. Review Results

The test will output:
```
LOAD TEST REPORT
================

📊 PERFORMANCE METRICS:
  Total Duration:              300.0 seconds
  Total Requests:              50000
  Requests per Second:         166.67
  
⏱️  LATENCY METRICS:
  Average Latency:            45.23 ms
  Min Latency:                12 ms
  Max Latency:               1250 ms
  
💾 FIRESTORE USAGE:
  Read Operations:            250000
  Write Operations:           10000
  Estimated Cost:             $0.015
```

## Load Test Configuration

**File**: `scripts/load_test.js`

**Default Settings**:

| Setting | Value | Description |
|---------|-------|-------------|
| CONCURRENT_USERS | 100 | Number of simultaneous connections |
| TEST_DURATION_MINUTES | 5 | How long to run the test |
| UPDATE_INTERVAL_MS | 2000 | Frequency of user updates (ms) |
| FIRESTORE_REGION | us-central1 | Firestore region |

**Customization**:

Edit `CONFIG` in `load_test.js`:

```javascript
const CONFIG = {
  CONCURRENT_USERS: 200,  // More users
  TEST_DURATION_MINUTES: 10,  // Longer test
  UPDATE_INTERVAL_MS: 1000,  // More frequent updates
};
```

## Real-Time Providers Tested

The load test monitors these Firestore collections:

### 1. **Inventory Sync**
```
franchise_inventory_sync/{userId}
```
- Simulates watching franchise inventory changes
- 1 listener per user

### 2. **Pricing Rules Updates**
```
pricing_rules_updates
```
- Watches product price changes
- Query: `where('affectedProducts', 'array-contains', userId)`

### 3. **Order Fulfillment**
```
orders/{orderId}
```
- Watches order status changes
- Used for delivery tracking

### 4. **Driver Locations**
```
driver_locations
```
- Watches active driver locations
- Query: `where('activeOrderId', '==', orderId)`

### 5. **Notifications**
```
notifications
```
- Watches unread notifications
- Query: `where('userId', '==', userId) & where('status', '==', 'unread')`

## Performance Targets

| Metric | Target | Red Flag |
|--------|--------|----------|
| Avg Latency | < 100 ms | > 500 ms |
| Failure Rate | 0% | > 5% |
| Requests/sec | > 100 | < 50 |
| Max Latency | < 1000 ms | > 2000 ms |
| Connection Stability | 100% | < 95% |

## Scaling Analysis

### Small Load (25 users)
```bash
CONCURRENT_USERS=25 npm run load-test
```
**Expected**: 
- Latency: 20-30 ms
- No failures
- ~60K operations

### Medium Load (100 users)
```bash
CONCURRENT_USERS=100 npm run load-test
```
**Expected**:
- Latency: 40-80 ms
- < 1% failures
- ~250K operations

### Heavy Load (500 users)
```bash
CONCURRENT_USERS=500 npm run load-test
```
**Expected**:
- Latency: 200-400 ms
- < 5% failures
- ~1.2M operations
- Monitor quotas carefully

### Stress Test (1000 users)
```bash
CONCURRENT_USERS=1000 npm run load-test
```
**Expected**:
- Will hit Firestore quotas
- Useful to identify breaking point
- May need Blaze plan

## Firestore Quota Limits (Spark Plan)

| Metric | Limit |
|--------|-------|
| Concurrent Connections | ~100 |
| Max Reads/sec | 10,000 |
| Max Writes/sec | 1,000 |
| Max Delete/sec | 1,000 |
| Storage | 1 GB |

**Note**: Upgrade to **Blaze Plan** for production load testing.

## Firestore Quota Limits (Blaze Plan)

| Metric | Limit | Cost |
|--------|-------|------|
| Concurrent Connections | ~10,000 | Included |
| Max Reads/sec | 60,000 | $0.06/M reads |
| Max Writes/sec | 20,000 | $0.18/M writes |
| Max Delete/sec | 20,000 | $0.02/M deletes |
| Storage | Unlimited | $0.18/GB/month |

## Setup for Load Testing

### 1. Create Firebase Project

```bash
firebase projects:create coop-commerce-load-test
```

### 2. Enable Firestore

```bash
firebase firestore:databases:create \
  --database=load-test \
  --location=us-central1
```

### 3. Set up Service Account

1. Go to **Google Cloud Console**
2. Navigate to **Service Accounts**
3. Create new service account
4. Download JSON key
5. Set environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
export FIREBASE_PROJECT_ID="your-project-id"
```

### 4. Create Test Collections

Initialize with dummy data:

```bash
npm run load-test:setup
```

## Interpreting Results

### Good Results ✓

```
Average Latency: 45.23 ms
Requests per Second: 166.67
Failed Requests: 0
Failure Rate: 0%
```

✅ System is performing well

### Warning Signs ⚠️

```
Average Latency: 450 ms
Requests per Second: 50
Failed Requests: 125
Failure Rate: 2.5%
```

⚠️ Consider:
- Optimizing queries
- Adding database indexing
- Upgrading to Blaze plan
- Reducing listener count

### Critical Issues ✗

```
Average Latency: 5000+ ms
Requests per Second: 10
Failed Requests: > 50%
Connection Timeouts: Frequent
```

✗ System cannot handle load - investigate:
- Firestore quotas exceeded
- Network issues
- Query complexity
- Too many concurrent listeners

## Optimization Tips

### 1. Query Optimization

```dart
// ❌ Bad: Inefficient query
stream: firestore
  .collection('orders')
  .where('userId', isEqualTo: userId)
  .snapshots(),

// ✅ Good: Indexed & paginated
stream: firestore
  .collection('users')
  .doc(userId)
  .collection('orders')
  .limit(20)
  .snapshots(),
```

### 2. Connection Pooling

```dart
// Use singleton pattern for Firestore instance
final firestore = FirebaseFirestore.instance;

// Reuse across the app
```

### 3. Listener Management

```dart
// ❌ Bad: Multiple listeners
StreamBuilder<List<Order>>(
  stream: firestore.collection('orders').snapshots(),
  builder: (context, snapshot) {
    // Each build creates new listener
  },
)

// ✅ Good: Single listener
@override
void initState() {
  _ordersStream = firestore.collection('orders').snapshots();
  super.initState();
}
```

### 4. Batch Operations

```dart
// ✅ Good: Batch write
WriteBatch batch = firestore.batch();
for (var order in orders) {
  batch.update(order.ref, order.toMap());
}
await batch.commit();
```

## Monitoring in Production

### 1. Enable Performance Monitoring

```bash
firebase emulators:start --inspect-functions
```

### 2. View Metrics in Firebase Console

- Analytics → Performance
- Database → Usage Stats

### 3. Set up Alerts

In Google Cloud Console:

```
Alerts > Create Policy
Condition: Firestore read operations > 50,000/sec
Notification: Email to ops@coop.dev
```

## Load Test Schedule

| Stage | Load | Duration | Target |
|-------|------|----------|--------|
| Dev | 10 users | 10 min | Verify basic functionality |
| Staging | 100 users | 30 min | Identify bottlenecks |
| Pre-prod | 500 users | 60 min | Stress test edge cases |
| Prod Launch | 1000+ users | Continuous | Real-time monitoring |

## Troubleshooting

### Test Won't Start

```bash
# Check Firebase credentials
echo $FIREBASE_PROJECT_ID

# Verify Firestore connectivity
firebase firestore:query "orders/test"
```

### High Latency

1. Check Firestore indices:
   ```
   Cloud Console > Firestore > Indexes
   ```

2. Optimize queries - use composite indexes

3. Monitor network latency:
   ```bash
   ping firestore.googleapis.com
   ```

### High Failure Rate

1. Check quotas:
   ```
   Cloud Console > Quotas
   ```

2. Review Firestore logs:
   ```
   Cloud Console > Logs > firestore.googleapis.com
   ```

3. Reduce concurrent users or update interval

## Next Steps

- [ ] Run load test with default settings
- [ ] Interpret results and identify bottlenecks
- [ ] Optimize queries based on findings
- [ ] Run load test again to verify improvements
- [ ] Document baseline metrics
- [ ] Create monitoring dashboards
- [ ] Plan for production load

## References

- [Firestore Quota Limits](https://firebase.google.com/docs/firestore/quotas)
- [Load Testing Best Practices](https://cloud.google.com/architecture/load-testing)
- [Real-Time Database Optimization](https://firebase.google.com/docs/firestore/optimize)
