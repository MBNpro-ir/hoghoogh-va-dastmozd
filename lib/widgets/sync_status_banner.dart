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
        final data = _visuals(snapshot, scheme);
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
                    _label(snapshot),
                    maxLines: 1,
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
                      : () => sync.syncNow(),
                  icon: Icon(Icons.sync_rounded, color: data.foreground),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _SyncVisuals _visuals(SyncSnapshot snapshot, ColorScheme scheme) {
    return switch (snapshot.phase) {
      SyncPhase.syncing => _SyncVisuals(
        icon: Icons.sync_rounded,
        foreground: scheme.primary,
        background: scheme.primaryContainer.withValues(alpha: 0.42),
      ),
      SyncPhase.synced => _SyncVisuals(
        icon: Icons.check_circle_rounded,
        foreground: Colors.green.shade700,
        background: Colors.green.withValues(alpha: 0.12),
      ),
      SyncPhase.offline => _SyncVisuals(
        icon: Icons.cloud_off_rounded,
        foreground: scheme.error,
        background: scheme.errorContainer.withValues(alpha: 0.52),
      ),
      SyncPhase.error => _SyncVisuals(
        icon: Icons.error_rounded,
        foreground: scheme.error,
        background: scheme.errorContainer.withValues(alpha: 0.52),
      ),
      SyncPhase.idle => _SyncVisuals(
        icon: Icons.sync_problem_rounded,
        foreground: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHighest,
      ),
    };
  }

  String _label(SyncSnapshot snapshot) {
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
        snapshot.message?.isNotEmpty == true
            ? snapshot.message!
            : 'خطا در sync',
      SyncPhase.idle =>
        snapshot.pendingCount == 0 ? '' : '$pending تغییر در صف sync است',
    };
  }
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
