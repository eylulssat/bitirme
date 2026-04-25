import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'contact_support_screen.dart';
import 'about_bebook_screen.dart';
import 'favorites_screen.dart';
import '../../widgets/book_card.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  List<Book> myBooks = [];
  bool isLoading = false;
  bool isLoggedIn = false;

  String? userEmail;
  String? userUniversity;
  String? userDepartment;
  int? userId;

  //final String baseUrl = "http://192.168.67.71:8000/uploads/";

  @override
  void initState() {
    super.initState();
    if (isLoggedIn && userId != null) {
      fetchMyBooks();
    }
  }

  // ProfileScreenState içindeki fetchMyBooks fonksiyonunu şu şekilde güncelle:

  Future<void> fetchMyBooks() async {
    if (userId == null) return;
    setState(() => isLoading = true);

    try {
      final data = await ApiService.getMyBooks(userId!);

      // fetchMyBooks fonksiyonunun içindeki setState kısmını şununla değiştir:

      setState(() {
        myBooks = data.map<Book>((b) {
          String rawPath = b['image_path'] ?? b['imageUrl'] ?? "";
          String finalImageUrl = "https://via.placeholder.com/150";

          if (rawPath.isNotEmpty) {
            if (rawPath.startsWith('http')) {
              finalImageUrl = rawPath;
            }
            // 500 yerine 200 karakter kontrolü daha garantidir (Base64 verileri binlerce karakterdir)
            else if (rawPath.length > 200 || rawPath.contains(';base64,')) {
              finalImageUrl = "https://via.placeholder.com/150";
              debugPrint(
                  "UYARI: Bozuk veri (Base64) algılandı, placeholder gösteriliyor.");
            } else {
              // Normal dosya adı ise birleştirme yap
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
                    setState(() {
                      isLoggedIn = true;
                      userEmail = result['user_email'];
                      userUniversity = result['university'];
                      userDepartment = result['department'];
                      userId = result['user_id'];
                    });
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
                CircleAvatar(
                  radius: 35,
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child: Text(
                    (userEmail != null && userEmail!.isNotEmpty)
                        ? userEmail![0].toUpperCase()
                        : "?",
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
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
          _buildTile(Icons.assignment_turned_in_outlined, "Satılan Kitaplarım",
              primaryColor, () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Bu özellik yakında eklenecek.")));
          }),
          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: () {
              setState(() {
                isLoggedIn = false;
                userEmail = null;
                userId = null;
                myBooks = [];
              });
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text("Çıkış Yap",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMyBooksSheet() {
    if (myBooks.isEmpty && !isLoading) {
      fetchMyBooks();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                padding: EdgeInsets.all(20.0),
                child: Text("İlanlarım",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : myBooks.isEmpty
                        ? const Center(
                            child: Text("Henüz bir ilanınız bulunmuyor."))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: myBooks.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.65,
                            ),
                            itemBuilder: (context, index) => BookCard(
                              book: myBooks[index],
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
