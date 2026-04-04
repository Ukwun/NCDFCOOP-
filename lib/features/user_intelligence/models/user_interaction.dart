import 'package:cloud_firestore/cloud_firestore.dart';

/// User interaction tracking model
/// Logs interactions between users (buyers, sellers, etc.)
class UserInteraction {
  final String id;
  final String fromUserId; // User initiating the interaction
  final String toUserId; // User receiving the interaction
  final String fromUserRole; // Role of initiator (buyer, seller, driver, etc.)
  final String toUserRole; // Role of recipient
  final String
      type; // Type of interaction: purchase, review, message, follow, mention, etc.
  final String?
      referenceId; // Reference to the interaction (orderId, productId, etc.)
  final Map<String, dynamic>? metadata; // Additional data about the interaction
  final DateTime timestamp;
  final bool isPositive; // Whether the interaction was positive/negative

  const UserInteraction({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserRole,
    required this.toUserRole,
    required this.type,
    this.referenceId,
    this.metadata,
    required this.timestamp,
    required this.isPositive,
  });

  /// Create from Firestore document
  factory UserInteraction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document does not exist');
    }

    return UserInteraction(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      fromUserRole: data['fromUserRole'] as String? ?? '',
      toUserRole: data['toUserRole'] as String? ?? '',
      type: data['type'] as String? ?? '',
      referenceId: data['referenceId'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPositive: data['isPositive'] as bool? ?? true,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserRole': fromUserRole,
      'toUserRole': toUserRole,
      'type': type,
      'referenceId': referenceId,
      'metadata': metadata,
      'timestamp': timestamp,
      'isPositive': isPositive,
    };
  }

  /// Copy with new values
  UserInteraction copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fromUserRole,
    String? toUserRole,
    String? type,
    String? referenceId,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    bool? isPositive,
  }) {
    return UserInteraction(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserRole: fromUserRole ?? this.fromUserRole,
      toUserRole: toUserRole ?? this.toUserRole,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      isPositive: isPositive ?? this.isPositive,
    );
  }
}
