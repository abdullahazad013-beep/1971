import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bdai/core/theme_service.dart';
import 'package:bdai/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: BdaiApp()));
}

class BdaiApp extends ConsumerWidget {
  const BdaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Hind Siliguri — best Bengali Google Font
    // Replace with AdorshoLipi TTF for authentic look
    final bengaliTextTheme = GoogleFonts.hindSiliguriTextTheme();

    return MaterialApp(
      title: 'BDAi',
      debugShowCheckedModeBanner: false,
      theme: BdaiTheme.light().copyWith(textTheme: bengaliTextTheme.apply(bodyColor: const Color(0xFF1A1A1A))),
      darkTheme: BdaiTheme.dark().copyWith(textTheme: bengaliTextTheme.apply(bodyColor: const Color(0xFFE6EDF3))),
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
