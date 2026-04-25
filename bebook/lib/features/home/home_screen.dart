import 'package:flutter/material.dart';
import '../../widgets/book_card.dart';
import '../../services/api_service.dart'; // ApiService eklendi

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Veritabanından gelecek kitapların tutulacağı liste
  late Future<List<dynamic>> _booksFuture;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında kitapları getirmesi için fonksiyonu tetikliyoruz
    _booksFuture = ApiService.fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Bebook Keşfet",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded,
                  color: Colors.black)),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Kitap, yazar veya bölüm ara...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // Kitap Listesi (Dinamik Grid)
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _booksFuture,
              builder: (context, snapshot) {
                // Veri yüklenirken dönen çember göster
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } 
                // Hata oluşursa mesaj göster
                else if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}"));
                } 
                // Veri boşsa veya gelmediyse
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Henüz hiç ilan bulunamadı."));
                }

                // Veri başarıyla geldiyse listeyi oluştur
                final books = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final bookData = books[index];
                    return BookCard(
                      book: Book(
                        bookId: bookData['id'] ?? index,
                        userId: bookData['user_id'] ?? 0,
                        title: bookData['title'] ?? "Başlıksız",
                        author: bookData['author'] ?? "Yazar Belirtilmemiş",
                        price: bookData['price']?.toString() ?? "0",
                        imageUrl: bookData['image_path'] ?? "https://via.placeholder.com/150",
                        university: bookData['university'] ?? "BEÜ",
                        description: bookData['description'] ?? "",
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}