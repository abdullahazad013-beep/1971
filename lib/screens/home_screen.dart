import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bdai/core/theme_service.dart';
import 'package:bdai/core/language_service.dart';
import 'package:bdai/core/app_constants.dart';
import 'package:bdai/model/chatmodel.dart';
import 'package:bdai/model/chat_message.dart';
import 'package:bdai/screens/login_screen.dart';
import 'package:bdai/screens/settings_screen.dart';
import 'package:bdai/widgets/bdai_logo.dart';
import 'package:bdai/widgets/message_bubble.dart';
import 'package:bdai/widgets/sidebar_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<AttachedImage> _attachedImages = [];
  bool _showAttachMenu = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _pickImage() async {
    setState(() => _showAttachMenu = false);
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    final imgs = <AttachedImage>[];
    for (final xf in picked) {
      final bytes = await xf.readAsBytes();
      imgs.add(AttachedImage(base64: base64Encode(bytes), previewBytes: bytes));
    }
    setState(() => _attachedImages.addAll(imgs));
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty) return;
    _textCtrl.clear();
    final imgs = List<AttachedImage>.from(_attachedImages);
    setState(() { _attachedImages = []; _showAttachMenu = false; });
    await ref.read(allChatsProvider).sendMessage(text, images: imgs);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatModel = ref.watch(allChatsProvider);
    final messages  = chatModel.messages;
    final lang      = ref.watch(languageProvider);
    final isDark    = ref.watch(themeModeProvider) == ThemeMode.dark;
    final theme     = Theme.of(context);

    _scrollToBottom();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SidebarDrawer(onNewChat: () { chatModel.createNewSession(); Navigator.pop(context); }),
      appBar: _buildAppBar(context, lang, isDark, chatModel),
      body: GestureDetector(
        onTap: () { setState(() => _showAttachMenu = false); FocusScope.of(context).unfocus(); },
        child: Column(
          children: [
            // Messages
            Expanded(
              child: messages.isEmpty
                  ? _EmptyState(lang: lang)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => MessageBubble(
                        message: messages[i],
                        lang: lang,
                        onCopy: (t) { Clipboard.setData(ClipboardData(text: t)); _showSnack(context, lang == 'bn' ? 'কপি হয়েছে' : 'Copied!'); },
                        onDelete: () => chatModel.deleteMessage(messages[i].id),
                      ),
                    ),
            ),
            // Input
            _InputBar(
              controller: _textCtrl,
              attachedImages: _attachedImages,
              showAttachMenu: _showAttachMenu,
              lang: lang,
              isDark: isDark,
              onSend: _sendMessage,
              onPickImage: _pickImage,
              onToggleAttach: () => setState(() => _showAttachMenu = !_showAttachMenu),
              onRemoveImage: (i) => setState(() => _attachedImages.removeAt(i)),
              onAttachAction: (action) {
                setState(() => _showAttachMenu = false);
                if (action == 'pick') _pickImage();
                if (action == 'imagegen') { _textCtrl.text = lang == 'bn' ? 'ছবি বানাও: ' : 'Generate image: '; _textCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _textCtrl.text.length)); }
                if (action == 'faceswap') _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String lang, bool isDark, AllChatsModel chatModel) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        color: isDark ? const Color(0xFF8B949E) : const Color(0xFF555555),
      ),
      title: Row(
        children: [
          const BdaiLogoWidget(size: 28),
          const SizedBox(width: 8),
          Text('বিডিএআই', style: TextStyle(
            fontFamily: 'HindSiliguri', fontSize: 17, fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A1A),
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(lang == 'bn' ? 'বেটা' : 'Beta', style: const TextStyle(
              fontFamily: 'HindSiliguri', fontSize: 9, color: Color(0xFF00C896), fontWeight: FontWeight.w700,
            )),
          ),
        ],
      ),
      actions: [
        // New chat
        TextButton.icon(
          onPressed: () { chatModel.createNewSession(); setState(() { _attachedImages = []; _textCtrl.clear(); }); },
          icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF00C896)),
          label: Text(lang == 'bn' ? 'নতুন' : 'New', style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 12, color: Color(0xFF00C896), fontWeight: FontWeight.w700)),
          style: TextButton.styleFrom(
            side: const BorderSide(color: Color(0xFF30363D)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
        ),
        const SizedBox(width: 4),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_rounded, size: 20),
          color: isDark ? const Color(0xFF8B949E) : const Color(0xFF555555),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(width: 2),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: isDark ? const Color(0xFF30363D) : const Color(0xFFEEEEEE))),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'HindSiliguri')),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ─── Empty state ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF00C896).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: const Center(child: BdaiLogoWidget(size: 42)),
          ),
          const SizedBox(height: 14),
          Text(lang == 'bn' ? 'বিডিএআই-কে কিছু জিজ্ঞেস করুন' : 'Ask BDAi anything',
            style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF8B949E))),
          const SizedBox(height: 6),
          Text(lang == 'bn' ? 'চ্যাট, ছবি তৈরি, কোড লিখুন — সব বাংলায়' : 'Chat, generate images, write code',
            style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 12, color: Color(0xFF484F58)),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Input Bar ───────────────────────────────────────────
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller, required this.attachedImages, required this.showAttachMenu,
    required this.lang, required this.isDark, required this.onSend,
    required this.onPickImage, required this.onToggleAttach,
    required this.onRemoveImage, required this.onAttachAction,
  });

  final TextEditingController controller;
  final List<AttachedImage> attachedImages;
  final bool showAttachMenu;
  final String lang;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onToggleAttach;
  final void Function(int) onRemoveImage;
  final void Function(String) onAttachAction;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFDDDDDD);
    final surfaceColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F4F8);

    return Container(
      color: bgColor,
      padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: MediaQuery.of(context).padding.bottom + 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attach menu
          if (showAttachMenu)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: Column(
                children: [
                  _AttachOption(icon: '🖼️', label: lang == 'bn' ? 'ছবি আপলোড' : 'Upload Image', onTap: () => onAttachAction('pick'), isDark: isDark),
                  Divider(height: 1, color: borderColor),
                  _AttachOption(icon: '🎨', label: lang == 'bn' ? 'ছবি তৈরি করুন' : 'Generate Image', onTap: () => onAttachAction('imagegen'), isDark: isDark),
                  Divider(height: 1, color: borderColor),
                  _AttachOption(icon: '✏️', label: lang == 'bn' ? 'ছবি এডিট করুন' : 'Edit Image', onTap: () => onAttachAction('pick'), isDark: isDark),
                  Divider(height: 1, color: borderColor),
                  _AttachOption(icon: '🔄', label: lang == 'bn' ? 'ফেস সোয়াপ' : 'Face Swap', onTap: () => onAttachAction('faceswap'), isDark: isDark, last: true),
                ],
              ),
            ),

          // Image chips
          if (attachedImages.isNotEmpty)
            SizedBox(
              height: 58,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 6),
                itemCount: attachedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(Uint8List.fromList(attachedImages[i].previewBytes),
                          width: 52, height: 52, fit: BoxFit.cover),
                    ),
                    Positioned(top: -2, right: -2, child: GestureDetector(
                      onTap: () => onRemoveImage(i),
                      child: Container(width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF85149)),
                        child: const Icon(Icons.close, size: 10, color: Colors.white)),
                    )),
                  ],
                ),
              ),
            ),

          // Text field row
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // + button
                _IconBtn(
                  icon: Icons.add_rounded,
                  active: showAttachMenu,
                  isDark: isDark,
                  onTap: onToggleAttach,
                ),
                // TextField
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: 5, minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 15, color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: lang == 'bn' ? 'বাংলায় বা ইংরেজিতে লিখুন...' : 'Type in Bengali or English...',
                      hintStyle: TextStyle(fontFamily: 'HindSiliguri', color: isDark ? const Color(0xFF484F58) : const Color(0xFF999999), fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                // Send button
                _SendBtn(onTap: onSend, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(lang == 'bn' ? 'বিডিএআই ভুল করতে পারে — গুরুত্বপূর্ণ বিষয় যাচাই করুন' : 'BDAi can make mistakes. Verify important info.',
            style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 10, color: Color(0xFF484F58))),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({required this.icon, required this.label, required this.onTap, required this.isDark, this.last = false});
  final String icon, label;
  final VoidCallback onTap;
  final bool isDark, last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(last ? 14 : 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A1A))),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.active, required this.isDark, required this.onTap});
  final IconData icon;
  final bool active, isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38, margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active ? const Color(0xFF00C896).withValues(alpha: 0.15) : (isDark ? const Color(0xFF21262D) : const Color(0xFFF0F0F0)),
          border: active ? Border.all(color: const Color(0xFF00C896)) : null,
        ),
        child: Icon(icon, size: 20, color: active ? const Color(0xFF00C896) : (isDark ? const Color(0xFF8B949E) : const Color(0xFF666666))),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  const _SendBtn({required this.onTap, required this.isDark});
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38, margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009970)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}
