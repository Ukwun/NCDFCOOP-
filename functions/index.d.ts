import * as functions from 'firebase-functions';
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
export declare const fulfillOrder: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
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
export {};
//# sourceMappingURL=index.d.ts.map