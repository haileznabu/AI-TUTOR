import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../main.dart';
import '../services/firestore_service.dart';
import '../services/visited_topics_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final visitedTopics = await _firestoreService.getVisitedTopics(userId);
      final progressMap = await _firestoreService.getUserProgress(userId);

      int totalProgress = 0;
      int completedTopics = 0;

      for (final topicId in visitedTopics) {
        final progress = progressMap[topicId] ?? 0;
        totalProgress += progress;
        if (progress >= 100) {
          completedTopics++;
        }
      }

      final avgProgress = visitedTopics.isEmpty
          ? 0
          : (totalProgress / visitedTopics.length).round();

      setState(() {
        _stats = {
          'visitedTopics': visitedTopics.length,
          'completedTopics': completedTopics,
          'averageProgress': avgProgress,
          'inProgressTopics': visitedTopics.length - completedTopics,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will clear your locally cached progress. Your data in the cloud will be preserved. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await VisitedTopicsService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local data cleared')),
        );
        _loadUserStats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          const SizedBox(height: 24),
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kAccentColor],
              ),
            ),
            child: Center(
              child: Text(
                (user?.displayName?.isNotEmpty == true
                        ? user!.displayName![0]
                        : user?.email?.isNotEmpty == true
                            ? user!.email![0]
                            : 'U')
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, color: kPrimaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Topics Visited',
                      '${_stats['visitedTopics'] ?? 0}',
                      Icons.explore,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      '${_stats['completedTopics'] ?? 0}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'In Progress',
                      '${_stats['inProgressTopics'] ?? 0}',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Avg Progress',
                      '${_stats['averageProgress'] ?? 0}%',
                      Icons.trending_up,
                      kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.settings, color: kPrimaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.white),
                title: const Text(
                  'Refresh Stats',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: _loadUserStats,
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Clear Local Data',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: _clearLocalData,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
