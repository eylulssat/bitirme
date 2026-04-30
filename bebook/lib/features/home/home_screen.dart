import 'package:flutter/material.dart';
import '../../widgets/book_card.dart';
import '../../services/api_service.dart';
import 'book_detail_screen.dart';
import 'package:bebook/models/book_model.dart';
class HomeScreen extends StatefulWidget {
  // --- EKSİK OLAN KISIM BURASI ---
  final int myId;
  final String myName;

  const HomeScreen({
    super.key,
    required this.myId,
    required this.myName,
  });
  // -------------------------------

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> allBooks = []; // Veritabanından gelen tüm kitaplar
  List<dynamic> filteredBooks = []; // Arama sonucuna göre filtrelenenler
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  // Kitapları API'den çekip listelere atıyoruz
  void _loadBooks() async {
    try {
      final books = await ApiService.fetchBooks();
      // EĞER SAYFA KAPANDIYSA SETSTATE YAPMA
      if (!mounted) return;

      setState(() {
        allBooks = books;
        filteredBooks = books;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // Arama işlemini yapan fonksiyon
  void _filterBooks(String query) {
    setState(() {
      filteredBooks = allBooks.where((book) {
        final title = (book['title'] ?? "").toString().toLowerCase();
        final author = (book['author'] ?? "").toString().toLowerCase();
        final searchLower = query.toLowerCase();

        // Hem başlıkta hem de yazarda arama yapar
        return title.contains(searchLower) || author.contains(searchLower);
      }).toList();
    });
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
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => _filterBooks(value),
              decoration: InputDecoration(
                hintText: "Kitap veya yazar ara...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // Kitap Listesi Alanı
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBooks.isEmpty
                    ? _buildEmptyState() // Kitap bulunamadığında burası çalışır
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          final bookData = filteredBooks[index];
                          final currentBook = Book(
                            // BURAYI DÜZELTTİK: 'id' yerine 'book_id'
                            bookId: bookData['book_id'] ?? 0,
                            userId: bookData['user_id'] ?? 0,
                            title: bookData['title'] ?? "Başlıksız",
                            author: bookData['author'] ?? "Yazar Belirtilmemiş",
                            price: bookData['price']?.toString() ?? "0",
                            // Backend'de image_path olarak tutuyorsun, kontrol et:
                            imageUrl: bookData['image_path'] ??
                                "https://via.placeholder.com/150",
                            university: bookData['university'] ?? "BEÜ",
                            description: bookData['description'] ?? "",
                          );

                          return InkWell(
                            onTap: () {
                              // Artık currentBook.bookId gerçek veritabanı ID'sini (örn: 76) taşıyor!
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailScreen(
                                    book: currentBook,
                                    myId: widget.myId,
                                    myName: widget.myName,
                                  ),
                                ),
                              );
                            },
                            child: BookCard(
                              book: currentBook,
                              myId: widget.myId, // ✅ DOĞRU
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Kitap bulunamadığında ekrana gelecek görsel yapı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "Aradığınız kriterde bir kitap\nveya yazar bulunamadı.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Lütfen farklı anahtar kelimeler deneyin.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
