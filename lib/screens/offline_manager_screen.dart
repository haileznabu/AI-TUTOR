import 'package:flutter/material.dart';
import '../main.dart';
import '../services/learning_repository.dart';
import '../models/topic_model.dart';
import '../services/firestore_service.dart';

class OfflineManagerScreen extends StatefulWidget {
  const OfflineManagerScreen({super.key});

  @override
  State<OfflineManagerScreen> createState() => _OfflineManagerScreenState();
}

class _OfflineManagerScreenState extends State<OfflineManagerScreen> {
  final LearningRepository _repository = LearningRepository();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  Map<String, dynamic> _offlineStatus = {};
  List<String> _cachedTopics = [];
  List<Map<String, dynamic>> _downloadQueue = [];
  List<Topic> _allTopics = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await _repository.getOfflineStatus();
      final cachedTopics = await _repository.getOfflineAvailableTopics();
      final downloadQueue = await _repository.getOfflineDownloadQueue();
      final topics = await _firestoreService.getAllTopics();

      setState(() {
        _offlineStatus = status;
        _cachedTopics = cachedTopics;
        _downloadQueue = downloadQueue;
        _allTopics = topics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load offline data: $e')),
        );
      }
    }
  }

  Future<void> _downloadTopic(Topic topic) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );

      await _repository.downloadForOffline(topic.id, topic.title);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${topic.title} downloaded for offline use')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    }
  }

  Future<void> _removeTopic(String topicId, String topicTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Offline Content'),
        content: Text('Remove cached content for "$topicTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.removeOfflineContent(topicId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline content removed')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e')),
          );
        }
      }
    }
  }

  Future<void> _clearAllCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Offline Content'),
        content: const Text(
          'This will remove all downloaded lessons and summaries. Your progress will be synced when you\'re back online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.clearAllOfflineCache();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All offline content cleared')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear cache: $e')),
          );
        }
      }
    }
  }

  Future<void> _syncNow() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );

      await _repository.syncPendingChanges();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
    final bgColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? kDarkGradient : [Colors.grey[50]!, Colors.grey[100]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(textColor),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(textColor, subtextColor, bgColor, borderColor),
                        const SizedBox(height: 20),
                        _buildCachedTopicsSection(textColor, subtextColor, bgColor, borderColor),
                        const SizedBox(height: 20),
                        _buildAvailableTopicsSection(textColor, subtextColor, bgColor, borderColor),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kAccentColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.offline_bolt, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Offline Manager',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Color textColor, Color subtextColor, Color bgColor, Color borderColor) {
    final isOnline = _offlineStatus['isOnline'] ?? false;
    final cachedCount = _offlineStatus['cachedTopicsCount'] ?? 0;
    final cacheSize = _offlineStatus['cacheSizeMB'] ?? '0.00';
    final pendingSync = _offlineStatus['pendingSyncCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: isOnline ? kSuccessColor : kErrorColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            Icons.download_done,
            'Cached Topics',
            '$cachedCount',
            textColor,
            subtextColor,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            Icons.storage,
            'Cache Size',
            '$cacheSize MB',
            textColor,
            subtextColor,
          ),
          if (pendingSync > 0) ...[
            const SizedBox(height: 8),
            _buildStatusRow(
              Icons.sync,
              'Pending Sync',
              '$pendingSync items',
              textColor,
              subtextColor,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (pendingSync > 0 && isOnline)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _syncNow,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              if (pendingSync > 0 && isOnline) const SizedBox(width: 12),
              if (cachedCount > 0)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllCache,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kErrorColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color textColor, Color subtextColor) {
    return Row(
      children: [
        Icon(icon, color: subtextColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: subtextColor, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCachedTopicsSection(Color textColor, Color subtextColor, Color bgColor, Color borderColor) {
    if (_cachedTopics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_download, size: 48, color: subtextColor),
            const SizedBox(height: 12),
            Text(
              'No offline content',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Download lessons to access them offline',
              style: TextStyle(color: subtextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final cachedTopicsList = _allTopics.where((t) => _cachedTopics.contains(t.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Downloaded (${_cachedTopics.length})',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...cachedTopicsList.map((topic) => _buildTopicCard(
          topic,
          true,
          textColor,
          subtextColor,
          bgColor,
          borderColor,
        )),
      ],
    );
  }

  Widget _buildAvailableTopicsSection(Color textColor, Color subtextColor, Color bgColor, Color borderColor) {
    final availableTopics = _allTopics.where((t) => !_cachedTopics.contains(t.id)).toList();

    if (availableTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available for Download',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...availableTopics.take(5).map((topic) => _buildTopicCard(
          topic,
          false,
          textColor,
          subtextColor,
          bgColor,
          borderColor,
        )),
      ],
    );
  }

  Widget _buildTopicCard(
    Topic topic,
    bool isCached,
    Color textColor,
    Color subtextColor,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
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
            child: Icon(topic.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic.category,
                  style: TextStyle(color: subtextColor, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isCached ? Icons.delete : Icons.download,
              color: isCached ? kErrorColor : kPrimaryColor,
            ),
            onPressed: () {
              if (isCached) {
                _removeTopic(topic.id, topic.title);
              } else {
                _downloadTopic(topic);
              }
            },
          ),
        ],
      ),
    );
  }
}
