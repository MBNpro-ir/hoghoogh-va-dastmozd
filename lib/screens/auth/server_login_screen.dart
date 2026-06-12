import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/local_security_service.dart';
import '../../utils/animations.dart';
import '../home_screen.dart';
import 'local_unlock_setup_screen.dart';

class ServerLoginScreen extends StatefulWidget {
  const ServerLoginScreen({super.key});

  @override
  State<ServerLoginScreen> createState() => _ServerLoginScreenState();
}

class _ServerLoginScreenState extends State<ServerLoginScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _loadSavedUrl();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _serverFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedUrl() async {
    final url = await _api.getServerUrl();
    if (!mounted) return;
    _serverUrlController.text = url;
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
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Logo(),
                            const SizedBox(height: 20),
                            Text(
                              'ورود به HvM',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'نام کاربری و رمز عبور سرور با Google Autofill ذخیره می‌شود',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 22),
                            if (_error.isNotEmpty) _ErrorBanner(_error),
                            _TapField(
                              focusNode: _serverFocus,
                              controller: _serverUrlController,
                              label: 'آدرس سرور',
                              prefixIcon: Icons.dns_rounded,
                              autofillHints: const [AutofillHints.url],
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'آدرس سرور الزامی است'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _TapField(
                              focusNode: _usernameFocus,
                              controller: _usernameController,
                              label: 'نام کاربری',
                              prefixIcon: Icons.person_outline_rounded,
                              autofillHints: const [AutofillHints.username],
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'نام کاربری الزامی است'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _TapField(
                              focusNode: _passwordFocus,
                              controller: _passwordController,
                              label: 'رمز عبور سرور',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              validator: (v) => v == null || v.isEmpty
                                  ? 'رمز عبور الزامی است'
                                  : null,
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton.icon(
                                onPressed: _loading ? null : _login,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: const Text('ورود به حساب'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await _api.clearSession();
                                if (!context.mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.bug_report_rounded),
                              label: const Text('ورود آزمایشی بدون قفل'),
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
      ),
    );
  }

  Future<void> _login() async {
    final navigator = Navigator.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await _api.setServerUrl(_serverUrlController.text);
      await _api.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        serverUrl: _serverUrlController.text,
      );
      final hasLocal = await LocalSecurityService().hasCredential();
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              hasLocal ? const HomeScreen() : const LocalUnlockSetupScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _TapField extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final String? Function(String?)? validator;
  const _TapField({
    required this.focusNode,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      obscureText: obscureText,
      autofillHints: autofillHints,
      enableInteractiveSelection: false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.shield_moon_rounded,
        size: 42,
        color: Colors.white,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
