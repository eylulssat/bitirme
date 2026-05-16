import 'package:flutter/material.dart';
import 'package:bebook/services/api_service.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
 
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkPurple = Color(0xFF1E0E3E);
    const Color brandColor = Color(0xFF9181F4);

    return Scaffold(
      backgroundColor: darkPurple,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Form( 
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Bizimle İletişime Geç",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: brandColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                     _buildField("Adınız Soyadınız", _nameController),
const SizedBox(height: 15),
_buildField("E-posta Adresiniz", _emailController, isEmail: true),
const SizedBox(height: 15),
_buildField("Mesajınız", _messageController, isLong: true),
                      
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
    if (_formKey.currentState!.validate()) {
      // 1. Kullanıcıya işlem yapıldığını göstermek için basit bir loading gösterilebilir
      // 2. ApiService'i çağırıyoruz
      bool basariliMi = await ApiService.sendContactMessage(
        _nameController.text,
        _emailController.text,
        _messageController.text,
      );

      if (basariliMi) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mesajınız başarıyla iletildi!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Veri gittikten sonra sayfayı kapat
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mesaj gönderilemedi. Lütfen bağlantınızı kontrol edin!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "Gönder",
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildField(String hint, TextEditingController controller, {bool isEmail = false, bool isLong = false}) {
  return TextFormField(
      controller: controller,
      maxLines: isLong ? 4 : 1,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Bu alan boş bırakılamaz";
        }
        return null; 
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.all(15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9181F4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder( 
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}