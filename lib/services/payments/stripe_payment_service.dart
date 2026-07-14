import 'package:cloud_functions/cloud_functions.dart';

/// Client facade for Stripe Checkout. Secrets and payment state never enter
/// the Flutter process; verified Stripe webhooks finalize the order.
class StripePaymentService {
  StripePaymentService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> createCheckoutSession({
    required String orderId,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('initializeStripeCheckout')
          .call(<String, dynamic>{'orderId': orderId});
      return <String, dynamic>{
        'success': true,
        ...Map<String, dynamic>.from(result.data as Map),
      };
    } on FirebaseFunctionsException catch (error) {
      return <String, dynamic>{
        'success': false,
        'error': error.message ?? 'Unable to initialize Stripe checkout.',
      };
    }
  }
}
