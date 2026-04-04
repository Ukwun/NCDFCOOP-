/**
 * FIREBASE CLOUD FUNCTIONS INDEX
 * Exports all backend functions
 * Using Flutterwave for card payments and bank transfers
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

// Export all functions
const flutterwaveWebhook = require('./src/payments/flutterwave-webhook');
const verifyBankTransfer = require('./src/payments/verify-bank-transfer');
const orderFulfillment = require('./src/orders/order-fulfillment');

module.exports = {
  // Webhook from Flutterwave
  onFlutterwaveWebhook: flutterwaveWebhook.onFlutterwaveWebhook,

  // Manual bank transfer verification (callable from client)
  verifyBankTransfer: verifyBankTransfer.verifyBankTransfer,

  // Order status changes
  onOrderStatusChange: orderFulfillment.onOrderStatusChange,
};
