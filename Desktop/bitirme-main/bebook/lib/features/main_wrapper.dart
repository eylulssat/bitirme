import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bebook/features/cart/cart_screen.dart';
import 'package:bebook/features/home/premium_home_screen.dart';
import 'package:bebook/features/post_ad/add_product_screen.dart';
import 'package:bebook/features/profile/profile_screen.dart';
import 'package:bebook/features/chat/chat_list_screen.dart';

// Global notifier'lar (diğer dosyalardan erişilebilir)
final ValueNotifier<bool> logoutNotifier = ValueNotifier(false);
final ValueNotifier<int> favoriteChangeNotifier = ValueNotifier(0);

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => MainWrapperState();
}

class MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  int? _currentUserId;
  String? _currentUserEmail;

  final GlobalKey<ProfileScreenState> _profileKey =
      GlobalKey<ProfileScreenState>();
  final GlobalKey<PremiumHomeScreenState> _homeKey =
      GlobalKey<PremiumHomeScreenState>();

  @override
  void initState() {
    super.initState();
    _loadUser();
    logoutNotifier.addListener(_onLogout);
  }

  @override
  void dispose() {
    logoutNotifier.removeListener(_onLogout);
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
      _currentUserEmail = prefs.getString('user_email');
    });
  }

  void _onLogout() {
    if (logoutNotifier.value) {
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0 - Ana Sayfa
          PremiumHomeScreen(key: _homeKey),

          // 1 - Mesajlar
          ChatListScreen(
            myId: _currentUserId ?? 0,
          ),

          // 2 - Sat (placeholder, navigator ile açılır)
          const SizedBox(),

          // 3 - Sepet
          CartScreen(
            onDiscoverPressed: () {
              setState(() => _selectedIndex = 0);
            },
          ),

          // 4 - Profil
          ProfileScreen(key: _profileKey),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
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
                GButton(icon: Icons.chat_bubble_outline_rounded, text: 'Mesajlar'),
                GButton(icon: Icons.add_circle_outline, text: 'Sat'),
                GButton(icon: Icons.shopping_cart_outlined, text: 'Sepetim'),
                GButton(icon: Icons.person_outline, text: 'Profil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) async {
                if (index == 2) {
                  // Sat butonuna basınca AddProductScreen aç
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getInt('user_id');
                  final userEmail = prefs.getString('user_email');

                  if (!mounted) return;
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(
                        userId: userId,
                        userEmail: userEmail,
                      ),
                    ),
                  );
                  if (result == true) {
                    _homeKey.currentState?.refreshAfterLogin();
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
