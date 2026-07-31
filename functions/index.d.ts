import * as functions from 'firebase-functions';
/**
 * Provisions the user's single marketplace identity and its matching profile.
 * Keeping this server-side prevents clients from fabricating role/profile data.
 */
export declare const provisionMarketplaceRole: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Calculate loyalty points on order completion
 * Triggered when an order status changes to 'delivered'
 *
 * Rules:
 * - 1 loyalty point per KES 1 spent
 * - Gold members: 1.5x multiplier
 * - Platinum members: 2x multiplier
 */
export declare const calculateLoyaltyPoints: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
/**
 * Automatically promote members to higher tiers based on loyalty points
 * Triggered when member loyalty points are updated
 *
 * Tiers:
 * - Standard: 0 - 4,999 points
 * - Gold: 5,000 - 14,999 points
 * - Platinum: 15,000+ points
 */
export declare const autoPromoteMemberTier: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
/**
 * Automatically trigger reorder when stock falls below minimum
 * Triggered hourly via scheduled function
 *
 * Logic:
 * - Check all warehouse locations
 * - Find items below minimum stock level
 * - Create reorder suggestions with cost calculation
 */
export declare const autoTriggerReorders: functions.CloudFunction<unknown>;
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
export declare const calculateDailyAnalytics: functions.CloudFunction<unknown>;
/**
 * Process order fulfillment when order is created
 * Triggered: When new order document is created
 * Actions:
 * 1. Deduct inventory from warehouse
 * 2. Create shipment record
 * 3. Send notifications to customer and warehouse
 * 4. Log activity
 */
export declare const fulfillOrder: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
/**
 * When payment is confirmed, mark order as paid and ready to ship
 * Triggered: When order payment status changes to paid
 */
export declare const onOrderPaymentConfirmed: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
/**
 * Get recommended products based on user's activity
 * Considers:
 * 1. Products viewed but not purchased
 * 2. Frequently viewed products (trending)
 * 3. Products bought by users like them
 * 4. Similar products in same category
 */
export declare const getRecommendedProducts: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Log product view for recommendations
 * Called when user views a product detail page
 */
export declare const logProductView: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Creates a Flutterwave checkout using the server-authoritative order total.
 * The secret key is injected by Secret Manager and never sent to the app.
 */
export declare const createMarketplaceOrder: functions.HttpsFunction & functions.Runnable<any>;
/** Creates a Stripe-hosted checkout from a server-authoritative order. */
export declare const initializeStripeCheckout: functions.HttpsFunction & functions.Runnable<any>;
/** Stripe is the sole authority that can transition an order to paid. */
export declare const stripeWebhook: functions.HttpsFunction;
export declare const initializeFlutterwavePayment: functions.HttpsFunction & functions.Runnable<any>;
/** Places a seller withdrawal request while reserving the requested balance. */
export declare const requestSellerWithdrawal: functions.HttpsFunction & functions.Runnable<any>;
/** Approves or rejects a seller withdrawal for the designated super admin. */
export declare const reviewSellerWithdrawal: functions.HttpsFunction & functions.Runnable<any>;
/** Redeems a member reward using a server-authoritative points transaction. */
export declare const claimMemberReward: functions.HttpsFunction & functions.Runnable<any>;
/** Deletes the authenticated account and its private marketplace records. */
export declare const deleteMyAccount: functions.HttpsFunction & functions.Runnable<any>;
/** Releases pending seller funds only after a paid order is delivered. */
export declare const releaseSellerEarningsOnDelivery: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
export {};
//# sourceMappingURL=index.d.ts.map