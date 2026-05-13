import 'package:carimakan/login_page.dart';
import 'package:carimakan/register_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'features/home/presentation/pages/home_page.dart';
=======
import 'splash_screen.dart';
>>>>>>> 294824d (membuat tampilan splash dan register sementara)
=======
import 'splash_screen.dart';
>>>>>>> 294824d779ba168394968b129930a67d5808f192

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
<<<<<<< HEAD
<<<<<<< HEAD
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const HomePage(),
=======
      theme: ThemeData(
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      ),
      home: const RegisterPage(),
>>>>>>> 294824d (membuat tampilan splash dan register sementara)
=======
      theme: ThemeData(
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      ),
      home: const RegisterPage(),
>>>>>>> 294824d779ba168394968b129930a67d5808f192
    );
  }
}
