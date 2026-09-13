import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animated_button.dart';
import '../../../core/utils/glass_card.dart';
import '../../../models/user_model.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deliveryMen = state.value ?? [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async =>
              ref.invalidate(adminViewModelProvider),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(
                    context, isDark, deliveryMen.length, state.isLoading),
              ),

              // ── Stats Row ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  child: _buildStatsRow(context, isDark, deliveryMen),
                ),
              ),

              // ── List header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                  child: Text(
                    'Delivery Partners',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),

              // ── List ────────────────────────────────────────────────────────
              state.when(
                data: (users) => users.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyState(context),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _DeliveryManTile(
                            user: users[i],
                            index: i,
                            onTap: () =>
                                context.push('/admin/partner-details', extra: users[i]),
                          ),
                          childCount: users.length,
                        ),
                      ),
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                      child: ShimmerCard(height: 80.h),
                    ),
                    childCount: 4,
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: GlassCard(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 40),
                          const SizedBox(height: 8),
                          Text('Failed to load: $e',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 32.h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    int count,
    bool loading,
  ) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 28.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF151831),
                    Color.lerp(
                      const Color(0xFF151831),
                      const Color(0xFF1A2045),
                      _headerAnimation.value,
                    )!,
                  ]
                : [
                    const Color(0xFFEDF0FF),
                    Color.lerp(
                      const Color(0xFFEDF0FF),
                      const Color(0xFFDDE3FF),
                      _headerAnimation.value,
                    )!,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                SizedBox(height: 4.h),
                Text(
                  'Manage your delivery fleet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate(delay: 100.ms).fadeIn(),
              ],
            ),
            AnimatedPressButton(
              onPressed: () =>
                  ref.read(authViewModelProvider.notifier).logout(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, size: 14, color: AppColors.error),
                    SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, bool isDark, List<UserModel> users) {
    final totalCount = users.length;
    final activeCount = users.where((u) => !u.isCompleted).length;
    final completedCount = users.fold<int>(0, (sum, u) => sum + u.totalCompletedTasks);
    
    final stats = [
      _StatData('Total', '$totalCount', Icons.people_alt_rounded, AppColors.primary),
      _StatData(
          'Active', '$activeCount', Icons.directions_run_rounded, AppColors.warning),
      _StatData('Completed', '$completedCount', Icons.event_available_rounded, AppColors.success),
    ];

    return Row(
      children: stats
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: e.key < 2 ? 10.w : 0),
                child: _StatCard(data: e.value).animate(
                  delay: Duration(milliseconds: 200 + e.key * 100),
                ).fadeIn(duration: 400.ms).slideY(begin: 0.2),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 64.h),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded,
              size: 64, color: AppColors.lightTextSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No delivery partners yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Partners will appear once they sign in.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ).animate().fadeIn(delay: 300.ms),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: data.color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: data.color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DeliveryManTile extends StatelessWidget {
  final UserModel user;
  final int index;
  final VoidCallback onTap;

  const _DeliveryManTile({
    required this.user,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.accent,
    ];
    final color = colors[index % colors.length];

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      child: AnimatedPressButton(
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isCompleted)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.08, curve: Curves.easeOutCubic);
  }
}
