import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/user_model.dart';
import '../../../models/checkpoint_model.dart';
import '../../../services/firestore_service.dart';

part 'admin_viewmodel.g.dart';

@riverpod
class AdminViewModel extends _$AdminViewModel {
  @override
  Stream<List<UserModel>> build() {
    return _fetchDeliveryMenStream();
  }

  Stream<List<UserModel>> _fetchDeliveryMenStream() {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return firestoreService.getDeliveryMenStream();
  }
}

@riverpod
Stream<List<CheckpointModel>> userCheckpoints(UserCheckpointsRef ref, String deliveryManId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCheckpointsForUser(deliveryManId);
}
