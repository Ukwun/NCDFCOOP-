class AppConstants {
  // App Information
  static const String appName = 'Coop Commerce';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // API Configuration
  static const String baseUrl = 'https://api.coopcommerce.com/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Firebase
  static const String firebaseProjectId = 'coop-commerce';
  static const String firebaseRegion = 'us-central1';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String categoriesCollection = 'categories';
  static const String cartCollection = 'carts';
  static const String addressesCollection = 'addresses';
  static const String favoritesCollection = 'favorites';

  // Storage Buckets
  static const String userProfilesBucket = 'user-profiles';
  static const String productImagesBucket = 'product-images';
  static const String reviewImagesBucket = 'review-images';

  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String cartDataKey = 'cart_data';
  static const String favoritesKey = 'favorites';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;
  static const int initialProductsCount = 20;

  // Image Sizes
  static const int thumbnailSize = 150;
  static const int mediumImageSize = 300;
  static const int largeImageSize = 600;
  static const int maxImageSize = 1200;

  // Text Field Constraints
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minBioLength = 0;
  static const int maxBioLength = 500;
  static const int minProductNameLength = 3;
  static const int maxProductNameLength = 200;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 2000;

  // Validation Patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern =
      r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$';
  static const String usernamePattern = r'^[a-zA-Z0-9_-]+$';
  static const String urlPattern =
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

  // Payment
  static const List<String> paymentMethods = [
    'credit_card',
    'debit_card',
    'paypal',
    'google_pay',
    'apple_pay',
    'bank_transfer',
  ];

  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'returned',
  ];

  static const List<String> paymentStatuses = [
    'pending',
    'processing',
    'completed',
    'failed',
    'refunded',
  ];

  static const List<String> userTypes = [
    'customer',
    'vendor',
    'admin',
  ];

  // Durations
  static const Duration tokenExpiration = Duration(hours: 24);
  static const Duration refreshTokenExpiration = Duration(days: 7);
  static const Duration cachedDataDuration = Duration(minutes: 15);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Limits
  static const double minPrice = 0.0;
  static const double maxPrice = 999999.99;
  static const int maxProductsPerRequest = 50;
  static const int maxSearchResults = 100;
  static const int maxFavoritesCount = 1000;
  static const int maxCartItems = 100;
  static const int maxOrderHistory = 500;
  static const int maxReviewsPerPage = 20;

  // Ratings
  static const double minRating = 0.0;
  static const double maxRating = 5.0;
  static const int minReviewLength = 10;
  static const int maxReviewLength = 2000;

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String unauthorizedError =
      'You are not authorized to perform this action.';
  static const String notFoundError = 'Resource not found.';
  static const String validationError =
      'Please check your input and try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String timeoutError = 'Request timed out. Please try again.';

  // Success Messages
  static const String operationSuccess = 'Operation completed successfully';
  static const String dataLoadedSuccess = 'Data loaded successfully';
  static const String dataSavedSuccess = 'Data saved successfully';
  static const String itemAddedSuccess = 'Item added successfully';
  static const String itemRemovedSuccess = 'Item removed successfully';
  static const String itemUpdatedSuccess = 'Item updated successfully';
  static const String orderPlacedSuccess = 'Order placed successfully';

  // Default Values
  static const String defaultCurrency = '\$';
  static const String defaultLanguage = 'en';
  static const String defaultCountry = 'US';
  static const String defaultTimeZone = 'UTC';

  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enableOfflineMode = true;
  static const bool enableDebugLogging = false;
}
