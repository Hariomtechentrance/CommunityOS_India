import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_config.dart';

/// Uploads media bytes directly to Cloudinary using an unsigned upload
/// preset, so it works identically on Flutter web and mobile without our
/// backend ever handling file bytes - the backend just stores the resulting
/// URL string. Cloudinary treats audio the same as video (`resource_type:
/// video`), so one preset covers photos, videos, and voice notes.
class MediaUploadService {
  final Dio _dio = Dio();

  Future<String> _upload(List<int> bytes, String filename, String resourceType) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'upload_preset': cloudinaryUploadPreset,
    });
    final res = await _dio.post(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/$resourceType/upload',
      data: formData,
    );
    return res.data['secure_url'] as String;
  }

  Future<String> upload(XFile file) async {
    return _upload(await file.readAsBytes(), file.name, 'image');
  }

  Future<List<String>> uploadAll(List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await upload(file));
    }
    return urls;
  }

  Future<String> uploadVideo(XFile file) async {
    return _upload(await file.readAsBytes(), file.name, 'video');
  }

  Future<String> uploadAudio(List<int> bytes, String filename) async {
    return _upload(bytes, filename, 'video');
  }
}
