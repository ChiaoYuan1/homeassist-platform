import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  const supabaseUrl = 'https://bokwddtvxacypreaxfdz.supabase.co';
  const supabasePublishableKey = 'sb_publishable_PlAoXFOxugMF3FMWwIZwJQ_reLjVjV3';

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
    accessToken: () async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return null;

      return user.getIdToken();
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeAssist',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}