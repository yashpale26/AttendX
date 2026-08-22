import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  String selectedRole = ""; // "teacher" or "student"

  // ✅ Password visibility toggle
  bool _isPasswordVisible = false;

  // Controllers for input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ✅ Clear input fields and selected role
  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    setState(() {
      selectedRole = "";
    });
  }

  Color getCardColor() {
    if (selectedRole == "teacher") {
      return const Color(0xFFE6FFF5); // light green
    } else if (selectedRole == "student") {
      return const Color(0xFFE6F0FF); // light blue
    }
    return Colors.white;
  }

  // ✅ Get button color
  Color? getButtonColor() {
    if (selectedRole == "teacher") {
      return const Color(0xFF00C9A7); // green
    } else if (selectedRole == "student") {
      return const Color(0xFF007CF0); // blue
    }
    return null; // for gradient
  }

  // Error UI
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Authentication method
  Future<void> loginUser(String username, String password) async {
    try {
      String email = username.trim();

      // ✅ avoid double @attendx.com
      if (!email.endsWith("@attendx.com")) {
        email = "$email@attendx.com";
      }

      final userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User data not found");
      }

      String role = userDoc['role'];

      if (role != selectedRole) {
        throw Exception("Wrong role selected");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful")),
        );

        if (role == "teacher") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      String message = "Login failed";

      if (e.code == 'user-not-found') {
        message = "No user found";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format";
      }

      showError(message);

    } catch (e) {
      showError(e.toString().replaceAll("Exception: ", ""));
    }
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
              Color(0xFF00C9A7),
              Color(0xFF007CF0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            children: [

              const SizedBox(height: 80),

              Image.asset(
                'assets/images/attendx_logo.png',
                width: 150,
              ),

              const SizedBox(height: 30),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: getCardColor(),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),

                child: Column(
                  children: [

                    // ✅ LOGIN TITLE
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF00C9A7),
                          Color(0xFF007CF0),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [

                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRole = "teacher";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: selectedRole == "teacher"
                                    ? const Color(0xFF00C9A7).withOpacity(0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: selectedRole == "teacher"
                                      ? const Color(0xFF00C9A7)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/tr_login_img.png',
                                    width: 100,
                                    height: 100,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text("Teacher"),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRole = "student";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: selectedRole == "student"
                                    ? const Color(0xFF007CF0).withOpacity(0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: selectedRole == "student"
                                      ? const Color(0xFF007CF0)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/st_login_img.png',
                                    width: 100,
                                    height: 100,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text("Student"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF007CF0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF00C9A7)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ LOGIN BUTTON (gradient + dynamic color)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: selectedRole == ""
                              ? const LinearGradient(
                            colors: [
                              Color(0xFF00C9A7),
                              Color(0xFF007CF0),
                            ],
                          )
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedRole.isEmpty) {
                              showError("Please select a role");
                              return;
                            }

                            loginUser(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor:
                            getButtonColor() ?? Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ✅ CLEARS FIELDS WHEN SWITCHING TO REGISTER SCREEN
                    GestureDetector(
                      onTap: () {
                        _clearFields();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ).then((_) {
                          _clearFields();
                        });
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF00C9A7),
                            Color(0xFF007CF0),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}