import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  String selectedRole = "";
  bool _isPasswordVisible = false;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> registerUser() async {
    FocusScope.of(context).unfocus();

    if (selectedRole.isEmpty) {
      showMessage("Please select a role");
      return;
    }

    if (nameController.text.trim().isEmpty) {
      showMessage("Please enter your name");
      return;
    }

    if (emailController.text.trim().isEmpty) {
      showMessage("Enter username");
      return;
    }

    if (passwordController.text.isEmpty) {
      showMessage("Please enter a password");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showMessage("Passwords do not match");
      return;
    }

    String email = emailController.text.trim();
    if (!email.endsWith("@attendx.com")) {
      email = "$email@attendx.com";
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create Auth account in Firebase
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // 2. Save user details in Firestore asynchronously
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'email': email,
        'role': selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 3. Forcefully clear all input fields and reset state
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      setState(() {
        selectedRole = "";
        _isLoading = false;
      });

      // 4. Force success feedback notification
      showMessage("Account created successfully!");

      // 5. Navigate to Login after short delay
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      showMessage(e.message ?? "Registration failed");
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      showMessage("Error creating account. Please try again.");
    }
  }

  Color getCardColor() {
    if (selectedRole == "teacher") {
      return const Color(0xFFE6FFF5);
    } else if (selectedRole == "student") {
      return const Color(0xFFE6F0FF);
    }
    return Colors.white;
  }

  Color? getButtonColor() {
    if (selectedRole == "teacher") {
      return const Color(0xFF00C9A7);
    } else if (selectedRole == "student") {
      return const Color(0xFF007CF0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C9A7), Color(0xFF007CF0)],
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

                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.green, Colors.blue],
                      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 28,
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
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        hintText: "Enter username",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixText: "@attendx.com",
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BUTTON WITH LOADING INDICATOR
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? const Center(
                        child: CircularProgressIndicator(),
                      )
                          : (getButtonColor() == null
                          ? Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00C9A7),
                              Color(0xFF007CF0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text("Register", style: TextStyle(color: Colors.white)),
                        ),
                      )
                          : ElevatedButton(
                        onPressed: registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getButtonColor(),
                        ),
                        child: const Text("Register", style: TextStyle(color: Colors.white)),
                      )),
                    ),

                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF00C9A7),
                            Color(0xFF007CF0),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "Already have an account? Login",
                          style: TextStyle(color: Colors.white),
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