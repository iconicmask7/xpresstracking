import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import '../models/checkpoint_model.dart';

part 'firestore_service.g.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> markUserCompleted(String uid, bool status) async {
    final updateData = <String, dynamic>{'isCompleted': status};
    if (status) {
      updateData['totalCompletedTasks'] = FieldValue.increment(1);
    }
    await _firestore.collection('users').doc(uid).update(updateData);
  }

  Future<void> startNewTask(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isCompleted': false,
      'currentTaskStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<UserModel>> getDeliveryMen() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'delivery_man')
        .get();
        
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<UserModel>> getDeliveryMenStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'delivery_man')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveCheckpoint(CheckpointModel checkpoint) async {
    await _firestore.collection('checkpoints').add({
      'deliveryManId': checkpoint.deliveryManId,
      'timestamp': FieldValue.serverTimestamp(),
      'location': {
        'latitude': checkpoint.latitude,
        'longitude': checkpoint.longitude,
      },
      'photoUrl': checkpoint.photoUrl,
      'notes': checkpoint.notes,
      if (checkpoint.taskId != null) 'taskId': checkpoint.taskId,
    });
  }

  Stream<List<CheckpointModel>> getCheckpointsForUser(String deliveryManId) {
    return _firestore
        .collection('checkpoints')
        .where('deliveryManId', isEqualTo: deliveryManId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CheckpointModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}

@riverpod
FirestoreService firestoreService(FirestoreServiceRef ref) {
  return FirestoreService(FirebaseFirestore.instance);
}
