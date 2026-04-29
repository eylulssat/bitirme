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

  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  // DİKKAT: Sayfa listesini build dışında veya build içinde dinamik oluşturmalısın.
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    // Listeden 'const' kelimesini sildik çünkü içine 'widget.myId' gibi değişkenler giriyor.
    final List<Widget> _pages = [
      HomeScreen(
        myId: widget.myId,
        myName: widget.myName,
      ),
      ChatListScreen(
        key: ValueKey("chat_${widget.myId}"),
        myId: widget.myId, // ChatListScreen'de myId tanımlı olmalı!
      ),
      const SizedBox(), // 'Sat' butonu için boşluk
      CartScreen(onDiscoverPressed: () {
        setState(() => _selectedIndex = 0);
      }),
      ProfileScreen(
        key: _profileKey,
        userId: widget.myId,
      ),
    ];
    return Scaffold(
      body: _pages[_selectedIndex],
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
                  setState(() => _selectedIndex = index);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
