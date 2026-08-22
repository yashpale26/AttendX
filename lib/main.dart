import 'package:flutter/material.dart';
import 'screens/slr_screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<FirebaseApp> _initializeFirebase() async {
    return await Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9A7),
        ),
      ),

      home: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {

          // ✅ SUCCESS
          if (snapshot.connectionState == ConnectionState.done) {
            return SplashScreen();
          }

          // ❌ ERROR HANDLING (THIS WAS MISSING)
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  "Firebase Error:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ⏳ LOADING
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}