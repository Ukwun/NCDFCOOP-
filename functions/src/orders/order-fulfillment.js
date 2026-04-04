/**
 * ORDER FULFILLMENT FUNCTION
 * Triggered automatically when order status changes
 * Handles next steps in fulfillment workflow
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

exports.onOrderStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const oldStatus = change.before.data().status;
    const newStatus = change.after.data().status;
    const orderId = context.params.orderId;
    const order = change.after.data();

    console.log(`📦 Order status changed: ${orderId}`);
    console.log(`   ${oldStatus} → ${newStatus}`);

    // Check status progression
    if (newStatus === 'confirmed' && oldStatus === 'pending') {
      return handleOrderConfirmed(orderId, order);
    } else if (newStatus === 'processing') {
      return handleOrderProcessing(orderId, order);
    } else if (newStatus === 'shipped') {
      return handleOrderShipped(orderId, order);
    } else if (newStatus === 'delivered') {
      return handleOrderDelivered(orderId, order);
    }

    return null;
  });

async function handleOrderConfirmed(orderId, order) {
  try {
    console.log(`✅ Handling order confirmed: ${orderId}`);

    // 1. Get product details for seller notification
    const productIds = order.items.map((item) => item.productId);

    // 2. Notify sellers about new orders
    const sellerIds = new Set();
    for (const item of order.items) {
      const productDoc = await db.collection('products').doc(item.productId).get();
      if (productDoc.exists) {
        sellerIds.add(productDoc.data().sellerId);
      }
    }

    for (const sellerId of sellerIds) {
      const notification = {
        userId: sellerId,
        type: 'new_order',
        title: 'New Order!',
        message: `You have a new order #${orderId}`,
        orderId: orderId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await db.collection('notifications').add(notification);

      // Send FCM if seller has tokens
      const sellerDoc = await db.collection('users').doc(sellerId).get();
      const seller = sellerDoc.data();

      if (seller.fcmTokens && seller.fcmTokens.length > 0) {
        const fcmMessage = {
          notification: {
            title: 'New Order Received! 🎉',
            body: `Order #${orderId} - ₦${order.totalAmount}`,
          },
          data: {
            orderId: orderId,
            type: 'new_order',
          },
        };

        for (const token of seller.fcmTokens) {
          try {
            await admin.messaging().sendToDevice(token, fcmMessage);
          } catch (err) {
            console.warn(`⚠️ FCM failed: ${err.message}`);
          }
        }
      }
    }

    // 3. Track user activity (purchase)
    await db.collection('user_interactions').add({
      userId: order.customerId,
      type: 'purchase',
      orderId: orderId,
      amount: order.totalAmount,
      itemCount: order.items.length,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isPositive: true,
    });

    console.log('✅ Order confirmation handled');
    return null;
  } catch (error) {
    console.error('❌ Error handling order confirmed:', error);
    return null;
  }
}

async function handleOrderProcessing(orderId, order) {
  try {
    console.log(`⚙️ Handling order processing: ${orderId}`);

    // Send notification to customer
    await db.collection('notifications').add({
      userId: order.customerId,
      type: 'order_processing',
      title: 'Processing Your Order',
      message: `Order #${orderId} is being prepared for shipment`,
      orderId: orderId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const userDoc = await db.collection('users').doc(order.customerId).get();
    const user = userDoc.data();

    if (user.fcmTokens && user.fcmTokens.length > 0) {
      const message = {
        notification: {
          title: 'Processing Your Order ⚙️',
          body: `Order #${orderId} is being prepared`,
        },
        data: {
          orderId: orderId,
          type: 'order_processing',
        },
      };

      for (const token of user.fcmTokens) {
        try {
          await admin.messaging().sendToDevice(token, message);
        } catch (err) {
          console.warn(`⚠️ FCM failed: ${err.message}`);
        }
      }
    }

    return null;
  } catch (error) {
    console.error('❌ Error handling order processing:', error);
    return null;
  }
}

async function handleOrderShipped(orderId, order) {
  try {
    console.log(`📤 Handling order shipped: ${orderId}`);

    // Send shipping notification
    await db.collection('notifications').add({
      userId: order.customerId,
      type: 'order_shipped',
      title: 'Your Order is On the Way!',
      message: `Order #${orderId} has been shipped. Tracking: ${order.trackingNumber || 'N/A'}`,
      orderId: orderId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const userDoc = await db.collection('users').doc(order.customerId).get();
    const user = userDoc.data();

    if (user.fcmTokens && user.fcmTokens.length > 0) {
      const message = {
        notification: {
          title: 'Your Order Shipped! 📦',
          body: `Track your order with: ${order.trackingNumber || 'ID'}`,
        },
        data: {
          orderId: orderId,
          type: 'order_shipped',
          trackingNumber: order.trackingNumber,
        },
      };

      for (const token of user.fcmTokens) {
        try {
          await admin.messaging().sendToDevice(token, message);
        } catch (err) {
          console.warn(`⚠️ FCM failed: ${err.message}`);
        }
      }
    }

    return null;
  } catch (error) {
    console.error('❌ Error handling order shipped:', error);
    return null;
  }
}

async function handleOrderDelivered(orderId, order) {
  try {
    console.log(`✅ Handling order delivered: ${orderId}`);

    // Send delivery confirmation
    await db.collection('notifications').add({
      userId: order.customerId,
      type: 'order_delivered',
      title: 'Order Delivered!',
      message: `Order #${orderId} has been delivered. Please review your purchase.`,
      orderId: orderId,
      actionUrl: `/orders/${orderId}`,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const userDoc = await db.collection('users').doc(order.customerId).get();
    const user = userDoc.data();

    if (user.fcmTokens && user.fcmTokens.length > 0) {
      const message = {
        notification: {
          title: 'Order Delivered! ✅',
          body: `Order #${orderId} delivered. Rate your purchase!`,
        },
        data: {
          orderId: orderId,
          type: 'order_delivered',
        },
      };

      for (const token of user.fcmTokens) {
        try {
          await admin.messaging().sendToDevice(token, message);
        } catch (err) {
          console.warn(`⚠️ FCM failed: ${err.message}`);
        }
      }
    }

    // Track activity
    await db.collection('user_interactions').add({
      userId: order.customerId,
      type: 'order_received',
      orderId: orderId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isPositive: true,
    });

    return null;
  } catch (error) {
    console.error('❌ Error handling order delivered:', error);
    return null;
  }
}

module.exports = {
  onOrderStatusChange,
};
