import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teamtask/profile_provider.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/app_theme.dart';
import 'package:go_router/go_router.dart';


class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // TT-121: Subir foto de perfil
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final file = File(image.path);
      final userId = ref.read(currentUserProvider)?.id ?? '';
      await ref.read(profileRepositoryProvider).uploadAvatar(
            userId: userId,
            imageFile: file,
          );
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto actualizada'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // TT-119: Guardar nombre
  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(profileActionsProvider).updateName(
            _nameController.text.trim(),
          );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre actualizado'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (!_isEditing && profile?.fullName != null &&
              _nameController.text.isEmpty) {
            _nameController.text = profile!.fullName!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Gap(20),

                // TT-121: Avatar con botón de editar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppTheme.primaryColor,
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: profile?.avatarUrl == null
                          ? Text(
                              (profile?.fullName?.isNotEmpty == true)
                                  ? profile!.fullName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    // Botón cámara
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                    ),
                  ],
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

                const Gap(16),

                // Email
                Text(
                  currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const Gap(32),

                // TT-119: Editar nombre
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nombre completo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            if (!_isEditing)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isEditing = true),
                                child: const Text('Editar'),
                              ),
                          ],
                        ),
                        const Gap(8),
                        if (_isEditing) ...[
                          TextField(
                            controller: _nameController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Tu nombre completo',
                            ),
                          ),
                          const Gap(12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _isEditing = false),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveName,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Guardar'),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Text(
                            profile?.fullName ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                const Gap(16),

                // Proveedor de autenticación
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            color: AppTheme.primaryColor),
                        const Gap(12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cuenta verificada',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _detectProvider(currentUser?.appMetadata),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const Gap(32),

                // Cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(authServiceProvider).signOut(),
                    icon: const Icon(Icons.logout,
                        color: AppTheme.errorColor),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),
              ],
            ),
          );
        },
      ),
    );
  }

  String _detectProvider(Map<String, dynamic>? metadata) {
    if (metadata == null) return 'Email';
    final provider = metadata['provider'] as String? ?? 'email';
    switch (provider) {
      case 'google':
        return 'Iniciaste sesión con Google';
      case 'github':
        return 'Iniciaste sesión con GitHub';
      case 'apple':
        return 'Iniciaste sesión con Apple';
      default:
        return 'Iniciaste sesión con Email';
    }
  }
}