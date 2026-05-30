import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  // TT-118: Obtener perfil del usuario
  Future<Profile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  // Actualizar nombre
  Future<void> updateProfile({
    required String userId,
    String? fullName,
  }) async {
    await _client
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', userId);
  }

  // Subir foto de perfil
  Future<String> uploadAvatar({
  required String userId,
  required File imageFile,
}) async {

  try {

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final filePath = '$userId/$fileName';

    // Subir imagen
    await _client.storage
        .from('Avatars')
        .upload(
          filePath,
          imageFile,
        );

    // Obtener URL pública
    final imageUrl = _client.storage
        .from('Avatars')
        .getPublicUrl(filePath);

    // Guardar en tabla profiles
    await _client
        .from('profiles')
        .update({
          'avatar_url': imageUrl,
        })
        .eq('id', userId);

    return imageUrl;

  } catch (e) {

    print('🔴 ERROR SUBIENDO AVATAR: $e');

    rethrow;
  }
}
}
