# DriverService API Reference

Quick reference for all DriverService methods, classes, and usage patterns.

## Classes

### `LatLng`
Simple coordinate storage.
```dart
final location = LatLng(
  latitude: 6.4969,   // e.g., Lagos
  longitude: 3.3521,
);

// Convert to/from Map
location.toMap();
LatLng.fromMap({'latitude': 6.4969, 'longitude': 3.3521});
```

### `DriverLocation`
Real-time driver location (for streaming).
```dart
final location = DriverLocation(
  latitude: 6.4969,
  longitude: 3.3521,
  timestamp: DateTime.now(),
  accuracy: 8.5,        // meters
  speed: 15.2,          // m/s
);

location.toMap();
DriverLocation.fromMap(map);
```

### `DeliveryStop`
Single stop on a delivery route.
```dart
final stop = DeliveryStop(
  id: 'STOP-001',
  orderId: 'ORD-001',
  customerName: 'John Okafor',
  address: '123 Ikoyi Lane, Lagos',
  notes: 'Gate code: 1234',
  coordinates: LatLng(6.4969, 3.3521),
  deliveryWindow: '10:00-12:00',
  status: 'pending',  // pending | in_progress | completed | failed
);

DeliveryStop.fromMap(map);
```

### `ProofOfDelivery`
Completed POD record.
```dart
final pod = ProofOfDelivery(
  id: 'POD-ORD-001-1705123456',
  deliveryId: 'DEL-001',
  driverId: 'DRV-001',
  orderId: 'ORD-001',
  photoUrl: 'gs://bucket/pod/DRV-001/ORD-001/photo.jpg',
  signatureUrl: 'gs://bucket/pod/DRV-001/ORD-001/signature.png',
  coordinates: LatLng(6.4969, 3.3521),
  timestamp: DateTime.now(),
  customerName: 'John Okafor',
  notes: 'Delivered at front gate',
);

pod.toMap();
ProofOfDelivery.fromMap(map);
```

### `PODSubmission`
POD during capture (before upload).
```dart
final submission = PODSubmission(
  id: 'PODS-ORD-001',
  orderId: 'ORD-001',
  driverId: 'DRV-001',
  photoPath: '/storage/photos/photo_123.jpg',      // Local file
  signaturePath: '/storage/signatures/sig_123.png', // Local file
  coordinates: LatLng(6.4969, 3.3521),
  timestamp: DateTime.now(),
  status: 'pending_upload',  // pending_upload | uploading | completed | failed
);

submission.toMap();
```

### `DriverStats`
Driver performance metrics.
```dart
final stats = DriverStats(
  driverId: 'DRV-001',
  deliveriesToday: 10,
  completedToday: 8,
  failedToday: 2,
  onTimePercentage: 85.5,
  averageRating: 4.8,
);

DriverStats.fromMap(map);
```

---

## Methods

### `getTodayDeliveries(driverId: String) → Future<List<DeliveryStop>>`

Get all delivery stops for today.

**Usage**:
```dart
final stops = await driverService.getTodayDeliveries('DRV-001');
// Returns: [DeliveryStop(...), DeliveryStop(...), ...]
```

**What it does**:
1. Queries Firestore: `delivery_routes` collection
2. Filters: `assignedDriverId == driverId` AND `date == today`
3. Extracts: `stops` array from route
4. Converts: Each stop to `DeliveryStop` object
5. Returns: List of stops

**Error handling**:
```dart
try {
  final stops = await driverService.getTodayDeliveries(driverId);
  if (stops.isEmpty) {
    // No deliveries scheduled
  }
} catch (e) {
  // Handle error
  print('Failed to get deliveries: $e');
}
```

---

### `recordLocationUpdate(driverId, coordinates, accuracy, speed) → Future<void>`

Save a single GPS location update.

**Usage**:
```dart
await driverService.recordLocationUpdate(
  'DRV-001',
  LatLng(6.4969, 3.3521),
  accuracy: 8.5,    // meters
  speed: 15.2,      // m/s
);
```

**What it does**:
1. Creates `DriverLocationUpdate` object
2. Updates: `drivers/DRV-001` with current location
3. Appends: To `driver_location_history` collection (for analytics)
4. Returns: Void (fire-and-forget)

**Typical pattern** (in a timer):
```dart
Timer.periodic(Duration(seconds: 30), (timer) async {
  final position = await Geolocator.getCurrentPosition();
  await driverService.recordLocationUpdate(
    'DRV-001',
    LatLng(position.latitude, position.longitude),
    position.accuracy,
    position.speed ?? 0,
  );
});
```

---

### `watchDriverLocation(driverId: String) → Stream<DriverLocation>`

Watch driver location in real-time.

**Usage**:
```dart
final locationStream = driverService.watchDriverLocation('DRV-001');
// Use in Riverpod StreamProvider
```

**What it does**:
1. Opens Firestore listener on `driver_locations/DRV-001`
2. Returns: Stream of `DriverLocation` objects
3. Streams: New location every time Firestore updates
4. Closes: When stream is cancelled

**In Riverpod**:
```dart
final driverLocationStreamProvider = StreamProvider<DriverLocation>((ref) {
  final driverId = ref.watch(currentUserProvider)?.id ?? '';
  final driverService = ref.watch(driverServiceProvider);
  return driverService.watchDriverLocation(driverId);
});

// In widget:
final locationAsync = ref.watch(driverLocationStreamProvider);
locationAsync.when(
  data: (location) => Text('Lat: ${location.latitude}'),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

---

### `capturePOD({...}) → Future<String>`

Capture and upload proof of delivery.

**Parameters**:
```dart
await driverService.capturePOD(
  deliveryId: 'DEL-001',         // ID from DeliveryStop
  driverId: 'DRV-001',           // Current driver
  orderId: 'ORD-001',            // Order being delivered
  photoPath: '/path/to/photo.jpg',      // Local file path (from camera)
  signaturePath: '/path/to/sig.png',    // Local file path (from signature pad)
  coordinates: LatLng(6.4969, 3.3521),  // Current GPS location
  customerName: 'John Okafor',          // From DeliveryStop
  notes: 'Delivered at gate',           // Optional driver notes
);
```

**Returns**: POD ID (e.g., `'POD-ORD-001-1705123456'`)

**What it does**:
1. Uploads photo to Firebase Storage: `/pod/DRV-001/ORD-001/photo.jpg`
2. Uploads signature to Firebase Storage: `/pod/DRV-001/ORD-001/signature.png`
3. Creates POD record in Firestore: `proof_of_delivery/{podId}`
4. Updates order status: `orders/ORD-001.status = 'delivered'`
5. Updates delivery route: marks stop as completed
6. Returns: POD ID for receipt

**Typical flow**:
```dart
// In DeliveryChecklistScreen
onPressed: () async {
  try {
    final podId = await ref.read(driverServiceProvider).capturePOD(
      deliveryId: widget.stop.id,
      driverId: currentUserId,
      orderId: widget.stop.orderId,
      photoPath: _capturedPhotoPath,
      signaturePath: _capturedSignaturePath,
      coordinates: _currentGpsLocation,
      customerName: widget.stop.customerName,
      notes: _driverNotes,
    );
    
    // Success!
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('POD submitted: $podId')),
    );
    
    // Close checklist and refresh parent
    Navigator.pop(context);
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
    );
  }
}
```

---

### `updateStopStatus({routeId, stopNumber, status, notes}) → Future<void>`

Update delivery stop status.

**Parameters**:
```dart
await driverService.updateStopStatus(
  routeId: 'ROUTE-001',
  stopNumber: 1,
  status: 'completed',  // pending | in_progress | completed | failed
  notes: 'Delivered successfully',
);
```

**What it does**:
1. Updates: `delivery_routes/ROUTE-001/stops.1.status`
2. Sets: Timestamp for last modification
3. Returns: Void

**Note**: `capturePOD()` automatically calls this, so you usually don't need to call it directly.

---

### `calculateETA(currentLocation: LatLng, nextStopLocation: LatLng) → Duration`

Calculate estimated time to next stop.

**Usage**:
```dart
final eta = driverService.calculateETA(
  LatLng(6.4969, 3.3521),  // Current location
  LatLng(6.5200, 3.3600),  // Next stop
);

print('ETA: ${eta.inMinutes} minutes');  // e.g., "22 minutes"
```

**What it does**:
1. Calculates distance using Haversine formula
2. Estimates travel time: 30 km/h average speed
3. Adds 5 minutes for delivery at next stop
4. Returns: Duration object

**How it's used**:
```dart
// Show ETA to driver
Text(
  'ETA to next stop: ${eta.inMinutes} min',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
);
```

---

### `reportFailedDelivery({orderId, driverId, reason, notes, coordinates}) → Future<void>`

Report that a delivery failed.

**Parameters**:
```dart
await driverService.reportFailedDelivery(
  orderId: 'ORD-001',
  driverId: 'DRV-001',
  reason: 'customer_not_home',  // customer_not_home | wrong_address | damaged | refused
  notes: 'Will try again tomorrow',
  coordinates: LatLng(6.4969, 3.3521),
);
```

**What it does**:
1. Creates failure record: `failed_deliveries/{failureId}`
2. Updates order status: `orders/ORD-001.status = 'failed_delivery'`
3. Stores: Reason, notes, GPS location, timestamp
4. Triggers: Rescheduling workflow (Week 11)

**Typical flow**:
```dart
// Driver taps "Can't Deliver" button
onPressed: () {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Why can\'t you deliver?'),
      actions: [
        TextButton(
          onPressed: () async {
            await driverService.reportFailedDelivery(
              orderId: widget.stop.orderId,
              driverId: currentUserId,
              reason: 'customer_not_home',
              notes: 'Customer not answering',
              coordinates: currentLocation,
            );
            Navigator.pop(context);
          },
          child: Text('Customer not home'),
        ),
        // ... more options
      ],
    ),
  );
}
```

---

### `getDriverStats(driverId: String) → Future<DriverStats?>`

Get driver performance metrics.

**Usage**:
```dart
final stats = await driverService.getDriverStats('DRV-001');

if (stats != null) {
  print('Completed: ${stats.completedToday}/${stats.deliveriesToday}');
  print('On-time: ${stats.onTimePercentage}%');
  print('Rating: ${stats.averageRating} stars');
}
```

**What it does**:
1. Queries: `drivers/DRV-001` document
2. Extracts: Metrics (completedToday, failedToday, rating, etc.)
3. Returns: DriverStats object

**Used by**: Dispatch dashboard, driver performance screen (Week 12)

---

### `completeRoute(routeId: String) → Future<void>`

Mark entire route as completed.

**Usage**:
```dart
await driverService.completeRoute('ROUTE-001');
```

**What it does**:
1. Updates: `delivery_routes/ROUTE-001.status = 'completed'`
2. Sets: Completion timestamp
3. Returns: Void

**When to call**:
- After driver completes the last delivery in route
- After uploading final POD

---

### `startLocationTracking(driverId: String) → Future<void>`

Initialize location tracking (placeholder).

**Usage**:
```dart
// Called when driver starts their route
await driverService.startLocationTracking('DRV-001');
```

**Note**: Currently just prints debug message. Implementation depends on geolocator setup in Week 10.

---

### `stopLocationTracking(driverId: String) → Future<void>`

Stop location tracking (placeholder).

**Usage**:
```dart
// Called when driver ends their route
await driverService.stopLocationTracking('DRV-001');
```

---

## Firestore Collections

### `pod_submissions/{podId}`
Proof of delivery records.
```dart
{
  'id': 'POD-ORD-001-1705123456',
  'orderId': 'ORD-001',
  'driverId': 'DRV-001',
  'photoUrl': 'gs://bucket/pod/DRV-001/ORD-001/photo.jpg',
  'signatureUrl': 'gs://bucket/pod/DRV-001/ORD-001/signature.png',
  'coordinates': {
    'latitude': 6.4969,
    'longitude': 3.3521,
  },
  'timestamp': '2024-01-15T14:30:00Z',
  'customerName': 'John Okafor',
  'notes': '',
}
```

### `driver_locations/{driverId}`
Real-time driver location.
```dart
{
  'driverId': 'DRV-001',
  'currentLocation': {
    'latitude': 6.4969,
    'longitude': 3.3521,
  },
  'lastLocationUpdate': '2024-01-15T14:32:00Z',
  'accuracy': 8.5,
  'speed': 15.2,
}
```

### `driver_location_history/{driverId}-{timestamp}`
Historical location data (for analytics).
```dart
{
  'driverId': 'DRV-001',
  'coordinates': {
    'latitude': 6.4969,
    'longitude': 3.3521,
  },
  'timestamp': '2024-01-15T14:32:00Z',
  'accuracy': 8.5,
  'speed': 15.2,
}
```

### `failed_deliveries/{failureId}`
Failed delivery records.
```dart
{
  'id': 'FAIL-ORD-001-1705123456',
  'orderId': 'ORD-001',
  'driverId': 'DRV-001',
  'reason': 'customer_not_home',
  'notes': 'Will try tomorrow',
  'coordinates': {
    'latitude': 6.4969,
    'longitude': 3.3521,
  },
  'timestamp': '2024-01-15T15:00:00Z',
  'status': 'pending_action',
}
```

---

## Common Patterns

### Pattern 1: Get Today's Deliveries and Display
```dart
// In ConsumerWidget
final deliveriesAsync = ref.watch(todayDeliveriesProvider);

return deliveriesAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
  data: (deliveries) {
    return ListView.builder(
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final stop = deliveries[index];
        return ListTile(
          title: Text(stop.customerName),
          subtitle: Text(stop.address),
        );
      },
    );
  },
);
```

### Pattern 2: Complete a Delivery
```dart
onPressed: () async {
  try {
    // Capture POD
    final podId = await ref.read(driverServiceProvider).capturePOD(
      deliveryId: stop.id,
      driverId: userId,
      orderId: stop.orderId,
      photoPath: photoPath,
      signaturePath: signaturePath,
      coordinates: currentGps,
      customerName: stop.customerName,
    );
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delivered! POD: $podId')),
    );
    
    // Move to next stop
    setState(() => currentStopIndex++);
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Pattern 3: Watch Driver Location
```dart
// In map screen (Week 12)
final locationAsync = ref.watch(driverLocationStreamProvider);

return locationAsync.when(
  data: (location) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(location.latitude, location.longitude),
        zoom: 16,
      ),
      markers: {
        Marker(
          markerId: MarkerId('driver'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(text: 'Driver Location'),
        ),
      },
    );
  },
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

### Pattern 4: Update Status Manually
```dart
// If not using capturePOD (e.g., manual button)
onPressed: () async {
  await ref.read(driverServiceProvider).updateStopStatus(
    routeId: route.id,
    stopNumber: stopIndex,
    status: 'completed',
    notes: 'Completed manually',
  );
}
```

---

## Error Handling

### Try-Catch Pattern
```dart
try {
  final stops = await driverService.getTodayDeliveries(driverId);
} on FirebaseException catch (e) {
  print('Firestore error: ${e.code}');
} catch (e) {
  print('Unknown error: $e');
}
```

### Riverpod Error Handling
```dart
final deliveriesAsync = ref.watch(todayDeliveriesProvider);

deliveriesAsync.whenData((deliveries) {
  // Use the data
});

deliveriesAsync.whenError((error, stackTrace) {
  // Handle the error
  print('Error: $error');
});
```

---

## Testing

### Unit Test Example
```dart
test('calculateETA returns correct duration', () {
  final service = DriverService();
  final eta = service.calculateETA(
    LatLng(6.0, 3.0),
    LatLng(6.1, 3.1),
  );
  
  // Should take ~7-8 minutes
  expect(eta.inMinutes, greaterThan(5));
  expect(eta.inMinutes, lessThan(15));
});
```

### Integration Test Example
```dart
testWidgets('Driver can complete delivery', (WidgetTester tester) async {
  // Create test order
  // Assign to test driver
  // Start driver app
  // Complete checklist
  // Verify order marked delivered
});
```

---

## Troubleshooting

### GPS Not Updating?
Check `driver_locations/{driverId}` document in Firestore console.

### POD Upload Failing?
1. Check Firebase Storage quota
2. Verify bucket rules allow write
3. Verify file paths don't have special characters

### DeliveryStop Missing Fields?
Check that `delivery_routes` route has all required fields in stops array.

---

**Last Updated**: January 27, 2025  
**Version**: 1.0  
**Status**: Ready for implementation

