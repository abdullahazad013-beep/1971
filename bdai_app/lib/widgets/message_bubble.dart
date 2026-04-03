import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bdai/model/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.lang,
    required this.onCopy,
    required this.onDelete,
  });

  final ChatMessage message;
  final String lang;
  final void Function(String) onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (message.sender == ChatSender.user) {
      return _UserBubble(message: message, isDark: isDark, onDelete: onDelete);
    }
    return _AiBubble(message: message, isDark: isDark, lang: lang, onCopy: onCopy);
  }
}

// ── User bubble ──────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.isDark, required this.onDelete});
  final ChatMessage message;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMenu(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F6FEB), Color(0xFF0050B3)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [BoxShadow(color: const Color(0xFF1F6FEB).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.delete_outline, color: Color(0xFFF85149)), title: const Text('মুছুন', style: TextStyle(fontFamily: 'HindSiliguri', color: Color(0xFFF85149))),
          onTap: () { Navigator.pop(context); onDelete(); }),
      ])),
    );
  }
}

// ── AI bubble ────────────────────────────────────────────
class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.message, required this.isDark, required this.lang, required this.onCopy});
  final ChatMessage message;
  final bool isDark, lang2 = false;
  final String lang;
  final void Function(String) onCopy;

  @override
  Widget build(BuildContext context) {
    final surfColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderCol = isDark ? const Color(0xFF30363D) : const Color(0xFFEEEEEE);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 28, height: 28, margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009970)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: const Color(0xFF00C896).withValues(alpha: 0.3), blurRadius: 6)],
            ),
            child: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
          ),

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: surfColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: borderCol),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading
                  if (message.isLoading) const _DotsWidget(),

                  // Text content
                  if (!message.isLoading && message.text.isNotEmpty && message.text != '✅')
                    _MarkdownText(text: message.text, isDark: isDark),

                  // Image
                  if (message.hasImage) ...[
                    if (!message.isLoading && message.text.isNotEmpty && message.text != '✅')
                      const SizedBox(height: 8),
                    _ImageWidget(imageUrl: message.imageUrl!),
                  ],

                  // Streaming bar
                  if (message.isStreaming) ...[
                    const SizedBox(height: 6),
                    const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Color(0xFF30363D),
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00C896)),
                    ),
                  ],

                  // Copy button
                  if (message.isComplete && !message.isLoading && message.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => onCopy(message.text),
                          child: Row(children: [
                            const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF484F58)),
                            const SizedBox(width: 3),
                            Text(lang == 'bn' ? 'কপি' : 'Copy',
                              style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 10, color: Color(0xFF484F58))),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Markdown text renderer ───────────────────────────────
class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A1A);
    // Simple inline rendering — split by lines
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _renderLine(line, baseColor)).toList(),
    );
  }

  Widget _renderLine(String line, Color baseColor) {
    if (line.startsWith('# ')) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(line.substring(2), style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 18, fontWeight: FontWeight.w700, color: baseColor, height: 1.4)));
    }
    if (line.startsWith('## ')) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(line.substring(3), style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 16, fontWeight: FontWeight.w700, color: baseColor, height: 1.4)));
    }
    if (line.startsWith('### ')) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(line.substring(4), style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 15, fontWeight: FontWeight.w600, color: baseColor, height: 1.4)));
    }
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(padding: const EdgeInsets.only(left: 4, top: 1),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(color: Color(0xFF00C896), fontSize: 14, height: 1.5)),
          Expanded(child: _inlineText(line.substring(2), baseColor)),
        ]));
    }
    if (line.startsWith('```') || line.startsWith('    ')) {
      final code = line.startsWith('```') ? line.replaceAll('`', '') : line.substring(4);
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF30363D))),
        child: Text(code, style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Color(0xFF58A6FF), height: 1.4)),
      );
    }
    if (line.isEmpty) return const SizedBox(height: 4);
    return _inlineText(line, baseColor);
  }

  Widget _inlineText(String text, Color baseColor) {
    // Bold: **text**
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|`(.+?)`|\*(.+?)\*');
    int last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) parts.add(TextSpan(text: text.substring(last, m.start)));
      if (m.group(1) != null) parts.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE6EDF3))));
      else if (m.group(2) != null) parts.add(TextSpan(text: m.group(2), style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Color(0xFFFF7B72), backgroundColor: Color(0xFF21262D))));
      else if (m.group(3) != null) parts.add(TextSpan(text: m.group(3), style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF79C0FF))));
      last = m.end;
    }
    if (last < text.length) parts.add(TextSpan(text: text.substring(last)));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(text: TextSpan(style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 15, color: baseColor, height: 1.6), children: parts)),
    );
  }
}

// ── Image widget ─────────────────────────────────────────
class _ImageWidget extends StatelessWidget {
  const _ImageWidget({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (imageUrl.startsWith('data:image')) {
      final b64 = imageUrl.split(',').last;
      img = Image.memory(base64Decode(b64), fit: BoxFit.cover, gaplessPlayback: true);
    } else {
      img = Image.network(imageUrl, fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Color(0xFF00C896))),
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(constraints: const BoxConstraints(maxHeight: 280), child: img),
    );
  }
}

// ── Dots loading ─────────────────────────────────────────
class _DotsWidget extends StatefulWidget {
  const _DotsWidget();
  @override
  State<_DotsWidget> createState() => _DotsWidgetState();
}

class _DotsWidgetState extends State<_DotsWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final v = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
          final opacity = v < 0.5 ? v * 2 : (1 - v) * 2;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: Opacity(opacity: opacity.clamp(0.2, 1.0),
              child: const CircleAvatar(radius: 4, backgroundColor: Color(0xFF00C896))),
          );
        }),
      ),
    );
  }
}
