import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/checkpoint_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/location_handler.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

part 'delivery_viewmodel.g.dart';

@riverpod
class DeliveryViewModel extends _$DeliveryViewModel {
  @override
  FutureOr<void> build() {}

  Future<void> checkIn(File? imageFile, String? notes) async {
    state = const AsyncValue.loading();
    
    try {
      final user = ref.read(authViewModelProvider).value;
      if (user == null) throw Exception("User not authenticated");

      // 1. Get Location (throws detailed exceptions if fails)
      final position = await LocationHandler.getCurrentPosition();
      // 'position' is now guaranteed to be non-null if no exception is thrown

      // 2. Upload Photo (Optional & Safe)
      String photoUrl = '';
      if (imageFile != null) {
        try {
          final storageService = ref.read(storageServiceProvider);
          final uploadedUrl = await storageService.uploadCheckinPhoto(user.uid, imageFile);
          if (uploadedUrl != null) {
            photoUrl = uploadedUrl;
          }
        } catch (e) {
          // If Firebase Storage fails (e.g. not on Blaze plan), we ignore the error 
          // so the delivery man can still check in with GPS and notes.
          print('Warning: Failed to upload photo, proceeding without it. Error: $e');
        }
      }

      // 3. Save to Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      final checkpoint = CheckpointModel(
        checkpointId: '', // Handled by Firestore
        deliveryManId: user.uid,
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        photoUrl: photoUrl,
        notes: notes,
        taskId: user.currentTaskStartedAt?.toIso8601String() ?? 
            DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String(),
      );

      await firestoreService.saveCheckpoint(checkpoint);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markCompleted() async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authViewModelProvider).value;
      if (user == null) throw Exception("User not authenticated");

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.markUserCompleted(user.uid, true);

      // We should also trigger an update of the auth user state so the UI reacts.
      // But we can just invalidate the auth provider or update it directly.
      ref.invalidate(authViewModelProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startNewTask() async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authViewModelProvider).value;
      if (user == null) throw Exception("User not authenticated");

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.startNewTask(user.uid);

      ref.invalidate(authViewModelProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
