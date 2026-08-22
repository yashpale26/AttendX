import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AddStudentUsersScreen extends StatefulWidget {
  const AddStudentUsersScreen({super.key});

  @override
  State<AddStudentUsersScreen> createState() => _AddStudentUsersScreenState();
}

class _AddStudentUsersScreenState extends State<AddStudentUsersScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> addStudent() async {
    String email = emailController.text.trim();

    if (email.isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!email.endsWith("@attendx.com")) {
      email = "$email@attendx.com";
    }

    if (passController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Initialize a secondary FirebaseApp instance
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      UserCredential tempUserCred =
      await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: email,
        password: passController.text.trim(),
      );

      String uid = tempUserCred.user!.uid;

      // 2. Clean up temporary app instance
      await tempApp.delete();

      // 3. Save student details into Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': 'student',
        'name': email.split('@')[0],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 4. Forcefully clear all fields and reset loading status
      emailController.clear();
      passController.clear();
      confirmController.clear();

      setState(() => isLoading = false);

      // 5. Display success popup dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Account has been created successfully!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student Users"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                suffixText: "@attendx.com",
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passController,
              obscureText: obscure1,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure1 ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => obscure1 = !obscure1);
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: confirmController,
              obscureText: obscure2,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure2 ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => obscure2 = !obscure2);
                  },
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: addStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Add Student",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}