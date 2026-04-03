import 'dart:collection';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bdai/core/app_constants.dart';
import 'package:bdai/model/chat_message.dart';
import 'package:bdai/repository/bdai_repository.dart';

class ChatSession {
  ChatSession({required this.id, required this.title, required this.messages, required this.createdAt});
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
    id: j['id'] as String, title: j['title'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    messages: (j['messages'] as List<dynamic>).map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList(),
  );
}

class AllChatsModel extends ChangeNotifier {
  AllChatsModel() { _init(); }

  final List<ChatSession> _sessions = [];
  String _activeChatId = '';
  int _idSeed = 0;

  List<ChatSession> get sessions => UnmodifiableListView(_sessions);
  String get activeChatId => _activeChatId;
  ChatSession? get activeSession => _sessions.isEmpty ? null : _sessions.firstWhere((s) => s.id == _activeChatId, orElse: () => _sessions.first);
  List<ChatMessage> get messages => activeSession?.messages ?? [];

  Future<void> _init() async {
    await _loadAll();
    if (_sessions.isEmpty) _createNew();
  }

  void createNewSession() { _createNew(); notifyListeners(); _saveAll(); }

  void _createNew() {
    final id = '${DateTime.now().millisecondsSinceEpoch}';
    _sessions.insert(0, ChatSession(id: id, title: 'নতুন চ্যাট', messages: [], createdAt: DateTime.now()));
    _activeChatId = id;
  }

  void switchSession(String id) { _activeChatId = id; notifyListeners(); }

  void deleteSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    if (_activeChatId == id) { if (_sessions.isEmpty) _createNew(); _activeChatId = _sessions.first.id; }
    notifyListeners(); _saveAll();
  }

  Future<void> clearActive() async {
    final idx = _sessions.indexWhere((s) => s.id == _activeChatId);
    if (idx != -1) { _sessions[idx].messages.clear(); notifyListeners(); await _saveAll(); }
  }

  String _nextId() => '${++_idSeed}';

  Future<void> sendMessage(String text, {List<AttachedImage> images = const []}) async {
    final intent = BdaiRepository.detectIntent(text, imageCount: images.length);
    final idx = _sessions.indexWhere((s) => s.id == _activeChatId);
    if (idx == -1) return;

    final userMsg = ChatMessage(id: _nextId(), sender: ChatSender.user, text: text, status: ChatMessageStatus.complete, timestamp: DateTime.now());
    final ph = (intent == ChatIntent.imageGenerate || intent == ChatIntent.imageEdit || intent == ChatIntent.faceSwap) ? AppConstants.imagePlaceholder : AppConstants.defaultPlaceholder;
    final aiMsg = ChatMessage(id: _nextId(), sender: ChatSender.assistant, text: ph, status: ChatMessageStatus.loading, timestamp: DateTime.now());

    _sessions[idx].messages.addAll([userMsg, aiMsg]);
    if (_sessions[idx].messages.length <= 2 && text.isNotEmpty) {
      _sessions[idx].title = text.length > 28 ? '${text.substring(0, 28)}...' : text;
    }
    notifyListeners(); await _saveAll();

    try {
      if (intent == ChatIntent.imageGenerate) {
        final url = await BdaiRepository.generateImage(prompt: text);
        _patchLast(idx, text: '✅', imageUrl: url);
      } else if (intent == ChatIntent.imageEdit && images.isNotEmpty) {
        final r = await BdaiRepository.editImage(prompt: text, imageBase64: images.first.base64);
        if (r.startsWith('data:') || r.startsWith('http')) { _patchLast(idx, text: '✅', imageUrl: r); } else { _patchLast(idx, text: r); }
      } else if (intent == ChatIntent.imageDescribe && images.isNotEmpty) {
        final r = await BdaiRepository.editImage(prompt: 'describe this image in Bengali', imageBase64: images.first.base64);
        _patchLast(idx, text: r);
      } else if (intent == ChatIntent.faceSwap && images.length >= 2) {
        final url = await BdaiRepository.faceSwap(image1Base64: images[0].base64, image2Base64: images[1].base64);
        _patchLast(idx, text: '✅', imageUrl: url);
      } else {
        _sessions[idx].messages.last = _sessions[idx].messages.last.copyWith(text: '', status: ChatMessageStatus.streaming);
        notifyListeners();
        await for (final partial in BdaiRepository.streamChat(message: text)) {
          _sessions[idx].messages.last = _sessions[idx].messages.last.copyWith(text: partial, status: ChatMessageStatus.streaming);
          notifyListeners();
        }
        _sessions[idx].messages.last = _sessions[idx].messages.last.copyWith(status: ChatMessageStatus.complete);
        notifyListeners();
      }
    } catch (e) {
      _patchLast(idx, text: '❌ ${e.toString()}');
    }
    await _saveAll();
  }

  void _patchLast(int idx, {required String text, String? imageUrl}) {
    final msgs = _sessions[idx].messages;
    if (msgs.isEmpty || msgs.last.sender != ChatSender.assistant) return;
    msgs.last = msgs.last.copyWith(text: text, imageUrl: imageUrl, status: ChatMessageStatus.complete);
    notifyListeners();
  }

  void deleteMessage(String id) {
    final idx = _sessions.indexWhere((s) => s.id == _activeChatId);
    if (idx == -1) return;
    _sessions[idx].messages.removeWhere((m) => m.id == id);
    notifyListeners(); _saveAll();
  }

  Future<void> _saveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.allChatsKey, jsonEncode(_sessions.map((s) => s.toJson()).toList()));
      await prefs.setString('active_chat_id', _activeChatId);
    } catch (_) {}
  }

  Future<void> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.allChatsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _sessions.addAll(list.map((j) => ChatSession.fromJson(j as Map<String, dynamic>)));
        _activeChatId = prefs.getString('active_chat_id') ?? (_sessions.isNotEmpty ? _sessions.first.id : '');
        if (!_sessions.any((s) => s.id == _activeChatId) && _sessions.isNotEmpty) _activeChatId = _sessions.first.id;
      }
      for (final s in _sessions) for (final m in s.messages) { final n = int.tryParse(m.id) ?? 0; if (n > _idSeed) _idSeed = n; }
    } catch (_) {}
    notifyListeners();
  }

  String exportChat() {
    final buf = StringBuffer('# BDAi Chat Export\n\n');
    for (final m in messages) {
      if (!m.isComplete) continue;
      buf.writeln('**${m.sender == ChatSender.user ? "আপনি" : "BDAi"}**: ${m.text}\n');
    }
    return buf.toString();
  }
}

final allChatsProvider = ChangeNotifierProvider((ref) => AllChatsModel());

class AttachedImage {
  const AttachedImage({required this.base64, required this.previewBytes});
  final String base64;
  final List<int> previewBytes;
}
