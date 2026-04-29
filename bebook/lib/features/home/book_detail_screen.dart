import 'package:flutter/material.dart';
import '../../widgets/book_card.dart'; // Book modeline erişim için
import '../../models/chat_detail_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  final int myId;
  final String myName; // Artık soru işareti (?) koymuyoruz, 'mutlaka gelecek' diyoruz.

  const BookDetailScreen({
    super.key, 
    required this.book, 
    required this.myId, 
    required this.myName // required yaparak zorunlu hale getirdik
  });
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(book.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kitap Görseli
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
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "Görsel Yok",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(book.author ?? "Yazar Belirtilmemiş",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 15),
                  Text("${book.price} TL",
                      style: const TextStyle(
                          fontSize: 24,
                          color: primaryColor,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(book.university ?? "Üniversite Bilgisi Yok",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),
                  const Text("Açıklama",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    book.description.isEmpty
                        ? "Açıklama belirtilmemiş."
                        : book.description,
                    style: const TextStyle(
                        fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      receiverId: book.userId,
                      receiverName: (book.author != null &&
                              book.author != "Yazar Belirtilmemiş")
                          ? book.author!
                          : "Satıcı",
                      bookTitle: book.title,
                      bookId: book.bookId,

                      // DÜZELTİLEN YER: "widget." kısımlarını sildik çünkü bu bir StatelessWidget
                      myId: myId,
                      myName: myName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: const Text("Satıcıya Mesaj At",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
