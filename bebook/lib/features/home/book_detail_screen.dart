import 'package:flutter/material.dart';
import '../../widgets/book_card.dart'; 
import '../../models/chat_detail_screen.dart';
import '../../services/api_service.dart'; // ApiService'i eklemeyi unutma!
import 'package:bebook/models/book_model.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  final int myId;
  final String myName;

  const BookDetailScreen({
    super.key, 
    required this.book, 
    required this.myId, 
    required this.myName
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(book.title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kitap Görseli Alanı (Mevcut kodun...)
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Image.network(
                  book.imageUrl ?? "",
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 100),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(book.author ?? "Yazar Belirtilmemiş", style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  const SizedBox(height: 15),
                  Text("${book.price} TL", style: const TextStyle(fontSize: 24, color: primaryColor, fontWeight: FontWeight.bold)),
                  const Divider(height: 40, thickness: 1),
                  const Text("Açıklama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(book.description.isEmpty ? "Açıklama belirtilmemiş." : book.description,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 120), // Butonlar için boşluk
                ],
              ),
            ),
          ],
        ),
      ),
      // --- DÜZELTİLEN VE BUTONLARIN EKLENDİĞİ KISIM ---
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row( // Row kullanarak butonları yan yana dizdik
            children: [
              // 1. BUTON: Satıcıya Mesaj At
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          receiverId: book.userId,
                          receiverName: (book.author != null && book.author != "Yazar Belirtilmemiş") ? book.author! : "Satıcı",
                          bookTitle: book.title,
                          bookId: book.bookId,
                          myId: myId,
                          myName: myName,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              // 2. BUTON: Sepete Ekle (ASIL EKSİK OLAN BUYDU)
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // ApiService'deki o meşhur fonksiyonu çağırıyoruz
                    bool basarili = await ApiService.addToCart(myId, book.bookId);

                    if (basarili) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Ürün başarıyla sepete eklendi!"),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Hata: Sepete eklenemedi!"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  label: const Text("Sepete Ekle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}