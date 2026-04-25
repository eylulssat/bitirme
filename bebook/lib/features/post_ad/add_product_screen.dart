import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:bebook/services/api_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AddProductScreen extends StatefulWidget {
  final int? userId;
  final String? userEmail;

  const AddProductScreen({super.key, this.userId, this.userEmail});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();

  bool isUserLoggedIn = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mailController.text = widget.userEmail ?? "";
    debugPrint("AddProductScreen aktif. User ID: ${widget.userId}");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _typeController.dispose();
    _publisherController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _mailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera && Platform.isWindows) {
        _showSnackBar("Windows'ta kamera pasif. 🚀", Colors.orange);
        return;
      }
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (_selectedImages.length < 5) {
            _selectedImages.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      debugPrint("Resim seçme hatası: $e");
    }
  }

  Future<void> pickImageAndScan() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1000,
      );

      if (pickedFile != null) {
        Uint8List imageBytes = await pickedFile.readAsBytes();
        await fetchBookData(imageBytes, pickedFile.name);
      }
    } catch (e) {
      print("Hata: $e");
    }
  }

  Future<void> fetchBookData(Uint8List imageBytes, String fileName) async {
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("http://192.168.67.71:8001/scan"),
      );
      request.files.add(
        http.MultipartFile.fromBytes("image", imageBytes, filename: fileName),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        setState(() {
          _nameController.text = data["title"] ?? "";
          _authorController.text = data["author"] ?? "";
          _publisherController.text = data["publisher"] ?? "";
        });
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showLoginAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Giriş Gerekli"),
        content: const Text("İlan vermek için lütfen giriş yapın."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Kitap Sat",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Kitabını Hızlıca Listele 📚",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildAIButton(),
            const SizedBox(height: 40),
            _buildDivider("veya manuel"),
            const SizedBox(height: 30),
            _buildInput(
                label: "Kitap Adı *",
                icon: Icons.book_outlined,
                controller: _nameController),
            const SizedBox(height: 15),
            _buildInput(
                label: "Yazar *",
                icon: Icons.person_outline,
                controller: _authorController),
            const SizedBox(height: 15),
            _buildInput(
                label: "Tür",
                icon: Icons.category_outlined,
                controller: _typeController),
            const SizedBox(height: 15),
            _buildInput(
                label: "Yayınevi",
                icon: Icons.business_outlined,
                controller: _publisherController),
            const SizedBox(height: 15),
            _buildInput(
                label: "Fiyat (TL) *",
                icon: Icons.sell_outlined,
                isNumber: true,
                controller: _priceController),
            const SizedBox(height: 15),
            _buildInput(
                label: "Açıklama",
                icon: Icons.description_outlined,
                controller: _descController),
            const SizedBox(height: 15),
            _buildInput(
                label: "İletişim Maili *",
                icon: Icons.contact_mail_outlined,
                controller: _mailController),
            const SizedBox(height: 30),
            const Text("Fotoğraf Ekle",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length +
                    (_selectedImages.length < 5 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length)
                    return _buildAddPhotoButton();
                  return _buildImageThumbnail(index);
                },
              ),
            ),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton() {
    return InkWell(
      onTap: _isLoading ? null : pickImageAndScan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4B45B2)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : const Column(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.white, size: 50),
                  SizedBox(height: 15),
                  Text("ISBN Barkodunu Tara",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: () async {
        if (!isUserLoggedIn) {
          showLoginAlert(context);
          return;
        }
        if (_nameController.text.isEmpty ||
            _authorController.text.isEmpty ||
            _priceController.text.isEmpty ||
            _mailController.text.isEmpty) {
          _showSnackBar("Lütfen yıldızlı (*) alanları doldurun!", Colors.orange);
          return;
        }
        double? priceValue = double.tryParse(_priceController.text);
        if (priceValue == null) {
          _showSnackBar("Geçerli bir fiyat giriniz!", Colors.orange);
          return;
        }

        // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
        String imagePathToSend = ""; 
        if (_selectedImages.isNotEmpty) {
          // Base64 metne çevirmek yerine doğrudan dosya yolunu alıyoruz
          imagePathToSend = _selectedImages[0].path; 
        }

        bool success = await ApiService.uploadBook(
          userId: widget.userId ?? 4,
          title: _nameController.text.trim(),
          author: _authorController.text.trim(),
          category: _typeController.text.trim(),
          price: priceValue,
          description: _descController.text.trim(),
          sellerEmail: _mailController.text.trim(),
          imagePath: imagePathToSend, // Artık Base64 değil, gerçek yol gidiyor
        );
        // --- DEĞİŞİKLİK BURADA BİTİYOR ---

        if (success) {
          _showSnackBar("İlan başarıyla yayınlandı!", Colors.green);
          Navigator.pop(context, true);
        } else {
          _showSnackBar("Hata: İlan yayınlanamadı.", Colors.red);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: const Text("İlanı Yayınla",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );
}

  Widget _buildInput(
      {required String label,
      required IconData icon,
      bool isNumber = false,
      TextEditingController? controller}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(text)),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF6C63FF)),
        ),
        child: const Icon(Icons.add_a_photo_outlined,
            color: Color(0xFF6C63FF), size: 30),
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
                image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 15,
          top: 5,
          child: GestureDetector(
            onTap: () => setState(() => _selectedImages.removeAt(index)),
            child: const CircleAvatar(
                backgroundColor: Colors.red,
                radius: 12,
                child: Icon(Icons.close, size: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
