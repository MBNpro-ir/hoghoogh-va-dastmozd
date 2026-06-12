import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/local_security_service.dart';
import '../../utils/animations.dart';
import '../home_screen.dart';

class LocalUnlockScreen extends StatefulWidget {
  const LocalUnlockScreen({super.key});

  @override
  State<LocalUnlockScreen> createState() => _LocalUnlockScreenState();
}

class _LocalUnlockScreenState extends State<LocalUnlockScreen>
    with SingleTickerProviderStateMixin {
  final _security = LocalSecurityService();
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _error = '';
  bool _loading = false;
  bool _biometrics = false;
  late AnimationController _animationController;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadBiometrics();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometrics() async {
    final value = await _security.biometricsEnabled();
    if (!mounted) return;
    setState(() => _biometrics = value);
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
            child: SlideTransition(
              position: _slide,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              Icons.fingerprint_rounded,
                              size: 42,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'باز کردن HvM',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'رمز محلی یا بیومتریک را وارد کنید',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 18),
                          if (_biometrics) ...[
                            FilledButton.tonalIcon(
                              onPressed: _biometricUnlock,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text('استفاده از اثر انگشت/چهره'),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_error.isNotEmpty) _ErrorBanner(_error),
                          TextFormField(
                            controller: _controller,
                            autofocus: false,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            decoration: const InputDecoration(
                              labelText: 'رمز محلی',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'رمز الزامی است'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _unlock,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.lock_open_rounded),
                              label: const Text('باز کردن برنامه'),
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
      ),
    );
  }

  Future<void> _unlock() async {
    final navigator = Navigator.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await _security.verifyCredential(_controller.text);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.lightImpact();
      await _security.setRequiresUnlock(false);
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'رمز محلی اشتباه است');
    }
    setState(() => _loading = false);
  }

  Future<void> _biometricUnlock() async {
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    final ok = await _security.authenticateWithBiometrics();
    if (!mounted) return;
    if (ok) {
      await _security.setRequiresUnlock(false);
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _error = 'تشخیص بیومتریک انجام نشد');
    }
    setState(() => _loading = false);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: AppDurations.short,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
      ),
    );
  }
}
