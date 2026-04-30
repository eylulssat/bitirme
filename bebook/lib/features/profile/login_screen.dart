import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isObscure = true;
  bool _isLoading = false; // Giriş yaparken butonu pasif yapmak için ekledik
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // BACKEND BAĞLANTI FONKSİYONU
  Future<void> _handleLogin() async {
    // Android Emulator için: 10.0.2.2, Gerçek cihaz/Web için kendi IP'n
    const String apiUrl = "http://192.168.67.144:8000/login";

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );
      print("🔥 LOGIN RESPONSE BODY: ${response.body}");

      final data = jsonDecode(response.body);

      final userId =
          int.tryParse((data['user_id'] ?? data['id'] ?? 0).toString()) ?? 0;

      print("🔥 FINAL USER ID: $userId");

      print("🔥 PARSED DATA: $data");
      print("🔥 USER ID TYPE: ${data['user_id'].runtimeType}");
      print("🔥 USER ID VALUE: ${data['user_id']}");

      // SİLİNEN VE DÜZENLENEN KISIM BURASI:
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 1. Verileri telefona kaydediyoruz (Kalıcı olması için)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString(
            'profile_image_path', data['profile_image_path'] ?? "");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final userId =
              int.tryParse((data['user_id'] ?? data['id'] ?? 0).toString()) ??
                  0;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainWrapper(
                myId: userId,
                myName: data['full_name'] ?? "Merve",
              ),
            ),
            (route) => false,
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorSnackBar(errorData['detail'] ?? "E-posta veya şifre hatalı!");
      }
    } catch (e) {
      _showErrorSnackBar("Bağlantı hatası: Sunucuya erişilemiyor.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Giriş Yap",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.lock_person_rounded,
                      size: 80, color: primaryColor),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "E-posta giriniz" : null,
                    decoration: InputDecoration(
                      labelText: "E-posta",
                      prefixIcon: const Icon(Icons.mail_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Şifre giriniz" : null,
                    decoration: InputDecoration(
                      labelText: "Şifre",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _isObscure = !_isObscure),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        "Şifremi Unuttum",
                        style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null // İstek devam ederken butonu pasif yap
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _handleLogin();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Giriş Yap",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
