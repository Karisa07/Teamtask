import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teamtask/auth_provider.dart';
import 'package:teamtask/profile_repository.dart';

// Provider del repositorio
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

// Provider del perfil actual
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(userId);
});

// Provider para acciones del perfil
final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(
    repo: ref.watch(profileRepositoryProvider),
    userId: ref.watch(currentUserProvider)?.id ?? '',
    ref: ref,
  );
});

class ProfileActions {
  final ProfileRepository _repo;
  final String _userId;
  final Ref _ref;

  ProfileActions({
    required ProfileRepository repo,
    required String userId,
    required Ref ref,
  })  : _repo = repo,
        _userId = userId,
        _ref = ref;

  // Actualizar nombre
  Future<void> updateName(String newName) async {
    await _repo.updateProfile(
      userId: _userId,
      fullName: newName,
    );
    _ref.invalidate(profileProvider);
  }
}