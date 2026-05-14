import 'package:carimakan/features/login/pages/login_page.dart';
import 'package:carimakan/features/login/pages/register_page.dart';
import 'package:carimakan/features/splash/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/firebase_options.dart';
import 'package:carimakan/features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CariMakan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}
