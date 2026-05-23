import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // ApiService dosya yolunu kontrol et
import 'otp_verification_screen.dart'; // Yeni olu┼şturaca─ş─▒n ekran─▒n yolu
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false; // Y├╝klenme durumunu takip etmek i├ğin

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("┼Şifremi Unuttum",
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
                  const Icon(Icons.mark_email_read_outlined,
                      size: 80, color: primaryColor),
                  const SizedBox(height: 20),
                  const Text(
                    "┼Şifrenizi mi Unuttunuz?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Kay─▒tl─▒ e-posta adresinizi girin, size bir do─şrulama kodu g├Ânderelim.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // E-POSTA ALANI
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || value.isEmpty)
                        ? "L├╝tfen e-postan─▒z─▒ girin"
                        : null,
                    decoration: InputDecoration(
                      labelText: "E-posta Adresi",
                      prefixIcon: const Icon(Icons.mail_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // G├ûNDER BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendOtp, // Y├╝kleniyorsa butonu pasif yap
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Kod G├Ânder",
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

  // OTP G├Ânderme ─░┼şlemi
  Future<void> _handleSendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final result = await ApiService.sendOtp(_emailController.text);

        if (!mounted) return;

        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Do─şrulama kodu e-posta adresinize g├Ânderildi!"),
              backgroundColor: Colors.green,
            ),
          );

          // Kod do─şrulama ekran─▒na y├Ânlendiriyoruz
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(email: _emailController.text),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? "Kod g├Ânderilemedi."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ba─şlant─▒ hatas─▒ olu┼ştu."),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}