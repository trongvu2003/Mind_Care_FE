import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class AIService {
  final String baseUrl;
  AIService({required this.baseUrl});

  Future<String?> _idToken() async {
    final u = FirebaseAuth.instance.currentUser;
    return u != null ? await u.getIdToken() : null;
  }

  Future<Map<String, dynamic>> analyzeText(String content) async {
    final token = await _idToken();
    final res = await http.post(
      Uri.parse('$baseUrl/ai/analyze-text'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: '{"content": ${_jsonEscape(content)}}',
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('Text analyze failed: ${res.statusCode} (${res.body})');
    }
    return _decode(res.body);
  }

  Future<Map<String, dynamic>> analyzeImage(File file) async {
    final token = await _idToken();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/ai/analyze-image'),
    );

    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final mimeSplit = mimeType.split('/');

    req.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ),
    );

    if (token != null) req.headers['Authorization'] = 'Bearer $token';

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode ~/ 100 != 2) {
      throw Exception('Image analyze failed: ${streamed.statusCode} ($body)');
    }
    return _decode(body);
  }

  // helpers
  Map<String, dynamic> _decode(String s) =>
      s.isEmpty ? {} : (s.codeUnitAt(0) == 123 ? _tryJson(s) : {});
  Map<String, dynamic> _tryJson(String s) {
    try {
      return Map<String, dynamic>.from(jsonDecode(s));
    } catch (_) {
      return {};
    }
  }

  String _jsonEscape(String s) =>
      '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}
