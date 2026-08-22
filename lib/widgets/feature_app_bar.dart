import 'package:flutter/material.dart';

PreferredSizeWidget featureAppBar(String title, BuildContext context) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
        ),
      ),
    ),
    foregroundColor: Colors.white,
  );
}