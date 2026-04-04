/**
 * MANUAL VERIFICATION FUNCTION
 * Backend admin function to verify received bank transfers
 * Called when seller/admin confirms payment has been received
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * Verify a bank transfer payment manually
 * This is called by seller or admin when they confirm bank transfer was received
 */
exports.verifyBankTransfer = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { orderId, paymentReference, verificationNotes } = data;
  const verifierId = context.auth.uid;

  console.log(`🔍 Verifying bank transfer for order: ${orderId}`);

  try {
    // 1. Get order
    const orderDoc = await db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Order not found');
    }

    const order = orderDoc.data();

    // 2. Get payment record
    const paymentDoc = await db
      .collection('payments')
      .doc(paymentReference)
      .get();
    if (!paymentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Payment not found');
    }

    const payment = paymentDoc.data();

    // 3. Check payment is bank transfer and pending verification
    if (payment.paymentType !== 'account' && payment.paymentType !== 'bank_transfer') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This is not a bank transfer payment'
      );
    }

    if (payment.status !== 'completed') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Payment is not in completed state'
      );
    }

    // 4. Update payment record - mark as verified
    await db.collection('payments').doc(paymentReference).update({
      verificationStatus: 'verified',
      verifiedBy: verifierId,
      verificationNotes: verificationNotes,
      verificationTime: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Payment verified');

    // 5. Update order status to confirmed
    await db.collection('orders').doc(orderId).update({
      status: 'confirmed',
      paymentStatus: 'verified',
      verificationTime: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Order marked as confirmed');

    // 6. Send notifications
    await sendVerificationNotifications(orderId, order);

    // 7. Log verification
    await db.collection('transactions').add({
      paymentId: paymentReference,
      orderId: orderId,
      type: 'bank_transfer_verified',
      verifiedBy: verifierId,
      verificationNotes: verificationNotes,
      status: 'verified',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      orderId: orderId,
      paymentReference: paymentReference,
      message: 'Payment verified successfully',
    };
  } catch (error) {
    console.error('❌ Verification error:', error);
    throw error;
  }
});

/**
 * Send notifications after bank transfer verification
 */
async function sendVerificationNotifications(orderId, order) {
  try {
    const customerId = order.customerId;
    const userDoc = await db.collection('users').doc(customerId).get();
    const user = userDoc.data();

    // Notify customer
    const notification = {
      userId: customerId,
      type: 'payment_verified',
      title: 'Payment Verified ✅',
      message: `Your payment for order #${orderId} has been verified. Order confirmed!`,
      orderId: orderId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('notifications').add(notification);

    if (user?.fcmTokens && user.fcmTokens.length > 0) {
      const message = {
        notification: {
          title: 'Payment Verified! ✅',
          body: `Order #${orderId} confirmed and processing...`,
        },
        data: {
          orderId: orderId,
          type: 'payment_verified',
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

    // Notify sellers
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
        type: 'order_confirmed',
        title: 'Order Confirmed ✅',
        message: `Order #${orderId} payment verified. Ready to ship!`,
        orderId: orderId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    console.log('✅ Verification notifications sent');
  } catch (error) {
    console.error('❌ Error sending verification notifications:', error);
  }
}

module.exports = {
  verifyBankTransfer,
};
