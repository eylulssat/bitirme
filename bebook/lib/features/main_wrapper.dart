import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:bebook/features/cart/cart_screen.dart';
import 'package:bebook/features/home/home_screen.dart';
import 'package:bebook/features/post_ad/add_product_screen.dart';
import 'package:bebook/features/profile/profile_screen.dart'; 

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> { 
  int _selectedIndex = 0;

 

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF); 
    final List<Widget> _pages = [
      const HomeScreen(),         // 0: Keşfet
      const Center(child: Text("Arama")), // 1: Ara
      const AddProductScreen(),   // 2: Sat
      CartScreen(onDiscoverPressed: () { // 3: Sepetim
        setState(() {
          _selectedIndex = 0; // Butona basınca Keşfet'e (0) gönder
        });
      }),
      const ProfileScreen(),      // 4: Profil
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
                GButton(icon: Icons.search_rounded, text: 'Ara'),
                GButton(icon: Icons.add_circle_outline, text: 'Sat'),
GButton(icon: Icons.shopping_cart_outlined, text: 'Sepetim'),
                GButton(icon: Icons.person_outline, text: 'Profil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}