import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../main.dart';
import '../providers/learning_providers.dart';
import '../models/data_models.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    final double maxWidth = isDesktop ? 1200 : double.infinity;
    final EdgeInsets padding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 48, vertical: 32)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 20);

    return RefreshIndicator.adaptive(
      color: kPrimaryColor,
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(adaptiveMetricsProvider);
        ref.invalidate(weeklyActivityProvider);
        ref.invalidate(achievementsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildStreakCard(context, ref),
                  const SizedBox(height: 20),
                  _buildMetricsOverview(context, ref),
                  const SizedBox(height: 20),
                  _buildWeeklyActivityChart(context, ref),
                  const SizedBox(height: 20),
                  _buildAchievements(context, ref),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimaryColor, kAccentColor],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          'Your Progress',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) => _GlassCard(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFFAA00)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.streakDays} Day Streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep it up! Learn something new today.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const _SkeletonCard(height: 96),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetricsOverview(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adaptiveMetricsProvider);

    return metricsAsync.when(
      data: (metrics) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.military_tech,
                  label: 'Level',
                  value: metrics.level,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.speed,
                  label: 'Pace',
                  value: metrics.pace,
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.psychology,
                  label: 'Mastery',
                  value: '${(metrics.mastery.clamp(0.0, 1.0) * 100).toInt()}%',
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.access_time,
                  label: 'Weekly Time',
                  value: _formatDuration(metrics.weeklyTime),
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const Column(
        children: [
          Row(
            children: [
              Expanded(child: _SkeletonCard(height: 100)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonCard(height: 100)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonCard(height: 100)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonCard(height: 100)),
            ],
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildWeeklyActivityChart(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(weeklyActivityProvider);

    return activityAsync.when(
      data: (activity) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: Column(
              children: [
                _WeeklyChart(activity: activity),
                const SizedBox(height: 16),
                _buildActivityStats(activity),
              ],
            ),
          ),
        ],
      ),
      loading: () => const _SkeletonCard(height: 250),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActivityStats(WeeklyActivity activity) {
    final totalLessons = activity.lessonsPerDay.fold<int>(0, (sum, val) => sum + val);
    final avgTime = activity.avgTimePerLessonMinutes.fold<double>(0.0, (sum, val) => sum + val) / 7.0;

    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'Total Lessons',
            value: '$totalLessons',
            icon: Icons.book,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatPill(
            label: 'Avg Time/Day',
            value: '${avgTime.toInt()}m',
            icon: Icons.timer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatPill(
            label: 'Trend',
            value: activity.paceTrend,
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        final earned = achievements.where((a) => a.earned).length;
        final total = achievements.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$earned/$total',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _AchievementCard(achievement: achievement);
              },
            ),
          ],
        );
      },
      loading: () => const _SkeletonCard(height: 300),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final WeeklyActivity activity;

  const _WeeklyChart({required this.activity});

  @override
  Widget build(BuildContext context) {
    final maxLessons = activity.lessonsPerDay.fold<int>(0, (max, val) => val > max ? val : max).toDouble();
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final lessons = activity.lessonsPerDay[index];
          final height = maxLessons > 0 ? (lessons / maxLessons) * 140 : 0.0;
          final date = now.subtract(Duration(days: 6 - index));
          final isToday = index == 6;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (lessons > 0)
                    Text(
                      '$lessons',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (lessons > 0) const SizedBox(height: 4),
                  if (lessons > 0)
                    Container(
                      height: height < 20 ? 20.0 : height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isToday
                              ? [kPrimaryColor, kAccentColor]
                              : [
                                  kPrimaryColor.withOpacity(0.6),
                                  kAccentColor.withOpacity(0.6),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  if (lessons == 0)
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    weekdays[index],
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: kPrimaryColor, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: achievement.earned
                  ? const LinearGradient(colors: [kPrimaryColor, kAccentColor])
                  : null,
              color: achievement.earned ? null : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: achievement.earned ? Colors.white : Colors.white.withOpacity(0.3),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(
              color: achievement.earned ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
