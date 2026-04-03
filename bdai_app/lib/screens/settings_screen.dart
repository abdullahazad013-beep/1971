import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bdai/core/theme_service.dart';
import 'package:bdai/core/language_service.dart';
import 'package:bdai/core/app_constants.dart';
import 'package:bdai/screens/login_screen.dart';
import 'package:bdai/widgets/bdai_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang   = ref.watch(languageProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final theme  = Theme.of(context);

    String t(String key) => sLang(lang, key);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t('settings'), style: const TextStyle(fontFamily: 'HindSiliguri', fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: isDark ? const Color(0xFF30363D) : const Color(0xFFEEEEEE))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Appearance ──
          _SectionHeader(title: t('appearance'), isDark: isDark),
          _SettingsCard(isDark: isDark, children: [
            _ToggleRow(
              icon: Icons.dark_mode_rounded,
              label: t('darkMode'),
              value: isDark,
              isDark: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Language ──
          _SectionHeader(title: t('languageSetting'), isDark: isDark),
          _SettingsCard(isDark: isDark, children: [
            _LangRow(lang: lang, isDark: isDark, onToggle: () => ref.read(languageProvider.notifier).toggle()),
          ]),

          const SizedBox(height: 12),

          // ── App Info ──
          _SectionHeader(title: t('appInfo'), isDark: isDark),
          _SettingsCard(isDark: isDark, children: [
            _InfoRow(label: t('version'), value: AppConstants.appVersion, isDark: isDark),
            Divider(height: 1, color: isDark ? const Color(0xFF30363D) : const Color(0xFFEEEEEE)),
            _InfoRow(label: t('language'), value: lang == 'bn' ? 'বাংলা (প্রাথমিক)' : 'Bengali (Primary)', isDark: isDark),
          ]),

          const SizedBox(height: 12),

          // ── Logout ──
          _SettingsCard(isDark: isDark, children: [
            InkWell(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(AppConstants.isLoggedInKey, false);
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFF85149)),
                  const SizedBox(width: 12),
                  Text(t('logout'), style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 15, color: Color(0xFFF85149), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Branding ──
          Center(
            child: Column(children: [
              const BdaiLogoWidget(size: 44),
              const SizedBox(height: 10),
              const Text('বিডিএআই', style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE6EDF3))),
              const SizedBox(height: 4),
              Text(lang == 'bn' ? 'বিডিএআই টেকনোলজি কর্তৃক নির্মিত' : 'Made by BDAi Technology',
                style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 12, color: Color(0xFF8B949E))),
              const SizedBox(height: 2),
              Text('v${AppConstants.appVersion}', style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 11, color: Color(0xFF484F58))),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
      child: Text(title, style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        color: isDark ? const Color(0xFF484F58) : const Color(0xFF999999))),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, required this.isDark});
  final List<Widget> children; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFEEEEEE)),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.isDark, required this.onChanged});
  final IconData icon; final String label; final bool value, isDark; final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(children: [
        Icon(icon, size: 20, color: isDark ? const Color(0xFF8B949E) : const Color(0xFF666666)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 15, color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A1A)))),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFF00C896)),
      ]),
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({required this.lang, required this.isDark, required this.onToggle});
  final String lang; final bool isDark; final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Icon(Icons.language_rounded, size: 20, color: isDark ? const Color(0xFF8B949E) : const Color(0xFF666666)),
        const SizedBox(width: 12),
        Expanded(child: Text(lang == 'bn' ? 'ভাষা' : 'Language', style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 15, color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A1A)))),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF00C896).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00C896))),
            child: Text(lang == 'bn' ? 'বাংলা → English' : 'English → বাংলা',
              style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 12, color: Color(0xFF00C896), fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.isDark});
  final String label, value; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Text(label, style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 14, color: isDark ? const Color(0xFF8B949E) : const Color(0xFF666666))),
        const Spacer(),
        Text(value, style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 13, color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A1A))),
      ]),
    );
  }
}
