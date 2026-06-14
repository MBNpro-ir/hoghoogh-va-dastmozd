import 'package:flutter/material.dart';

import 'screens/auth/local_unlock_screen.dart';
import 'services/local_security_service.dart';
import 'services/sync_service.dart';

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  final _sync = SyncService();
  final _security = LocalSecurityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (await _security.hasCredential() && await _security.requiresUnlock()) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LocalUnlockScreen()),
          (_) => false,
        );
        return;
      }
      await _sync.startAutoSync();
      await _sync.syncNow(silent: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (await _security.hasCredential()) {
        await _security.setRequiresUnlock(true);
      }
      _sync.stopAutoSync();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
