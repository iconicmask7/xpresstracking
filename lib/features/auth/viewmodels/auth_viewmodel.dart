import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';

part 'auth_viewmodel.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  FutureOr<UserModel?> build() async {
    final authService = ref.watch(authServiceProvider);
    
    // Listen to auth state changes
    final user = authService.currentUser;
    if (user != null) {
      return _fetchUserRole(user.uid);
    }
    return null;
  }

  Future<UserModel?> _fetchUserRole(String uid) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    return await firestoreService.getUser(uid);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final userModel = await _fetchUserRole(credential.user!.uid);
        state = AsyncValue.data(userModel);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final newUser = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: 'delivery_man',
          createdAt: DateTime.now(),
        );
        
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.createUser(newUser);
        
        state = AsyncValue.data(newUser);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    state = const AsyncValue.data(null);
  }
}
