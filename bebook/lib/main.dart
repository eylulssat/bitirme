import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/main_wrapper.dart';

void main() {
  runApp(const BebookApp());
}

class BebookApp extends StatelessWidget {
  const BebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bebook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          secondary: const Color(0xFFFF6584),
          surface: const Color(0xFFF5F5F5), 
        ),
        textTheme: GoogleFonts.poppinsTextTheme(), 
      ),
      
      home: const MainWrapper(), 
    );
  }
}