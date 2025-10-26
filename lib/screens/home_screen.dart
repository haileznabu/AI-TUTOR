import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../main.dart';
import '../providers/learning_providers.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import '../models/topic_model.dart';
import 'topic_detail_screen.dart';
import '../services/visited_topics_service.dart';
import '../services/firestore_service.dart';

// 🏠 HOME
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeInController = AnimationController(
    vsync: this,
    duration: kAnimationNormal,
  )..forward();

  final StateProvider<int> _navIndexProvider = StateProvider<int>((ref) => 0);

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(userProfileProvider);
    ref.invalidate(adaptiveMetricsProvider);
    ref.invalidate(recommendationsProvider);
    ref.invalidate(activeLessonProvider);
    ref.invalidate(weeklyActivityProvider);
    ref.invalidate(dailyChallengeProvider);
    ref.invalidate(aiInsightsProvider);
    ref.invalidate(nextTopicsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = ref.watch(_navIndexProvider);
    final bool isDesktop = _isDesktopPlatform();

    final Widget body = switch (currentIndex) {
      0 => _HomeTab(onSignOut: () => _signOut(context), onRefresh: _refreshAll),
      1 => const ChatScreen(),
      2 => const _PlaceholderTab(title: 'My Progress'),
      _ => const ProfileScreen(),
    };

    if (isDesktop) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: kDarkGradient,
            ),
          ),
          child: Row(
            children: [
              _DesktopSideNav(
                currentIndex: currentIndex,
                onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
                onSignOut: () => _signOut(context),
              ),
              Expanded(
                child: SafeArea(child: body),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kDarkGradient,
          ),
        ),
        child: SafeArea(child: body),
      ),
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: _GlassNavBar(
          currentIndex: currentIndex,
          onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
        ),
      ),
    );
  }

  bool _isDesktopPlatform() {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width > 800;
    }
    return Theme.of(context).platform == TargetPlatform.windows ||
           Theme.of(context).platform == TargetPlatform.linux ||
           Theme.of(context).platform == TargetPlatform.macOS;
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title (Coming soon)',
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(color: Colors.white70),
      ),
    );
  }
}

// ===============================
// HOME TAB & SECTIONS
// ===============================

class _HomeTab extends ConsumerWidget {
  final VoidCallback onSignOut;
  final Future<void> Function() onRefresh;
  const _HomeTab({required this.onSignOut, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    final double maxWidth = isDesktop ? 1200 : double.infinity;
    final EdgeInsets padding = isDesktop
      ? const EdgeInsets.symmetric(horizontal: 48, vertical: 32)
      : const EdgeInsets.symmetric(horizontal: 16, vertical: 20);

    return RefreshIndicator.adaptive(
      color: kPrimaryColor,
      onRefresh: onRefresh,
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
                  if (!isDesktop) _PersonalizedHeader(onSignOut: onSignOut),
                  if (!isDesktop) const SizedBox(height: 20),
                  const _AiTopicExplorer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalizedHeader extends ConsumerWidget {
  final VoidCallback onSignOut;
  const _PersonalizedHeader({required this.onSignOut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, MMM d • h:mm a').format(now);

    return profileAsync.when(
      data: (profile) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${profile.name}! 👋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            GestureDetector(
              onTap: onSignOut,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [kPrimaryColor, kAccentColor],
                  ),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      },
      loading: () => const _Skeleton(height: 60),
      error: (_, __) => const _ErrorText(),
    );
  }
}

class _AiTopicExplorer extends StatefulWidget {
  const _AiTopicExplorer();

  @override
  State<_AiTopicExplorer> createState() => _AiTopicExplorerState();
}

class _AiTopicExplorerState extends State<_AiTopicExplorer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  final Map<String, bool> _expandedCategories = {}; // null = All

  static const List<Topic> _allTopics = [
    Topic(
      id: '1',
      title: 'Flutter Basics',
      description: 'Learn the fundamentals of Flutter development',
      category: 'Programming',
      icon: Icons.smartphone,
      estimatedMinutes: 30,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '2',
      title: 'State Management',
      description: 'Master state management with Provider and Riverpod',
      category: 'Programming',
      icon: Icons.settings_applications,
      estimatedMinutes: 45,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '3',
      title: 'REST APIs',
      description: 'Understanding and working with REST APIs',
      category: 'Programming',
      icon: Icons.cloud,
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '4',
      title: 'Firebase Integration',
      description: 'Integrate Firebase services in your Flutter app',
      category: 'Programming',
      icon: Icons.data_exploration_rounded,
      estimatedMinutes: 50,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '5',
      title: 'Custom Animations',
      description: 'Create beautiful custom animations in Flutter',
      category: 'Programming',
      icon: Icons.animation,
      estimatedMinutes: 35,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '6',
      title: 'Material Design',
      description: 'Implement Material Design principles',
      category: 'Programming',
      icon: Icons.design_services,
      estimatedMinutes: 25,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '7',
      title: 'Responsive Layouts',
      description: 'Build responsive UIs for all screen sizes',
      category: 'Programming',
      icon: Icons.devices,
      estimatedMinutes: 30,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '8',
      title: 'Local Database',
      description: 'Work with SQLite and local storage',
      category: 'Programming',
      icon: Icons.storage,
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '9',
      title: 'Testing in Flutter',
      description: 'Write unit, widget, and integration tests',
      category: 'Programming',
      icon: Icons.bug_report,
      estimatedMinutes: 45,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '10',
      title: 'App Deployment',
      description: 'Deploy your app to App Store and Play Store',
      category: 'Programming',
      icon: Icons.publish,
      estimatedMinutes: 60,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '11',
      title: 'Dart Fundamentals',
      description: 'Syntax, types, collections, and async in Dart',
      category: 'Programming',
      icon: Icons.code,
      estimatedMinutes: 40,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '12',
      title: 'Clean Architecture',
      description: 'Layered architecture patterns for Flutter apps',
      category: 'Programming',
      icon: Icons.account_tree,
      estimatedMinutes: 50,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '13',
      title: 'CI/CD with GitHub Actions',
      description: 'Automate build, test and deploy for Flutter',
      category: 'Programming',
      icon: Icons.sync,
      estimatedMinutes: 55,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '14',
      title: 'Accessibility',
      description: 'Build accessible apps with a11y best practices',
      category: 'Programming',
      icon: Icons.accessibility,
      estimatedMinutes: 30,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '15',
      title: 'Security Basics',
      description: 'Secure storage, auth, and network in apps',
      category: 'Programming',
      icon: Icons.lock,
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '16',
      title: 'Time Management',
      description: 'Master productivity and time organization skills',
      category: 'Life Skills',
      icon: Icons.schedule,
      estimatedMinutes: 35,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '17',
      title: 'Communication Skills',
      description: 'Effective verbal and written communication',
      category: 'Life Skills',
      icon: Icons.chat,
      estimatedMinutes: 40,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '18',
      title: 'Financial Literacy',
      description: 'Budgeting, saving, and basic personal finance',
      category: 'Life Skills',
      icon: Icons.account_balance_wallet,
      estimatedMinutes: 45,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '19',
      title: 'Critical Thinking',
      description: 'Develop analytical and problem-solving skills',
      category: 'Life Skills',
      icon: Icons.psychology,
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '20',
      title: 'Physics Fundamentals',
      description: 'Newton\'s laws, energy, and motion',
      category: 'Science',
      icon: Icons.science,
      estimatedMinutes: 50,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '21',
      title: 'Chemistry Basics',
      description: 'Elements, compounds, and chemical reactions',
      category: 'Science',
      icon: Icons.biotech,
      estimatedMinutes: 45,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '22',
      title: 'Biology Introduction',
      description: 'Cell structure, genetics, and ecosystems',
      category: 'Science',
      icon: Icons.local_florist,
      estimatedMinutes: 40,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '23',
      title: 'Environmental Science',
      description: 'Climate change, sustainability, and ecology',
      category: 'Science',
      icon: Icons.eco,
      estimatedMinutes: 35,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '24',
      title: 'World History',
      description: 'Major civilizations and historical events',
      category: 'Arts & Humanities',
      icon: Icons.public,
      estimatedMinutes: 50,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '25',
      title: 'Philosophy Basics',
      description: 'Ethics, logic, and major philosophical ideas',
      category: 'Arts & Humanities',
      icon: Icons.menu_book,
      estimatedMinutes: 45,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '26',
      title: 'Creative Writing',
      description: 'Storytelling, character development, and narrative',
      category: 'Arts & Humanities',
      icon: Icons.edit,
      estimatedMinutes: 40,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '27',
      title: 'Art History',
      description: 'Major art movements and influential artists',
      category: 'Arts & Humanities',
      icon: Icons.palette,
      estimatedMinutes: 35,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '28',
      title: 'Algebra Fundamentals',
      description: 'Equations, variables, and functions',
      category: 'Math',
      icon: Icons.calculate,
      estimatedMinutes: 45,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '29',
      title: 'Geometry Basics',
      description: 'Shapes, angles, and spatial reasoning',
      category: 'Math',
      icon: Icons.architecture,
      estimatedMinutes: 40,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '30',
      title: 'Statistics & Probability',
      description: 'Data analysis and probability theory',
      category: 'Math',
      icon: Icons.bar_chart,
      estimatedMinutes: 50,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '31',
      title: 'Calculus Introduction',
      description: 'Limits, derivatives, and integrals',
      category: 'Math',
      icon: Icons.functions,
      estimatedMinutes: 60,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '32',
      title: 'Microeconomics',
      description: 'Supply, demand, and market structures',
      category: 'Economics',
      icon: Icons.store,
      estimatedMinutes: 45,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '33',
      title: 'Macroeconomics',
      description: 'GDP, inflation, and economic policies',
      category: 'Economics',
      icon: Icons.trending_up,
      estimatedMinutes: 50,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '34',
      title: 'Personal Finance',
      description: 'Investing, retirement planning, and wealth building',
      category: 'Economics',
      icon: Icons.savings,
      estimatedMinutes: 40,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '35',
      title: 'Business Economics',
      description: 'Cost analysis, pricing strategies, and profit',
      category: 'Economics',
      icon: Icons.business_center,
      estimatedMinutes: 45,
      difficulty: 'Intermediate',
    ),
  ];

  static final Map<String, Topic> _idToTopic = {
    for (final t in _allTopics) t.id: t,
  };

  List<String> get _allCategories {
    final set = <String>{ for (final t in _allTopics) t.category };
    final list = set.toList()..sort();
    return list;
  }

  List<Topic> get _filteredTopics {
    Iterable<Topic> base = _allTopics;
    if (_selectedCategory != null) {
      base = base.where((t) => t.category == _selectedCategory);
    }
    if (_searchQuery.isEmpty) {
      return base.toList();
    }
    final String q = _searchQuery.toLowerCase();
    return base.where((topic) {
      return topic.title.toLowerCase().contains(q) ||
          topic.description.toLowerCase().contains(q) ||
          topic.category.toLowerCase().contains(q);
    }).toList();
  }

  Future<List<dynamic>> _loadRecentlyVisitedWithProgress() async {
    final ids = await VisitedTopicsService.getVisitedIdsOrdered();
    final localProgressMap = await VisitedTopicsService.getVisitedTopicsWithProgress();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    Map<String, int> firestoreProgressMap = {};

    if (userId != null) {
      try {
        final firestoreService = FirestoreService();
        firestoreProgressMap = await firestoreService.getUserProgress(userId);

        for (final id in firestoreProgressMap.keys) {
          final firestoreProgress = firestoreProgressMap[id] ?? 0;
          final localProgress = localProgressMap[id] ?? 0;

          if (firestoreProgress > localProgress) {
            await VisitedTopicsService.updateProgress(id, firestoreProgress);
          }
        }
      } catch (e) {
        debugPrint('Failed to load Firestore progress: $e');
      }
    }

    final mergedProgressMap = <String, int>{};
    for (final id in ids) {
      final firestoreProgress = firestoreProgressMap[id] ?? 0;
      final localProgress = localProgressMap[id] ?? 0;
      mergedProgressMap[id] = firestoreProgress > localProgress ? firestoreProgress : localProgress;
    }

    return [ids, mergedProgressMap];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(context),
        _buildCategoryChips(context),
        _buildRecentlyVisited(context),
        _buildTopicsList(context),
      ],
    );
  }
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search topics...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final categories = _allCategories;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            const SizedBox(width: 4),
            _buildCategoryChip('All', _selectedCategory == null, onTap: () {
              setState(() => _selectedCategory = null);
            }),
            const SizedBox(width: 8),
            for (final c in categories) ...[
              _buildCategoryChip(c, _selectedCategory == c, onTap: () {
                setState(() => _selectedCategory = c);
              }),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool selected, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimaryColor : Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.category,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyVisited(BuildContext context) {
    if (_searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<dynamic>>(
      future: _loadRecentlyVisitedWithProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final ids = snapshot.data![0] as List<String>;
        final progressMap = snapshot.data![1] as Map<String, int>;

        if (ids.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<Topic> visitedTopics = ids
            .map((id) => _idToTopic[id])
            .whereType<Topic>()
            .toList();
        if (visitedTopics.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.history, color: kPrimaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recently visited',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: Builder(
                builder: (context) {
                  final int itemCount = visitedTopics.length > 12 ? 12 : visitedTopics.length;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final topic = visitedTopics[index];
                      final progress = progressMap[topic.id] ?? 0;
                      return _VisitedTopicTile(
                        topic: topic,
                        progressPercentage: progress,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TopicDetailScreen(topic: topic),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryTopics(BuildContext context, String category, List<Topic> topics) {
    final isExpanded = _expandedCategories[category] ?? false;
    final displayTopics = isExpanded ? topics : topics.take(3).toList();
    final hasMore = topics.length > 3;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayTopics.length,
          itemBuilder: (context, index) {
            final topic = displayTopics[index];
            return _TopicCard(
              topic: topic,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopicDetailScreen(topic: topic),
                  ),
                ).then((_) => setState(() {}));
              },
            );
          },
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _expandedCategories[category] = !isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: kPrimaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isExpanded ? 'Wrap up' : 'See more (${topics.length - 3} more)',
                              style: const TextStyle(
                                color: kPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopicsList(BuildContext context) {
    final topics = _filteredTopics;

    final Map<String, List<Topic>> byCategory = <String, List<Topic>>{};
    for (final t in topics) {
      byCategory.putIfAbsent(t.category, () => <Topic>[]).add(t);
    }

    if (topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                'No topics found',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              const Icon(Icons.view_list, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                _selectedCategory == null ? 'All categories' : _selectedCategory!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          _buildCategoryTopics(context, entry.key, entry.value),
        ],
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;

  const _TopicCard({required this.topic, required this.onTap});

  Color get _difficultyColor {
    switch (topic.difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kPrimaryColor, kAccentColor],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(topic.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topic.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                _buildChip(
                                  '${topic.estimatedMinutes} min',
                                  Icons.access_time,
                                  Colors.purple.withOpacity(0.3),
                                ),
                                const SizedBox(width: 8),
                                _buildChip(
                                  topic.difficulty,
                                  Icons.signal_cellular_alt,
                                  _difficultyColor.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.5),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitedTopicTile extends StatelessWidget {
  final Topic topic;
  final int progressPercentage;
  final VoidCallback onTap;
  const _VisitedTopicTile({
    required this.topic,
    required this.progressPercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kPrimaryColor, kAccentColor]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(topic.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          topic.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topic.category,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$progressPercentage%',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercentage / 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================
// SHARED UI COMPONENTS
// ===============================

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

class _ErrorText extends StatelessWidget {
  const _ErrorText();
  @override
  Widget build(BuildContext context) {
    return const Text('Something went wrong', style: TextStyle(color: Colors.redAccent));
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _DesktopSideNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSignOut;
  const _DesktopSideNav({
    required this.currentIndex,
    required this.onTap,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, kAccentColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Tutor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          profileAsync.when(
            data: (profile) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [kPrimaryColor, kAccentColor],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              profile.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, y').format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox(height: 80),
          ),
          const SizedBox(height: 16),
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.insights_rounded,
            label: 'Progress',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? kPrimaryColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? kPrimaryColor.withOpacity(0.5) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white60,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GlassNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: BottomNavigationBar(
          backgroundColor: Colors.white.withOpacity(0.06),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: onTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Progress'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}