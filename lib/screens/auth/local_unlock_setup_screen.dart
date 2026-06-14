import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/local_security_service.dart';
import '../home_screen.dart';

class LocalUnlockSetupScreen extends StatefulWidget {
  final bool returnToPrevious;

  const LocalUnlockSetupScreen({super.key, this.returnToPrevious = false});

  @override
  State<LocalUnlockSetupScreen> createState() => _LocalUnlockSetupScreenState();
}

class _LocalUnlockSetupScreenState extends State<LocalUnlockSetupScreen>
    with SingleTickerProviderStateMixin {
  final _security = LocalSecurityService();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  LocalCredentialMethod _method = LocalCredentialMethod.pin;
  bool _enableBiometrics = false;
  bool _loading = false;
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _security.canUseBiometrics().then((v) {
      if (mounted) setState(() => _enableBiometrics = v);
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ساخت رمز ورود به برنامه')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SlideTransition(
            position: _slide,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.lock_person_rounded,
                          size: 54,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'رمز محلی HvM',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'این رمز با رمز سرور فرق دارد و فقط روی همین دستگاه برای باز کردن برنامه استفاده می‌شود.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 22),
                        SegmentedButton<LocalCredentialMethod>(
                          selected: {_method},
                          onSelectionChanged: (v) =>
                              setState(() => _method = v.first),
                          segments: const [
                            ButtonSegment(
                              value: LocalCredentialMethod.pin,
                              label: Text('PIN'),
                              icon: Icon(Icons.pin_rounded),
                            ),
                            ButtonSegment(
                              value: LocalCredentialMethod.password,
                              label: Text('Password'),
                              icon: Icon(Icons.password_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: _method == LocalCredentialMethod.pin
                              ? TextInputType.number
                              : TextInputType.visiblePassword,
                          decoration: const InputDecoration(
                            labelText: 'رمز محلی',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null ||
                                  v.length <
                                      (_method == LocalCredentialMethod.pin
                                          ? 4
                                          : 8)
                              ? 'رمز کوتاه است'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: true,
                          keyboardType: _method == LocalCredentialMethod.pin
                              ? TextInputType.number
                              : TextInputType.visiblePassword,
                          decoration: const InputDecoration(
                            labelText: 'تکرار رمز',
                            prefixIcon: Icon(Icons.lock_reset_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v != _pinController.text
                              ? 'تکرار رمز مطابقت ندارد'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<bool>(
                          future: _security.canUseBiometrics(),
                          builder: (context, snapshot) => SwitchListTile(
                            value: _enableBiometrics && snapshot.data == true,
                            onChanged: snapshot.data == true
                                ? (v) => setState(() => _enableBiometrics = v)
                                : null,
                            secondary: const Icon(Icons.fingerprint_rounded),
                            title: const Text(
                              'استفاده از اثر انگشت یا تشخیص چهره',
                            ),
                            subtitle: const Text(
                              'برای باز کردن سریع‌تر برنامه',
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _loading ? null : _save,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: const Text('فعال‌سازی قفل'),
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
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      await _security.createCredential(
        value: _pinController.text,
        method: _method,
        enableBiometrics: _enableBiometrics,
      );
      await _security.setRequiresUnlock(false);
      if (!mounted) return;
      if (widget.returnToPrevious) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در فعال‌سازی قفل: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
