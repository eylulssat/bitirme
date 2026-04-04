import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP istekleri için
import 'dart:convert'; // JSON dönüşümleri için

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 1. VERİLERİ YAKALAMAK İÇİN CONTROLLER'LAR
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedUniversity;
  String? _selectedDepartment;

  // Liste Verileri
  final List<String> _universities = [
    'Zonguldak Bülent Ecevit Üniversitesi',
    'İstanbul Teknik Üniversitesi',
    'Orta Doğu Teknik Üniversitesi',
    'Diğer'
  ];

  final List<String> _departments = [
    'Bilgisayar Mühendisliği',
    'Elektrik-Elektronik Mühendisliği',
    'Makine Mühendisliği',
    'İktisat',
    'İşletme',
    'Tıp',
    'Diş Hekimliği',
    'Eczacılık',
    'Psikoloji',
    'İstatistik',
    'Yönetim Bilişim Sistemleri',
    'Diğer'
  ];

  Future<void> _handleSignup() async {
const String apiUrl = "http://192.168.67.122:8000/signup"; // Web'de çalıştığın için localhost kullanmalısın.
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
          "university": _selectedUniversity,
          "department": _selectedDepartment,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSnackBar("Başarılı: ${data['message']}", Colors.green);
        Navigator.pop(context); 
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar("Hata: ${errorData['detail']}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Bağlantı hatası: Sunucu açık mı?", Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Üye Ol", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Bebook Dünyasına Katıl",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 30),
                  
                  _buildTextField("E-posta", Icons.email_outlined, controller: _emailController),
                  const SizedBox(height: 15),
                  _buildTextField("Şifre", Icons.lock_outline, isPassword: true, controller: _passwordController),
                  const SizedBox(height: 15),

                  _buildDropdownField(
                    "Okuduğun Üniversite", 
                    Icons.school_outlined, 
                    _universities, 
                    (val) => setState(() => _selectedUniversity = val)
                  ),
                  const SizedBox(height: 15),

                  _buildDropdownField(
                    "Okuduğun Bölüm", 
                    Icons.computer_outlined, 
                    _departments, 
                    (val) => setState(() => _selectedDepartment = val)
                  ),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _handleSignup(); 
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Üye Ol", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(String label, IconData icon, {bool isPassword = false, required TextEditingController controller}) {
    return TextFormField(
      controller: controller, 
      obscureText: isPassword,
      validator: (v) => (v == null || v.isEmpty) ? "Bu alan gereklidir" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => (v == null) ? "Lütfen seçim yapın" : null,
      isExpanded: true,
    );
  }
}