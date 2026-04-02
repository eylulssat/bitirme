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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Book> myBooks = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  String? userEmail;
  String? userUniversity;
  String? userDepartment;
  int? userId;
  @override
  void initState() {
    super.initState();
  }

  void fetchMyBooks() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final data = await ApiService.getMyBooks(userId!);

      setState(() {
        myBooks = data
            .map<Book>((b) => Book(
                  bookId: b['book_id'],
                  userId: b['user_id'],
                  title: b['title'],
                  author: b['author'] ?? "Bilinmiyor",
                  price: b['price'].toString(),
                  imageUrl: b['imageUrl'] ?? "https://via.placeholder.com/150",
                  university: b['university'] ?? "BEÜ",
                  description: b['description'],
                ))
            .toList();

        isLoading = false;
      });
    } catch (e) {
      print("HATA: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title:
            const Text("Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
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
            const Text("Profilini yönetmek için giriş yapmalısın.",
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final Map<String, dynamic>? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );

                  if (result != null) {
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
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text("Giriş Yap",
                    style: TextStyle(color: Colors.white)),
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
                    side: BorderSide(color: primaryColor)),
                child: Text("Üye Ol", style: TextStyle(color: primaryColor)),
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
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                // Baş harfi dinamik yaptık
                CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF6C63FF),
                    child: Text(
                        userEmail != null ? userEmail![0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(userEmail?.split('@')[0] ?? "Kullanıcı",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(userDepartment ?? "Bölüm Belirtilmedi",
                      style: const TextStyle(color: Colors.grey)),
                  Text(userUniversity ?? "Üniversite Belirtilmedi",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
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
          _buildTile(
            Icons.sell_outlined,
            "Satışa Sunduğum Kitaplar",
            primaryColor,
            () {
              
             

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: myBooks.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          child: BookCard(book: myBooks[index]),
                          
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          _buildTile(Icons.assignment_turned_in_outlined, "Satılan Kitaplarım",
              primaryColor, () {}),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() {
              isLoggedIn = false;
              userEmail = null;
            }),
            child: const Text("Çıkış Yap", style: TextStyle(color: Colors.red)),
          ),
        ],
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
