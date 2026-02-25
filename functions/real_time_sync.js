/**
 * Firebase Cloud Functions for Real-Time Sync
 * Populates real-time collections when warehouse/fulfillment data changes
 * 
 * Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ============================================================================
// 1. INVENTORY SYNC - Warehouse updates → Franchise dashboard
// ============================================================================

/**
 * Trigger: When warehouse inventory changes
 * Updates: franchise_inventory_sync collection
 * Sends: Item list that's low/out of stock
 */
exports.syncFranchiseInventory = functions.firestore
  .document('warehouse_inventory/{franchiseId}')
  .onWrite(async (change, context) => {
    const franchiseId = context.params.franchiseId;
    const newData = change.after.data();

    if (!newData) return;

    const itemsLowOnStock = [];
    const itemsOutOfStock = [];
    const reorderSuggestions = [];

    // Process inventory items
    if (newData.items && Array.isArray(newData.items)) {
      newData.items.forEach(item => {
        if (item.quantity === 0) {
          itemsOutOfStock.push(item.sku);
        } else if (item.quantity < item.reorderLevel) {
          itemsLowOnStock.push(item.sku);
          reorderSuggestions.push({
            sku: item.sku,
            name: item.name,
            currentQuantity: item.quantity,
            recommendedOrder: item.reorderQuantity,
          });
        }
      });
    }

    // Update franchise_inventory_sync collection
    await db.collection('franchise_inventory_sync').doc(franchiseId).set({
      franchiseId: franchiseId,
      itemsLowOnStock: itemsLowOnStock,
      itemsOutOfStock: itemsOutOfStock,
      reorderSuggestions: reorderSuggestions,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      itemsLowCount: itemsLowOnStock.length,
      itemsOutCount: itemsOutOfStock.length,
    }, { merge: true });

    // Update reorder count for quick access
    await db.collection('franchise_reorder_alerts').doc(franchiseId).set({
      franchiseId: franchiseId,
      criticalReorderCount: reorderSuggestions.length,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`Synced inventory for franchise: ${franchiseId}`);
  });

// ============================================================================
// 2. PRICING UPDATES - Pricing changes → Shopping cart
// ============================================================================

/**
 * Trigger: When pricing rules change
 * Updates: pricing_rules_updates collection
 * Sends: Product IDs affected, old/new prices, promotion status
 */
exports.syncPricingUpdates = functions.firestore
  .document('pricing_rules/{ruleId}')
  .onWrite(async (change, context) => {
    const ruleId = context.params.ruleId;
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData) return;

    // Determine if this is a price change or promotion
    const isPriceChange = oldData && oldData.basePrice !== newData.basePrice;
    const isPromotionChange =
      oldData && oldData.promotionActive !== newData.promotionActive;

    if (!isPriceChange && !isPromotionChange) return;

    const eventType = isPromotionChange ? 'promotion_changed' : 'price_changed';
    const affectedProducts = newData.affectedProductIds || [];

    // Create pricing update event
    const updateEvent = {
      eventType: eventType,
      ruleId: ruleId,
      affectedProducts: affectedProducts,
      oldPrice: oldData?.basePrice || null,
      newPrice: newData.basePrice || null,
      promotionActive: newData.promotionActive || false,
      description: newData.description || `Pricing update: ${eventType}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Store in pricing_rules_updates (limit to latest 1 per rule)
    await db.collection('pricing_rules_updates').doc(ruleId).set(updateEvent);

    // Also notify affected products for cart listeners
    for (const productId of affectedProducts) {
      await db
        .collection('product_price_changes')
        .doc(productId)
        .set(updateEvent, { merge: true });
    }

    console.log(`Pricing update: ${eventType} for rule ${ruleId}`);
  });

/**
 * Trigger: When contract pricing changes
 * Updates: contract_pricing_updates collection
 * Sends: Contract details, affected items, new pricing
 */
exports.syncContractPricingUpdates = functions.firestore
  .document('contracts/{contractId}')
  .onWrite(async (change, context) => {
    const contractId = context.params.contractId;
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData) return;

    // Only sync if pricing changed
    const pricingChanged =
      !oldData ||
      JSON.stringify(oldData.pricing) !==
        JSON.stringify(newData.pricing);

    if (!pricingChanged) return;

    const updateEvent = {
      contractId: contractId,
      institutionId: newData.institutionId,
      updateType: 'pricing_updated',
      affectedItems: newData.lineItems || [],
      message: `Contract ${contractId} pricing updated`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db
      .collection('contract_pricing_updates')
      .doc(contractId)
      .set(updateEvent);

    console.log(`Contract pricing updated: ${contractId}`);
  });

// ============================================================================
// 3. ORDER STATUS - Fulfillment updates → Customer tracking
// ============================================================================

/**
 * Trigger: When order status changes
 * Updates: orders/{orderId} document
 * Sends: Status history, timestamps, fulfillment progress
 */
exports.syncOrderStatus = functions.firestore
  .document('orders/{orderId}')
  .onWrite(async (change, context) => {
    const orderId = context.params.orderId;
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData) return;

    // Check if status changed
    const statusChanged = !oldData || oldData.status !== newData.status;

    if (statusChanged) {
      // Update status timeline
      const statusHistory = newData.statusHistory || [];
      statusHistory.push({
        status: newData.status,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        notes: newData.statusNotes || '',
      });

      // Update order with timeline
      await db.collection('orders').doc(orderId).update({
        statusHistory: statusHistory,
        lastStatusChange: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Order ${orderId} status changed to ${newData.status}`);
    }
  });

/**
 * Trigger: When warehouse operations update (picking, packing, QC)
 * Updates: warehouse_operations collection
 * Sends: Current stage, progress %, estimated completion time
 */
exports.syncWarehouseProgress = functions.firestore
  .document('warehouse_operations/{orderId}')
  .onWrite(async (change, context) => {
    const orderId = context.params.orderId;
    const newData = change.after.data();

    if (!newData) return;

    // Calculate progress percentage
    const stages = ['pending', 'picking', 'packing', 'qc', 'ready_ship'];
    const currentStageIndex = stages.indexOf(newData.currentStage || 'pending');
    const percentComplete = ((currentStageIndex + 1) / stages.length) * 100;

    // Estimate completion time (rough estimate: ~15 min per stage)
    const stagesRemaining = stages.length - currentStageIndex;
    const estimatedMinutes = stagesRemaining * 15;
    const estimatedCompletionTime = new Date(
      Date.now() + estimatedMinutes * 60000
    );

    // Update progress
    const progressUpdate = {
      orderId: orderId,
      stage: newData.currentStage,
      percentComplete: percentComplete,
      currentStep: newData.currentStep || `${newData.currentStage}...`,
      estimatedCompletionTime: estimatedCompletionTime,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db
      .collection('warehouse_operations')
      .doc(orderId)
      .update(progressUpdate);

    console.log(
      `Warehouse progress for ${orderId}: ${percentComplete.toFixed(1)}%`
    );
  });

// ============================================================================
// 4. DELIVERY TRACKING - GPS updates → Customer map
// ============================================================================

/**
 * Trigger: When driver location updates (from mobile app)
 * Updates: driver_locations/{driverId} document
 * Sends: Current GPS, heading, speed, accuracy
 */
exports.updateDriverLocation = functions.firestore
  .document('driver_locations/{driverId}')
  .onWrite(async (change, context) => {
    const driverId = context.params.driverId;
    const newData = change.after.data();

    if (!newData) return;

    // Validate location data
    if (!newData.latitude || !newData.longitude) return;

    // Calculate distance to delivery (if order exists)
    if (newData.activeOrderId) {
      const orderRef = db.collection('orders').doc(newData.activeOrderId);
      const order = await orderRef.get();

      if (order.exists) {
        const orderData = order.data();
        if (
          orderData.deliveryAddress &&
          orderData.deliveryAddress.latitude &&
          orderData.deliveryAddress.longitude
        ) {
          const distance = calculateDistance(
            newData.latitude,
            newData.longitude,
            orderData.deliveryAddress.latitude,
            orderData.deliveryAddress.longitude
          );

          // Update ETA estimate
          const speed = newData.speed || 40; // km/h, default 40
          const minutesToDelivery = Math.max(
            1,
            Math.round((distance / speed) * 60)
          );

          await db
            .collection('delivery_eta_updates')
            .doc(newData.activeOrderId)
            .set({
              orderId: newData.activeOrderId,
              driverId: driverId,
              driverName: newData.driverName || 'Driver',
              driverPhone: newData.driverPhone || '',
              vehicleInfo: newData.vehicleInfo || '',
              estimatedDeliveryTime: new Date(
                Date.now() + minutesToDelivery * 60000
              ),
              distanceToDelivery: distance,
              minutesToDelivery: minutesToDelivery,
              currentLocation: {
                latitude: newData.latitude,
                longitude: newData.longitude,
              },
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
      }
    }

    console.log(
      `Driver ${driverId} location updated: (${newData.latitude}, ${newData.longitude})`
    );
  });

// ============================================================================
// 5. NOTIFICATIONS - Events → Users live
// ============================================================================

/**
 * Trigger: When important events occur (order status, delivery, etc)
 * Updates: notifications collection
 * Sends: Notification title, message, priority, type
 */
exports.createNotification = functions.firestore
  .document('notification_events/{eventId}')
  .onCreate(async (snap, context) => {
    const eventData = snap.data();
    const eventType = eventData.type; // 'order_status', 'delivery', 'pricing', etc

    let notification = null;

    switch (eventType) {
      case 'order_status_changed':
        notification = {
          userId: eventData.userId,
          title: 'Order Status Update',
          message: `Your order #${eventData.orderId} is now ${eventData.status}`,
          type: 'order',
          priority: 'high',
          relatedId: eventData.orderId,
        };
        break;

      case 'delivery_incoming':
        notification = {
          userId: eventData.userId,
          title: 'Delivery Arriving Soon',
          message: `Your package is ${eventData.minutesToDelivery} minutes away`,
          type: 'delivery',
          priority: 'high',
          relatedId: eventData.orderId,
        };
        break;

      case 'price_promotion':
        notification = {
          userId: eventData.userId,
          title: 'Price Drop Alert!',
          message: `${eventData.itemName} is now ${eventData.discount}% off`,
          type: 'promotion',
          priority: 'normal',
          relatedId: eventData.productId,
        };
        break;

      case 'reorder_needed':
        notification = {
          userId: eventData.userId,
          title: 'Inventory Alert',
          message: `${eventData.itemName} is running low`,
          type: 'inventory',
          priority: 'normal',
          relatedId: eventData.itemId,
        };
        break;

      default:
        notification = {
          userId: eventData.userId,
          title: eventData.title || 'Notification',
          message: eventData.message || '',
          type: eventData.type || 'system',
          priority: eventData.priority || 'normal',
          relatedId: eventData.relatedId,
        };
    }

    if (notification) {
      notification.status = 'unread';
      notification.createdAt = admin.firestore.FieldValue.serverTimestamp();
      notification.read = false;

      // Store notification
      await db
        .collection('users')
        .doc(notification.userId)
        .collection('notifications')
        .add(notification);

      // Also update global notifications for quick access
      await db.collection('notifications').add(notification);

      console.log(`Notification created for ${notification.userId}`);
    }
  });

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Calculate distance between two coordinates using Haversine formula
 * Returns distance in kilometers
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = (toRad(lat2) - toRad(lat1)) / 2;
  const dLon = (toRad(lon2) - toRad(lon1)) / 2;
  const a =
    Math.sin(dLat) * Math.sin(dLat) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon) *
      Math.sin(dLon);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg) {
  return deg * (Math.PI / 180);
}
