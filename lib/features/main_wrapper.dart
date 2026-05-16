import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:bebook/features/cart/premium_cart_screen.dart'; // 💎 Premium sepet
import 'package:bebook/features/home/premium_home_screen.dart'; // 💎 Premium ana sayfa
import 'package:bebook/features/post_ad/premium_add_product_screen.dart'; // 💎 Premium ilan ver
import 'package:bebook/features/profile/profile_screen.dart';
import 'package:bebook/core/theme/app_theme.dart'; // 💎 Premium tema 

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> { 
  int _selectedIndex = 0;

  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();
  final GlobalKey<PremiumHomeScreenState> _homeKey = GlobalKey<PremiumHomeScreenState>(); // 💎 Premium

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      PremiumHomeScreen(key: _homeKey),   // 💎 Premium ana sayfa
      const Center(child: Text("Arama")), // 1: Ara
      const SizedBox(),                   // 2: Sat
      PremiumCartScreen(onDiscoverPressed: () { // 💎 Premium sepet
        setState(() => _selectedIndex = 0);
      }),
      ProfileScreen(key: _profileKey),    // 4: Profil
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.neutralWhite, // ✅ Modern renk
          boxShadow: AppTheme.shadowLG,  // ✅ Modern gölge
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: AppTheme.primaryIndigo.withOpacity(0.1),
              hoverColor: AppTheme.primaryIndigo.withOpacity(0.05),
              gap: 8,
              activeColor: AppTheme.primaryIndigo, // ✅ Modern renk
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
              color: AppTheme.neutralDark,
              tabs: const [
                GButton(icon: Icons.home_rounded,  ),
                GButton(icon: Icons.search_rounded, ),
                GButton(icon: Icons.add_circle_outline, ),
                GButton(icon: Icons.shopping_cart_outlined,),
                GButton(icon: Icons.person_outline),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) async {
                if (index == 2) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PremiumAddProductScreen( // 💎 Premium ilan ver
                        userId: _profileKey.currentState?.userId,
                        userEmail: _profileKey.currentState?.userEmail,
                      ),
                    ),
                  );
                  if (result == true) {
                    _profileKey.currentState?.fetchMyBooks();
                    setState(() => _selectedIndex = 4);
                  }
                } else {
                  // Profil sekmesinden anasayfaya geçilince yenile
                  // (giriş/çıkış yapılmış olabilir)
                  if (_selectedIndex == 4 && index == 0) {
                    _homeKey.currentState?.refreshAfterLogin();
                  }
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