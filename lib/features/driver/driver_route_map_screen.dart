import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/driver_service.dart'
    show LatLng, DeliveryStop;
import 'package:coop_commerce/providers/logistics_providers.dart';
import 'package:geolocator/geolocator.dart';

/// Screen displaying driver's route on a map
/// Shows all delivery stops, current location, and navigation
class DriverRouteMapScreen extends ConsumerStatefulWidget {
  const DriverRouteMapScreen({super.key});

  @override
  ConsumerState<DriverRouteMapScreen> createState() =>
      _DriverRouteMapScreenState();
}

class _DriverRouteMapScreenState extends ConsumerState<DriverRouteMapScreen> {
  late fm.MapController _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // ignore: deprecated_member_use
      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Center map on current location
      _mapController.move(
        ll.LatLng(position.latitude, position.longitude),
        15,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(todayDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Center on my location',
          ),
        ],
      ),
      body: deliveriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading route: $error'),
        ),
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return const Center(child: Text('No deliveries today'));
          }

          // Build markers for all delivery stops
          final markers = <fm.Marker>[];

          // Add current location marker
          if (_currentLocation != null) {
            markers.add(
              fm.Marker(
                point: ll.LatLng(
                  _currentLocation!.latitude,
                  _currentLocation!.longitude,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            );
          }

          // Add delivery stop markers
          for (int i = 0; i < deliveries.length; i++) {
            final delivery = deliveries[i];
            final isCompleted = delivery.status == 'completed';
            final isActive = i == 0 && !isCompleted;

            markers.add(
              fm.Marker(
                point: ll.LatLng(
                  delivery.coordinates.latitude,
                  delivery.coordinates.longitude,
                ),
                child: GestureDetector(
                  onTap: () => _showDeliveryDetails(delivery),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green
                          : isCompleted
                              ? Colors.grey
                              : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Calculate bounds for all markers
          if (markers.isEmpty) {
            return const Center(child: Text('No location data available'));
          }

          return fm.FlutterMap(
            mapController: _mapController,
            options: fm.MapOptions(
              initialCenter: ll.LatLng(
                deliveries.first.coordinates.latitude,
                deliveries.first.coordinates.longitude,
              ),
              initialZoom: 14,
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              fm.MarkerLayer(markers: markers),
              fm.PolylineLayer(
                polylines: [
                  fm.Polyline(
                    points: deliveries
                        .map((d) => ll.LatLng(
                              d.coordinates.latitude,
                              d.coordinates.longitude,
                            ))
                        .toList(),
                    color: Colors.blue,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomSheet: deliveriesAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (deliveries) => _buildDeliveryStats(deliveries),
      ),
    );
  }

  void _showDeliveryDetails(DeliveryStop delivery) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                delivery.customerName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(delivery.address),
              const SizedBox(height: 8),
              if (delivery.notes != null && delivery.notes!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notes:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(delivery.notes!),
                  ],
                ),
              const SizedBox(height: 16),
              if (delivery.status != 'completed')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToDelivery(delivery);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Navigate'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDelivery(DeliveryStop delivery) {
    // Launch Google Maps with destination
    // import 'package:url_launcher/url_launcher.dart';
    // final url =
    //     'https://www.google.com/maps/dir/?api=1&destination=${delivery.coordinates.latitude},${delivery.coordinates.longitude}';
    // launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _buildDeliveryStats(List<DeliveryStop> deliveries) {
    final completed = deliveries.where((d) => d.status == 'completed').length;
    final remaining = deliveries.length - completed;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completed',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text('Completed'),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remaining',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Text('Remaining'),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${deliveries.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Text('Total'),
            ],
          ),
        ],
      ),
    );
  }
}
