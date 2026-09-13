import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/glass_card.dart';
import '../../../models/user_model.dart';
import '../../../models/checkpoint_model.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';

class AdminPartnerDetailsScreen extends ConsumerWidget {
  final UserModel deliveryMan;

  const AdminPartnerDetailsScreen({super.key, required this.deliveryMan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checkpointsAsync = ref.watch(userCheckpointsProvider(deliveryMan.uid));

    final currentTaskId = deliveryMan.currentTaskStartedAt?.toIso8601String() ?? 
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(deliveryMan.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: checkpointsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (checkpoints) {
          final ongoingCheckpoints = checkpoints.where((c) => c.taskId == currentTaskId).toList();
          final completedCheckpoints = checkpoints.where((c) => c.taskId != currentTaskId).toList();

          final Map<String, List<CheckpointModel>> groupedCompleted = {};
          for (final cp in completedCheckpoints) {
            final key = cp.taskId ?? 'Older Tasks';
            if (!groupedCompleted.containsKey(key)) {
              groupedCompleted[key] = [];
            }
            groupedCompleted[key]!.add(cp);
          }

          final sortedCompletedTaskIds = groupedCompleted.keys.toList()
            ..sort((a, b) {
              if (a == 'Older Tasks') return 1;
              if (b == 'Older Tasks') return -1;
              return b.compareTo(a);
            });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Ongoing Task Section ──
                    Text(
                      'Current Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildOngoingTaskCard(context, isDark, deliveryMan, ongoingCheckpoints.length),
                    const SizedBox(height: 32),

                    // ── Completed Tasks Section ──
                    Text(
                      'Completed Tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (sortedCompletedTaskIds.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No completed tasks yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ...sortedCompletedTaskIds.asMap().entries.map((entry) {
                        final index = entry.key;
                        final taskId = entry.value;
                        final taskCheckpoints = groupedCompleted[taskId]!;
                        
                        String displayTitle = taskId;
                        if (taskId != 'Older Tasks') {
                          try {
                            final dt = DateTime.parse(taskId);
                            displayTitle = 'Task on ${DateFormat('MMM dd, hh:mm a').format(dt)}';
                          } catch (_) {
                            displayTitle = 'Task Record';
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () {
                                context.push('/tracking-history-details', extra: {
                                  'date': displayTitle,
                                  'checkpoints': taskCheckpoints,
                                });
                              },
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                              ),
                              title: Text(
                                displayTitle,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${taskCheckpoints.length} Check-ins',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                            ),
                          ).animate(delay: Duration(milliseconds: 100 + index * 50)).fadeIn().slideX(begin: 0.1),
                        );
                      }),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOngoingTaskCard(BuildContext context, bool isDark, UserModel user, int checkinCount) {
    return GlassCard(
      child: InkWell(
        onTap: () => context.push('/admin/route-map', extra: user),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.map_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.isCompleted ? 'Task Completed' : 'Active Route Tracking',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$checkinCount checkpoints so far',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
