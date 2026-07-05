import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageOptimizationResult {
  const ImageOptimizationResult({
    required this.bytes,
    required this.contentType,
    required this.fileExtension,
    required this.wasCompressed,
    this.thumbnailBytes,
  });

  final Uint8List bytes;
  final String contentType;
  final String fileExtension;
  final bool wasCompressed;
  final Uint8List? thumbnailBytes;
}

class ImageOptimizationService {
  const ImageOptimizationService._();

  static const int maxUploadBytes = 8 * 1024 * 1024;
  static const int maxImageSide = 1600;
  static const int thumbnailSide = 420;

  static ImageOptimizationResult prepareForUpload(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('ملف الصورة فارغ.');
    }
    if (bytes.length > maxUploadBytes) {
      throw const FormatException('حجم الصورة كبير جداً. الحد الأعلى 8MB.');
    }
    final _ImageSignature signature = _detectSignature(bytes);
    if (!signature.isSupported) {
      throw const FormatException('نوع الصورة غير مدعوم. استخدم JPG أو PNG أو WebP.');
    }
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('تعذر قراءة الصورة. قد يكون الملف تالفاً.');
    }

    final img.Image normalized = img.bakeOrientation(decoded);
    final bool needsResize = normalized.width > maxImageSide || normalized.height > maxImageSide;
    final img.Image uploadImage = needsResize
        ? img.copyResize(
            normalized,
            width: normalized.width >= normalized.height ? maxImageSide : null,
            height: normalized.height > normalized.width ? maxImageSide : null,
            interpolation: img.Interpolation.average,
          )
        : normalized;
    final Uint8List uploadBytes = Uint8List.fromList(img.encodeJpg(uploadImage, quality: 82));
    final img.Image thumb = img.copyResize(
      normalized,
      width: normalized.width >= normalized.height ? thumbnailSide : null,
      height: normalized.height > normalized.width ? thumbnailSide : null,
      interpolation: img.Interpolation.average,
    );
    final Uint8List thumbnailBytes = Uint8List.fromList(img.encodeJpg(thumb, quality: 70));
    final bool wasCompressed = needsResize || uploadBytes.length < bytes.length;
    return ImageOptimizationResult(
      bytes: uploadBytes,
      contentType: 'image/jpeg',
      fileExtension: 'jpg',
      wasCompressed: wasCompressed,
      thumbnailBytes: thumbnailBytes,
    );
  }

  static _ImageSignature _detectSignature(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return const _ImageSignature('image/jpeg', 'jpg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return const _ImageSignature('image/png', 'png');
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return const _ImageSignature('image/webp', 'webp');
    }
    return const _ImageSignature('', '');
  }
}

class _ImageSignature {
  const _ImageSignature(this.contentType, this.extension);

  final String contentType;
  final String extension;

  bool get isSupported => contentType.isNotEmpty;
}
