"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const axios_1 = __importDefault(require("axios"));
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
// Express app for payment endpoints
const app = (0, express_1.default)();
app.use((0, cors_1.default)({ origin: true }));
app.use(express_1.default.json());
// ============= ENVIRONMENT VARIABLES =============
// Use these from your system environment or Firebase Config
const FLUTTERWAVE_SECRET_KEY = process.env.FLUTTERWAVE_SECRET_KEY || '';
const FLUTTERWAVE_PUBLIC_KEY = process.env.FLUTTERWAVE_PUBLIC_KEY || '';
// ============= FLUTTERWAVE ENDPOINTS =============
/**
 * Initialize payment with Flutterwave
 * POST /initiatePayment
 *
 * Supports: Card, Bank Transfer, Mobile Money
 */
app.post('/initiatePayment', async (req, res) => {
    try {
        const { amount, currency = 'NGN', email, customerName, customerPhone, customerId, orderId, description, paymentMethod = 'card' } = req.body;
        // Validation
        if (!amount || amount <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Valid amount is required',
            });
        }
        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'Email is required',
            });
        }
        // Generate unique transaction reference
        const txRef = `FLW_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        // Prepare Flutterwave payload
        const flutterwavePayload = {
            tx_ref: txRef,
            amount,
            currency,
            redirect_url: 'https://coop-commerce-8d43f.web.app/payment-callback',
            customer: {
                email,
                name: customerName || 'Customer',
                phonenumber: customerPhone || '',
            },
            customizations: {
                title: 'COOP Commerce Payment',
                description: description || 'Order Payment',
                logo: 'https://coop-commerce-8d43f.web.app/logo.png',
            },
            meta: {
                customerId: customerId || '',
                orderId: orderId || '',
                paymentMethod: paymentMethod,
            },
        };
        // Call Flutterwave API
        const flutterwaveResponse = await axios_1.default.post('https://api.flutterwave.com/v3/payments', flutterwavePayload, {
            headers: {
                Authorization: `Bearer ${FLUTTERWAVE_SECRET_KEY}`,
                'Content-Type': 'application/json',
            },
        });
        const { data } = flutterwaveResponse.data;
        // Save to Firestore
        await db.collection('payments').add({
            provider: 'flutterwave',
            txRef: data.id,
            txReference: txRef,
            amount,
            currency,
            email,
            customerName: customerName || '',
            customerPhone: customerPhone || '',
            customerId: customerId || '',
            orderId: orderId || '',
            paymentMethod,
            status: 'pending',
            authLink: data.link,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        res.json({
            success: true,
            txRef: data.id,
            authorizationUrl: data.link,
            message: 'Payment initialized successfully',
        });
    }
    catch (error) {
        console.error('Payment initialization error:', error.response?.data || error.message);
        res.status(500).json({
            success: false,
            message: error.response?.data?.message || error.message || 'Failed to initialize payment',
        });
    }
});
/**
 * Verify payment with Flutterwave
 * POST /verifyPayment
 */
app.post('/verifyPayment', async (req, res) => {
    try {
        const { txRef } = req.body;
        if (!txRef) {
            return res.status(400).json({
                success: false,
                message: 'Transaction reference is required',
            });
        }
        // Verify with Flutterwave
        const verifyResponse = await axios_1.default.get(`https://api.flutterwave.com/v3/transactions/${txRef}/verify`, {
            headers: {
                Authorization: `Bearer ${FLUTTERWAVE_SECRET_KEY}`,
            },
        });
        const transactionData = verifyResponse.data.data;
        const status = transactionData.status === 'successful' ? 'completed' : 'failed';
        // Update payment record in Firestore
        const paymentQuery = await db
            .collection('payments')
            .where('txRef', '==', txRef)
            .limit(1)
            .get();
        if (!paymentQuery.empty) {
            const paymentDoc = paymentQuery.docs[0];
            await paymentDoc.ref.update({
                status,
                verified: true,
                verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
                flutterwaveData: transactionData,
            });
            // If successful, create transaction record
            if (status === 'completed') {
                await db.collection('transactions').add({
                    paymentId: paymentDoc.id,
                    txRef,
                    amount: transactionData.amount,
                    email: transactionData.customer?.email,
                    status: 'completed',
                    provider: 'flutterwave',
                    paymentMethod: paymentDoc.data().paymentMethod,
                    metadata: {
                        customerId: paymentDoc.data().customerId,
                        orderId: paymentDoc.data().orderId,
                    },
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
        res.json({
            success: status === 'completed',
            txRef,
            status,
            amount: transactionData.amount,
            message: `Payment ${status}`,
            data: transactionData,
        });
    }
    catch (error) {
        console.error('Payment verification error:', {
            txRef: req.body.txRef,
            error: error.response?.data || error.message,
        });
        res.status(500).json({
            success: false,
            message: error.response?.data?.message || error.message || 'Failed to verify payment',
        });
    }
});
/**
 * Process refund
 * POST /processRefund
 */
app.post('/processRefund', async (req, res) => {
    try {
        const { txRef, amount } = req.body;
        if (!txRef || !amount) {
            return res.status(400).json({
                success: false,
                message: 'Transaction reference and amount are required',
            });
        }
        // Find payment in Firestore
        const paymentQuery = await db
            .collection('payments')
            .where('txRef', '==', txRef)
            .limit(1)
            .get();
        if (paymentQuery.empty) {
            return res.status(404).json({
                success: false,
                message: 'Payment not found',
            });
        }
        const paymentDoc = paymentQuery.docs[0];
        // Call Flutterwave refund API
        const refundResponse = await axios_1.default.post(`https://api.flutterwave.com/v3/transactions/${txRef}/refund`, { amount }, {
            headers: {
                Authorization: `Bearer ${FLUTTERWAVE_SECRET_KEY}`,
            },
        });
        // Update payment status
        await paymentDoc.ref.update({
            status: 'refunded',
            refundAmount: amount,
            refundedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        res.json({
            success: true,
            message: 'Refund processed successfully',
            txRef,
            refundAmount: amount,
        });
    }
    catch (error) {
        console.error('Refund error:', error.response?.data || error.message);
        res.status(500).json({
            success: false,
            message: error.response?.data?.message || error.message || 'Failed to process refund',
        });
    }
});
// ============= WEBHOOK HANDLERS =============
/**
 * Flutterwave webhook
 * POST /webhooks/flutterwave
 */
app.post('/webhooks/flutterwave', async (req, res) => {
    try {
        const { event, data } = req.body;
        console.log(`Flutterwave webhook received: ${event}`);
        if (event === 'charge.completed') {
            const { id, tx_ref, amount, customer, status } = data;
            // Update payment status
            const paymentQuery = await db
                .collection('payments')
                .where('txRef', '==', id)
                .limit(1)
                .get();
            if (!paymentQuery.empty) {
                const paymentDoc = paymentQuery.docs[0];
                const paymentData = paymentDoc.data();
                const paymentStatus = status === 'successful' ? 'completed' : 'failed';
                await paymentDoc.ref.update({
                    status: paymentStatus,
                    completedAt: admin.firestore.FieldValue.serverTimestamp(),
                    webhookProcessed: true,
                });
                // If successful, record transaction
                if (paymentStatus === 'completed') {
                    await db.collection('transactions').add({
                        paymentId: paymentDoc.id,
                        txRef: id,
                        txReference: tx_ref,
                        amount,
                        email: customer?.email,
                        phone: customer?.phone_number,
                        status: 'completed',
                        provider: 'flutterwave',
                        source: 'webhook',
                        paymentMethod: paymentData.paymentMethod,
                        metadata: {
                            customerId: paymentData.customerId,
                            orderId: paymentData.orderId,
                        },
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    // If there's an order, update its payment status
                    if (paymentData.orderId) {
                        await db.collection('orders').doc(paymentData.orderId).update({
                            paymentStatus: 'paid',
                            paidAt: admin.firestore.FieldValue.serverTimestamp(),
                        }).catch(() => {
                            // Order might not exist, that's Ok
                        });
                    }
                }
            }
        }
        res.json({ success: true });
    }
    catch (error) {
        console.error('Flutterwave webhook error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});
// ============= UTILITY ENDPOINTS =============
/**
 * Get available payment methods
 * GET /availablePaymentMethods
 */
app.get('/availablePaymentMethods', async (req, res) => {
    res.json({
        success: true,
        methods: [
            {
                id: 'card',
                type: 'card',
                name: 'Credit/Debit Card',
                icon: '💳',
                description: 'Visa, Mastercard, American Express',
            },
            {
                id: 'bank_transfer',
                type: 'bank_transfer',
                name: 'Bank Account Transfer',
                icon: '🏦',
                description: 'Direct bank transfer',
            },
            {
                id: 'mobile_money',
                type: 'mobile_money',
                name: 'Mobile Money',
                icon: '📱',
                description: 'MTN, Airtel, GLO, 9mobile',
            },
        ],
    });
});
/**
 * Get transaction history
 * GET /transactionHistory?page=1&limit=10
 */
app.get('/transactionHistory', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const offset = (page - 1) * limit;
        // Get auth token from request
        const authHeader = req.headers.authorization;
        const token = authHeader?.replace('Bearer ', '');
        // Optional: Verify token and filter by user
        let query = db.collection('payments');
        // Add user-specific filtering if authenticated
        if (token) {
            try {
                const decodedToken = await admin.auth().verifyIdToken(token);
                query = query.where('customerId', '==', decodedToken.uid);
            }
            catch (e) {
                console.log('Token verification skipped');
            }
        }
        const snapshot = await query
            .orderBy('createdAt', 'desc')
            .offset(offset)
            .limit(limit)
            .get();
        const payments = snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        }));
        res.json({
            success: true,
            payments,
            page,
            limit,
            total: snapshot.size,
        });
    }
    catch (error) {
        console.error('History error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch history',
        });
    }
});
/**
 * Health check
 * GET /health
 */
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        provider: 'flutterwave',
        configured: FLUTTERWAVE_SECRET_KEY ? true : false,
    });
});
// ============= EXPORT AS CLOUD FUNCTION =============
/**
 * Export all endpoints
 */
exports.payments = functions
    .region('us-central1')
    .https.onRequest(app);
/**
 * Scheduled function to clean up old pending payments (24 hours old)
 */
exports.cleanupOldPayments = functions
    .region('us-central1')
    .pubsub
    .schedule('every 24 hours')
    .onRun(async () => {
    try {
        const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const snapshot = await db
            .collection('payments')
            .where('status', '==', 'pending')
            .where('createdAt', '<', dayAgo)
            .get();
        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
            batch.update(doc.ref, { status: 'expired' });
        });
        await batch.commit();
        console.log(`Cleaned up ${snapshot.size} expired payments`);
        return null;
    }
    catch (error) {
        console.error('Cleanup error:', error);
        return null;
    }
});
//# sourceMappingURL=index.js.map