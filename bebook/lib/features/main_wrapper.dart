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

  // 🔥 1. ADIM: ProfileScreen'in içindeki fonksiyonlara erişmek için bir Key tanımlıyoruz.
  // ProfileScreen'in State sınıfının public olması (adı başında _ olmaması) gerekebilir.
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF); 

    final List<Widget> _pages = [
      const HomeScreen(),                 // 0: Keşfet
      const Center(child: Text("Arama")), // 1: Ara
      const SizedBox(),                   // 2: Sat
      CartScreen(onDiscoverPressed: () {  // 3: Sepetim
        setState(() {
          _selectedIndex = 0;
        });
      }),
      // 🔥 2. ADIM: Key'i buraya bağlıyoruz
      ProfileScreen(key: _profileKey),    // 4: Profil
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
              onTabChange: (index) async {
                if (index == 2) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddProductScreen(),
                    ),
                  );

                  if (result == true) {
                    // 🔥 3. ADIM: Profil sayfasındaki yenileme fonksiyonunu tetikliyoruz
                    // ProfileScreen içinde ilanları çeken fonksiyonun adının 'fetchUserBooks' olduğunu varsayıyorum.
                    _profileKey.currentState?.fetchMyBooks(); 

                    setState(() {
                      _selectedIndex = 4; // Profile'a git
                    });
                  }
                } else {
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