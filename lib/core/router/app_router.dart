import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/delivery/views/delivery_home_screen.dart';
import '../../features/admin/views/admin_dashboard_screen.dart';
import '../../features/admin/views/admin_partner_details_screen.dart';
import '../../features/admin/views/route_map_screen.dart';
import '../../features/shared/views/checkpoint_details_screen.dart';
import '../../features/delivery/views/tracking_history_screen.dart';
import '../../features/delivery/views/tracking_history_details_screen.dart';
import '../../models/user_model.dart';
import '../../models/checkpoint_model.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';
      final userModel = authState.value;

      final isLoading = authState.isLoading || authState.isReloading;
      
      // Prevent redirect flash during reloading if we still have a user
      if (isLoading && !authState.hasValue) return null;

      if (userModel == null) {
        return (isLoggingIn || isRegistering) ? null : '/login';
      }

      if (isLoggingIn || isRegistering) {
        if (userModel.role == 'admin') {
          return '/admin';
        } else {
          return '/delivery';
        }
      }

      // Check role access
      final isAdminRoute = state.uri.toString().startsWith('/admin');
      if (isAdminRoute && userModel.role != 'admin') {
        return '/delivery'; // Prevent delivery men from accessing admin routes
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/delivery',
        builder: (context, state) => const DeliveryHomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'partner-details',
            builder: (context, state) {
              final user = state.extra as UserModel;
              return AdminPartnerDetailsScreen(deliveryMan: user);
            },
          ),
          GoRoute(
            path: 'route-map',
            builder: (context, state) {
              final user = state.extra as UserModel;
              return RouteMapScreen(deliveryMan: user);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/checkpoint-details',
        builder: (context, state) {
          final checkpoint = state.extra as CheckpointModel;
          return CheckpointDetailsScreen(checkpoint: checkpoint);
        },
      ),
      GoRoute(
        path: '/tracking-history',
        builder: (context, state) => const TrackingHistoryScreen(),
      ),
      GoRoute(
        path: '/tracking-history-details',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return TrackingHistoryDetailsScreen(
            date: data['date'] as String,
            checkpoints: data['checkpoints'] as List<CheckpointModel>,
          );
        },
      ),
    ],
  );
}
