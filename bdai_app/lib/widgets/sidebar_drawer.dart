import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bdai/core/language_service.dart';
import 'package:bdai/core/theme_service.dart';
import 'package:bdai/model/chatmodel.dart';
import 'package:bdai/widgets/bdai_logo.dart';

class SidebarDrawer extends ConsumerWidget {
  const SidebarDrawer({super.key, required this.onNewChat});
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatModel = ref.watch(allChatsProvider);
    final lang   = ref.watch(languageProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bgColor   = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderCol = isDark ? const Color(0xFF30363D) : const Color(0xFFEEEEEE);
    final textCol   = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A1A);
    final dimCol    = isDark ? const Color(0xFF484F58) : const Color(0xFF999999);

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(children: [
              const BdaiLogoWidget(size: 30),
              const SizedBox(width: 10),
              Text('বিডিএআই', style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 18, fontWeight: FontWeight.w700, color: textCol)),
              Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFF00C896).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(lang == 'bn' ? 'বেটা' : 'Beta', style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 9, color: Color(0xFF00C896), fontWeight: FontWeight.w700))),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded, size: 20), color: dimCol, onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
          ),

          // New chat button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: OutlinedButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF00C896)),
              label: Text(lang == 'bn' ? 'নতুন চ্যাট' : 'New Chat',
                style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 13, color: Color(0xFF00C896), fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                side: const BorderSide(color: Color(0xFF30363D)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Text(lang == 'bn' ? 'চ্যাট ইতিহাস' : 'Chat History',
                style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 10, fontWeight: FontWeight.w700, color: dimCol, letterSpacing: 0.8)),
            ]),
          ),

          // Chat list
          Expanded(
            child: chatModel.sessions.isEmpty
              ? Center(child: Text(lang == 'bn' ? 'কোনো চ্যাট নেই' : 'No chats yet',
                  style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 13, color: dimCol)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: chatModel.sessions.length,
                  itemBuilder: (_, i) {
                    final session = chatModel.sessions[i];
                    final isActive = session.id == chatModel.activeChatId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF00C896).withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isActive ? const Color(0xFF00C896).withValues(alpha: 0.3) : Colors.transparent),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        title: Text(session.title, style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 13, color: isActive ? const Color(0xFF00C896) : textCol, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_formatTime(session.createdAt),
                          style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 10, color: dimCol)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          color: dimCol,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (isActive && chatModel.sessions.length == 1) return;
                            chatModel.deleteSession(session.id);
                          },
                        ),
                        onTap: () {
                          chatModel.switchSession(session.id);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF0070F3)])),
                child: const Center(child: Text('ব', style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang == 'bn' ? 'Demo ব্যবহারকারী' : 'Demo User',
                  style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 13, fontWeight: FontWeight.w600, color: textCol)),
                Text(lang == 'bn' ? 'বিডিএআই টেকনোলজি' : 'BDAi Technology',
                  style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 10, color: dimCol)),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}
