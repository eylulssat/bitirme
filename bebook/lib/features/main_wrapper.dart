import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:bebook/features/cart/cart_screen.dart';
import 'package:bebook/features/home/home_screen.dart';
import 'package:bebook/features/post_ad/add_product_screen.dart';
import 'package:bebook/features/profile/profile_screen.dart';
import 'package:bebook/features/chat/chat_list_screen.dart';

class MainWrapper extends StatefulWidget {
  final int myId;
  final String myName;
  const MainWrapper({super.key, required this.myId, required this.myName});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  String? userEmail;
  bool _hasUnreadMessages = false;
  
  // 1. Sayfaları tutacak listeyi burada tanımlıyoruz
  late List<Widget> _pages;

  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  @override
  void initState() {
    super.initState();
    print("MAINWRAPPER USER ID: ${widget.myId}");
    _checkNotifications();

    // 2. Sayfaları initState içinde bir kez oluşturuyoruz
    // Böylece sayfalar bellekte "canlı" kalır, durumları kaybolmaz
    _pages = [
      HomeScreen(
        myId: widget.myId,
        myName: widget.myName,
      ),
      ChatListScreen(
        key: ValueKey("chat_${widget.myId}"),
        myId: widget.myId,
      ),
      const SizedBox(), // Sat butonu için boşluk
      CartScreen(
        myId: widget.myId, // <-- İşte bu eksik olduğu için kırmızı yanıyor!
        onDiscoverPressed: () {
          setState(() => _selectedIndex = 0);
        },
      ),
      ProfileScreen(
        key: _profileKey,
        userId: widget.myId,
      ),
    ];
  }

  Future<void> _checkNotifications() async {
    try {
      setState(() {
        _hasUnreadMessages = false;
      });
    } catch (e) {
      print("Bildirim kontrol hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      // 3. Body kısmında IndexedStack kullanıyoruz
      // Bu widget, tüm sayfaları üst üste dizer ama sadece seçili olanı gösterir
      // Diğer sayfalar arka planda "uyur" ama durumlarını (scroll vs.) korur
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
              tabs: [
                const GButton(icon: Icons.home_rounded, text: 'Keşfet'),
                GButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'Mesajlar',
                  leading: Stack(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: _selectedIndex == 1 ? primaryColor : Colors.grey[600],
                        size: 24,
                      ),
                      if (_hasUnreadMessages) 
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                          ),
                        ),
                    ],
                  ),
                ),
                const GButton(icon: Icons.add_circle_outline, text: 'Sat'),
                const GButton(icon: Icons.shopping_cart_outlined, text: 'Sepetim'),
                const GButton(icon: Icons.person_outline, text: 'Profil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) async {
                if (index == 2) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(
                        userId: widget.myId,
                        userEmail: userEmail,
                      ),
                    ),
                  );

                  if (result == true) {
                    _profileKey.currentState?.fetchMyBooks(widget.myId);
                    setState(() => _selectedIndex = 4);
                  }
                } else {
                  setState(() {
                    _selectedIndex = index;
                    if (index == 1) {
                      _hasUnreadMessages = false;
                    }
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }
} // _MainWrapperState sınıfı bitti