import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/app_theme.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loadingEmail = false;
  bool _loadingGoogle = false;
  bool _loadingGitHub = false;
  bool _loadingApple = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _anyLoading =>
      _loadingEmail || _loadingGoogle || _loadingGitHub || _loadingApple;

  void _setError(Object e) {
    setState(() => _error = ref.read(authServiceProvider).parseError(e));
  }

  Future<void> _register() async {
    debugPrint('🔴 _register() llamado');
    debugPrint('🔴 nombre: "${_nameCtrl.text}"');
    debugPrint('🔴 email: "${_emailCtrl.text}"');
    debugPrint('🔴 password length: ${_passCtrl.text.length}');
    final isValid = _formKey.currentState!.validate();
    debugPrint('🔴 FORMULARIO VALIDO: $isValid');
    if (!isValid) return;

    setState(() {
      _loadingEmail = true;
      _error = null;
    });

    try {
      debugPrint('🔴 Intentando crear cuenta: ${_emailCtrl.text.trim()}');
      await ref.read(authServiceProvider).signUpWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            fullName: _nameCtrl.text.trim(),
          );
      debugPrint('🔴 Cuenta creada exitosamente');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      debugPrint('🔴 ERROR: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error detallado'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _oauth(
      Future<void> Function() action, void Function(bool) setLoading) async {
    setState(() {
      _error = null;
      setLoading(true);
    });
    try {
      await action();
    } catch (e) {
      _setError(e);
    } finally {
      if (mounted) setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔴 BUILD - anyLoading: $_anyLoading, email: $_loadingEmail');
    final svc = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Empieza gratis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
              const Gap(4),
              Text(
                'Crea tu cuenta con email o una red social',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ).animate().fadeIn(delay: 50.ms),
              const Gap(28),
              _OAuthRow(
                loadingGoogle: _loadingGoogle,
                loadingGitHub: _loadingGitHub,
                loadingApple: _loadingApple,
                disabled: _anyLoading,
                onGoogle: () => _oauth(svc.signInWithGoogle,
                    (v) => setState(() => _loadingGoogle = v)),
                onGitHub: () => _oauth(svc.signInWithGitHub,
                    (v) => setState(() => _loadingGitHub = v)),
                onApple: () => _oauth(svc.signInWithApple,
                    (v) => setState(() => _loadingApple = v)),
              ).animate().fadeIn(delay: 100.ms),
              const Gap(24),
              _DividerOr().animate().fadeIn(delay: 150.ms),
              const Gap(24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Ingresa tu nombre'
                          : null,
                    ).animate().fadeIn(delay: 200.ms),
                    const Gap(14),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu correo';
                        if (!v.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ).animate().fadeIn(delay: 240.ms),
                    const Gap(14),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Mínimo 6 caracteres',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Ingresa una contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ).animate().fadeIn(delay: 280.ms),
                    if (_error != null) ...[
                      const Gap(10),
                      _ErrorBanner(message: _error!)
                          .animate()
                          .fadeIn()
                          .shake(hz: 3, offset: const Offset(4, 0)),
                    ],
                    const Gap(22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _register, // 👈 sin deshabilitar por ahora
                        child: _loadingEmail
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Crear cuenta'),
                      ),
                    ).animate().fadeIn(delay: 320.ms),
                  ],
                ),
              ),
              const Gap(28),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey.shade600),
                      children: [
                        const TextSpan(text: '¿Ya tienes cuenta? '),
                        TextSpan(
                          text: 'Inicia sesión',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 380.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _OAuthRow extends StatelessWidget {
  final bool loadingGoogle, loadingGitHub, loadingApple, disabled;
  final VoidCallback onGoogle, onGitHub, onApple;

  const _OAuthRow({
    required this.loadingGoogle,
    required this.loadingGitHub,
    required this.loadingApple,
    required this.disabled,
    required this.onGoogle,
    required this.onGitHub,
    required this.onApple,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OAuthIcon(icon: FontAwesomeIcons.google, color: AppTheme.googleRed,
            loading: loadingGoogle, disabled: disabled, onTap: onGoogle, tooltip: 'Google'),
        const Gap(12),
        _OAuthIcon(icon: FontAwesomeIcons.github, color: AppTheme.githubDark,
            loading: loadingGitHub, disabled: disabled, onTap: onGitHub, tooltip: 'GitHub'),
        const Gap(12),
        _OAuthIcon(icon: FontAwesomeIcons.apple, color: AppTheme.appleBlack,
            loading: loadingApple, disabled: disabled, onTap: onApple, tooltip: 'Apple'),
      ],
    );
  }
}

class _OAuthIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool loading, disabled;
  final VoidCallback onTap;
  final String tooltip;

  const _OAuthIcon({
    required this.icon, required this.color, required this.loading,
    required this.disabled, required this.onTap, required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: disabled ? Colors.grey.shade200 : color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: loading
                  ? SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : FaIcon(icon, size: 20,
                      color: disabled ? Colors.grey.shade300 : color),
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerOr extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('o con email',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 16),
          const Gap(8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}