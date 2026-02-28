import 'package:flutter/material.dart';
import '../../main.dart'; // ✅ makePayment için eklendi

// Define the Book class
class Book {
  final String title;
  final String author;
  final String price;
  final String imageUrl;
  final String university;

  Book({
    required this.title,
    required this.author,
    required this.price,
    required this.imageUrl,
    required this.university,
  });
}

// Define the global favoriteBooks list
List<Book> favoriteBooks = [];

class BookCard extends StatefulWidget {
  final String title;
  final String author;
  final String price;
  final String imageUrl;
  final String university;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.price,
    required this.imageUrl,
    required this.university,
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
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    widget.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 📘 Kitap Bilgileri
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.author,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${widget.price} TL",
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
                            widget.university,
                            style: const TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ✅ SATIN AL BUTONU EKLENDİ
                    ElevatedButton(
                      onPressed: () {
                        makePayment(
                          context,
                          2, // ⚠️ Şimdilik sabit user_id
                          10, // ⚠️ Şimdilik sabit book_id
                          double.parse(widget.price),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize:
                            const Size(double.infinity, 35),
                      ),
                      child: const Text("Satın Al"),
                    ),
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

                final currentBook = Book(
                  title: widget.title,
                  author: widget.author,
                  price: widget.price,
                  imageUrl: widget.imageUrl,
                  university: widget.university,
                );

                if (_isFavorite) {
                  favoriteBooks.add(currentBook);
                } else {
                  favoriteBooks.removeWhere(
                      (item) => item.title == widget.title);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4)
                  ],
                ),
                child: Icon(
                  _isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                      _isFavorite ? Colors.red : Colors.grey,
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