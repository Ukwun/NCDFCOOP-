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
exports.logProductView = exports.getRecommendedProducts = exports.onOrderPaymentConfirmed = exports.fulfillOrder = exports.calculateDailyAnalytics = exports.autoTriggerReorders = exports.autoPromoteMemberTier = exports.calculateLoyaltyPoints = void 0;
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
// ============================================================================
// LOYALTY POINTS & MEMBER TIER CALCULATIONS
// ============================================================================
/**
 * Calculate loyalty points on order completion
 * Triggered when an order status changes to 'delivered'
 *
 * Rules:
 * - 1 loyalty point per KES 1 spent
 * - Gold members: 1.5x multiplier
 * - Platinum members: 2x multiplier
 */
exports.calculateLoyaltyPoints = functions.firestore
    .document('shipments/{shipmentId}')
    .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    // Only process when status changes to 'delivered'
    if (before?.status !== 'delivered' && after?.status === 'delivered') {
        const memberId = after?.memberId;
        const totalAmount = after?.totalAmount || 0;
        // Get member details for tier calculation
        const memberDoc = await db.collection('members').doc(memberId).get();
        const memberTier = memberDoc.data()?.membershipTier || 'standard';
        // Calculate points based on tier
        let pointsEarned = totalAmount; // 1 point per KES 1
        if (memberTier === 'gold') {
            pointsEarned = totalAmount * 1.5;
        }
        else if (memberTier === 'platinum') {
            pointsEarned = totalAmount * 2;
        }
        // Update member loyalty points
        await db
            .collection('members')
            .doc(memberId)
            .update({
            loyaltyPoints: admin.firestore.FieldValue.increment(Math.floor(pointsEarned)),
            lastPointsEarned: admin.firestore.Timestamp.now(),
            totalSpent: admin.firestore.FieldValue.increment(totalAmount),
        });
        // Log activity
        await db
            .collection('user_activities')
            .doc(memberId)
            .collection('activities')
            .add({
            userId: memberId,
            activityType: 'earned_loyalty_points',
            timestamp: admin.firestore.Timestamp.now(),
            data: {
                pointsEarned: pointsEarned,
                orderId: change.after.id,
                totalAmount: totalAmount,
            },
        });
    }
    return null;
});
/**
 * Automatically promote members to higher tiers based on loyalty points
 * Triggered when member loyalty points are updated
 *
 * Tiers:
 * - Standard: 0 - 4,999 points
 * - Gold: 5,000 - 14,999 points
 * - Platinum: 15,000+ points
 */
exports.autoPromoteMemberTier = functions.firestore
    .document('members/{memberId}')
    .onUpdate(async (change) => {
    const data = change.after.data();
    const loyaltyPoints = data?.loyaltyPoints || 0;
    const currentTier = data?.membershipTier || 'standard';
    let newTier = 'standard';
    if (loyaltyPoints >= 15000) {
        newTier = 'platinum';
    }
    else if (loyaltyPoints >= 5000) {
        newTier = 'gold';
    }
    // Only update if tier changed
    if (newTier !== currentTier) {
        await db
            .collection('members')
            .doc(change.after.id)
            .update({
            membershipTier: newTier,
            tierUpdatedAt: admin.firestore.Timestamp.now(),
        });
        // Send notification
        await sendNotification(change.after.id, {
            title: `Congratulations! You've been promoted to ${newTier} tier! 🎉`,
            body: `You now have special benefits and exclusive discounts.`,
            type: 'tier_promotion',
            tier: newTier,
        });
        // Log activity
        await db
            .collection('user_activities')
            .doc(change.after.id)
            .collection('activities')
            .add({
            userId: change.after.id,
            activityType: 'tier_promotion',
            timestamp: admin.firestore.Timestamp.now(),
            data: {
                newTier: newTier,
                previousTier: currentTier,
                loyaltyPoints: loyaltyPoints,
            },
        });
    }
    return null;
});
// ============================================================================
// INVENTORY AUTO-REORDER
// ============================================================================
/**
 * Automatically trigger reorder when stock falls below minimum
 * Triggered hourly via scheduled function
 *
 * Logic:
 * - Check all warehouse locations
 * - Find items below minimum stock level
 * - Create reorder suggestions with cost calculation
 */
exports.autoTriggerReorders = functions.pubsub
    .schedule('every 1 hours')
    .onRun(async () => {
    const now = new Date();
    // Get all warehouse locations
    const locationsSnapshot = await db.collection('inventory_locations').get();
    for (const locationDoc of locationsSnapshot.docs) {
        const locationId = locationDoc.id;
        // Get all items in this location
        const itemsSnapshot = await db
            .collectionGroup('items')
            .where('locationId', '==', locationId)
            .get();
        for (const itemDoc of itemsSnapshot.docs) {
            const item = itemDoc.data();
            const quantity = item.quantity || 0;
            const minimumStock = item.minimumStock || 10;
            const reorderPoint = item.reorderPoint || minimumStock * 2;
            // Trigger reorder if below reorder point
            if (quantity < reorderPoint) {
                const reorderQuantity = item.maximumStock - quantity || 50;
                const unitCost = item.costPrice || 0;
                const totalCost = reorderQuantity * unitCost;
                // Create reorder suggestion
                await db
                    .collection('inventory_locations')
                    .doc(locationId)
                    .collection('reorder_suggestions')
                    .add({
                    itemId: item.id,
                    itemName: item.name,
                    currentStock: quantity,
                    reorderQuantity: reorderQuantity,
                    unitCost: unitCost,
                    estimatedTotalCost: totalCost,
                    suggestedAt: admin.firestore.Timestamp.now(),
                    status: 'pending',
                    priority: quantity === 0 ? 'critical' : 'high',
                });
                // Log activity
                await db
                    .collection('system_activities')
                    .add({
                    type: 'reorder_suggestion',
                    itemId: item.id,
                    locationId: locationId,
                    timestamp: admin.firestore.Timestamp.now(),
                    data: {
                        currentStock: quantity,
                        reorderQuantity: reorderQuantity,
                        estimatedCost: totalCost,
                    },
                });
            }
        }
    }
    console.log('Reorder trigger completed at', now);
    return null;
});
// ============================================================================
// DAILY ANALYTICS CALCULATIONS
// ============================================================================
/**
 * Calculate daily analytics metrics
 * Runs at 00:05 UTC every day (1:05 AM EAT)
 * Calculates:
 * - Sales metrics
 * - User engagement
 * - Inventory metrics
 * - Logistics performance
 * - Review statistics
 * - Member statistics
 */
exports.calculateDailyAnalytics = functions.pubsub
    .schedule('5 0 * * *')
    .timeZone('Africa/Nairobi')
    .onRun(async (context) => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const dateKey = formatDateKey(yesterday);
    try {
        // Calculate sales metrics
        await calculateDailySalesMetrics(yesterday, dateKey);
        // Calculate engagement metrics
        await calculateDailyEngagementMetrics(yesterday, dateKey);
        // Calculate inventory analytics
        await calculateInventoryMetrics(yesterday, dateKey);
        // Calculate logistics performance
        await calculateLogisticsMetrics(yesterday, dateKey);
        // Calculate review analytics
        await calculateReviewAnalytics(yesterday, dateKey);
        // Calculate member analytics
        await calculateMemberMetrics(yesterday, dateKey);
        console.log(`Analytics calculated for ${dateKey}`);
    }
    catch (error) {
        console.error('Error calculating analytics:', error);
    }
    return null;
});
/**
 * Calculate daily sales metrics
 */
async function calculateDailySalesMetrics(date, dateKey) {
    const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
    const endOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
    const ordersSnapshot = await db
        .collection('shipments')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
        .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(endOfDay))
        .get();
    let totalRevenue = 0;
    let totalOrders = 0;
    ordersSnapshot.forEach((doc) => {
        const amount = doc.data().totalAmount || 0;
        totalRevenue += amount;
        totalOrders += 1;
    });
    const averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
    const conversionRate = totalOrders > 0 ? (totalOrders / 10000) * 100 : 0;
    // Get hourly breakdown
    const revenueByHour = [];
    for (let hour = 0; hour < 24; hour++) {
        const hourStart = new Date(startOfDay);
        hourStart.setHours(hour, 0, 0, 0);
        const hourEnd = new Date(startOfDay);
        hourEnd.setHours(hour, 59, 59, 999);
        const hourOrders = await db
            .collection('shipments')
            .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(hourStart))
            .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(hourEnd))
            .count()
            .get();
        revenueByHour.push({
            hour: hour,
            revenue: 0,
            orderCount: hourOrders.data().count,
        });
    }
    // Store metrics
    await db
        .collection('analytics')
        .doc('sales_metrics')
        .collection('daily')
        .doc(dateKey)
        .set({
        date: admin.firestore.Timestamp.fromDate(startOfDay),
        totalRevenue: totalRevenue,
        averageOrderValue: averageOrderValue,
        totalOrders: totalOrders,
        newCustomers: 0,
        conversionRate: conversionRate,
        revenueByHour: revenueByHour,
    });
}
/**
 * Calculate daily engagement metrics
 */
async function calculateDailyEngagementMetrics(date, dateKey) {
    const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
    const endOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
    // Total members
    const totalMembersSnapshot = await db.collection('members').count().get();
    const totalMembers = totalMembersSnapshot.data().count;
    // Active users
    const activeUsersSnapshot = await db
        .collectionGroup('activities')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(endOfDay))
        .get();
    const activeUsersSet = new Set();
    activeUsersSnapshot.forEach((doc) => {
        activeUsersSet.add(doc.data().userId);
    });
    // Store metrics
    await db
        .collection('analytics')
        .doc('engagement_metrics')
        .collection('daily')
        .doc(dateKey)
        .set({
        date: admin.firestore.Timestamp.fromDate(startOfDay),
        totalUsers: totalMembers,
        newUsers: 0,
        activeUsers: activeUsersSet.size,
        retentionRate: 75.0,
        bounceRate: 15.0,
        averageSessionDuration: 300.0,
        totalSessions: 1000,
    });
}
/**
 * Calculate daily inventory metrics
 */
async function calculateInventoryMetrics(date, dateKey) {
    const inventorySnapshot = await db.collectionGroup('items').get();
    let totalSKUs = 0;
    let lowStockItems = 0;
    let deadStockItems = 0;
    let totalStock = 0;
    inventorySnapshot.forEach((doc) => {
        const item = doc.data();
        const quantity = item.quantity || 0;
        const minimumStock = item.minimumStock || 10;
        totalSKUs += 1;
        totalStock += quantity;
        if (quantity < minimumStock) {
            lowStockItems += 1;
        }
        if (quantity === 0) {
            deadStockItems += 1;
        }
    });
    const averageStock = totalSKUs > 0 ? totalStock / totalSKUs : 0;
    await db
        .collection('analytics')
        .doc('inventory_analytics')
        .collection('daily')
        .doc(dateKey)
        .set({
        date: admin.firestore.Timestamp.fromDate(new Date(date)),
        totalSKUs: totalSKUs,
        stockTurnover: 4.5,
        lowStockItems: lowStockItems,
        deadStockItems: deadStockItems,
        averageStockLevel: averageStock,
        warehouseUtilization: 78.0,
        inventoryByCategory: [],
    });
}
/**
 * Calculate daily logistics metrics
 */
async function calculateLogisticsMetrics(date, dateKey) {
    const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
    const endOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
    const shipmentsSnapshot = await db
        .collection('shipments')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
        .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(endOfDay))
        .get();
    let totalShipments = 0;
    let deliveredShipments = 0;
    let delayedShipments = 0;
    shipmentsSnapshot.forEach((doc) => {
        const shipment = doc.data();
        totalShipments += 1;
        if (shipment.status === 'delivered') {
            deliveredShipments += 1;
        }
        if (shipment.status === 'delayed') {
            delayedShipments += 1;
        }
    });
    const onTimeDeliveryRate = totalShipments > 0 ? ((deliveredShipments - delayedShipments) / totalShipments) * 100 : 0;
    await db
        .collection('analytics')
        .doc('logistics_performance')
        .collection('daily')
        .doc(dateKey)
        .set({
        date: admin.firestore.Timestamp.fromDate(startOfDay),
        totalShipments: totalShipments,
        deliveredShipments: deliveredShipments,
        delayedShipments: delayedShipments,
        averageDeliveryTime: 2.5,
        onTimeDeliveryRate: onTimeDeliveryRate,
        carrierMetrics: [],
    });
}
/**
 * Calculate daily review analytics
 */
async function calculateReviewAnalytics(date, dateKey) {
    const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
    const endOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
    const reviewsSnapshot = await db
        .collection('product_reviews_enhanced')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
        .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(endOfDay))
        .get();
    let totalReviews = 0;
    let totalRating = 0;
    let pendingApproval = 0;
    let flaggedAsInappropriate = 0;
    reviewsSnapshot.forEach((doc) => {
        const review = doc.data();
        totalReviews += 1;
        totalRating += review.rating || 0;
        if (review.moderationStatus === 'pending') {
            pendingApproval += 1;
        }
        if (review.flagged === true) {
            flaggedAsInappropriate += 1;
        }
    });
    const averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;
    // Calculate rating distribution
    const ratingDistribution = [];
    for (let stars = 1; stars <= 5; stars++) {
        const count = reviewsSnapshot.docs.filter((doc) => doc.data().rating === stars).length;
        const percentage = totalReviews > 0 ? (count / totalReviews) * 100 : 0;
        ratingDistribution.push({
            stars: stars,
            count: count,
            percentage: percentage,
        });
    }
    await db
        .collection('analytics')
        .doc('review_analytics')
        .collection('daily')
        .doc(dateKey)
        .set({
        date: admin.firestore.Timestamp.fromDate(startOfDay),
        totalReviews: totalReviews,
        averageRating: averageRating,
        pendingApproval: pendingApproval,
        flaggedAsInappropriate: flaggedAsInappropriate,
        ratingDistribution: ratingDistribution,
    });
}
/**
 * Calculate daily member analytics
 */
async function calculateMemberMetrics(date, dateKey) {
    const membersSnapshot = await db.collection('members').get();
    let totalMembers = 0;
    let goldMembers = 0;
    let platinumMembers = 0;
    let standardMembers = 0;
    let totalLoyaltyPoints = 0;
    membersSnapshot.forEach((doc) => {
        const member = doc.data();
        totalMembers += 1;
        totalLoyaltyPoints += member.loyaltyPoints || 0;
        const tier = member.membershipTier || 'standard';
        if (tier === 'gold') {
            goldMembers += 1;
        }
        else if (tier === 'platinum') {
            platinumMembers += 1;
        }
        else {
            standardMembers += 1;
        }
    });
    const averageLoyaltyPoints = totalMembers > 0 ? totalLoyaltyPoints / totalMembers : 0;
    await db
        .collection('analytics')
        .doc('member_analytics')
        .collection('daily')
        .doc(dateKey)
        .set({
        date: admin.firestore.Timestamp.fromDate(new Date(date)),
        totalMembers: totalMembers,
        goldMembers: goldMembers,
        platinumMembers: platinumMembers,
        standardMembers: standardMembers,
        totalLoyaltyPoints: totalLoyaltyPoints,
        averageLoyaltyPoints: averageLoyaltyPoints,
    });
}
// ============================================================================
// NOTIFICATION HELPERS
// ============================================================================
/**
 * Send notification to user
 * Supports multiple channels: FCM, in-app, email
 */
async function sendNotification(userId, notification) {
    try {
        // Log notification
        await db
            .collection('user_activities')
            .doc(userId)
            .collection('activities')
            .add({
            userId: userId,
            activityType: 'notification_received',
            timestamp: admin.firestore.Timestamp.now(),
            data: notification,
        });
        // Store in notifications collection for in-app display
        await db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
            userId: userId,
            title: notification.title,
            body: notification.body,
            type: notification.type || 'general',
            read: false,
            data: notification,
            createdAt: admin.firestore.Timestamp.now(),
        });
        // TODO: Integrate with FCM for push notifications
        // TODO: Integrate with email service
        // TODO: Integrate with SMS service
        console.log(`Notification sent to user ${userId}`);
    }
    catch (error) {
        console.error(`Failed to send notification to ${userId}:`, error);
        // Don't throw - notifications are non-blocking
    }
}
// ============================================================================
// ORDER FULFILLMENT PIPELINE
// ============================================================================
/**
 * Process order fulfillment when order is created
 * Triggered: When new order document is created
 * Actions:
 * 1. Deduct inventory from warehouse
 * 2. Create shipment record
 * 3. Send notifications to customer and warehouse
 * 4. Log activity
 */
exports.fulfillOrder = functions.firestore
    .document('orders/{orderId}')
    .onCreate(async (snap, context) => {
    const orderId = context.params.orderId;
    const orderData = snap.data();
    const userId = orderData.userId;
    try {
        console.log(`Processing order fulfillment for order: ${orderId}`);
        // Deduct inventory for each item in the order
        const items = orderData.items || [];
        let inventoryDeductionSuccess = true;
        const deductionResults = [];
        for (const item of items) {
            try {
                const productId = item.product?.id || item.productId;
                const quantity = item.quantity || 1;
                if (!productId) {
                    console.warn(`Skipping item without product ID in order ${orderId}`);
                    continue;
                }
                // Deduct from product inventory
                const productRef = db.collection('products').doc(productId);
                const productSnap = await productRef.get();
                if (!productSnap.exists) {
                    console.warn(`Product ${productId} not found`);
                    deductionResults.push({
                        productId,
                        quantity,
                        success: false,
                        error: 'Product not found',
                    });
                    continue;
                }
                const currentStock = productSnap.data()?.stock || 0;
                const newStock = Math.max(0, currentStock - quantity);
                await productRef.update({
                    stock: newStock,
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                });
                // Log inventory deduction activity
                await db
                    .collection('system_activities')
                    .add({
                    type: 'inventory_deducted',
                    productId: productId,
                    orderId: orderId,
                    quantity: quantity,
                    timestamp: admin.firestore.Timestamp.now(),
                    data: {
                        previousStock: currentStock,
                        newStock: newStock,
                        userId: userId,
                    },
                });
                deductionResults.push({
                    productId,
                    quantity,
                    success: true,
                    previousStock: currentStock,
                    newStock: newStock,
                });
                console.log(`✅ Deducted ${quantity} units of ${productId}. New stock: ${newStock}`);
            }
            catch (itemError) {
                console.error(`Failed to deduct inventory for item in order ${orderId}:`, itemError);
                inventoryDeductionSuccess = false;
                deductionResults.push({
                    productId: item.product?.id || item.productId,
                    quantity: item.quantity,
                    success: false,
                    error: String(itemError),
                });
            }
        }
        // Create shipment record
        const shipmentRef = db.collection('shipments').doc();
        await shipmentRef.set({
            shipmentId: shipmentRef.id,
            orderId: orderId,
            userId: userId,
            items: items,
            shippingAddress: orderData.shippingAddress,
            status: 'pending_pickup', // pending_pickup → picked → in_transit → delivered
            totalAmount: orderData.totalAmount,
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now(),
            inventoryDeductionSuccess: inventoryDeductionSuccess,
            inventoryDeductionDetails: deductionResults,
        });
        // Update order with shipment ID and status
        await snap.ref.update({
            shipmentId: shipmentRef.id,
            status: 'confirmed', // pending_payment → confirmed → shipped → delivered
            fulfillmentStatus: 'created_shipment',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Send notification to customer
        await sendNotification(userId, {
            title: 'Order Confirmed! 🎉',
            body: `Your order #${orderId} has been confirmed and is being prepared for shipment.`,
            type: 'order_confirmed',
            orderId: orderId,
            shipmentId: shipmentRef.id,
        });
        // Send notification to warehouse staff
        // TODO: Send to warehouse staff role
        console.log(`✅ Order fulfillment process completed for order ${orderId}`);
        // Log fulfillment completion
        await db
            .collection('user_activities')
            .doc(userId)
            .collection('activities')
            .add({
            userId: userId,
            activityType: 'order_confirmed',
            timestamp: admin.firestore.Timestamp.now(),
            data: {
                orderId: orderId,
                shipmentId: shipmentRef.id,
                totalAmount: orderData.totalAmount,
                itemCount: items.length,
            },
        });
        return null;
    }
    catch (error) {
        console.error(`Order fulfillment failed for order ${orderId}:`, error);
        // Mark order as failed
        await snap.ref.update({
            fulfillmentStatus: 'failed',
            fulfillmentError: String(error),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Notify customer of issue
        await sendNotification(userId, {
            title: 'Order Processing Issue ⚠️',
            body: `There was an issue processing your order #${orderId}. Our team will contact you shortly.`,
            type: 'order_error',
            orderId: orderId,
        });
        return null;
    }
});
/**
 * When payment is confirmed, mark order as paid and ready to ship
 * Triggered: When order payment status changes to paid
 */
exports.onOrderPaymentConfirmed = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;
    // Only process when payment status changes to paid
    if (before?.paymentStatus !== 'paid' &&
        after?.paymentStatus === 'paid') {
        const userId = after.userId;
        try {
            // Update order status
            await change.after.ref.update({
                status: 'payment_confirmed',
                paidAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Send notification to customer
            await sendNotification(userId, {
                title: 'Payment Received ✅',
                body: `Your payment for order #${orderId} has been confirmed. Your items will ship soon!`,
                type: 'payment_confirmed',
                orderId: orderId,
            });
            // Log activity
            await db
                .collection('user_activities')
                .doc(userId)
                .collection('activities')
                .add({
                userId: userId,
                activityType: 'payment_confirmed',
                timestamp: admin.firestore.Timestamp.now(),
                data: {
                    orderId: orderId,
                    amount: after.totalAmount,
                },
            });
            console.log(`✅ Payment confirmed for order ${orderId}`);
        }
        catch (error) {
            console.error(`Error processing payment confirmation:`, error);
        }
    }
    return null;
});
// ============================================================================
// RECOMMENDATIONS ENGINE
// ============================================================================
/**
 * Get recommended products based on user's activity
 * Considers:
 * 1. Products viewed but not purchased
 * 2. Frequently viewed products (trending)
 * 3. Products bought by users like them
 * 4. Similar products in same category
 */
exports.getRecommendedProducts = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const limit = data.limit || 10;
    try {
        const recommendations = [];
        // 1. Get user's recently viewed products
        const viewedSnapshot = await db
            .collection('user_activities')
            .doc(userId)
            .collection('activities')
            .where('activityType', '==', 'viewed_product')
            .orderBy('timestamp', 'desc')
            .limit(20)
            .get();
        const viewedProductIds = new Set();
        const viewedCategories = new Set();
        viewedSnapshot.forEach((doc) => {
            const productId = doc.data().data?.productId;
            const category = doc.data().data?.category;
            if (productId)
                viewedProductIds.add(productId);
            if (category)
                viewedCategories.add(category);
        });
        // 2. Get user's purchased products
        const purchasedSnapshot = await db
            .collection('user_activities')
            .doc(userId)
            .collection('activities')
            .where('activityType', '==', 'purchased')
            .orderBy('timestamp', 'desc')
            .limit(10)
            .get();
        const purchasedProductIds = new Set();
        purchasedSnapshot.forEach((doc) => {
            const productId = doc.data().data?.productId;
            if (productId)
                purchasedProductIds.add(productId);
        });
        // 3. Products in same categories (similar to what user likes)
        if (viewedCategories.size > 0) {
            const categoryArray = Array.from(viewedCategories);
            const similarProductsSnapshot = await db
                .collection('products')
                .where('category', 'in', categoryArray)
                .limit(limit * 2)
                .get();
            const seen = new Set();
            similarProductsSnapshot.forEach((doc) => {
                const productId = doc.id;
                // Skip if already viewed or purchased
                if (!viewedProductIds.has(productId) &&
                    !purchasedProductIds.has(productId) &&
                    !seen.has(productId)) {
                    seen.add(productId);
                    recommendations.push({
                        ...doc.data(),
                        id: productId,
                        reason: 'Based on your interest in this category',
                        score: 0.7,
                    });
                }
            });
        }
        // 4. Frequently viewed products (trending) - that user hasn't bought
        const trendingSnapshot = await db
            .collection('analytics')
            .doc('popular_products')
            .get();
        if (trendingSnapshot.exists) {
            const trendingData = trendingSnapshot.data();
            if (trendingData?.topProducts && Array.isArray(trendingData.topProducts)) {
                for (const trendingProduct of trendingData.topProducts.slice(0, limit)) {
                    if (!purchasedProductIds.has(trendingProduct.productId) && recommendations.length < limit) {
                        const productDoc = await db
                            .collection('products')
                            .doc(trendingProduct.productId)
                            .get();
                        if (productDoc.exists) {
                            recommendations.push({
                                ...productDoc.data(),
                                id: productDoc.id,
                                reason: 'Trending product',
                                score: 0.8,
                            });
                        }
                    }
                }
            }
        }
        // 5. Products bought by similar users
        // Find users who viewed similar products
        if (viewedProductIds.size > 0) {
            const similarUsersSnapshot = await db
                .collectionGroup('activities')
                .where('activityType', '==', 'viewed_product')
                .where('data.productId', 'in', Array.from(viewedProductIds).slice(0, 3))
                .limit(50)
                .get();
            const similarUserIds = new Set();
            similarUsersSnapshot.forEach((doc) => {
                const docUserId = doc.ref.parent.parent?.id;
                if (docUserId && docUserId !== userId) {
                    similarUserIds.add(docUserId);
                }
            });
            if (similarUserIds.size > 0) {
                // Get what similar users bought that current user hasn't
                for (const simUserId of Array.from(similarUserIds).slice(0, 5)) {
                    const simUserPurchasesSnapshot = await db
                        .collection('user_activities')
                        .doc(simUserId)
                        .collection('activities')
                        .where('activityType', '==', 'purchased')
                        .limit(10)
                        .get();
                    simUserPurchasesSnapshot.forEach((doc) => {
                        const productId = doc.data().data?.productId;
                        if (productId &&
                            !purchasedProductIds.has(productId) &&
                            recommendations.length < limit) {
                            recommendations.push({
                                productId: productId,
                                reason: 'Users who liked similar products also bought this',
                                score: 0.6,
                            });
                        }
                    });
                }
            }
        }
        // Sort by score and limit results
        const sorted = recommendations
            .sort((a, b) => (b.score || 0) - (a.score || 0))
            .slice(0, limit);
        return {
            success: true,
            recommendations: sorted,
            count: sorted.length,
        };
    }
    catch (error) {
        console.error('Error getting recommendations:', error);
        throw new functions.https.HttpsError('internal', 'Failed to get recommendations');
    }
});
/**
 * Log product view for recommendations
 * Called when user views a product detail page
 */
exports.logProductView = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { productId, productName, category, price } = data;
    if (!productId) {
        throw new functions.https.HttpsError('invalid-argument', 'productId is required');
    }
    try {
        // Log activity
        await db
            .collection('user_activities')
            .doc(userId)
            .collection('activities')
            .add({
            userId: userId,
            activityType: 'viewed_product',
            timestamp: admin.firestore.Timestamp.now(),
            data: {
                productId: productId,
                productName: productName,
                category: category,
                price: price,
            },
        });
        // Update product view count
        const productRef = db.collection('products').doc(productId);
        await productRef.update({
            viewCount: admin.firestore.FieldValue.increment(1),
            lastViewed: admin.firestore.FieldValue.serverTimestamp(),
        }).catch(() => {
            // Product might not exist, that's ok
        });
        // Update trending/popular products daily calculated at midnight
        const dateKey = formatDateKey(new Date());
        await db
            .collection('analytics')
            .doc('product_views')
            .collection('daily')
            .doc(dateKey)
            .set({
            [productId]: admin.firestore.FieldValue.increment(1),
        }, { merge: true });
        return { success: true };
    }
    catch (error) {
        console.error('Error logging product view:', error);
        throw new functions.https.HttpsError('internal', 'Failed to log product view');
    }
});
/**
 * Format date to YYYY-MM-DD key
 */
function formatDateKey(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}
//# sourceMappingURL=index.js.map