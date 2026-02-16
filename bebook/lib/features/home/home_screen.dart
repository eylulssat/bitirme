import 'package:flutter/material.dart';
import '../../widgets/book_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Kırık beyaz zemin
      appBar: AppBar(
        title: const Text("Bebook Keşfet", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.black)),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu (Statik Görünüm)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Ders kitabı veya roman ara...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // İlan Izgarası (Grid)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Yan yana 2 kart
                childAspectRatio: 0.65, // Kartların boy/en oranı
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: 6, // Şimdilik 6 tane örnek gösterelim
              itemBuilder: (context, index) {
                return const BookCard(
                  title: "Algoritmaya Giriş (CLRS)",
                  price: "450",
                  imageUrl: "https://m.media-amazon.com/images/I/41T-iYtu95L._AC_UF1000,1000_QL80_.jpg",
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}