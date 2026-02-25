/**
 * Load Testing Script for Real-Time Sync
 * Simulates concurrent users, measures Firestore performance
 * 
 * Usage: npm run load-test
 */

const firebase = require('@firebase/app');
require('@firebase/firestore');
const admin = require('firebase-admin');

// Configuration
const CONFIG = {
  CONCURRENT_USERS: 100,
  TEST_DURATION_MINUTES: 5,
  UPDATE_INTERVAL_MS: 2000, // How often each user gets updates
  FIRESTORE_REGION: 'us-central1',
  TEST_DATA_PREFIX: 'load_test_',
};

class LoadTestRunner {
  constructor() {
    this.stats = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      totalLatency: 0,
      minLatency: Infinity,
      maxLatency: 0,
      listenerActivationTime: [],
      updateProcessingTime: [],
      firestoreReadCount: 0,
      firestoreWriteCount: 0,
      startTime: null,
      endTime: null,
    };

    this.activeListeners = [];
  }

  /**
   * Initialize Firebase Admin SDK
   */
  async init() {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID,
    });

    console.log('✓ Firebase initialized');
    console.log(`Starting load test with ${CONFIG.CONCURRENT_USERS} concurrent users`);
    console.log(`Test duration: ${CONFIG.TEST_DURATION_MINUTES} minutes\n`);
  }

  /**
   * Simulate a single user watching real-time providers
   */
  async simulateUser(userId) {
    const db = admin.firestore();
    const testOrderId = `${CONFIG.TEST_DATA_PREFIX}${userId}`;

    console.log(`[User ${userId}] Connecting to real-time streams...`);

    return new Promise((resolve) => {
      const startTime = Date.now();
      let updateCount = 0;

      // Listener 1: Inventory Sync (watch franchise inventory)
      const inventoryListener = db
        .collection('franchise_inventory_sync')
        .doc(userId)
        .onSnapshot(
          (doc) => {
            const latency = Date.now() - startTime;
            this.stats.totalLatency += latency;
            this.stats.minLatency = Math.min(
              this.stats.minLatency,
              latency
            );
            this.stats.maxLatency = Math.max(
              this.stats.maxLatency,
              latency
            );
            this.stats.firestoreReadCount++;
            updateCount++;
          },
          (error) => {
            console.error(
              `[User ${userId}] Inventory listener error:`,
              error
            );
            this.stats.failedRequests++;
          }
        );

      // Listener 2: Pricing Updates (watch cart pricing)
      const pricingListener = db
        .collection('pricing_rules_updates')
        .where('affectedProducts', 'array-contains', userId)
        .onSnapshot(
          (snapshot) => {
            snapshot.docChanges().forEach((change) => {
              if (change.type === 'added' || change.type === 'modified') {
                this.stats.firestoreReadCount++;
                updateCount++;
              }
            });
          },
          (error) => {
            console.error(
              `[User ${userId}] Pricing listener error:`,
              error
            );
            this.stats.failedRequests++;
          }
        );

      // Listener 3: Order Status (watch order fulfillment)
      const orderListener = db
        .collection('orders')
        .doc(testOrderId)
        .onSnapshot(
          (doc) => {
            if (doc.exists) {
              this.stats.firestoreReadCount++;
              updateCount++;
            }
          },
          (error) => {
            console.error(
              `[User ${userId}] Order listener error:`,
              error
            );
            this.stats.failedRequests++;
          }
        );

      // Listener 4: Driver Location (watch delivery tracking)
      const locationListener = db
        .collection('driver_locations')
        .where('activeOrderId', '==', testOrderId)
        .limit(1)
        .onSnapshot(
          (snapshot) => {
            if (!snapshot.empty) {
              this.stats.firestoreReadCount++;
              updateCount++;
            }
          },
          (error) => {
            console.error(
              `[User ${userId}] Location listener error:`,
              error
            );
            this.stats.failedRequests++;
          }
        );

      // Listener 5: Notifications (watch unread notifications)
      const notificationListener = db
        .collection('notifications')
        .where('userId', '==', userId)
        .where('status', '==', 'unread')
        .onSnapshot(
          (snapshot) => {
            this.stats.firestoreReadCount++;
            updateCount++;
          },
          (error) => {
            console.error(
              `[User ${userId}] Notification listener error:`,
              error
            );
            this.stats.failedRequests++;
          }
        );

      this.activeListeners.push({
        userId,
        listeners: [
          inventoryListener,
          pricingListener,
          orderListener,
          locationListener,
          notificationListener,
        ],
      });

      // Log updates periodically
      const updateInterval = setInterval(() => {
        console.log(
          `[User ${userId}] Updates received: ${updateCount}`
        );
      }, 10000);

      // Simulate periodic write operations (user actions)
      const writeInterval = setInterval(async () => {
        try {
          // Simulate user adding item to cart
          await db
            .collection('load_test_cart')
            .doc(userId)
            .update({
              lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
              itemCount: admin.firestore.FieldValue.increment(1),
            });
          this.stats.firestoreWriteCount++;
        } catch (error) {
          console.error(
            `[User ${userId}] Write operation failed:`,
            error
          );
        }
      }, CONFIG.UPDATE_INTERVAL_MS);

      // Clean up after test duration
      const testEndTime =
        Date.now() + CONFIG.TEST_DURATION_MINUTES * 60 * 1000;
      const cleanupTimeout = setTimeout(() => {
        clearInterval(updateInterval);
        clearInterval(writeInterval);

        // Unsubscribe all listeners
        this.activeListeners.forEach((listener) => {
          if (listener.userId === userId) {
            listener.listeners.forEach((l) => l());
          }
        });

        console.log(
          `[User ${userId}] Test completed - ${updateCount} updates`
        );
        resolve();
      }, CONFIG.TEST_DURATION_MINUTES * 60 * 1000);
    });
  }

  /**
   * Create test data in Firestore
   */
  async createTestData() {
    const db = admin.firestore();
    console.log('Creating test data...');

    const batch = db.batch();

    // Create test orders
    for (let i = 0; i < CONFIG.CONCURRENT_USERS; i++) {
      const orderRef = db.collection('orders').doc(
        `${CONFIG.TEST_DATA_PREFIX}${i}`
      );
      batch.set(orderRef, {
        userId: `user_${i}`,
        status: 'processing',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        deliveryAddress: {
          latitude: 6.9271,
          longitude: 3.1449,
        },
      });
    }

    // Create inventory sync documents
    for (let i = 0; i < CONFIG.CONCURRENT_USERS; i++) {
      const invRef = db
        .collection('franchise_inventory_sync')
        .doc(`user_${i}`);
      batch.set(invRef, {
        franchiseId: `franchise_${i}`,
        itemsLowOnStock: ['SKU001', 'SKU002'],
        itemsOutOfStock: [],
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Create pricing rules
    for (let i = 0; i < 10; i++) {
      const pricingRef = db.collection('pricing_rules_updates').doc(
        `rule_${i}`
      );
      batch.set(pricingRef, {
        eventType: 'price_changed',
        affectedProducts: [`user_${i % CONFIG.CONCURRENT_USERS}`],
        oldPrice: 5000,
        newPrice: 4000,
        promotionActive: true,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log('✓ Test data created\n');
  }

  /**
   * Run the load test
   */
  async run() {
    try {
      this.stats.startTime = Date.now();

      // Create test data
      await this.createTestData();

      // Simulate concurrent users
      const userPromises = [];
      for (let i = 0; i < CONFIG.CONCURRENT_USERS; i++) {
        userPromises.push(this.simulateUser(i));
      }

      console.log(
        `\n✓ Started ${CONFIG.CONCURRENT_USERS} concurrent users`
      );
      console.log(`Test running for ${CONFIG.TEST_DURATION_MINUTES} minutes...`);
      console.log('(Monitor Firestore quota in Cloud Console)\n');

      // Wait for all users to complete
      await Promise.all(userPromises);

      this.stats.endTime = Date.now();
      this.printReport();
    } catch (error) {
      console.error('Load test failed:', error);
    } finally {
      process.exit(0);
    }
  }

  /**
   * Print test report
   */
  printReport() {
    const duration = (this.stats.endTime - this.stats.startTime) / 1000;
    const requestsPerSecond = (
      this.stats.totalRequests / duration
    ).toFixed(2);
    const avgLatency = (
      this.stats.totalLatency / this.stats.totalRequests || 0
    ).toFixed(2);

    console.log('\n' + '='.repeat(60));
    console.log('LOAD TEST REPORT');
    console.log('='.repeat(60));

    console.log('\n📊 PERFORMANCE METRICS:');
    console.log(
      `  Total Duration:              ${duration.toFixed(1)} seconds`
    );
    console.log(
      `  Total Requests:              ${this.stats.totalRequests}`
    );
    console.log(
      `  Successful Requests:         ${this.stats.successfulRequests}`
    );
    console.log(`  Failed Requests:             ${this.stats.failedRequests}`);
    console.log(`  Requests per Second:         ${requestsPerSecond}`);

    console.log('\n⏱️  LATENCY METRICS:');
    console.log(`  Average Latency:            ${avgLatency} ms`);
    console.log(`  Min Latency:                ${this.stats.minLatency} ms`);
    console.log(`  Max Latency:                ${this.stats.maxLatency} ms`);

    console.log('\n💾 FIRESTORE USAGE:');
    console.log(
      `  Estimated Read Operations:  ${this.stats.firestoreReadCount}`
    );
    console.log(
      `  Estimated Write Operations: ${this.stats.firestoreWriteCount}`
    );
    const totalOps = this.stats.firestoreReadCount +
      this.stats.firestoreWriteCount;
    const estimatedCost = (totalOps * 0.06) / 1000000; // $0.06 per million ops
    console.log(
      `  Estimated Cost:             $${estimatedCost.toFixed(4)}`
    );

    console.log('\n🎯 CONCURRENT USERS:');
    console.log(`  Active Users:               ${CONFIG.CONCURRENT_USERS}`);
    console.log(`  Test Duration:              ${CONFIG.TEST_DURATION_MINUTES} min`);
    console.log(
      `  Update Interval:            ${CONFIG.UPDATE_INTERVAL_MS} ms`
    );

    console.log('\n✅ RECOMMENDATIONS:');
    if (avgLatency < 100) {
      console.log('  ✓ Latency is excellent for real-time sync');
    } else if (avgLatency < 500) {
      console.log('  ⚠ Latency is acceptable but could be optimized');
    } else {
      console.log('  ✗ Latency is high - consider query optimization');
    }

    if (this.stats.failedRequests === 0) {
      console.log('  ✓ No failed requests - system is stable');
    } else {
      const failureRate = (
        (this.stats.failedRequests / this.stats.totalRequests) *
        100
      ).toFixed(2);
      console.log(
        `  ✗ Failure rate: ${failureRate}% - investigate error handling`
      );
    }

    console.log('\n' + '='.repeat(60));
  }

  /**
   * Clean up test data
   */
  async cleanup() {
    const db = admin.firestore();
    console.log('\nCleaning up test data...');

    // Delete test orders
    const ordersQuery = await db
      .collection('orders')
      .where('__name__', '>=', CONFIG.TEST_DATA_PREFIX)
      .get();

    for (const doc of ordersQuery.docs) {
      await doc.ref.delete();
    }

    console.log('✓ Test data cleaned up');
  }
}

// Main execution
async function main() {
  const runner = new LoadTestRunner();
  await runner.init();
  await runner.run();
  await runner.cleanup();
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
