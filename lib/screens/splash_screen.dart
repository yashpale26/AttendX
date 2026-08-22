import 'dart:async';
import 'package:attendx/screens/student_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'teacher_dashboard.dart'; // Ensure TeacherDashboard is imported

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // 3-second delay followed by authentication & role check
    Timer(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  // ✅ Auth & Role Routing Logic
  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fetch role from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (userDoc.exists && userDoc.data() != null) {
          String role = userDoc['role'] ?? '';

          if (role == "teacher") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TeacherDashboard()),
            );
          } else {
            // Default/Student route
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentDashboard()),
            );
          }
        } else {
          // Document missing -> fallback to login
          _goToLogin();
        }
      } catch (e) {
        // Error fetching document -> fallback to login
        _goToLogin();
      }
    } else {
      // User not logged in -> go to login
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00C9A7), // Green
              Color(0xFF007CF0), // Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/images/attendx_logo.png',
              width: 350,
            ),
          ),
        ),
      ),
    );
  }
}