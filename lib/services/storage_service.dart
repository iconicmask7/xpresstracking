import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

part 'storage_service.g.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  Future<String?> uploadCheckinPhoto(String deliveryManId, File imageFile) async {
    try {
      // Compress image before uploading
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.absolute.parent.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 70,
      );

      if (compressedImage == null) return null;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'checkins/$deliveryManId/$fileName';
      
      final ref = _storage.ref().child(path);
      
      final uploadTask = await ref.putFile(File(compressedImage.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Cleanup temp file
      File(compressedImage.path).deleteSync();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}

@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService(FirebaseStorage.instance);
}
