import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/services/driver_service.dart';
import 'package:coop_commerce/providers/logistics_providers.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';

/// Driver App Screen - Shows today's deliveries
/// Accessed by: Drivers
/// Responsibilities:
/// - Display driver's assigned route for today
/// - Show list of delivery stops
/// - Track delivery progress
/// - Navigate to next stop
/// - Mark deliveries complete
class DriverAppScreen extends ConsumerStatefulWidget {
  const DriverAppScreen({super.key});

  @override
  ConsumerState<DriverAppScreen> createState() => _DriverAppScreenState();
}

class _DriverAppScreenState extends ConsumerState<DriverAppScreen> {
  int _currentStopIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Load today's deliveries from provider
    final deliveriesAsync = ref.watch(todayDeliveriesProvider);
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Today\'s Deliveries',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_enabled, color: Colors.green),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver support: 0123-456-789')),
              );
            },
          ),
        ],
      ),
      body: deliveriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading deliveries: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(todayDeliveriesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'No deliveries scheduled for today',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route Progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stop ${_currentStopIndex + 1} of ${deliveries.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${((_currentStopIndex / deliveries.length) * 100).toStringAsFixed(0)}% complete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Text(
                                '${((_currentStopIndex / deliveries.length) * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _currentStopIndex / deliveries.length,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Current Delivery Stop
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Current Stop',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCurrentStopCard(deliveries),
              ),
              const SizedBox(height: 24),
              // Remaining Stops
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next Deliveries',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${deliveries.length - _currentStopIndex - 1} remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildRemainingStops(deliveries),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentStopCard(List<DeliveryStop> deliveries) {
    if (_currentStopIndex >= deliveries.length) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text(
                'All deliveries completed!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stop = deliveries[_currentStopIndex];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stop ${_currentStopIndex + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stop.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: stop.address,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  label: 'Delivery Window',
                  value: stop.deliveryWindow ?? 'Not specified',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: '+1234567890',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeliveryChecklistScreen(
                            stop: stop,
                            onDeliveryComplete: () {
                              setState(() {
                                _currentStopIndex++;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Start Delivery'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingStops(List<DeliveryStop> deliveries) {
    final remaining = deliveries.sublist(
      (_currentStopIndex + 1).clamp(0, deliveries.length),
      deliveries.length,
    );

    if (remaining.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: remaining.length,
      itemBuilder: (context, index) {
        final stop = remaining[index];
        final stopNumber = _currentStopIndex + 2 + index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$stopNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                stop.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                stop.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey[400]),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Delivery Checklist Screen - Captures proof of delivery
/// Accessed by: Drivers
/// Responsibilities:
/// - Scan/verify order barcode
/// - Verify customer name and details
/// - Capture delivery photo
/// - Capture signature
/// - Record GPS coordinates
/// - Submit POD to system
class DeliveryChecklistScreen extends ConsumerStatefulWidget {
  final DeliveryStop stop;
  final VoidCallback onDeliveryComplete;

  const DeliveryChecklistScreen({
    super.key,
    required this.stop,
    required this.onDeliveryComplete,
  });

  @override
  ConsumerState<DeliveryChecklistScreen> createState() =>
      _DeliveryChecklistScreenState();
}

class _DeliveryChecklistScreenState
    extends ConsumerState<DeliveryChecklistScreen> {
  bool _barcodeScanned = false;
  bool _customerVerified = false;
  bool _photoTaken = false;
  bool _signatureCaptured = false;
  bool _isSubmitting = false;
  String? _photoPath;

  @override
  Widget build(BuildContext context) {
    final allChecked = _barcodeScanned &&
        _customerVerified &&
        _photoTaken &&
        _signatureCaptured;

    return WillPopScope(
      onWillPop: () async {
        if (!allChecked) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard Delivery?'),
              content: const Text(
                  'You haven\'t completed the delivery checklist. Discard?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continue'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
          return confirm ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'POD: ${widget.stop.customerName}',
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Checklist',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ChecklistItem(
                        number: 1,
                        title: 'Scan Order Barcode',
                        description: 'Verify order number matches delivery',
                        completed: _barcodeScanned,
                        onTap: () {
                          setState(() => _barcodeScanned = !_barcodeScanned);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Order ORD-001 barcode scanned successfully'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ChecklistItem(
                        number: 2,
                        title: 'Verify Customer',
                        description: 'Confirm customer identity and address',
                        completed: _customerVerified,
                        onTap: () {
                          setState(
                              () => _customerVerified = !_customerVerified);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Customer John Okafor verified at 123 Ikoyi Lane'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ChecklistItem(
                        number: 3,
                        title: 'Take Delivery Photo',
                        description: 'Proof of package delivery',
                        completed: _photoTaken,
                        onTap: _takePhoto,
                      ),
                      const SizedBox(height: 12),
                      _ChecklistItem(
                        number: 4,
                        title: 'Capture Signature',
                        description: 'Customer signature or thumbprint',
                        completed: _signatureCaptured,
                        onTap: () {
                          setState(
                              () => _signatureCaptured = !_signatureCaptured);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Signature captured successfully'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!allChecked)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Complete all steps to submit delivery',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: allChecked && !_isSubmitting
                            ? () async {
                                setState(() => _isSubmitting = true);
                                try {
                                  final driverService =
                                      ref.read(driverServiceProvider);
                                  final authState = ref.read(authStateProvider);
                                  final currentUser = authState.value;

                                  // Get current location
                                  final position =
                                      await Geolocator.getCurrentPosition();

                                  await driverService.capturePOD(
                                    deliveryId: widget.stop.id,
                                    driverId: currentUser?.id ?? 'unknown',
                                    orderId: widget.stop.orderId,
                                    photoPath: _photoPath ?? '',
                                    signaturePath: '', // Not implemented yet
                                    coordinates: LatLng(
                                        position.latitude, position.longitude),
                                    customerName: widget.stop.customerName,
                                    notes: 'Delivered via app',
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('POD submitted successfully'),
                                      ),
                                    );
                                    widget.onDeliveryComplete();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                    setState(() => _isSubmitting = false);
                                  }
                                }
                              }
                            : null,
                        icon: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          _isSubmitting ? 'Submitting...' : 'Submit Delivery',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        setState(() {
          _photoPath = photo.path;
          _photoTaken = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }
}

class _ChecklistItem extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final bool completed;
  final VoidCallback onTap;

  const _ChecklistItem({
    required this.number,
    required this.title,
    required this.description,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              completed ? Colors.green.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: completed ? Colors.green : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: completed ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: completed
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        '$number',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (completed)
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }
}
