import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/delivery_viewmodel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animated_button.dart';
import '../../../core/utils/glass_card.dart';
import '../../../core/utils/error_handler.dart';
import '../../../models/checkpoint_model.dart';

class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  ConsumerState<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends ConsumerState<DeliveryHomeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Try to get a photo, but don't fail if the user skips/cancels
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (!mounted) return;

    final file = pickedFile != null ? File(pickedFile.path) : null;
    await ref.read(deliveryViewModelProvider.notifier).checkIn(
          file,
          _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        );

    if (!mounted) return;

    final state = ref.read(deliveryViewModelProvider);
    if (!state.hasError) {
      _showSnack('✅ Check-in recorded!');
      _notesController.clear();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(deliveryViewModelProvider, (previous, next) {
      if (next.hasError && next.error != null) {
        _showSnack(ErrorHandler.getFriendlyMessage(next.error!), isError: true);
      }
    });

    final state = ref.watch(deliveryViewModelProvider);
    final userState = ref.watch(authViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = userState.value?.name ?? 'Delivery Partner';
    final uid = userState.value?.uid ?? '';
    final isCompleted = userState.value?.isCompleted ?? false;
    final checkpointsAsync = ref.watch(userCheckpointsProvider(uid));
    
    // Filter checkpoints to only show those for the CURRENT task session
    final now = DateTime.now();
    final taskStartTime = userState.value?.currentTaskStartedAt ?? 
        DateTime(now.year, now.month, now.day);
        
    final checkpoints = (checkpointsAsync.value ?? []).where((c) {
      return c.timestamp.isAfter(taskStartTime) || c.timestamp.isAtSameMomentAs(taskStartTime);
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        drawer: _buildDrawer(context, isDark),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(context, isDark, userName, state.isLoading),
            ),

            // ── Check-In Card or Completed Banner ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: isCompleted
                    ? _buildCompletedBanner(context, isDark)
                    : _buildCheckInCard(context, isDark, state.isLoading),
              ),
            ),

            // ── Recent Check-ins Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Check-ins',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${checkpoints.length} total',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Check-ins List ───────────────────────────────────────────────
            ...(() {
              if (checkpointsAsync.isLoading) {
                return List.generate(
                  3,
                  (i) => SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                      child: ShimmerCard(height: 80.h),
                    ),
                  ),
                );
              }
              if (checkpointsAsync.hasError) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Text(
                        'Error loading check-ins:\n${checkpointsAsync.error}',
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ];
              }
              if (checkpoints.isEmpty) {
                return [
                  SliverToBoxAdapter(child: _buildEmptyState(context)),
                ];
              }
              return [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _CheckpointTile(
                      checkpoint: checkpoints[i],
                      index: i,
                    ),
                    childCount: checkpoints.length,
                  ),
                ),
              ];
            })(),

            if (!isCompleted)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 48.h),
                  child: GradientButton(
                    onPressed: state.isLoading ? () {} : _handleCompleteOrder,
                    label: 'Mark as Completed',
                    isLoading: state.isLoading,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 32.h)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Tasks'),
        content: const Text('Are you sure you want to mark all tasks as completed for today? You will not be able to check in anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(deliveryViewModelProvider.notifier).markCompleted();
  }

  Widget _buildCompletedBanner(BuildContext context, bool isDark) {
    return GlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              'Tasks Completed!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have marked your assigned tasks as completed. Great job!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleStartNewTask(context),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Start New Check Point'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
    );
  }

  Future<void> _handleStartNewTask(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start New Check Point'),
        content: const Text('Are you sure you want to start a new check point and reset your completed status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Start'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(deliveryViewModelProvider.notifier).startNewTask(    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                const Text('Delivery Dashboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text('Tracking History', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.push('/tracking-history');
            },
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedPressButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(authViewModelProvider.notifier).logout();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    String userName,
    bool isLoading,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 32.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF151831), const Color(0xFF1A1D38)]
              : [const Color(0xFFEDF0FF), AppColors.lightBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    _greeting(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms),
                  SizedBox(height: 2.h),
                  Text(
                    userName.split(' ').first,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1),
                ],
              ),
              ],
            ),
              // Avatar with pulse
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha:0.3 + _pulseAnimation.value * 0.15),
                        blurRadius: 12 + _pulseAnimation.value * 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),

              // Logout
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success
                            .withValues(alpha:0.4 + _pulseAnimation.value * 0.4),
                        blurRadius: 4 + _pulseAnimation.value * 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'On duty • Ready for check-in',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              _LogoutButton(),
            ],
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildCheckInCard(BuildContext context, bool isDark, bool isLoading) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Check-In',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Capture your current location',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _notesController,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Please enter a valid note (min 3 chars)';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'Add check-in notes...',
                prefixIcon: Icon(Icons.edit_note_rounded, size: 22, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: isLoading ? 'Checking in...' : 'Check-In Now',
            onPressed: isLoading ? null : _handleCheckIn,
            isLoading: isLoading,
            icon: Icons.my_location_rounded,
          ),
        ],
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        children: [
          Icon(Icons.location_off_rounded,
              size: 64, color: AppColors.lightTextSecondary.withValues(alpha:0.5)),
          const SizedBox(height: 16),
          Text(
            'No check-ins yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Start by capturing your first location.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ).animate().fadeIn(delay: 300.ms),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌅';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedPressButton(
      onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, size: 14, color: AppColors.error),
            SizedBox(width: 4),
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
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  final CheckpointModel checkpoint;
  final int index;

  const _CheckpointTile({required this.checkpoint, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      child: Container(
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
                    color: AppColors.primary.withValues(alpha:0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ListTile(
          onTap: () => context.push('/checkpoint-details', extra: checkpoint),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(
            DateFormat('MMM dd, yyyy • hh:mm a')
                .format(checkpoint.timestamp),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: checkpoint.notes != null && checkpoint.notes!.isNotEmpty
              ? Text(
                  checkpoint.notes!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  'No notes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.primary, size: 20),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
