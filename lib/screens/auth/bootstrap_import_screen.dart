import 'package:flutter/material.dart';

import '../../services/sync_service.dart';
import '../home_screen.dart';

class BootstrapImportScreen extends StatefulWidget {
  const BootstrapImportScreen({super.key});

  @override
  State<BootstrapImportScreen> createState() => _BootstrapImportScreenState();
}

class _BootstrapImportScreenState extends State<BootstrapImportScreen>
    with SingleTickerProviderStateMixin {
  final _sync = SyncService();
  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fade,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.cloud_upload_rounded,
                        size: 58,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'انتقال دیتای فعلی به سرور',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'داده‌های فعلی این دستگاه به شرکت همین حساب منتقل می‌شود و بعد از آن sync آنلاین فعال می‌ماند.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(_error),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _loading ? null : _import,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_rounded),
                        label: const Text('آپلود و فعال‌سازی sync'),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _loading ? null : _skip,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('بعدا انجام می‌دهم'),
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

  Future<void> _import() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await _sync.bootstrapImport();
      await _continue();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skip() async {
    await _sync.skipBootstrapImport();
    await _continue();
  }

  Future<void> _continue() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }
}
