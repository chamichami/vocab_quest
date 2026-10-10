import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'app_config.dart';

class CloudinaryException implements Exception {
  final String message;
  const CloudinaryException(this.message);
  @override
  String toString() => message;
}

class PickedImage {
  final Uint8List bytes;
  final String name;
  const PickedImage(this.bytes, this.name);
}

class CloudinaryService {
  static bool get isConfigured => AppConfig.cloudinaryConfigured;

  static const configurationMessage =
      'Photo uploads are not set up yet. Add your Cloudinary cloud name and unsigned upload preset in lib/app_config.dart.';

  static Future<PickedImage?> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    return PickedImage(await file.readAsBytes(), file.name);
  }

  static Future<String> uploadAvatar(PickedImage image) async {
    if (!isConfigured) {
      throw const CloudinaryException(configurationMessage);
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..fields['folder'] = 'vocab_quest/avatars'
      ..files.add(
        http.MultipartFile.fromBytes('file', image.bytes, filename: image.name),
      );

    try {
      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 30)),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final msg = (body['error'] as Map?)?['message'] ?? 'Upload failed.';
        throw CloudinaryException('$msg');
      }

      final url = body['secure_url'] as String;
      return url.replaceFirst(
        '/upload/',
        '/upload/c_fill,g_auto,w_400,h_400,f_auto,q_auto/',
      );
    } on CloudinaryException {
      rethrow;
    } catch (_) {
      throw const CloudinaryException('Upload failed. Check your connection.');
    }
  }
}
