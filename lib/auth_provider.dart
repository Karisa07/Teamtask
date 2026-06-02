import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'constants/supabase_constants.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);

  // Emitir un valor inicial (sesión persistida si existe)
  // y luego seguir con los cambios reales del auth.
  final initialUser = client.auth.currentUser;

  // Construimos un stream con valor inicial (currentUser) y luego el stream real.
  return Stream<User?>.multi((controller) {
    controller.add(initialUser);

    final sub = client.auth
        .onAuthStateChange
        .map((e) => e.session?.user)
        .listen(
          (user) => controller.add(user),
          onError: controller.addError,
        );

    controller.onCancel = () => sub.cancel();
  });
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (res.user != null) {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'email': email,
          'full_name': fullName,
        });
      }
      return res;
    } catch (e) {
      debugPrint('🔴 ERROR SIGNUP: $e');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
  await _client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: SupabaseConstants.redirectUrl,
    authScreenLaunchMode: LaunchMode.externalApplication,
    queryParams: {
      'access_type': 'offline',
      'prompt': 'select_account',
    },
  );
}
  

  Future<void> signInWithGitHub() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: SupabaseConstants.redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: SupabaseConstants.redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  bool get isAuthenticated => _client.auth.currentUser != null;
  User? get currentUser => _client.auth.currentUser;

  String _parseError(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Confirma tu correo antes de continuar';
    }
    if (raw.contains('already registered')) {
      return 'Este correo ya tiene una cuenta';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }

  String parseError(Object e) => _parseError(e.toString());
}