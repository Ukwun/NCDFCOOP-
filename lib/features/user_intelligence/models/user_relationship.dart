import 'package:cloud_firestore/cloud_firestore.dart';

/// User relationship model
/// Tracks relationships between users (follows, blocks, connections, etc.)
class UserRelationship {
  final String id;
  final String userId; // Primary user
  final String relatedUserId; // Related user
  final String
      relationshipType; // follow, block, favorite, mentor, apprentice, etc.
  final String? notes; // Optional notes about the relationship
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive; // Whether the relationship is active
  final int interactionCount; // Number of interactions between users

  const UserRelationship({
    required this.id,
    required this.userId,
    required this.relatedUserId,
    required this.relationshipType,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.interactionCount,
  });

  /// Create from Firestore document
  factory UserRelationship.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document does not exist');
    }

    return UserRelationship(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      relatedUserId: data['relatedUserId'] as String? ?? '',
      relationshipType: data['relationshipType'] as String? ?? '',
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
      interactionCount: data['interactionCount'] as int? ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'relatedUserId': relatedUserId,
      'relationshipType': relationshipType,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'interactionCount': interactionCount,
    };
  }

  /// Copy with new values
  UserRelationship copyWith({
    String? id,
    String? userId,
    String? relatedUserId,
    String? relationshipType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? interactionCount,
  }) {
    return UserRelationship(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relationshipType: relationshipType ?? this.relationshipType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      interactionCount: interactionCount ?? this.interactionCount,
    );
  }
}
