/**
 * FLUTTERWAVE WEBHOOK HANDLER
 * Receives payment confirmation from Flutterwave
 * Handles both card payments and bank transfers
 * Manages manual verification for bank transfers
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

const db = admin.firestore();

exports.onFlutterwaveWebhook = functions.https.onRequest(
  async (req, res) => {
    console.log('🔔 Flutterwave webhook received');

    // Verify webhook signature
    const signature = req.headers['verif-hash'];
    const hash = crypto
      .createHmac('sha256', process.env.FLUTTERWAVE_SECRET_KEY)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (hash !== signature) {
      console.error('❌ Invalid webhook signature');
      return res.status(401).send('Unauthorized');
    }

    const { event, data } = req.body;

    // Only process successful charges
    if (event === 'charge.completed' && data.status === 'successful') {
      return handlePaymentSuccess(data, res);
    } else if (event === 'charge.completed' && data.status === 'failed') {
      return handlePaymentFailed(data, res);
    }

    return res.status(200).send('Webhook received');
  }
);

/**
 * Handle successful payment from Flutterwave
 */
async function handlePaymentSuccess(data, res) {
  try {
    const reference = data.id.toString();
    const amount = data.amount;
    const customerId = data.meta?.consumer_id || data.customer?.id;
    const orderId = data.meta?.consumer_mac || data.tx_ref;
    const paymentType = data.payment_type; // 'card', 'account', 'ussd', etc.

    console.log(`✅ Payment successful: ${reference}`);
    console.log(
      `   Order: ${orderId}, Amount: ₦${amount}, Type: ${paymentType}`
    );

    // 1. Update payment record in Firestore
    const paymentRef = db.collection('payments').doc(reference);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      console.error(`❌ Payment not found: ${reference}`);
      return res.status(404).send('Payment not found');
    }

    await paymentRef.update({
      status: 'completed',
      flutterwaveStatus: 'successful',
      paymentType: paymentType,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('📝 Payment record updated');

    // 2. Get order details
    const orderDoc = await db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      console.error(`❌ Order not found: ${orderId}`);
      return res.status(404).send('Order not found');
    }

    const order = orderDoc.data();

    // 3. Verify amount matches
    if (order.totalAmount !== amount) {
      console.error(
        `❌ Amount mismatch: Expected ₦${order.totalAmount}, Got ₦${amount}`
      );
      return res.status(400).send('Amount mismatch');
    }

    // 4. For bank transfers, mark as pending verification
    let orderStatus = 'confirmed';
    if (paymentType === 'account' || paymentType === 'bank_transfer') {
      orderStatus = 'payment_pending_verification';
      console.log('⏳ Bank transfer - payment pending manual verification');
    }

    // 5. Deduct inventory (ATOMIC TRANSACTION)
    const batch = db.batch();

    for (const item of order.items) {
      const inventoryRef = db
        .collection('inventory')
        .doc(`${item.productId}_${order.storeId}`);

      const inventoryDoc = await inventoryRef.get();
      if (!inventoryDoc.exists) {
        console.error(`❌ Inventory not found for product: ${item.productId}`);
        return res.status(404).send('Product inventory not found');
      }

      const inventory = inventoryDoc.data();
      const newStock = inventory.currentStock - item.quantity;

      if (newStock < 0) {
        console.error(
          `❌ Insufficient stock: Product ${item.productId}, Available: ${inventory.currentStock}, Requested: ${item.quantity}`
        );
        return res.status(400).send('Insufficient stock');
      }

      // Update inventory
      batch.update(inventoryRef, {
        currentStock: newStock,
        status:
          newStock === 0
            ? 'out_of_stock'
            : newStock <= inventory.reorderPoint
            ? 'low_stock'
            : 'in_stock',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log transaction
      batch.set(db.collection('stock_transactions').doc(), {
        inventoryId: inventoryRef.id,
        productId: item.productId,
        type: 'outbound',
        quantity: item.quantity,
        reason: 'order_fulfillment',
        referenceType: 'order',
        referenceId: orderId,
        createdBy: 'system',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Update order status
    batch.update(db.collection('orders').doc(orderId), {
      status: orderStatus,
      paymentStatus: paymentType === 'account' ? 'bank_transfer_received' : 'completed',
      paymentReference: reference,
      paymentType: paymentType,
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Execute all updates atomically
    await batch.commit();

    console.log('✅ Inventory deducted, order updated');

    // 6. Send notifications
    await sendNotifications(orderId, customerId, order, orderStatus);

    // 7. Log transaction
    await db.collection('transactions').add({
      paymentId: reference,
      orderId: orderId,
      customerId: customerId,
      type: 'payment_completed',
      amount: amount,
      paymentType: paymentType,
      status: 'success',
      details: {
        reference: reference,
        paymentType: paymentType,
        channel: data.payment_type,
        customer: data.customer,
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Payment processing complete');

    return res.status(200).send('Payment processed successfully');
  } catch (error) {
    console.error('❌ Error handling payment success:', error);
    return res.status(500).send('Internal server error');
  }
}

/**
 * Handle failed payment from Flutterwave
 */
async function handlePaymentFailed(data, res) {
  try {
    const reference = data.id.toString();
    const orderId = data.meta?.consumer_mac || data.tx_ref;
    const customerId = data.meta?.consumer_id || data.customer?.id;

    console.log(`❌ Payment failed: ${reference}`);
    console.log(`   Order: ${orderId}`);

    // Update payment record
    await db.collection('payments').doc(reference).update({
      status: 'failed',
      flutterwaveStatus: 'failed',
      failureReason: data.processor_response,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update order status
    await db.collection('orders').doc(orderId).update({
      paymentStatus: 'failed',
      status: 'payment_failed',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification to user
    await sendPaymentFailedNotification(orderId, customerId);

    // Log transaction
    await db.collection('transactions').add({
      paymentId: reference,
      orderId: orderId,
      customerId: customerId,
      type: 'payment_failed',
      status: 'failed',
      failureReason: data.processor_response,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).send('Payment failure recorded');
  } catch (error) {
    console.error('❌ Error handling payment failure:', error);
    return res.status(500).send('Internal server error');
  }
}

/**
 * Send notifications after payment
 */
async function sendNotifications(orderId, customerId, order, orderStatus) {
  try {
    const userDoc = await db.collection('users').doc(customerId).get();
    const user = userDoc.data();

    let notificationTitle = 'Order Confirmed!';
    let notificationMessage = `Your order #${orderId} has been confirmed.`;

    if (orderStatus === 'payment_pending_verification') {
      notificationTitle = 'Bank Transfer Received ✅';
      notificationMessage = `Payment for order #${orderId} received. Verifying...`;
    }

    // Create in-app notification
    const notification = {
      userId: customerId,
      type: 'order_confirmed',
      title: notificationTitle,
      message: notificationMessage,
      orderId: orderId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('notifications').add(notification);

    // Send FCM notification if user has device tokens
    if (user.fcmTokens && user.fcmTokens.length > 0) {
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationMessage,
        },
        data: {
          orderId: orderId,
          type: 'order_confirmed',
        },
      };

      for (const token of user.fcmTokens) {
        try {
          await admin.messaging().sendToDevice(token, message);
        } catch (err) {
          console.warn(`⚠️ FCM send failed for token: ${err.message}`);
        }
      }
    }

    // Notify seller immediately
    await notifySeller(order, customerId);

    console.log('✅ Notifications sent');
  } catch (error) {
    console.error('❌ Error sending notifications:', error);
  }
}

/**
 * Send notification to seller
 */
async function notifySeller(order, customerId) {
  try {
    const sellerIds = new Set();
    for (const item of order.items) {
      const productDoc = await db.collection('products').doc(item.productId).get();
      if (productDoc.exists) {
        sellerIds.add(productDoc.data().sellerId);
      }
    }

    for (const sellerId of sellerIds) {
      await db.collection('notifications').add({
        userId: sellerId,
        type: 'new_order',
        title: 'New Order Received!',
        message: `Order #${order.id} - ₦${order.totalAmount}`,
        orderId: order.id,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const sellerDoc = await db.collection('users').doc(sellerId).get();
      const seller = sellerDoc.data();

      if (seller?.fcmTokens && seller.fcmTokens.length > 0) {
        const message = {
          notification: {
            title: 'New Order!',
            body: `Order #${order.id} - ₦${order.totalAmount}`,
          },
          data: {
            orderId: order.id,
            type: 'new_order',
          },
        };

        for (const token of seller.fcmTokens) {
          try {
            await admin.messaging().sendToDevice(token, message);
          } catch (err) {
            console.warn(`⚠️ FCM failed: ${err.message}`);
          }
        }
      }
    }
  } catch (error) {
    console.error('❌ Error notifying seller:', error);
  }
}

/**
 * Send payment failed notification
 */
async function sendPaymentFailedNotification(orderId, customerId) {
  try {
    const userDoc = await db.collection('users').doc(customerId).get();
    const user = userDoc.data();

    const notification = {
      userId: customerId,
      type: 'payment_failed',
      title: 'Payment Failed',
      message: `Payment for order #${orderId} failed. Please try again.`,
      orderId: orderId,
      severity: 'warning',
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('notifications').add(notification);

    if (user?.fcmTokens && user.fcmTokens.length > 0) {
      const message = {
        notification: {
          title: 'Payment Failed ❌',
          body: `Payment for order #${orderId} failed. Tap to retry.`,
        },
        data: {
          orderId: orderId,
          type: 'payment_failed',
        },
      };

      for (const token of user.fcmTokens) {
        try {
          await admin.messaging().sendToDevice(token, message);
        } catch (err) {
          console.warn(`⚠️ FCM send failed: ${err.message}`);
        }
      }
    }

    console.log('✅ Payment failed notification sent');
  } catch (error) {
    console.error('❌ Error sending payment failed notification:', error);
  }
}

module.exports = {
  onFlutterwaveWebhook,
};
