import 'package:cloud_firestore/cloud_firestore.dart';

/// Compliance scoring for franchise stores
/// Simple scoring function (not Drools) with configurable rules
class ComplianceScoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _complianceCollection = 'compliance_scores';
  static const String _scoreHistoryCollection = 'compliance_history';

  // Scoring weights (totals 100 points)
  static const Map<String, int> scoringWeights = {
    'checklist_completion': 30, // Compliance checklist completion %
    'incident_free_days': 20, // Days without incidents
    'stock_accuracy': 15, // Physical stock vs system match
    'delivery_sla': 15, // On-time delivery rate
    'payment_timeliness': 10, // Payment within terms %
    'staff_training': 10, // Staff certification completion %
  };

  // ===================== SCORE CALCULATION =====================

  /// Calculate overall compliance score for a franchise
  Future<ComplianceScore> calculateComplianceScore(
    String franchiseId,
  ) async {
    try {
      final checklistScore = await _getChecklistScore(franchiseId);
      final incidentScore = await _getIncidentScore(franchiseId);
      final stockScore = await _getStockAccuracyScore(franchiseId);
      final slaScore = await _getDeliverySLAScore(franchiseId);
      final paymentScore = await _getPaymentTimelinessScore(franchiseId);
      final trainingScore = await _getStaffTrainingScore(franchiseId);

      // Weighted calculation
      final overallScore =
          (checklistScore * (scoringWeights['checklist_completion']! / 100)) +
              (incidentScore * (scoringWeights['incident_free_days']! / 100)) +
              (stockScore * (scoringWeights['stock_accuracy']! / 100)) +
              (slaScore * (scoringWeights['delivery_sla']! / 100)) +
              (paymentScore * (scoringWeights['payment_timeliness']! / 100)) +
              (trainingScore * (scoringWeights['staff_training']! / 100));

      final grade = _scoreToGrade(overallScore.round());
      final riskLevel = _scoreToRiskLevel(overallScore.round());

      final score = ComplianceScore(
        franchiseId: franchiseId,
        overallScore: overallScore.round(),
        grade: grade,
        riskLevel: riskLevel,
        checklistCompletion: checklistScore,
        incidentFreeDays: incidentScore,
        stockAccuracy: stockScore,
        deliverySLA: slaScore,
        paymentTimeliness: paymentScore,
        staffTraining: trainingScore,
        calculatedAt: DateTime.now(),
      );

      // Store in Firestore
      await _saveComplianceScore(score);

      return score;
    } catch (e) {
      throw Exception('Failed to calculate compliance score: $e');
    }
  }

  /// Get compliance score for a franchise
  Future<ComplianceScore?> getComplianceScore(String franchiseId) async {
    try {
      final doc = await _firestore
          .collection(_complianceCollection)
          .doc(franchiseId)
          .get();

      if (!doc.exists) return null;

      return ComplianceScore.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get compliance score: $e');
    }
  }

  /// Get compliance history for a franchise (last N scores)
  Future<List<ComplianceScore>> getComplianceHistory(
    String franchiseId, {
    int limit = 12,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_scoreHistoryCollection)
          .doc(franchiseId)
          .collection('records')
          .orderBy('calculatedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ComplianceScore.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get compliance history: $e');
    }
  }

  // ===================== INDIVIDUAL SCORING COMPONENTS =====================

  /// Score: Compliance checklist completion (0-100)
  Future<int> _getChecklistScore(String franchiseId) async {
    try {
      final doc = await _firestore
          .collection('franchise_stores')
          .doc(franchiseId)
          .collection('compliance_checklists')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return 0;

      final data = doc.docs.first.data();
      final items = (data['items'] as List? ?? []);
      final completed = items
          .whereType<Map>()
          .where((item) => item['completed'] == true)
          .length;

      if (items.isEmpty) return 0;
      return ((completed / items.length) * 100).round();
    } catch (e) {
      print('Error calculating checklist score: $e');
      return 0;
    }
  }

  /// Score: Days since last incident (0-100)
  /// 100 = no incidents in 90 days
  /// 0 = incident in last day
  Future<int> _getIncidentScore(String franchiseId) async {
    try {
      final doc = await _firestore
          .collection('franchise_stores')
          .doc(franchiseId)
          .collection('incidents')
          .orderBy('reportedAt', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return 100; // No incidents = perfect score

      final lastIncident = doc.docs.first.data();
      final reportedAt = (lastIncident['reportedAt'] as Timestamp).toDate();
      final daysSinceIncident = DateTime.now().difference(reportedAt).inDays;

      // Score: 100 if 90+ days, 0 if 0 days, linear interpolation
      if (daysSinceIncident >= 90) return 100;
      if (daysSinceIncident <= 0) return 0;
      return ((daysSinceIncident / 90) * 100).round();
    } catch (e) {
      print('Error calculating incident score: $e');
      return 100;
    }
  }

  /// Score: Physical stock vs system accuracy (0-100)
  /// Based on recent stock counts
  Future<int> _getStockAccuracyScore(String franchiseId) async {
    try {
      final doc = await _firestore
          .collection('franchise_inventory')
          .doc(franchiseId)
          .collection('stock_counts')
          .orderBy('countedAt', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return 75; // Assume decent if no recent count

      final data = doc.docs.first.data();
      final totalItems = data['totalItemsChecked'] as int? ?? 1;
      final accurateItems = data['accurateItems'] as int? ?? totalItems;

      if (totalItems == 0) return 100;
      return ((accurateItems / totalItems) * 100).round();
    } catch (e) {
      print('Error calculating stock accuracy score: $e');
      return 75;
    }
  }

  /// Score: Delivery SLA compliance (0-100)
  /// Based on last 30 orders' on-time rate
  Future<int> _getDeliverySLAScore(String franchiseId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('orders')
          .where('storeId', isEqualTo: franchiseId)
          .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .limit(30)
          .get();

      if (snapshot.docs.isEmpty) return 75;

      int onTime = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final deliveredAt = data['deliveredAt'] as Timestamp?;
        final expectedDelivery = data['expectedDelivery'] as Timestamp?;

        if (deliveredAt != null && expectedDelivery != null) {
          if (deliveredAt.toDate().isBefore(expectedDelivery.toDate())) {
            onTime++;
          }
        }
      }

      return ((onTime / snapshot.docs.length) * 100).round();
    } catch (e) {
      print('Error calculating SLA score: $e');
      return 75;
    }
  }

  /// Score: Payment timeliness (0-100)
  /// Based on invoices paid within 7 days of due date
  Future<int> _getPaymentTimelinessScore(String franchiseId) async {
    try {
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));

      final snapshot = await _firestore
          .collection('invoices')
          .where('franchiseId', isEqualTo: franchiseId)
          .where('dueDate', isGreaterThanOrEqualTo: ninetyDaysAgo)
          .get();

      if (snapshot.docs.isEmpty) return 75;

      int onTimePayments = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final paidAt = data['paidAt'] as Timestamp?;
        final dueDate = data['dueDate'] as Timestamp;

        if (paidAt != null) {
          final daysBefore =
              dueDate.toDate().difference(paidAt.toDate()).inDays;
          if (daysBefore >= 0) {
            // Paid before or on due date
            onTimePayments++;
          } else if (daysBefore > -7) {
            // Paid within 7 days after due date = partial credit
            onTimePayments++;
          }
        }
      }

      return ((onTimePayments / snapshot.docs.length) * 100).round();
    } catch (e) {
      print('Error calculating payment timeliness score: $e');
      return 75;
    }
  }

  /// Score: Staff training completion (0-100)
  /// Based on mandatory training certifications
  Future<int> _getStaffTrainingScore(String franchiseId) async {
    try {
      // Get all staff in this franchise
      final staffSnapshot = await _firestore
          .collection('franchise_stores')
          .doc(franchiseId)
          .collection('staff')
          .get();

      if (staffSnapshot.docs.isEmpty) return 100;

      int trainedStaff = 0;
      for (final staffDoc in staffSnapshot.docs) {
        final data = staffDoc.data();
        final certifications = (data['certifications'] as List? ?? []);
        final hasRequiredTraining = certifications.any(
          (cert) =>
              cert['type'] == 'compliance_training' && cert['active'] == true,
        );

        if (hasRequiredTraining) {
          trainedStaff++;
        }
      }

      return ((trainedStaff / staffSnapshot.docs.length) * 100).round();
    } catch (e) {
      print('Error calculating training score: $e');
      return 75;
    }
  }

  // ===================== HELPERS =====================

  String _scoreToGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  ComplianceRiskLevel _scoreToRiskLevel(int score) {
    if (score >= 85) return ComplianceRiskLevel.low;
    if (score >= 70) return ComplianceRiskLevel.medium;
    if (score >= 55) return ComplianceRiskLevel.high;
    return ComplianceRiskLevel.critical;
  }

  Future<void> _saveComplianceScore(ComplianceScore score) async {
    try {
      // Save current score
      await _firestore
          .collection(_complianceCollection)
          .doc(score.franchiseId)
          .set({
        'franchiseId': score.franchiseId,
        'overallScore': score.overallScore,
        'grade': score.grade,
        'riskLevel': score.riskLevel.toString(),
        'checklistCompletion': score.checklistCompletion,
        'incidentFreeDays': score.incidentFreeDays,
        'stockAccuracy': score.stockAccuracy,
        'deliverySLA': score.deliverySLA,
        'paymentTimeliness': score.paymentTimeliness,
        'staffTraining': score.staffTraining,
        'calculatedAt': FieldValue.serverTimestamp(),
      });

      // Save to history
      await _firestore
          .collection(_scoreHistoryCollection)
          .doc(score.franchiseId)
          .collection('records')
          .add(score.toFirestore());
    } catch (e) {
      print('Failed to save compliance score: $e');
    }
  }
}

// ===================== DATA MODELS =====================

class ComplianceScore {
  final String franchiseId;
  final int overallScore; // 0-100
  final String grade; // A, B, C, D, F
  final ComplianceRiskLevel riskLevel;
  final int checklistCompletion;
  final int incidentFreeDays;
  final int stockAccuracy;
  final int deliverySLA;
  final int paymentTimeliness;
  final int staffTraining;
  final DateTime calculatedAt;

  ComplianceScore({
    required this.franchiseId,
    required this.overallScore,
    required this.grade,
    required this.riskLevel,
    required this.checklistCompletion,
    required this.incidentFreeDays,
    required this.stockAccuracy,
    required this.deliverySLA,
    required this.paymentTimeliness,
    required this.staffTraining,
    required this.calculatedAt,
  });

  factory ComplianceScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplianceScore(
      franchiseId: data['franchiseId'] as String,
      overallScore: data['overallScore'] as int,
      grade: data['grade'] as String,
      riskLevel: _parseRiskLevel(data['riskLevel'] as String),
      checklistCompletion: data['checklistCompletion'] as int,
      incidentFreeDays: data['incidentFreeDays'] as int,
      stockAccuracy: data['stockAccuracy'] as int,
      deliverySLA: data['deliverySLA'] as int,
      paymentTimeliness: data['paymentTimeliness'] as int,
      staffTraining: data['staffTraining'] as int,
      calculatedAt: (data['calculatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'overallScore': overallScore,
      'grade': grade,
      'riskLevel': riskLevel.toString(),
      'checklistCompletion': checklistCompletion,
      'incidentFreeDays': incidentFreeDays,
      'stockAccuracy': stockAccuracy,
      'deliverySLA': deliverySLA,
      'paymentTimeliness': paymentTimeliness,
      'staffTraining': staffTraining,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  static ComplianceRiskLevel _parseRiskLevel(String value) {
    switch (value) {
      case 'ComplianceRiskLevel.low':
        return ComplianceRiskLevel.low;
      case 'ComplianceRiskLevel.medium':
        return ComplianceRiskLevel.medium;
      case 'ComplianceRiskLevel.high':
        return ComplianceRiskLevel.high;
      case 'ComplianceRiskLevel.critical':
        return ComplianceRiskLevel.critical;
      default:
        return ComplianceRiskLevel.medium;
    }
  }
}

enum ComplianceRiskLevel { low, medium, high, critical }
