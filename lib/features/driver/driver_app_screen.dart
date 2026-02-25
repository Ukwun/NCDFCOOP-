import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong2.dart'; // TODO: Fix latlong2 package dependency
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/services/driver_service.dart';
import 'package:coop_commerce/core/services/location_service.dart';
import 'package:coop_commerce/providers/logistics_providers.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:coop_commerce/features/driver/signature_canvas_screen.dart';
import 'package:coop_commerce/features/driver/driver_route_map_screen.dart';

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
  String? _photoPath;
  List<Offset?>? _signaturePoints;
  Position? _currentPosition;
  String _notes = '';
  bool _isSubmittingPOD = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationService = LocationService();
    try {
      final position = await locationService.getCurrentPosition();
      if (position != null) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load today's deliveries from provider
    final deliveriesAsync = ref.watch(todayDeliveriesProvider);
    final authState = ref.watch(authStateProvider);

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
            icon: const Icon(Icons.map, color: Colors.blue),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DriverRouteMapScreen(),
                ),
              );
            },
            tooltip: 'View Route Map',
          ),
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
                // POD Capture Section
                if (_photoPath == null || _signaturePoints == null)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _capturePhoto(context, stop),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(_photoPath == null
                              ? 'Capture Photo'
                              : '✓ Photo Captured'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _photoPath != null ? Colors.green : null,
                            foregroundColor:
                                _photoPath != null ? Colors.white : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _captureSignature(context, stop),
                          icon: const Icon(Icons.edit),
                          label: Text(_signaturePoints == null
                              ? 'Get Signature'
                              : '✓ Signature Captured'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _signaturePoints != null ? Colors.green : null,
                            foregroundColor:
                                _signaturePoints != null ? Colors.white : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Delivery notes (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.note),
                        ),
                        onChanged: (value) => setState(() => _notes = value),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_photoPath != null &&
                                  _signaturePoints != null &&
                                  !_isSubmittingPOD)
                              ? () => _submitPOD(context, stop)
                              : null,
                          icon: _isSubmittingPOD
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: const Text('Complete Delivery'),
                        ),
                      ),
                    ],
                  )
                else
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 8),
                        const Text('POD Submitted Successfully'),
                      ],
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
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey[400]),
              onTap: () {
                setState(
                    () => _currentStopIndex = _currentStopIndex + 1 + index);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _capturePhoto(BuildContext context, DeliveryStop stop) async {
    final imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Capture Photo'),
        content: const Text('Choose photo source'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final pickedFile =
                  await imagePicker.pickImage(source: ImageSource.camera);
              if (pickedFile != null) {
                setState(() => _photoPath = pickedFile.path);
              }
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final pickedFile =
                  await imagePicker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() => _photoPath = pickedFile.path);
              }
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureSignature(
      BuildContext context, DeliveryStop stop) async {
    final signature = await Navigator.push<List<Offset?>>(
      context,
      MaterialPageRoute(
        builder: (context) => SignatureCanvasScreen(
          deliveryId: stop.id,
          customerName: stop.customerName,
        ),
      ),
    );

    if (signature != null) {
      setState(() => _signaturePoints = signature);
    }
  }

  Future<void> _submitPOD(BuildContext context, DeliveryStop stop) async {
    if (_photoPath == null ||
        _signaturePoints == null ||
        _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing required POD information')),
      );
      return;
    }

    setState(() => _isSubmittingPOD = true);

    try {
      final driverService = ref.read(driverServiceProvider);
      final authState = ref.read(authStateProvider).value;
      final driverId = authState?.id ?? 'unknown';

      // Convert signature to file path (simplified)
      final signatureFile =
          '/tmp/signature_${DateTime.now().millisecondsSinceEpoch}.png';

      final podId = await driverService.capturePOD(
        deliveryId: stop.id,
        driverId: driverId,
        orderId: stop.orderId,
        photoPath: _photoPath!,
        signaturePath: signatureFile,
        coordinates:
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        customerName: stop.customerName,
        notes: _notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery completed! POD: $podId')),
        );

        setState(() {
          _currentStopIndex++;
          _photoPath = null;
          _signaturePoints = null;
          _notes = '';
          _isSubmittingPOD = false;
        });

        // Refresh delivery list
        ref.refresh(todayDeliveriesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting POD: $e')),
        );
        setState(() => _isSubmittingPOD = false);
      }
    }
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
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
