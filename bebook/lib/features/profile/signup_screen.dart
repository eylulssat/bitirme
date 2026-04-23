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
  bool _obscurePassword = true;
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
  bool _isPasswordStrong(String password) {
  // En az 8 karakter, 1 büyük harf, 1 küçük harf ve 1 rakam
  final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
  return regex.hasMatch(password);
}

  Future<void> _handleSignup() async {
    const String apiUrl = "http://192.168.67.75:8000/signup"; 
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
        // null mesajı yerine senin istediğin sabit yazı:
        _showSnackBar("Üye olma işlemi başarılı!", Colors.green);
        
        // Kullanıcının mesajı görmesi için yarım saniye bekleyip sayfayı kapatır
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context); 
        });
      } else {
        // Hata durumunda da karmaşayı önlemek için basit bir mesaj:
        _showSnackBar("Hata: Kayıt oluşturulamadı.", Colors.red);
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
    // Eğer bu bir şifre alanıysa ve _obscurePassword true ise gizle
    obscureText: isPassword ? _obscurePassword : false, 
    validator: (v) {
  // 1. Önce boş olup olmadığını kontrol et (Tüm alanlar için geçerli)
  if (v == null || v.isEmpty) {
    return "Bu alan gereklidir";
  }

  // 2. Eğer bu alan E-posta alanıysa, format kontrolü yap
  if (label == "E-posta") {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(v)) {
      return "Geçerli bir e-posta adresi giriniz.";
    }
  }

  // 3. Eğer bu alan Şifre alanıysa, güç kontrolü yap
  if (isPassword && !_isPasswordStrong(v)) {
    return "Şifre en az 8 karakter, bir büyük, bir küçük harf ve rakam içermelidir.";
  }

  // Her şey yolundaysa null döndür
  return null;
},
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      // Şifre alanına göz ikonu ekliyoruz
      suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                // İkona basıldığında durumu tersine çeviriyoruz
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            )
          : null,
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