import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sync_service.dart';
import '../utils/persian_number_formatter.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = SyncService();
    return ValueListenableBuilder<SyncSnapshot>(
      valueListenable: sync.status,
      builder: (context, snapshot, _) {
        if (snapshot.phase == SyncPhase.idle && snapshot.pendingCount == 0) {
          return const SizedBox.shrink();
        }
        final scheme = Theme.of(context).colorScheme;
        final data = _syncVisuals(snapshot, scheme);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: data.background,
            border: Border(
              bottom: BorderSide(color: data.foreground.withValues(alpha: 0.2)),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Row(
              children: [
                if (snapshot.phase == SyncPhase.syncing)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: data.foreground,
                    ),
                  )
                else
                  Icon(data.icon, size: 20, color: data.foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _syncLabel(snapshot),
                    maxLines: snapshot.phase == SyncPhase.error ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: data.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'sync',
                  visualDensity: VisualDensity.compact,
                  onPressed: snapshot.phase == SyncPhase.syncing
                      ? null
                      : () => sync.syncNow(forcePush: true),
                  icon: Icon(Icons.sync_rounded, color: data.foreground),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MobileSyncStatusButton extends StatefulWidget {
  const MobileSyncStatusButton({super.key});

  @override
  State<MobileSyncStatusButton> createState() => _MobileSyncStatusButtonState();
}

class _MobileSyncStatusButtonState extends State<MobileSyncStatusButton> {
  final _sync = SyncService();
  String? _lastShownIssue;

  @override
  void initState() {
    super.initState();
    _sync.status.addListener(_onStatusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStatusChanged());
  }

  @override
  void dispose() {
    _sync.status.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    final snapshot = _sync.status.value;
    final hasIssue =
        snapshot.phase == SyncPhase.error ||
        snapshot.phase == SyncPhase.offline;
    if (!hasIssue) {
      _lastShownIssue = null;
      return;
    }

    final message = _syncLabel(snapshot);
    if (message == _lastShownIssue) return;
    _lastShownIssue = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'جزئیات',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: _showDetails,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncSnapshot>(
      valueListenable: _sync.status,
      builder: (context, snapshot, _) {
        final scheme = Theme.of(context).colorScheme;
        final data = _syncVisuals(snapshot, scheme);
        final hasIssue =
            snapshot.phase == SyncPhase.error ||
            snapshot.phase == SyncPhase.offline;
        final showBadge = hasIssue || snapshot.pendingCount > 0;
        final badgeLabel = hasIssue
            ? '!'
            : snapshot.pendingCount > 9
            ? '+۹'
            : PersianNumberFormatter.toPersian(
                snapshot.pendingCount.toString(),
              );

        return Badge(
          isLabelVisible: showBadge,
          label: Text(badgeLabel),
          backgroundColor: hasIssue ? scheme.error : scheme.primary,
          child: IconButton(
            key: const ValueKey('mobile-sync-status-button'),
            tooltip: _syncLabel(snapshot).isEmpty
                ? 'وضعیت همگام‌سازی'
                : _syncLabel(snapshot),
            onPressed: _showDetails,
            icon: snapshot.phase == SyncPhase.syncing
                ? SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: data.foreground,
                    ),
                  )
                : Icon(data.icon, color: data.foreground),
          ),
        );
      },
    );
  }

  void _showDetails() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ValueListenableBuilder<SyncSnapshot>(
            valueListenable: _sync.status,
            builder: (context, snapshot, _) {
              final scheme = Theme.of(context).colorScheme;
              final data = _syncVisuals(snapshot, scheme);
              final lastSync = snapshot.lastSyncedAt == null
                  ? 'هنوز همگام‌سازی کامل نشده است'
                  : 'آخرین همگام‌سازی: ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(snapshot.lastSyncedAt!.toLocal()))}';
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: data.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(data.icon, color: data.foreground),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'وضعیت همگام‌سازی',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _syncLabel(snapshot).isEmpty
                          ? 'آماده همگام‌سازی'
                          : _syncLabel(snapshot),
                      style: TextStyle(
                        color: data.foreground,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastSync,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: snapshot.phase == SyncPhase.syncing
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              unawaited(_sync.syncNow());
                            },
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(
                        snapshot.phase == SyncPhase.syncing
                            ? 'در حال همگام‌سازی'
                            : 'همگام‌سازی دوباره',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

_SyncVisuals _syncVisuals(SyncSnapshot snapshot, ColorScheme scheme) {
  return switch (snapshot.phase) {
    SyncPhase.syncing => _SyncVisuals(
      icon: Icons.sync_rounded,
      foreground: scheme.primary,
      background: scheme.primaryContainer.withValues(alpha: 0.42),
    ),
    SyncPhase.synced => _SyncVisuals(
      icon: Icons.cloud_done_rounded,
      foreground: Colors.green.shade700,
      background: Colors.green.withValues(alpha: 0.12),
    ),
    SyncPhase.offline => _SyncVisuals(
      icon: Icons.cloud_off_rounded,
      foreground: scheme.error,
      background: scheme.errorContainer.withValues(alpha: 0.52),
    ),
    SyncPhase.error => _SyncVisuals(
      icon: Icons.sync_problem_rounded,
      foreground: scheme.error,
      background: scheme.errorContainer.withValues(alpha: 0.52),
    ),
    SyncPhase.idle => _SyncVisuals(
      icon: snapshot.pendingCount > 0
          ? Icons.cloud_upload_rounded
          : Icons.cloud_queue_rounded,
      foreground: snapshot.pendingCount > 0
          ? scheme.primary
          : scheme.onSurfaceVariant,
      background: scheme.surfaceContainerHighest,
    ),
  };
}

String _syncLabel(SyncSnapshot snapshot) {
  final pending = PersianNumberFormatter.toPersian(
    snapshot.pendingCount.toString(),
  );
  return switch (snapshot.phase) {
    SyncPhase.syncing => 'در حال همگام‌سازی...',
    SyncPhase.synced =>
      snapshot.pendingCount == 0
          ? 'همه تغییرات ذخیره شد'
          : '$pending تغییر در صف sync است',
    SyncPhase.offline =>
      snapshot.pendingCount == 0
          ? 'اتصال به سرور برقرار نیست'
          : 'آفلاین - $pending تغییر ذخیره‌نشده روی سرور',
    SyncPhase.error =>
      snapshot.message?.isNotEmpty == true ? snapshot.message! : 'خطا در sync',
    SyncPhase.idle =>
      snapshot.pendingCount == 0 ? '' : '$pending تغییر در صف sync است',
  };
}

class _SyncVisuals {
  final IconData icon;
  final Color foreground;
  final Color background;

  const _SyncVisuals({
    required this.icon,
    required this.foreground,
    required this.background,
  });
}
