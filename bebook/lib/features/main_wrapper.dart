import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:bebook/features/cart/cart_screen.dart';
import 'package:bebook/features/home/home_screen.dart';
import 'package:bebook/features/post_ad/add_product_screen.dart';
import 'package:bebook/features/profile/profile_screen.dart';
import 'package:bebook/features/chat/chat_list_screen.dart';

class MainWrapper extends StatefulWidget {
  final int myId; // <-- BURAYI EKLEDİK: Dışarıdan ID gelecek
  const MainWrapper({super.key, this.myId = 0}); // Varsayılan olarak 0 verdik

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  int? userId;
  String? userEmail;

  final GlobalKey<ProfileScreenState> _profileKey =
      GlobalKey<ProfileScreenState>();

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    // MainWrapper içindeki _pages listesi
    final List<Widget> _pages = [
      const HomeScreen(),
      ChatListScreen(
          myId: widget
              .myId), // <-- BURAYI GÜNCELLEDİK: Artık 4 değil, giriş yapanın ID'si!
      const SizedBox(),
      CartScreen(onDiscoverPressed: () {
        setState(() {
          _selectedIndex = 0;
        });
      }),
      ProfileScreen(key: _profileKey),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.05))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: primaryColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: primaryColor.withOpacity(0.1),
              color: Colors.grey[600],
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Keşfet'),
                GButton(
                    icon: Icons.chat_bubble_outline_rounded, text: 'Mesajlar'),
                GButton(icon: Icons.add_circle_outline, text: 'Sat'),
                GButton(icon: Icons.shopping_cart_outlined, text: 'Sepetim'),
                GButton(icon: Icons.person_outline, text: 'Profil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) async {
                if (index == 2) {
                  // 1. Yeni ürün ekleme sayfasını açıyoruz
                  // MainWrapper.dart içinde
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(
                        userId:
                            widget.myId, // Giriş yapanın ID'sini gönderiyoruz
                        userEmail: userEmail, // Varsa emailini de gönder
                      ),
                    ),
                  );

                  // 2. Eğer ürün başarıyla eklendiyse (genelde geri dönerken true döner)
                  if (result == true) {
                    // Profil sayfasındaki ilanlarım listesini yeniliyoruz
                    _profileKey.currentState?.fetchMyBooks(widget.myId);

                    // Kullanıcıyı otomatik olarak "Profil" sekmesine yönlendiriyoruz ki ilanını görsün
                    setState(() {
                      _selectedIndex = 4; // Profil sekmesinin indeksi
                    });
                  }
                } else {
                  // Diğer sekmelere tıklandığında normal geçiş yap
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
