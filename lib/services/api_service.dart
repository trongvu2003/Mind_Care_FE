import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AIService {
  final String baseUrl;
  AIService({required this.baseUrl});

  Future<Map<String, dynamic>> analyzeText(String content) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final res = await http.post(
      Uri.parse('$baseUrl/analyze/text'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('Text analyze failed: ${res.statusCode} (${res.body})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyzeImage(File file) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/analyze/image'),
    );
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    final resp = await req.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode ~/ 100 != 2) {
      throw Exception('Image analyze failed: ${resp.statusCode} ($body)');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
