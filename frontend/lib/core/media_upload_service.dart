import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'cloudinary_config.dart';

/// Uploads media bytes directly to Cloudinary (so our backend never handles
/// file bytes - it just stores the resulting URL), using a freshly-signed,
/// single-use upload credential from our own backend instead of a reusable
/// unsigned upload preset. A preset's cloud name + preset name are both
/// embedded in the shipped app - anyone who decompiles it or sniffs its
/// traffic could otherwise upload arbitrary files to this Cloudinary
/// account forever, with no rate limit and no auth. A signature is tied to
/// one timestamp and one request, so there's nothing reusable to extract.
class MediaUploadService {
  final ApiClient _apiClient;
  final Dio _cloudinaryDio = Dio();

  MediaUploadService(this._apiClient);

  Future<String> _upload(List<int> bytes, String filename, String resourceType) async {
    final sigRes = await _apiClient.dio.get('/media/cloudinary-signature');
    final signature = sigRes.data as Map<String, dynamic>;

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'api_key': signature['apiKey'],
      'timestamp': signature['timestamp'],
      'signature': signature['signature'],
    });
    final res = await _cloudinaryDio.post(
      'https://api.cloudinary.com/v1_1/${signature['cloudName'] ?? cloudinaryCloudName}/$resourceType/upload',
      data: formData,
    );
    return res.data['secure_url'] as String;
  }

  Future<String> upload(XFile file) async {
    return _upload(await file.readAsBytes(), file.name, 'image');
  }

  /// For images composited client-side (e.g. stickers baked onto a photo)
  /// rather than picked directly from the device, so there's no [XFile].
  Future<String> uploadImageBytes(List<int> bytes, String filename) async {
    return _upload(bytes, filename, 'image');
  }

  /// Uploads every file concurrently instead of one at a time - a 5-photo
  /// post was previously paying for 5x the network round-trip time
  /// sequentially; Cloudinary has no issue with parallel uploads from one
  /// client, so there's no reason not to.
  Future<List<String>> uploadAll(List<XFile> files) {
    return Future.wait(files.map(upload));
  }

  Future<String> uploadVideo(XFile file) async {
    return _upload(await file.readAsBytes(), file.name, 'video');
  }

  Future<String> uploadAudio(List<int> bytes, String filename) async {
    return _upload(bytes, filename, 'video');
  }
}

final mediaUploadServiceProvider = Provider<MediaUploadService>(
  (ref) => MediaUploadService(ref.read(apiClientProvider)),
);
