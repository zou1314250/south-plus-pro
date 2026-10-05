import 'package:flutter/material.dart';

import '../../models/forum_models.dart';
import '../../services/forum_repository.dart';
import '../../services/purchase_history_store.dart';
import '../../theme/app_theme.dart';
import '../common/async_state_view.dart';
import '../thread/thread_detail_screen.dart';

/// Lists threads whose paid content was unlocked in the app.
///
/// The forum has no equivalent page, so this reads the local purchase history
/// written whenever `ForumRepository.buySaleBox` succeeds.
class PurchasedThreadsPage extends StatefulWidget {
  const PurchasedThreadsPage({
    super.key,
    required this.repository,
    this.store,
  });

  final ForumRepository repository;
  final PurchaseHistoryStore? store;

  @override
  State<PurchasedThreadsPage> createState() => _PurchasedThreadsPageState();
}

class _PurchasedThreadsPageState extends State<PurchasedThreadsPage> {
  late final PurchaseHistoryStore _store =
      widget.store ?? PurchaseHistoryStore();
  late Future<List<PurchasedThread>> _future = _store.recent();

  void _reload() {
    setState(() {
      _future = _store.recent();
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空购买记录'),
        content: const Text('只会清掉本机记录，不影响论坛上的购买状态。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.clear();
    if (!mounted) return;
    _reload();
  }

  Future<void> _remove(PurchasedThread entry) async {
    await _store.remove(entry.tid);
    if (!mounted) return;
    _reload();
  }

  void _open(PurchasedThread entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThreadDetailScreen(
          thread: ForumThread(
            title: entry.title,
            url: entry.url,
            replies: 0,
            section: '',
          ),
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('已购买的帖子'),
        actions: [
          IconButton(
            tooltip: '清空记录',
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<PurchasedThread>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AsyncErrorView(
              title: '读取购买记录失败',
              message: '${snapshot.error}',
              onRetry: _reload,
            );
          }
          final entries = snapshot.data;
          if (entries == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entries.isEmpty) {
            return const _EmptyPurchases();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: entries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PurchasesHint(count: entries.length);
              }
              final entry = entries[index - 1];
              return _PurchasedThreadTile(
                entry: entry,
                onTap: () => _open(entry),
                onRemove: () => _remove(entry),
              );
            },
          );
        },
      ),
    );
  }
}

class _PurchasesHint extends StatelessWidget {
  const _PurchasesHint({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '共 $count 条本机购买记录。论坛没有"已购买"列表，这里只记录在本 App 内购买过的帖子。',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
      ),
    );
  }
}

class _EmptyPurchases extends StatelessWidget {
  const _EmptyPurchases();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 42, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(
              '还没有购买记录',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '在帖子里点击"购买查看"成功后，这里会自动记录该帖子。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchasedThreadTile extends StatelessWidget {
  const _PurchasedThreadTile({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final PurchasedThread entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 6, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_open_outlined,
                    size: 17,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (entry.price != null) ...[
                            _MetaPill(
                              icon: Icons.paid_outlined,
                              label: '${entry.price} SP币',
                            ),
                            const SizedBox(width: 6),
                          ],
                          _MetaPill(
                            icon: Icons.tag,
                            label: 'tid ${entry.tid}',
                          ),
                          if (entry.purchasedAt != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatDate(entry.purchasedAt!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textFaint,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '移除记录',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textFaint,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.inkSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.link),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
