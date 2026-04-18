import 'package:flutter/material.dart';
import '../../widgets/book_card.dart';
import '../../models/book_model.dart'; // Modelimizi ekledik
import '../../services/api_service.dart'; // API servisimizi ekledik

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // API'den gelen karmaşık listeyi Book nesnelerine çeviren yardımcı fonksiyon
  Future<List<Book>> loadBooks() async {
    final rawData = await ApiService.fetchBooks();
    return rawData.map((json) => Book.fromJson(json)).toList();
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
          // Arama Çubuğu (Senin kodun, dokunmadık)
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

          // Kitap Listesi (FutureBuilder ile Dinamik Hale Geldi)
          Expanded(
            child: FutureBuilder<List<Book>>(
              future: loadBooks(), // Kitapları çekme fonksiyonunu çağırıyoruz
              builder: (context, snapshot) {
                // 1. Durum: Veriler yükleniyor (Dönen yuvarlak)
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                } 
                // 2. Durum: Hata oluştu
                else if (snapshot.hasError) {
                  return Center(child: Text("Hata oluştu: ${snapshot.error}"));
                } 
                // 3. Durum: Veritabanında henüz kitap yok
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Henüz satılık kitap bulunmuyor."));
                }

                // 4. Durum: Kitaplar başarıyla geldi!
                List<Book> books = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: books.length, // Veritabanındaki kitap sayısı kadar döndür
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    return BookCard(
                      book: books[index], // Ekrana gerçek kitabı yolla
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