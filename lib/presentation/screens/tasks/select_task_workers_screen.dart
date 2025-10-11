import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/logger.dart';
import '../../providers/task_workers_provider.dart';
import '../../../data/models/worker_models.dart';

class SelectTaskWorkersScreen extends StatefulWidget {
  final int taskId;
  const SelectTaskWorkersScreen({super.key, required this.taskId});

  @override
  State<SelectTaskWorkersScreen> createState() =>
      _SelectTaskWorkersScreenState();
}

class _SelectTaskWorkersScreenState extends State<SelectTaskWorkersScreen> {
  String _search = '';
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    // Load initial data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskWorkersProvider>().load();
    });
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(() {
      if (mounted) setState(() {}); // update clear icon visibility
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<TaskWorkersProvider>();
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 120 &&
        provider.hasMoreAvailable &&
        !provider.loadingMore &&
        _search.isEmpty) {
      provider.loadMoreAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('workers.selectTitle')),
        actions: [
          Consumer<TaskWorkersProvider>(
            builder: (_, p, __) => TextButton(
              onPressed: p.mutating
                  ? null
                  : () => Navigator.of(context).pop(true),
              child: p.mutating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.t('common.done')),
            ),
          ),
        ],
      ),
      body: Consumer<TaskWorkersProvider>(
        builder: (_, provider, __) {
          if (provider.loadingAssigned && provider.assigned.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final assigned = provider.assigned;
          final filteredAvailable = provider.available.where((w) {
            if (_search.isEmpty) return true;
            final s = _search.toLowerCase();
            return w.name.toLowerCase().contains(s) ||
                (w.phone ?? '').contains(s);
          }).toList();

          return RefreshIndicator(
            onRefresh: () => provider.load(),
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.error != null)
                  _ErrorBanner(
                    message: provider.error!,
                    onClose: () {
                      provider.load();
                    },
                  ),
                Text(
                  loc.t('workers.assigned'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (assigned.isEmpty)
                  Text(loc.t('workers.noneAssigned'))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assigned
                        .map(
                          (w) => _WorkerChip(
                            user: w,
                            onRemove: () => _removeWorker(provider, w.id),
                          ),
                        )
                        .toList(),
                  ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.t('workers.available'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (provider.loadingAvailable)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: loc.t('common.search'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _debounce?.cancel();
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() => _search = v.trim());
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (filteredAvailable.isEmpty && !provider.loadingAvailable)
                  Text(loc.t('workers.noneAvailable'))
                else ...[
                  for (final w in filteredAvailable)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            (w.avatarUrl != null && w.avatarUrl!.isNotEmpty)
                            ? NetworkImage(w.avatarUrl!)
                            : null,
                        child: (w.avatarUrl == null || w.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person_outline)
                            : null,
                      ),
                      title: Text(w.name),
                      subtitle: w.departments.isNotEmpty
                          ? Text(w.departments.map((d) => d.name).join(', '))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: provider.mutating
                            ? null
                            : () => _addWorker(provider, w.id),
                      ),
                    ),
                  if (provider.loadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  if (!provider.hasMoreAvailable &&
                      provider.available.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '— ${loc.t('common.done')} —',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addWorker(TaskWorkersProvider provider, int userId) async {
    final ok = await provider.addWorker(userId);
    if (!ok && mounted) {
      Logger.warning('Failed to add worker');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('workers.addFailed')),
        ),
      );
    }
  }

  Future<void> _removeWorker(TaskWorkersProvider provider, int userId) async {
    final ok = await provider.removeWorker(userId);
    if (!ok && mounted) {
      Logger.warning('Failed to remove worker');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('workers.removeFailed')),
        ),
      );
    }
  }
}

class _WorkerChip extends StatelessWidget {
  final WorkerUser user;
  final VoidCallback onRemove;
  const _WorkerChip({required this.user, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(user.name),
      avatar: CircleAvatar(
        backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
            ? const Icon(Icons.person, size: 16)
            : null,
      ),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _ErrorBanner({required this.message, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(.1),
        border: Border.all(color: Theme.of(context).colorScheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: Theme.of(context).colorScheme.error,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
