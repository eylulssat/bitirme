import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'contact_support_screen.dart';
import 'about_bebook_screen.dart';
import 'favorites_screen.dart';
import '../../widgets/book_card.dart';
import '../../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ekle
import 'faq_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile; // Seçilen dosyayı hafızada tutmak için
  List<Book> myBooks = [];
  bool isLoading = false;
  bool isLoggedIn = false;
  String? _remoteImagePath;

  String? userEmail;
  String? userUniversity;
  String? userDepartment;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Eskiden burada sadece fetchMyBooks kontrolü vardı, şimdi bu geldi
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Hafızadan verileri okuyoruz (Login ekranında kaydettiğimiz bilgiler)
      userId = prefs.getInt('user_id');
      userEmail = prefs.getString('user_email');
      userUniversity = prefs.getString('university');
      userDepartment = prefs.getString('department');
      _remoteImagePath = prefs.getString('profile_image_path');

      // Eğer hafızada bir id varsa, kullanıcı hala "Giriş Yapmış" demektir
      isLoggedIn = userId != null;
    });

    if (isLoggedIn) {
      fetchMyBooks(); // Giriş yapılmışsa kitapları çek
    }
  }

  Future<void> fetchMyBooks() async {
    if (userId == null) return;
    setState(() => isLoading = true);

    try {
      final data = await ApiService.getMyBooks(userId!);

      setState(() {
        myBooks = data.map<Book>((b) {
          String rawPath = b['image_path'] ?? b['imageUrl'] ?? "";
          String finalImageUrl = "https://via.placeholder.com/150";

          if (rawPath.isNotEmpty) {
            if (rawPath.startsWith('http')) {
              finalImageUrl = rawPath;
            } else if (rawPath.length > 200 || rawPath.contains(';base64,')) {
              finalImageUrl = "https://via.placeholder.com/150";
              debugPrint("UYARI: Bozuk veri (Base64) algılandı.");
            } else {
              String cleanFileName =
                  rawPath.replaceAll("uploads", "").replaceAll("/", "").trim();
              finalImageUrl = "${ApiService.baseUrl}/uploads/$cleanFileName";
            }
          }

          return Book(
            bookId: b['book_id'] ?? b['id'],
            userId: b['user_id'] ?? userId,
            title: b['title'] ?? "Bilinmiyor",
            author: b['author'] ?? "Bilinmiyor",
            price: b['price'].toString(),
            imageUrl: finalImageUrl,
            university: b['university'] ?? "Zonguldak BEÜ",
            description: b['description'] ?? "",
          );
        }).toList();
      });
    } catch (e) {
      debugPrint("Profil Kitapları Yükleme Hatası: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && userId != null) {
      File image = File(pickedFile.path);
      bool success = await ApiService.uploadProfilePhoto(userId!, image);

      if (success) {
        setState(() {
          _imageFile = image;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil fotoğrafı güncellendi!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    if (isLoggedIn && myBooks.isEmpty && !isLoading && userId != null) {
      fetchMyBooks();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Profil",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AboutBebookScreen())),
            icon: const Icon(Icons.info_outline_rounded, color: primaryColor),
          ),
          IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ContactSupportScreen())),
            icon: const Icon(Icons.support_agent_rounded, color: primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoggedIn
          ? _buildProfileDashboard(primaryColor)
          : _buildAuthUI(primaryColor),
    );
  }

  Widget _buildAuthUI(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined,
                size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text("Bebook'a Hoş Geldin",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                "Profilini yönetmek ve ilanlarını görmek için giriş yapmalısın.",
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );

                  if (result != null && result is Map) {
                    final prefs = await SharedPreferences
                        .getInstance(); // Hafızaya erişmek için
                    setState(() {
                      isLoggedIn = true;
                      userEmail = result['user_email'];
                      userUniversity = result['university'];
                      userDepartment = result['department'];
                      userId = result['user_id'];
                      _remoteImagePath = result[
                          'profile_image_path']; // Backend'den gelen resim yolu
                    });

                    // Hafızaya kalıcı olarak yazıyoruz ki uygulama kapanınca bilgiler gitmesin
                    await prefs.setInt('user_id', userId!);
                    await prefs.setString('user_email', userEmail!);
                    await prefs.setString(
                        'profile_image_path', _remoteImagePath ?? "");
                    // Diğer bilgileri de istersen buraya ekleyebilirsin (okul, bölüm vb.)

                    fetchMyBooks();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Giriş Yap",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen())),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Üye Ol",
                    style: TextStyle(
                        color: primaryColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDashboard(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ]),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryColor.withOpacity(0.2),
                    // BURASI GÜNCELLENDİ: Hem galeriden seçilen hem sunucudan gelen fotoğrafa bakar
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_remoteImagePath != null &&
                                _remoteImagePath!.isNotEmpty
                            ? NetworkImage(
                                    "${ApiService.baseUrl}/$_remoteImagePath")
                                as ImageProvider
                            : null),

                    // BURASI GÜNCELLENDİ: Eğer her iki durumda da fotoğraf yoksa harfi gösterir
                    child: (_imageFile == null &&
                            (_remoteImagePath == null ||
                                _remoteImagePath!.isEmpty))
                        ? Text(
                            (userEmail != null && userEmail!.isNotEmpty)
                                ? userEmail![0].toUpperCase()
                                : "?",
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userEmail ?? "E-posta bulunamadı",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(
                          userUniversity ??
                              "Zonguldak Bülent Ecevit Üniversitesi",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildTile(
              Icons.favorite_border,
              "Favorilediğim Kitaplar",
              primaryColor,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesScreen()))),
          _buildTile(Icons.sell_outlined, "Satışa Sunduğum Kitaplar",
              primaryColor, () => _showMyBooksSheet()),

// YENİ EKLEYECEĞİN KISIM:

          _buildTile(Icons.assignment_turned_in_outlined, "Satılan Kitaplarım",
              primaryColor, () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Bu özellik yakında eklenecek.")));
          }),
          _buildTile(
            Icons.help_outline_rounded,
            "Sıkça Sorulan Sorular(SSS)",
            primaryColor,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ),

          // ... Profil Dashboard'un en altındaki Çıkış Yap butonu ...

          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: () async {
              // Burayı async yapmayı unutma
              final prefs = await SharedPreferences.getInstance();
              await prefs
                  .clear(); // Telefona kayıtlı tüm kullanıcı bilgilerini (id, email, foto yolu) siliyoruz

              setState(() {
                isLoggedIn = false;
                userEmail = null;
                userId = null;
                _remoteImagePath = null; // Fotoğraf yolunu da sıfırla
                myBooks = [];
              });
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text(
              "Çıkış Yap",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showMyBooksSheet() {
    // Arama için geçici liste ve controller
    List<Book> filteredMyBooks = List.from(myBooks);

    if (myBooks.isEmpty && !isLoading) {
      fetchMyBooks();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 10),
                child: Text("İlanlarım",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),

              // Arama Çubuğu
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: TextField(
                  onChanged: (value) {
                    setModalState(() {
                      filteredMyBooks = myBooks.where((book) {
                        return book.title
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                            (book.author ?? "")
                                .toLowerCase()
                                .contains(value.toLowerCase());
                      }).toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "İlanlarımda ara...",
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF6C63FF)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredMyBooks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 60, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text(
                                  myBooks.isEmpty
                                      ? "Henüz bir ilanınız bulunmuyor."
                                      : "Aradığınız ilan bulunamadı.",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredMyBooks.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.65,
                            ),
                            itemBuilder: (context, index) => BookCard(
                              book: filteredMyBooks[index],
                              isMyPost: true,
                              onUpdated: () {
                                fetchMyBooks();
                                Navigator.pop(context);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
