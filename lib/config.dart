import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Endpoint
  static String get apiUrl =>
      dotenv.env['API_URL'] ?? '';

  // Gemini
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  // Cloudinary
  static String get cloudinaryApiKey =>
      dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret =>
      dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
}
