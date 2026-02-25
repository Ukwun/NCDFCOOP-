import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coop_commerce/core/services/driver_service.dart';
import 'package:coop_commerce/providers/logistics_providers.dart';

/// Simple state for POD data collection
class PodDataState {
  final String? photoPath;
  final List<int>? signatureBytes;
  final String? notes;

  const PodDataState({
    this.photoPath,
    this.signatureBytes,
    this.notes,
  });

  PodDataState copyWith({
    String? photoPath,
    List<int>? signatureBytes,
    String? notes,
  }) {
    return PodDataState(
      photoPath: photoPath ?? this.photoPath,
      signatureBytes: signatureBytes ?? this.signatureBytes,
      notes: notes ?? this.notes,
    );
  }
}

/// Notifier for POD data
class PodDataNotifier extends Notifier<PodDataState> {
  @override
  PodDataState build() {
    return const PodDataState();
  }

  void setPhotoPath(String path) {
    state = state.copyWith(photoPath: path);
  }

  void setSignatureBytes(List<int> bytes) {
    state = state.copyWith(signatureBytes: bytes);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void reset() {
    state = const PodDataState();
  }
}

/// Provider for managing POD data
final podDataProvider =
    NotifierProvider.autoDispose<PodDataNotifier, PodDataState>(() {
  return PodDataNotifier();
});

/// Provider for camera photo capture
final cameraPhotoProvider = FutureProvider.autoDispose<String?>((ref) async {
  final picker = ImagePicker();
  final photo = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  return photo?.path;
});

/// Provider for gallery photo selection
final galleryPhotoProvider = FutureProvider.autoDispose<String?>((ref) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  return image?.path;
});

/// Provider for accessing DriverService to call capturePOD
final podSubmissionProvider = Provider<DriverService>((ref) {
  return ref.watch(driverServiceProvider);
});
