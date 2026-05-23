import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/app_theme.dart';

class HomePlaceholderPage extends ConsumerWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = user?.userMetadata?['full_name']?.toString() ??
        user?.email ??
        'Usuario';
    final provider = _detectProvider(user);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de éxito
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 52,
                    color: AppTheme.successColor,
                  ),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 500.ms,
                        curve: Curves.elasticOut)
                    .fadeIn(),

                const Gap(28),

                Text(
                  '¡Bienvenido!',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const Gap(8),

                Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const Gap(12),

                // Badge del proveedor usado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sesión iniciada con $provider',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const Gap(48),

                // Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: AppTheme.primaryColor),
                          const Gap(8),
                          const Text(
                            'Sprint completado ✅',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Gap(10),
                      Text(
                        'La autenticación multi-plataforma está funcionando.\n'
                        'El siguiente sprint conectará esta pantalla con el\n'
                        'tablero Kanban en tiempo real.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),

                const Gap(32),

                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authServiceProvider).signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _detectProvider(user) {
    if (user == null) return 'desconocido';
    final identities = user.identities;
    if (identities == null || identities.isEmpty) return 'Email';
    final p = identities.first.provider;
    switch (p) {
      case 'google': return 'Google';
      case 'github': return 'GitHub';
      case 'apple': return 'Apple';
      default: return 'Email';
    }
  }
}
