import 'package:flutter/material.dart';
import '../../main.dart' hide ApiService;

// Define the Book class
class Book {
  final int bookId;
  final int userId;
  final String title;
  final String price;
  final String description;

  // opsiyonel alanlar
  final String? author;
  final String? imageUrl;
  final String? university;

  Book({
    required this.bookId,
    required this.userId,
    required this.title,
    this.author,
    required this.price,
    this.imageUrl,
    this.university,
    required this.description,
  });
}

// Define the global favoriteBooks list
List<Book> favoriteBooks = [];

class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onUpdated;

  const BookCard({
    super.key,
    required this.book,
    this.onUpdated,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📘 Kitap Resmi
              Expanded(
                child: Image.network(
                  widget.book.imageUrl?.isNotEmpty == true
                      ? widget.book.imageUrl!
                      : "https://via.placeholder.com/150",
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    );
                  },
                ),
              ),

              // 📘 Kitap Bilgileri
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.book.author ?? "Bilinmeyen yazar",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${widget.book.price} TL",
                          style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.book.university ?? "-",
                            style: const TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        makePayment(
                            context,
                            widget.book.userId,
                            widget.book.bookId,
                            double.tryParse(widget.book.price) ?? 0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 35),
                      ),
                      child: const Text("Satın Al"),
                    ),
                    const SizedBox(height: 6),
                    
                  ],
                ),
              ),
            ],
          ),

          // ❤️ FAVORİ BUTONU
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });

                final currentBook = widget.book;

                if (_isFavorite) {
                  favoriteBooks.add(currentBook);
                } else {
                  favoriteBooks.removeWhere(
                    (item) => item.bookId == widget.book.bookId,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
