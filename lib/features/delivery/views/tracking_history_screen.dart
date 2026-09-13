import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/glass_card.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';
import '../../../models/checkpoint_model.dart';

class TrackingHistoryScreen extends ConsumerWidget {
  const TrackingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    final checkpointsAsync = ref.watch(userCheckpointsProvider(user.uid));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Tracking History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: checkpointsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Text('Error loading history:\n$err',
              style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
        ),
        data: (checkpoints) {
          if (checkpoints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppColors.lightTextSecondary.withValues(alpha:0.5)),
                  const SizedBox(height: 16),
                  Text('No history found', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('You have not completed any check-ins yet.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ).animate().fadeIn(delay: 200.ms),
            );
          }

          // Group by taskId
          final Map<String, List<CheckpointModel>> grouped = {};

          for (final cp in checkpoints) {
            final key = cp.taskId ?? 'Older Tasks';
            if (!grouped.containsKey(key)) {
              grouped[key] = [];
            }
            grouped[key]!.add(cp);
          }

          final sortedTaskIds = grouped.keys.toList()
            ..sort((a, b) {
              if (a == 'Older Tasks') return 1;
              if (b == 'Older Tasks') return -1;
              return b.compareTo(a); // Sort ISO-8601 strings descending
            });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: sortedTaskIds.length,
            itemBuilder: (context, index) {
              final taskId = sortedTaskIds[index];
              final taskCheckpoints = grouped[taskId]!;
              
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
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    onTap: () {
                      context.push('/tracking-history-details', extra: {
                        'date': displayTitle,
                        'checkpoints': taskCheckpoints,
                      });
                    },
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        taskId == 'Older Tasks' ? Icons.history_rounded : Icons.route_rounded, 
                        color: AppColors.primary
                      ),
                    ),
                    title: Text(
                      displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    subtitle: Text(
                      '${taskCheckpoints.length} Check-ins',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ),
                ).animate(delay: Duration(milliseconds: 100 + index * 50)).fadeIn().slideX(begin: 0.1),
              );
            },
          );
        },
      ),
    );
  }
}
