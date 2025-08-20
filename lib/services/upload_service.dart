import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';

class UploadService {
  static Future<Map<String, String?>> uploadImage(File imageFile) async {
    try {
      final cloudinary = Cloudinary.full(
        apiKey: Config.cloudinaryApiKey,
        apiSecret: Config.cloudinaryApiSecret,
        cloudName: Config.cloudinaryCloudName,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";

      final response = await cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: "mindcare/users/$uid",
        fileName: "profile_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return {'url': response.secureUrl, 'error': null};
      } else {
        return {'url': null, 'error': response.error ?? "Upload thất bại"};
      }
    } catch (e) {
      return {'url': null, 'error': "Đã xảy ra lỗi khi tải ảnh lên: $e"};
    }
  }
}