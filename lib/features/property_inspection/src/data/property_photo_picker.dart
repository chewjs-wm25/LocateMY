import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/property_models.dart';

final class DevicePropertyPhotoPicker implements PropertyPhotoPicker {
  final ImagePicker _picker = ImagePicker();
  @override
  Future<PropertyPickedPhoto?> pick(PropertyPhotoSource source) async {
    try {
      if (source == PropertyPhotoSource.camera) {
        final PermissionStatus permission = await Permission.camera.request();
        if (!permission.isGranted) {
          throw const PropertyFailure('permission');
        }
      }
      final XFile? file = await _picker.pickImage(
        source: source == PropertyPhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null) {
        return null;
      }
      final Uint8List original = await file.readAsBytes();
      final String extension = file.name.toLowerCase();
      if (!<String>['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'].any((
        String suffix,
      ) {
        return extension.endsWith(suffix);
      })) {
        throw const PropertyFailure('format');
      }
      final Uint8List bytes = await FlutterImageCompress.compressWithList(
        original,
        minWidth: 1600,
        minHeight: 1600,
        quality: 80,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      final bool jpeg =
          bytes.length > 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      if (!jpeg || bytes.length > 10 * 1024 * 1024) {
        throw const PropertyFailure('format');
      }
      return PropertyPickedPhoto(bytes);
    } on PlatformException catch (error) {
      if (error.code.contains('denied') || error.code.contains('restricted')) {
        throw const PropertyFailure('permission');
      }
      throw const PropertyFailure('photo');
    }
  }
}
