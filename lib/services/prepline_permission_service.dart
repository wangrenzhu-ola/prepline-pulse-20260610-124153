import 'package:permission_handler/permission_handler.dart';

class PrepPermissionSnapshot {
  const PrepPermissionSnapshot({
    required this.cameraGranted,
    required this.microphoneGranted,
    required this.photosGranted,
  });

  final bool cameraGranted;
  final bool microphoneGranted;
  final bool photosGranted;

  bool get allGranted => cameraGranted && microphoneGranted && photosGranted;

  String get readback {
    if (allGranted) {
      return 'Media access is ready for station proof capture.';
    }
    return 'Media access is limited; station updates still work without it.';
  }
}

class PreplinePermissionService {
  Future<bool> requestPhotoLibraryRead() async {
    final photos = await Permission.photos.request();
    return photos.isGranted || photos.isLimited;
  }

  Future<bool> requestPhotoLibraryWrite() async {
    final photos = await Permission.photosAddOnly.request();
    if (photos.isGranted || photos.isLimited) {
      return true;
    }
    final fallback = await Permission.photos.request();
    return fallback.isGranted || fallback.isLimited;
  }

  Future<PrepPermissionSnapshot> requestMediaAccess() async {
    final camera = await Permission.camera.request();
    final microphone = await Permission.microphone.request();
    final photos = await Permission.photos.request();
    return PrepPermissionSnapshot(
      cameraGranted: camera.isGranted || camera.isLimited,
      microphoneGranted: microphone.isGranted || microphone.isLimited,
      photosGranted: photos.isGranted || photos.isLimited,
    );
  }
}
