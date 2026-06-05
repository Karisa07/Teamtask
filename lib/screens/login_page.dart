import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/app_theme.dart';
import 'package:teamtask/screens/register_page.dart';
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loadingEmail = false;
  bool _loadingGoogle = false;
  bool _loadingGitHub = false;
  //
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Helpers

  bool get _anyLoading =>
      _loadingEmail || _loadingGoogle || _loadingGitHub ;

  void _setError(Object e) {
    final svc = ref.read(authServiceProvider);
    setState(() => _error = svc.parseError(e));
  }

  //  Acciones 

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loadingEmail = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } catch (e) {
      _setError(e);
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() { _loadingGoogle = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      _setError(e);
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _loginGitHub() async {
    setState(() { _loadingGitHub = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGitHub();
    } catch (e) {
      _setError(e);
    } finally {
      if (mounted) setState(() => _loadingGitHub = false);
    }
  }


  // UI 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header()
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.15, end: 0),

              const Gap(40),

              // Formulario email 
              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                    ).animate().fadeIn(delay: 100.ms),

                    const Gap(14),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _loginEmail(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                    ).animate().fadeIn(delay: 150.ms),

                    const Gap(6),

                    // Error message
                    if (_error != null)
                      _ErrorBanner(message: _error!)
                          .animate()
                          .fadeIn()
                          .shake(hz: 3, offset: const Offset(4, 0)),

                    const Gap(20),

                    // Botón email
                    ElevatedButton(
                      onPressed: _anyLoading ? null : _loginEmail,
                      child: _loadingEmail
                          ? _Spinner()
                          : const Text('Iniciar sesión'),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),

              const Gap(28),

              // Divider
              _Divider().animate().fadeIn(delay: 250.ms),

              const Gap(20),

              // Botones OAuth
              _OAuthButton(
                label: 'Continuar con Google',
                icon: FontAwesomeIcons.google,
                color: AppTheme.googleRed,
                loading: _loadingGoogle,
                disabled: _anyLoading,
                onPressed: _loginGoogle,
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.08, end: 0),

              const Gap(12),

              _OAuthButton(
                label: 'Continuar con GitHub',
                icon: FontAwesomeIcons.github,
                color: AppTheme.githubDark,
                loading: _loadingGitHub,
                disabled: _anyLoading,
                onPressed: _loginGitHub,
              ).animate().fadeIn(delay: 360.ms).slideX(begin: 0.08, end: 0),

              const Gap(12),


              //Link a registro
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey.shade600),
                      children: [
                        const TextSpan(text: '¿Sin cuenta? '),
                        TextSpan(
                          text: 'Regístrate aquí',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 480.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// Sub-widgets

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.task_alt, color: Colors.white, size: 30),
        ),
        const Gap(24),
        const Text(
          'Bienvenido\na TeamTask',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.1,
          ),
        ),
        const Gap(10),
        Text(
          'Inicia sesión con tu cuenta preferida',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;
  final String? note;

  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.disabled,
    required this.onPressed,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(
              color: disabled ? Colors.grey.shade200 : color.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : FaIcon(icon, size: 18, color: color),
              const Gap(12),
              Text(
                label,
                style: TextStyle(
                  color: disabled ? Colors.grey.shade400 : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        if (note != null) ...[
          const Gap(4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              note!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o continúa con',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.errorColor, size: 16),
          const Gap(8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppTheme.errorColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}
