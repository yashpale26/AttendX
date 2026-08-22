import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../slr_screens/login_screen.dart';


class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentStudentEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Student Account';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6F0FF), Color(0xFFCFE2FF)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF004AAD), Color(0xFF007CF0)],
                  ),
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                "Student Account",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                currentStudentEmail,
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();

                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          "Logout",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}