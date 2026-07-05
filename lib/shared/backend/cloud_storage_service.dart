import 'dart:typed_data';

import '../services/image_optimization_service.dart';
import 'remote_backend_client.dart';

class CloudStorageService {
  const CloudStorageService(this._backend);

  final RemoteBackendClient? _backend;

  bool get isEnabled => _backend?.isEnabled ?? false;

  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String ownerUserId,
    required String folder,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    if (!isEnabled) {
      return null;
    }
    final ImageOptimizationResult optimized = ImageOptimizationService.prepareForUpload(bytes);
    final String cleanedFolder = folder.replaceAll(RegExp('[^a-zA-Z0-9_/-]'), '_');
    final String cleanedName = _safeFileName(fileName, optimized.fileExtension);
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String path = '$ownerUserId/$cleanedFolder/${timestamp}_$cleanedName';
    final String publicUrl = await _backend!.uploadBytes(
      bytes: optimized.bytes,
      path: path,
      contentType: optimized.contentType,
    );
    final Uint8List? thumbnailBytes = optimized.thumbnailBytes;
    if (thumbnailBytes != null) {
      final String thumbnailPath = '$ownerUserId/$cleanedFolder/thumbnails/${timestamp}_$cleanedName';
      await _backend!.uploadBytes(
        bytes: thumbnailBytes,
        path: thumbnailPath,
        contentType: optimized.contentType,
      );
    }
    return publicUrl;
  }

  String _safeFileName(String rawName, String extension) {
    final String cleanedName = rawName.replaceAll(RegExp('[^a-zA-Z0-9_.-]'), '_');
    if (cleanedName.trim().isEmpty) {
      return 'image.$extension';
    }
    if (RegExp(r'\.(jpg|jpeg|png|webp)$', caseSensitive: false).hasMatch(cleanedName)) {
      return cleanedName;
    }
    return '$cleanedName.$extension';
  }
}
