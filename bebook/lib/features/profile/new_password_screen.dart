import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({super.key, required this.email});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false; 
  bool _isConfirmVisible = false; // ─░kinci kutu i├ğin de─şi┼şken
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    String password = _passwordController.text.trim();
    String confirm = _confirmPasswordController.text.trim();

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("┼Şifre en az 6 karakter olmal─▒d─▒r!")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("┼Şifreler birbiriyle uyu┼şmuyor!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.resetPassword(widget.email, password);

    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("┼Şifreniz ba┼şar─▒yla g├╝ncellendi! Giri┼ş yapabilirsiniz.")),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Bir hata olu┼ştu")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni ┼Şifre Belirle"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "L├╝tfen yeni ┼şifrenizi giriniz.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            
            // YEN─░ ┼Ş─░FRE KUTUSU
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Yeni ┼Şifre",
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
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
            
            const SizedBox(height: 16),
            
            // ┼Ş─░FRE TEKRAR KUTUSU (Buray─▒ da g├╝ncelledik)
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmVisible, // De─şi┼şkene ba─şland─▒
              decoration: InputDecoration(
                labelText: "┼Şifre Tekrar",
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isConfirmVisible = !_isConfirmVisible;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("┼Şifreyi G├╝ncelle",
                        style: TextStyle(fontSize: 18)),
                  ),
          ],
        ),
      ),
    );
  }
}