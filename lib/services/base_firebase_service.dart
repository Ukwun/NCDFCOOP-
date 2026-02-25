import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

abstract class BaseFirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<T?> getDocument<T>(
    String collection,
    String documentId,
    T Function(DocumentSnapshot) fromFirestore,
  ) async {
    try {
      AppLogger.logFirestoreOperation(
        'GET',
        collection: collection,
        documentId: documentId,
      );
      final doc = await firestore.collection(collection).doc(documentId).get();
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to get document');
      rethrow;
    }
  }

  Future<List<T>> getCollection<T>(
    String collection,
    T Function(DocumentSnapshot) fromFirestore, {
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      AppLogger.logFirestoreOperation('GET_COLLECTION', collection: collection);
      Query query = firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to get collection');
      rethrow;
    }
  }

  Stream<List<T>> watchCollection<T>(
    String collection,
    T Function(DocumentSnapshot) fromFirestore, {
    Query Function(Query)? queryBuilder,
  }) {
    try {
      AppLogger.debug('Watching collection: $collection');
      Query query = firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
      });
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to watch collection');
      rethrow;
    }
  }

  Stream<T?> watchDocument<T>(
    String collection,
    String documentId,
    T Function(DocumentSnapshot) fromFirestore,
  ) {
    try {
      AppLogger.debug('Watching document: $documentId in $collection');
      return firestore
          .collection(collection)
          .doc(documentId)
          .snapshots()
          .map((doc) => doc.exists ? fromFirestore(doc) : null);
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to watch document');
      rethrow;
    }
  }

  Future<void> addDocument(
    String collection,
    Map<String, dynamic> data, {
    String? documentId,
  }) async {
    try {
      AppLogger.logFirestoreOperation(
        'ADD',
        collection: collection,
        documentId: documentId,
        data: data,
      );
      if (documentId != null) {
        await firestore.collection(collection).doc(documentId).set(data);
      } else {
        await firestore.collection(collection).add(data);
      }
      AppLogger.success('Document added to $collection');
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to add document');
      rethrow;
    }
  }

  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.logFirestoreOperation(
        'UPDATE',
        collection: collection,
        documentId: documentId,
        data: data,
      );
      await firestore.collection(collection).doc(documentId).update(data);
      AppLogger.success('Document updated in $collection');
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to update document');
      rethrow;
    }
  }

  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      AppLogger.logFirestoreOperation(
        'DELETE',
        collection: collection,
        documentId: documentId,
      );
      await firestore.collection(collection).doc(documentId).delete();
      AppLogger.success('Document deleted from $collection');
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to delete document');
      rethrow;
    }
  }

  Future<void> batch(Function(WriteBatch) operation) async {
    try {
      final batch = firestore.batch();
      await operation(batch);
      await batch.commit();
      AppLogger.success('Batch operation completed');
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to execute batch');
      rethrow;
    }
  }

  Future<int> getCollectionCount(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      Query query = firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to count documents');
      rethrow;
    }
  }

  Future<bool> documentExists(String collection, String documentId) async {
    try {
      final doc = await firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace,
          message: 'Failed to check document existence');
      rethrow;
    }
  }
}
