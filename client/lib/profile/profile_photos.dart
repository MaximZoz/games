import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/api_client.dart';
import 'package:multigames_client/core/api_config.dart';
import 'package:multigames_client/core/locale_provider.dart';

const int maxProfilePhotos = 3;

class ProfilePhotoMeta {
  const ProfilePhotoMeta({
    required this.id,
    required this.userId,
    required this.slot,
    required this.imageMime,
  });

  final String id;
  final String userId;
  final int slot;
  final String imageMime;

  factory ProfilePhotoMeta.fromJson(Map<String, dynamic> json) {
    return ProfilePhotoMeta(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      slot: (json['slot'] as num?)?.toInt() ?? 0,
      imageMime: json['image_mime'] as String? ?? 'image/jpeg',
    );
  }
}

/// Три слота 0..2: занятые фото или `null`.
List<ProfilePhotoMeta?> profilePhotoSlots(Iterable<ProfilePhotoMeta> photos) {
  final out = List<ProfilePhotoMeta?>.filled(maxProfilePhotos, null);
  for (final photo in photos) {
    if (photo.slot >= 0 && photo.slot < maxProfilePhotos) {
      out[photo.slot] = photo;
    }
  }
  return out;
}

/// Стабильная подпись состава галереи — чтобы форма «Сохранить»
/// видела добавление/замену/удаление фото.
String profilePhotosSignature(Iterable<ProfilePhotoMeta> photos) {
  final parts = photos
      .where((p) => p.id.isNotEmpty)
      .map((p) => '${p.slot}:${p.id}')
      .toList()
    ..sort();
  return parts.join('|');
}

class ProfilePhotosRepository {
  ProfilePhotosRepository({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<List<ProfilePhotoMeta>> listPhotos(String userId) async {
    final id = userId.trim();
    final uri = Uri.parse('$apiBaseUrl/api/profile/photos').replace(
      queryParameters: id.isEmpty ? null : {'user_id': id},
    );
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ProfilePhotosRepository.listPhotos',
      ),
    );
    if (response.statusCode != 200) {
      _throwForError(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['photos'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ProfilePhotoMeta.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  Future<Uint8List> fetchPhotoBytes(String photoId) async {
    final uri = Uri.parse('$apiBaseUrl/api/profile/photos/file').replace(
      queryParameters: {'id': photoId},
    );
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        operation: 'ProfilePhotosRepository.fetchPhotoBytes',
      ),
    );
    if (response.statusCode != 200) {
      _throwForError(response);
    }
    return response.bodyBytes;
  }

  Future<ProfilePhotoMeta> uploadPhoto({
    int? slot,
    required String imageBase64,
    String imageMime = 'image/jpeg',
  }) async {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/profile/photos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (slot != null) 'slot': slot,
          'image_base64': imageBase64,
          'image_mime': imageMime,
        }),
        operation: 'ProfilePhotosRepository.uploadPhoto',
      ),
    );
    if (response.statusCode != 200) {
      _throwForError(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final photo = body['photo'];
    if (photo is! Map) {
      throw AuthException(500, LocaleService.l10n.profilePhotoUploadFailed);
    }
    return ProfilePhotoMeta.fromJson(Map<String, dynamic>.from(photo));
  }

  Future<void> deletePhoto(String photoId) async {
    final response = await _auth.sendAuthorized(
      (token) => ApiClient.post(
        Uri.parse('$apiBaseUrl/api/profile/photos/delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': photoId}),
        operation: 'ProfilePhotosRepository.deletePhoto',
      ),
    );
    if (response.statusCode != 200) {
      _throwForError(response);
    }
  }

  Never _throwForError(http.Response response) {
    final l10n = LocaleService.l10n;
    if (response.statusCode == 409) {
      throw AuthException(409, l10n.profilePhotosLimit);
    }
    if (response.statusCode == 413) {
      throw AuthException(413, l10n.profilePhotoTooLarge);
    }
    String message = l10n.profilePhotoUploadFailed;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      }
    } catch (_) {}
    throw AuthException(response.statusCode, message);
  }
}

final profilePhotosRepositoryProvider = Provider<ProfilePhotosRepository>((ref) {
  return ProfilePhotosRepository(
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final profilePhotosProvider = FutureProvider.autoDispose
    .family<List<ProfilePhotoMeta>, String>((ref, userId) async {
  if (userId.trim().isEmpty) return const [];
  return ref.watch(profilePhotosRepositoryProvider).listPhotos(userId);
});
