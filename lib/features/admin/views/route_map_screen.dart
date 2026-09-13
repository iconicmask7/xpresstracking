import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../models/checkpoint_model.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/glass_card.dart';

class RouteMapScreen extends ConsumerStatefulWidget {
  final UserModel deliveryMan;

  const RouteMapScreen({super.key, required this.deliveryMan});

  @override
  ConsumerState<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends ConsumerState<RouteMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  final MapController _mapController = MapController();
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkpointsStream =
        ref.watch(userCheckpointsProvider(widget.deliveryMan.uid));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: _buildAppBar(context, isDark),
        body: checkpointsStream.when(
          data: (allCheckpoints) {
            final now = DateTime.now();
            final taskStartTime = widget.deliveryMan.currentTaskStartedAt ?? 
                DateTime(now.year, now.month, now.day);
                
            final checkpoints = allCheckpoints.where((c) {
              return c.timestamp.isAfter(taskStartTime) || c.timestamp.isAtSameMomentAs(taskStartTime);
            }).toList();

            if (checkpoints.isEmpty) {
              return _buildEmptyState(context);
            }

            final points = checkpoints
                .map((cp) => LatLng(cp.latitude, cp.longitude))
                .toList();

            return Stack(
              children: [
                // ── Map ─────────────────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: points.first,
                    initialZoom: 13.0,
                    onTap: (_, __) => setState(() => _selectedIndex = -1),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
                      userAgentPackageName: 'com.example.xpresstrack',
                    ),

                    // Polyline route
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4,
                          gradientColors: const [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                        ),
                      ],
                    ),

                    // Markers
                    MarkerLayer(
                      markers: checkpoints.asMap().entries.map((e) {
                        final i = e.key;
                        final cp = e.value;
                        final isSelected = _selectedIndex == i;
                        return Marker(
                          point: LatLng(cp.latitude, cp.longitude),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedIndex = i);
                              _mapController.move(
                                  LatLng(cp.latitude, cp.longitude), 15);
                            },
                            child: AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isSelected)
                                      Container(
                                        width: 44 + _pulseAnim.value * 8,
                                        height: 44 + _pulseAnim.value * 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25 -
                                                  _pulseAnim.value * 0.1),
                                        ),
                                      ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppColors.primaryGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.45),
                                            blurRadius: isSelected ? 12 : 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // ── Top gradient fade ────────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isDark
                                    ? AppColors.darkBackground
                                    : AppColors.lightBackground)
                                .withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Checkpoint detail bottom sheet ───────────────────────────
                if (_selectedIndex >= 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _CheckpointDetailPanel(
                      checkpoint: checkpoints[_selectedIndex],
                      index: _selectedIndex,
                      total: checkpoints.length,
                      onClose: () => setState(() => _selectedIndex = -1),
                    ).animate().slideY(
                          begin: 1,
                          duration: 350.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),

                // ── Floating stat pill ───────────────────────────────────────
                if (_selectedIndex < 0)
                  Positioned(
                    bottom: 32,
                    left: 20,
                    right: 20,
                    child: _buildStatPill(context, isDark, checkpoints),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.deliveryMan.name.isNotEmpty
                          ? widget.deliveryMan.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.deliveryMan.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(
      BuildContext context, bool isDark, List<CheckpointModel> checkpoints) {
    return GestureDetector(
      onTap: () {
        context.push('/tracking-history-details', extra: {
          'date': 'Active Route',
          'checkpoints': checkpoints,
        });
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        borderRadius: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _PillStat(
              label: 'Check-ins',
              value: '${checkpoints.length}',
              icon: Icons.location_on_rounded,
              color: AppColors.primary),
          Container(width: 1, height: 32, color: AppColors.darkCardBorder),
          _PillStat(
              label: 'Tap to view',
              value: 'Details',
              icon: Icons.touch_app_rounded,
              color: AppColors.success),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined,
              size: 72, color: AppColors.lightTextSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No route data yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.deliveryMan.name} has not checked in yet.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PillStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: color)),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _CheckpointDetailPanel extends StatelessWidget {
  final CheckpointModel checkpoint;
  final int index;
  final int total;
  final VoidCallback onClose;

  const _CheckpointDetailPanel({
    required this.checkpoint,
    required this.index,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stop ${index + 1} of $total',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              DateFormat('MMM dd • hh:mm a')
                                  .format(checkpoint.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),

                if (checkpoint.notes != null &&
                    checkpoint.notes!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.lightCardBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            checkpoint.notes!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (checkpoint.photoUrl.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      checkpoint.photoUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 180,
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Coordinates row
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${checkpoint.latitude.toStringAsFixed(5)}, ${checkpoint.longitude.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/checkpoint-details', extra: checkpoint),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View Full Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
