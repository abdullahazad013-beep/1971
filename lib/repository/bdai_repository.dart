import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bdai/model/chat_message.dart';

/// BDAi API Repository — connects to 103.7.4.121:5000
class BdaiRepository {
  BdaiRepository._();

  static const String _baseUrl = 'http://103.7.4.121:5000';
  static final http.Client _client = http.Client();

  // ─── Chat ───────────────────────────────────────────
  static Future<String> chat({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('Chat API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['reply'] as String? ?? '';
  }

  // ─── Stream chat (simulate streaming from response) ──
  static Stream<String> streamChat({required String message}) async* {
    final reply = await chat(message: message);
    final words = reply.split(' ');
    var buffer = '';
    for (final word in words) {
      buffer += (buffer.isEmpty ? '' : ' ') + word;
      yield buffer;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  // ─── Image Generate ─────────────────────────────────
  static Future<String> generateImage({required String prompt}) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/image'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt}),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw Exception('Image API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['image'] != null) {
      return 'data:image/png;base64,${data['image']}';
    }
    if (data['url'] != null) {
      return data['url'] as String;
    }
    throw Exception('No image in response');
  }

  // ─── Image Edit ──────────────────────────────────────
  static Future<String> editImage({
    required String prompt,
    required String imageBase64,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/image'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt, 'image': imageBase64}),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw Exception('Image edit API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['image'] != null) {
      return 'data:image/png;base64,${data['image']}';
    }
    if (data['url'] != null) {
      return data['url'] as String;
    }
    if (data['reply'] != null) {
      return data['reply'] as String;
    }
    throw Exception('No result in response');
  }

  // ─── Face Swap ───────────────────────────────────────
  static Future<String> faceSwap({
    required String image1Base64,
    required String image2Base64,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/image'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image1': image1Base64,
            'image2': image2Base64,
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw Exception('Face swap API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['image'] != null) {
      return 'data:image/png;base64,${data['image']}';
    }
    if (data['url'] != null) {
      return data['url'] as String;
    }
    throw Exception('No image in response');
  }

  // ─── STT ─────────────────────────────────────────────
  static Future<String> speechToText({required List<int> audioBytes}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/stt'),
    );
    request.files.add(
      http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav'),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  // ─── TTS ─────────────────────────────────────────────
  static Future<String?> textToSpeech({required String text}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/tts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['audio_base64'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── Intent Detection ────────────────────────────────
  static ChatIntent detectIntent(String text, {int imageCount = 0}) {
    if (imageCount == 2) return ChatIntent.faceSwap;
    if (imageCount == 1) {
      return text.trim().isEmpty ? ChatIntent.imageDescribe : ChatIntent.imageEdit;
    }

    final lower = text.toLowerCase();
    const imageKeywords = [
      'ছবি বানাও', 'ছবি তৈরি', 'ছবি আঁকো', 'ছবি দাও',
      'image generate', 'generate image', 'create image',
      'draw', 'paint', 'artwork', 'illustration',
      'photo বানাও', 'একটা ছবি',
    ];
    for (final kw in imageKeywords) {
      if (lower.contains(kw)) return ChatIntent.imageGenerate;
    }
    return ChatIntent.chat;
  }
}

enum ChatIntent { chat, imageGenerate, imageEdit, imageDescribe, faceSwap }
