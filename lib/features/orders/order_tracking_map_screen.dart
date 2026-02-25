import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/order_providers.dart';
import 'package:coop_commerce/core/providers/real_time_providers.dart';

/// Real-time delivery tracking map screen showing driver location and ETA
class OrderTrackingMapScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingMapScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingMapScreen> createState() =>
      _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState
    extends ConsumerState<OrderTrackingMapScreen> {
  gmf.GoogleMapController? _mapController;
  final Set<gmf.Marker> _markers = {};
  final Set<gmf.Polyline> _polylines = {};

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Update map camera to show both driver and delivery locations
  Future<void> _updateMapCamera(
    gmf.LatLng driverLocation,
    gmf.LatLng deliveryLocation,
  ) async {
    if (_mapController == null) return;

    final bounds = gmf.LatLngBounds(
      southwest: gmf.LatLng(
        driverLocation.latitude < deliveryLocation.latitude
            ? driverLocation.latitude
            : deliveryLocation.latitude,
        driverLocation.longitude < deliveryLocation.longitude
            ? driverLocation.longitude
            : deliveryLocation.longitude,
      ),
      northeast: gmf.LatLng(
        driverLocation.latitude > deliveryLocation.latitude
            ? driverLocation.latitude
            : deliveryLocation.latitude,
        driverLocation.longitude > deliveryLocation.longitude
            ? driverLocation.longitude
            : deliveryLocation.longitude,
      ),
    );

    final cameraUpdate = gmf.CameraUpdate.newLatLngBounds(bounds, 100);
    await _mapController!.animateCamera(cameraUpdate);
  }

  /// Build driver location marker
  gmf.Marker _buildDriverMarker(
    String driverId,
    double latitude,
    double longitude,
    double heading,
    String driverName,
  ) {
    return gmf.Marker(
      markerId: gmf.MarkerId('driver_$driverId'),
      position: gmf.LatLng(latitude, longitude),
      infoWindow: gmf.InfoWindow(
        title: driverName,
        snippet: 'En route to delivery',
      ),
      icon: gmf.BitmapDescriptor.defaultMarkerWithHue(
        gmf.BitmapDescriptor.hueBlue,
      ),
    );
  }

  /// Build delivery location marker
  gmf.Marker _buildDeliveryMarker(double latitude, double longitude) {
    return gmf.Marker(
      markerId: const gmf.MarkerId('delivery_location'),
      position: gmf.LatLng(latitude, longitude),
      infoWindow: const gmf.InfoWindow(
        title: 'Delivery Location',
        snippet: 'Your package will be delivered here',
      ),
      icon: gmf.BitmapDescriptor.defaultMarkerWithHue(
        gmf.BitmapDescriptor.hueGreen,
      ),
    );
  }

  /// Build polyline connecting driver to delivery
  gmf.Polyline _buildRouteLine(
    gmf.LatLng driverLocation,
    gmf.LatLng deliveryLocation,
  ) {
    return gmf.Polyline(
      polylineId: const gmf.PolylineId('route'),
      points: [driverLocation, deliveryLocation],
      color: AppColors.primary,
      width: 4,
      geodesic: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    // Real-time driver location and ETA
    final driverLocationAsync =
        ref.watch(driverLocationSyncProvider('driver_id_here'));
    final deliveryETAAsync =
        ref.watch(deliveryETAUpdateProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Delivery Tracking'),
        elevation: 0,
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null || order.shippingAddress.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No delivery address',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final deliveryLocation = gmf.LatLng(
            6.9271, // Default Lagos coordinates
            3.1449, // These would normally come from order.deliveryLocation or geocoding
          );

          return Stack(
            children: [
              // Map view
              driverLocationAsync.when(
                data: (driverLocation) {
                  // Update markers when driver location changes
                  _markers.clear();
                  _polylines.clear();

                  final driverLatLng = gmf.LatLng(
                    driverLocation.latitude,
                    driverLocation.longitude,
                  );

                  _markers.add(
                    _buildDriverMarker(
                      driverLocation.driverId,
                      driverLocation.latitude,
                      driverLocation.longitude,
                      driverLocation.heading ?? 0.0,
                      'Driver (${(driverLocation.speed ?? 0.0).toInt()} km/h)',
                    ),
                  );

                  _markers.add(
                    _buildDeliveryMarker(
                      deliveryLocation.latitude,
                      deliveryLocation.longitude,
                    ),
                  );

                  _polylines.add(
                    _buildRouteLine(driverLatLng, deliveryLocation),
                  );

                  // Schedule camera update
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateMapCamera(driverLatLng, deliveryLocation);
                  });

                  return gmf.GoogleMap(
                    initialCameraPosition: gmf.CameraPosition(
                      target: driverLatLng,
                      zoom: 15,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    myLocationButtonEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_disabled_outlined,
                        size: 64,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Waiting for driver location...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ETA Card (Real-Time)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: deliveryETAAsync.when(
                  data: (eta) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppShadows.md],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Driver Info
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eta.driverName ?? 'Driver',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      eta.driverPhone ?? 'N/A',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ETA Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Arriving in',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${eta.minutesToDelivery} min',
                                      style: AppTextStyles.h3.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Distance',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${(eta.distanceToDelivery ?? 0.0).toStringAsFixed(1)} km',
                                      style: AppTextStyles.h4.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Vehicle Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    eta.vehicleInfo ?? 'Vehicle info',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Contact Driver Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.call),
                              label: const Text('Call Driver'),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Calling ${eta.driverName}...',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [AppShadows.md],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [AppShadows.md],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'ETA unavailable',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load order',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
