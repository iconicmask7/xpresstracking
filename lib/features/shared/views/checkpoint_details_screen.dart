import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/checkpoint_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/glass_card.dart';

class CheckpointDetailsScreen extends StatelessWidget {
  final CheckpointModel checkpoint;

  const CheckpointDetailsScreen({super.key, required this.checkpoint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormatted = DateFormat('EEEE, MMM dd • hh:mm a').format(checkpoint.timestamp);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Check-in Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header / Time ───────────────────────────────────────────────
            Text(
              'Time Captured',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ).animate().fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 8),
            Text(
              timeFormatted,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 32),

            // ── Mock Photo ──────────────────────────────────────────────────
            Text(
              'Location Photo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark ? const Color(0xFF2A2D43) : const Color(0xFFE2E6FF),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1522204523234-8729aa6e3d5f?q=80&w=600&auto=format&fit=crop', // A nice mock delivery/location image
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'System Mock Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 300.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 32),

            // ── Location Coordinates ─────────────────────────────────────────
            Text(
              'GPS Coordinates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ).animate(delay: 400.ms).fadeIn(),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LAT: ${checkpoint.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LNG: ${checkpoint.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 32),

            // ── Notes ────────────────────────────────────────────────────────
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ).animate(delay: 600.ms).fadeIn(),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  checkpoint.notes != null && checkpoint.notes!.isNotEmpty
                      ? checkpoint.notes!
                      : 'No notes provided by delivery partner.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: checkpoint.notes != null && checkpoint.notes!.isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
                        height: 1.5,
                      ),
                ),
              ),
            ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
