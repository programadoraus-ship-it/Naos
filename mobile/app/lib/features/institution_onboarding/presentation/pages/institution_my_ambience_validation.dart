import 'dart:typed_data';
import 'dart:ui' as ui;

import 'institution_brand_draft.dart';

class MyAmbienceValidationException implements Exception {
  const MyAmbienceValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Checks encoded bytes, not the picker-provided MIME type or extension alone.
Future<MyAmbienceFile> validateMyAmbienceFile(
  String name,
  Uint8List bytes, {
  required bool element,
}) async {
  final limit = element ? 2 * 1024 * 1024 : 5 * 1024 * 1024;
  if (bytes.isEmpty || bytes.length > limit) {
    throw MyAmbienceValidationException(
      element
          ? 'Each element must be at most 2 MB.'
          : 'The background must be at most 5 MB.',
    );
  }
  final lower = name.toLowerCase();
  final format = _detectFormat(bytes);
  final extension = lower.contains('.') ? lower.split('.').last : '';
  final matching = switch (format) {
    'PNG' => extension == 'png',
    'JPEG' => extension == 'jpg' || extension == 'jpeg',
    'WebP' => extension == 'webp',
    _ => false,
  };
  if (!matching || (element && format == 'JPEG')) {
    throw MyAmbienceValidationException(
      element
          ? 'Choose a real PNG or WebP image with transparency (not SVG, JPG or animation).'
          : 'Choose a real PNG, JPG or WebP image. The extension must match its contents.',
    );
  }
  if (_isAnimatedContainer(bytes, format)) {
    throw const MyAmbienceValidationException(
      'Animated images are not supported.',
    );
  }
  final maxSide = element ? 2048 : 4096;
  final minSide = element ? 16 : 180;
  final encodedSize = _encodedDimensions(bytes, format);
  if (encodedSize != null &&
      (encodedSize.$1 < minSide ||
          encodedSize.$2 < minSide ||
          encodedSize.$1 > maxSide ||
          encodedSize.$2 > maxSide)) {
    throw MyAmbienceValidationException(
      element
          ? 'Element dimensions must be 16–2048 px on each side.'
          : 'Background dimensions must be 180–4096 px on each side.',
    );
  }
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(bytes, allowUpscaling: false);
    if (codec.frameCount != 1) {
      throw const MyAmbienceValidationException(
        'Animated images are not supported.',
      );
    }
    image = (await codec.getNextFrame()).image;
    final width = image.width;
    final height = image.height;
    if (width < minSide ||
        height < minSide ||
        width > maxSide ||
        height > maxSide) {
      throw MyAmbienceValidationException(
        element
            ? 'Element dimensions must be 16–2048 px on each side.'
            : 'Background dimensions must be 180–4096 px on each side.',
      );
    }
    if (element) {
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) {
        throw const MyAmbienceValidationException(
          'Could not inspect image transparency.',
        );
      }
      final pixels = rgba.buffer.asUint8List();
      var transparent = false;
      var visible = false;
      for (var i = 3; i < pixels.length; i += 4) {
        if (pixels[i] < 255) {
          transparent = true;
        }
        if (pixels[i] > 0) visible = true;
        if (transparent && visible) break;
      }
      if (!transparent) {
        throw const MyAmbienceValidationException(
          'This image has no transparent pixels. Remove its background and export as PNG or WebP.',
        );
      }
      if (!visible) {
        throw const MyAmbienceValidationException(
          'The image is fully transparent. Add visible artwork before uploading it.',
        );
      }
    }
    return MyAmbienceFile(
      name: name,
      bytes: bytes,
      width: width,
      height: height,
      format: format,
    );
  } on MyAmbienceValidationException {
    rethrow;
  } catch (_) {
    throw const MyAmbienceValidationException(
      'The image is damaged or cannot be decoded.',
    );
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}

/// Read canvas dimensions before decoding, so a small compressed file cannot
/// request an unexpectedly huge bitmap allocation.
(int, int)? _encodedDimensions(Uint8List b, String format) {
  if (format == 'PNG' && b.length >= 24) {
    final data = ByteData.sublistView(b);
    return (data.getUint32(16), data.getUint32(20));
  }
  if (format == 'JPEG') {
    var p = 2;
    while (p + 9 < b.length) {
      if (b[p] != 0xff) break;
      while (p < b.length && b[p] == 0xff) {
        p++;
      }
      if (p >= b.length) break;
      final marker = b[p++];
      if (marker == 0xd9 || marker == 0xda) break;
      if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
      if (p + 2 > b.length) break;
      final length = (b[p] << 8) | b[p + 1];
      if (length < 2 || p + length > b.length) break;
      if ((marker >= 0xc0 && marker <= 0xcf) &&
          marker != 0xc4 &&
          marker != 0xc8 &&
          marker != 0xcc &&
          length >= 7) {
        return ((b[p + 5] << 8) | b[p + 6], (b[p + 3] << 8) | b[p + 4]);
      }
      p += length;
    }
  }
  if (format == 'WebP' && b.length >= 30) {
    final tag = String.fromCharCodes(b.sublist(12, 16));
    if (tag == 'VP8X') {
      return (
        1 + b[24] + (b[25] << 8) + (b[26] << 16),
        1 + b[27] + (b[28] << 8) + (b[29] << 16),
      );
    }
    if (tag == 'VP8 ' && b.length >= 30) {
      return (((b[26] | b[27] << 8) & 0x3fff), ((b[28] | b[29] << 8) & 0x3fff));
    }
    if (tag == 'VP8L' && b.length >= 25) {
      return (
        1 + (((b[22] & 0x3f) << 8) | b[21]),
        1 + (((b[24] & 0x0f) << 10) | (b[23] << 2) | ((b[22] & 0xc0) >> 6)),
      );
    }
  }
  return null;
}

String _detectFormat(Uint8List b) {
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4e &&
      b[3] == 0x47 &&
      b[4] == 0x0d &&
      b[5] == 0x0a &&
      b[6] == 0x1a &&
      b[7] == 0x0a) {
    return 'PNG';
  }
  if (b.length >= 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) {
    return 'JPEG';
  }
  if (b.length >= 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return 'WebP';
  }
  return 'unknown';
}

bool _isAnimatedContainer(Uint8List b, String format) {
  if (format == 'PNG') {
    var position = 8;
    while (position + 12 <= b.length) {
      final length = ByteData.sublistView(
        b,
        position,
        position + 4,
      ).getUint32(0);
      if (length > b.length - position - 12) return true;
      final type = String.fromCharCodes(b.sublist(position + 4, position + 8));
      if (type == 'acTL') return true;
      if (type == 'IEND') break;
      position += 12 + length;
    }
  }
  if (format == 'WebP') {
    var position = 12;
    while (position + 8 <= b.length) {
      final type = String.fromCharCodes(b.sublist(position, position + 4));
      final length = ByteData.sublistView(
        b,
        position + 4,
        position + 8,
      ).getUint32(0, Endian.little);
      if (length > b.length - position - 8) return true;
      if (type == 'ANIM' || type == 'ANMF') return true;
      if (type == 'VP8X' && length >= 1 && b[position + 8] & 0x02 != 0) {
        return true;
      }
      position += 8 + length + (length.isOdd ? 1 : 0);
    }
  }
  return false;
}
