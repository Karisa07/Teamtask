import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/supabase_constants.dart';
import 'package:flutter/foundation.dart'; 


// Cliente Supabase global
 
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

 
// Stream del estado de sesión
 
final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((e) => e.session?.user);
});

// Usuario actual (sincrono)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

 
// Servicio de autenticación
 
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
      redirectTo: kIsWeb 
        ? 'http://localhost:3000'           // para web
        : SupabaseConstants.redirectUrl,    // para móvil
    authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }
                                            
  Future<void> signInWithGitHub() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: SupabaseConstants.redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  //      OAuth: Apple                                                 
  /// Apple Sign In solo funciona en dispositivos iOS/macOS reales
  /// con un Apple Developer Account configurado.
  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: SupabaseConstants.redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  //      Cerrar sesión                                               
  Future<void> signOut() => _client.auth.signOut();

  //      Helpers                                                           
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
