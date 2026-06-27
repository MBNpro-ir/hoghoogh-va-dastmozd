import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_client.dart';
import '../../services/company_service.dart';
import '../../services/sync_service.dart';
import '../../utils/animations.dart';
import '../home_screen.dart';

enum _ServerAuthMode { choices, login, register }

class ServerLoginScreen extends StatefulWidget {
  const ServerLoginScreen({super.key});

  @override
  State<ServerLoginScreen> createState() => _ServerLoginScreenState();
}

class _ServerLoginScreenState extends State<ServerLoginScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  final _companyService = CompanyService();
  final _sync = SyncService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerNotesController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  _ServerAuthMode _mode = _ServerAuthMode.choices;
  bool _loading = false;
  bool _checkingPendingRegistration = false;
  bool _showLoginPassword = false;
  bool _showRegisterPassword = false;
  bool _showRegisterConfirm = false;
  String _error = '';
  String _info = '';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryPendingRegistrationLogin();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _registerNameController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    _registerPhoneController.dispose();
    _registerNotesController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
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
            child: SlideTransition(
              position: _slide,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: switch (_mode) {
                        _ServerAuthMode.choices => _buildChoiceContent(
                          context,
                          scheme,
                        ),
                        _ServerAuthMode.login => _buildLoginContent(
                          context,
                          scheme,
                        ),
                        _ServerAuthMode.register => _buildRegisterContent(
                          context,
                          scheme,
                        ),
                      },
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

  Widget _buildChoiceContent(BuildContext context, ColorScheme scheme) {
    return Column(
      key: const ValueKey('choices'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Logo(),
        const SizedBox(height: 20),
        Text('HvM', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          _checkingPendingRegistration
              ? 'در حال بررسی تایید ثبت‌نام شما...'
              : 'برای ادامه یکی از گزینه‌ها را انتخاب کنید.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        if (_info.isNotEmpty) _InfoBanner(_info),
        if (_error.isNotEmpty) _ErrorBanner(_error),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _loading
                ? null
                : () => setState(() {
                    _mode = _ServerAuthMode.register;
                    _error = '';
                    _info = '';
                  }),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('ثبت نام'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.tonalIcon(
            onPressed: _loading
                ? null
                : () => setState(() {
                    _mode = _ServerAuthMode.login;
                    _error = '';
                    _info = '';
                  }),
            icon: const Icon(Icons.login_rounded),
            label: const Text('ورود'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _openSupport,
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('پشتیبانی'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginContent(BuildContext context, ColorScheme scheme) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          key: const ValueKey('login'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _BackToChoices(onPressed: _loading ? null : _backToChoices),
            const _Logo(),
            const SizedBox(height: 20),
            Text(
              'ورود به HvM',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'نام کاربری و رمز عبور سرور می‌تواند توسط Google Password Manager ذخیره شود.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            if (_error.isNotEmpty) _ErrorBanner(_error),
            _TapField(
              focusNode: _usernameFocus,
              controller: _usernameController,
              label: 'نام کاربری',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
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
              suffixIcon: IconButton(
                tooltip: _showLoginPassword ? 'مخفی کردن رمز' : 'نمایش رمز',
                onPressed: () =>
                    setState(() => _showLoginPassword = !_showLoginPassword),
                icon: Icon(
                  _showLoginPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
              obscureText: !_showLoginPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_loading) _login();
              },
              autofillHints: const [AutofillHints.password],
              validator: (v) =>
                  v == null || v.isEmpty ? 'رمز عبور الزامی است' : null,
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: const Text('ورود به حساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterContent(BuildContext context, ColorScheme scheme) {
    return Form(
      key: _registerFormKey,
      child: AutofillGroup(
        child: Column(
          key: const ValueKey('register'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _BackToChoices(onPressed: _loading ? null : _backToChoices),
            const _Logo(),
            const SizedBox(height: 20),
            Text('ثبت نام', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'درخواست شما برای ادمین سرور ارسال می‌شود و بعد از تایید، ورود خودکار انجام می‌شود.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            if (_error.isNotEmpty) _ErrorBanner(_error),
            _TapField(
              controller: _registerNameController,
              label: 'نام و نام خانوادگی',
              prefixIcon: Icons.badge_outlined,
              autofillHints: const [AutofillHints.name],
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'نام و نام خانوادگی الزامی است'
                  : null,
            ),
            const SizedBox(height: 12),
            _TapField(
              controller: _registerUsernameController,
              label: 'نام کاربری',
              prefixIcon: Icons.person_outline_rounded,
              autofillHints: const [AutofillHints.username],
              validator: (v) => v == null || v.trim().length < 4
                  ? 'نام کاربری باید حداقل ۴ کاراکتر باشد'
                  : null,
            ),
            const SizedBox(height: 12),
            _TapField(
              controller: _registerPhoneController,
              label: 'شماره تماس',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            const SizedBox(height: 12),
            _TapField(
              controller: _registerPasswordController,
              label: 'رمز عبور',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                tooltip: _showRegisterPassword ? 'مخفی کردن رمز' : 'نمایش رمز',
                onPressed: () => setState(
                  () => _showRegisterPassword = !_showRegisterPassword,
                ),
                icon: Icon(
                  _showRegisterPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
              obscureText: !_showRegisterPassword,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => _isStrongPassword(value ?? '')
                  ? null
                  : 'رمز باید ۱۲ کاراکتر و شامل حرف بزرگ، حرف کوچک، عدد و نماد باشد',
            ),
            const SizedBox(height: 12),
            _TapField(
              controller: _registerConfirmController,
              label: 'تکرار رمز عبور',
              prefixIcon: Icons.lock_reset_rounded,
              suffixIcon: IconButton(
                tooltip: _showRegisterConfirm ? 'مخفی کردن رمز' : 'نمایش رمز',
                onPressed: () => setState(
                  () => _showRegisterConfirm = !_showRegisterConfirm,
                ),
                icon: Icon(
                  _showRegisterConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
              obscureText: !_showRegisterConfirm,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => value == _registerPasswordController.text
                  ? null
                  : 'تکرار رمز با رمز عبور یکسان نیست',
            ),
            const SizedBox(height: 12),
            _TapField(
              controller: _registerNotesController,
              label: 'توضیحات برای ادمین',
              prefixIcon: Icons.notes_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _loading ? null : _register,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('ارسال درخواست ثبت نام'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _backToChoices() {
    setState(() {
      _mode = _ServerAuthMode.choices;
      _error = '';
      _info = '';
    });
  }

  Future<void> _openSupport() async {
    final uri = Uri.parse('https://t.me/mbnproo');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      await Clipboard.setData(
        const ClipboardData(text: 'https://t.me/mbnproo'),
      );
      setState(() => _info = 'لینک پشتیبانی کپی شد.');
    }
  }

  Future<void> _tryPendingRegistrationLogin() async {
    final credentials = await _api.getPendingRegistrationCredentials();
    if (credentials == null || !mounted) return;
    setState(() {
      _checkingPendingRegistration = true;
      _info = 'درخواست ثبت‌نام شما هنوز در انتظار تایید ادمین است.';
    });
    try {
      final body = await _api.login(
        username: credentials['username']!,
        password: credentials['password']!,
      );
      await _enterAppAfterLogin(body, credentials['password']!);
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingPendingRegistration = false);
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
      _info = '';
    });
    try {
      await _api.registerRequest(
        fullName: _registerNameController.text.trim(),
        username: _registerUsernameController.text.trim(),
        password: _registerPasswordController.text,
        phone: _registerPhoneController.text.trim(),
        notes: _registerNotesController.text.trim(),
      );
      TextInput.finishAutofillContext(shouldSave: true);
      if (!mounted) return;
      setState(() {
        _mode = _ServerAuthMode.choices;
        _info =
            'درخواست ثبت‌نام ارسال شد. بعد از تایید ادمین، با باز کردن برنامه ورود خودکار انجام می‌شود.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      _sync.stopAutoSync();
      var body = await _api.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      await _enterAppAfterLogin(body, _passwordController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enterAppAfterLogin(
    Map<String, dynamic> body,
    String currentPassword,
  ) async {
    var user = body['user'] is Map
        ? Map<String, dynamic>.from(body['user'] as Map)
        : null;
    if (user?['must_change_password'] == true) {
      if (!mounted) return;
      final newPassword = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _PasswordChangeDialog(),
      );
      if (newPassword == null) {
        await _api.clearSession();
        if (!mounted) return;
        setState(
          () => _error = 'برای ادامه، تغییر رمز در ورود بعدی الزامی شده است.',
        );
        return;
      }
      body = await _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      user = body['user'] is Map
          ? Map<String, dynamic>.from(body['user'] as Map)
          : user;
    }
    await _sync.registerLoginSession(user);
    await _companyService.syncCurrentCompanyFromSession();
    TextInput.finishAutofillContext(shouldSave: true);
    await _sync.bootstrapFromServer(markBootstrapComplete: true);
    await _sync.startAutoSync();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }
}

class _TapField extends StatefulWidget {
  final FocusNode? focusNode;
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const _TapField({
    this.focusNode,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<_TapField> createState() => _TapFieldState();
}

class _TapFieldState extends State<_TapField> {
  late TextDirection _direction;

  @override
  void initState() {
    super.initState();
    _direction = _directionFor(widget.controller.text);
    widget.controller.addListener(_syncDirection);
  }

  @override
  void didUpdateWidget(covariant _TapField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_syncDirection);
    _direction = _directionFor(widget.controller.text);
    widget.controller.addListener(_syncDirection);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncDirection);
    super.dispose();
  }

  void _syncDirection() {
    final next = _directionFor(widget.controller.text);
    if (next == _direction) return;
    setState(() => _direction = next);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: widget.focusNode,
      controller: widget.controller,
      autofocus: false,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      textDirection: _direction,
      textAlign: _direction == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.prefixIcon),
        suffixIcon: widget.suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

TextDirection _directionFor(String value) {
  for (final rune in value.runes) {
    if ((rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF)) {
      return TextDirection.rtl;
    }
    if ((rune >= 0x0041 && rune <= 0x005A) ||
        (rune >= 0x0061 && rune <= 0x007A) ||
        (rune >= 0x0030 && rune <= 0x0039)) {
      return TextDirection.ltr;
    }
  }
  return TextDirection.rtl;
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 118,
      height: 86,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
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

class _InfoBanner extends StatelessWidget {
  final String message;
  const _InfoBanner(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: AppDurations.short,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _BackToChoices extends StatelessWidget {
  final VoidCallback? onPressed;
  const _BackToChoices({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('بازگشت'),
      ),
    );
  }
}

class _PasswordChangeDialog extends StatefulWidget {
  const _PasswordChangeDialog();

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغییر رمز عبور'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'مدیر سیستم درخواست کرده است در این ورود رمز عبور خود را تغییر دهید.',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: !_showPassword,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: 'رمز جدید',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'مخفی کردن رمز' : 'نمایش رمز',
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                ),
                validator: (value) => _isStrongPassword(value ?? '')
                    ? null
                    : 'رمز باید ۱۲ کاراکتر و شامل حرف بزرگ، حرف کوچک، عدد و نماد باشد',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: !_showConfirm,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: 'تکرار رمز جدید',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    tooltip: _showConfirm ? 'مخفی کردن رمز' : 'نمایش رمز',
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                    icon: Icon(
                      _showConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                ),
                validator: (value) => value == _password.text
                    ? null
                    : 'تکرار رمز با رمز جدید یکسان نیست',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _password.text);
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('ثبت رمز جدید'),
        ),
      ],
    );
  }
}

bool _isStrongPassword(String value) {
  return value.length >= 12 &&
      RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(value);
}
