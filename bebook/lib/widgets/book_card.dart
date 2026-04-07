import 'package:flutter/material.dart';
import '../../main.dart' hide ApiService;
import '../../services/api_service.dart';
import '../features/edit_book_screen.dart';

// Book sınıfı model olarak burada tanımlı kalsın
class Book {
  final int bookId;
  final int userId;
  final String title;
  final String price;
  final String description;
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

// Global favori listesi
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
  void initState() {
    super.initState();
    print("Karttaki Kitap Yazarı: ${widget.book.author}");
    _isFavorite =
        favoriteBooks.any((item) => item.bookId == widget.book.bookId);
  }

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
              // 📘 Kitap Resmi Bölümü
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    widget.book.imageUrl != null &&
                            widget.book.imageUrl!.isNotEmpty
                        ? widget.book.imageUrl!
                        : "https://via.placeholder.com/150",
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // 🔥 Resim yüklenirken gösterilecek yükleme göstergesi
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    // 🔥 Resim hatalıysa gösterilecek alan
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 4),
                            Text("Resim Yok",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
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
                      widget.book.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      (widget.book.author != null &&
                              widget.book.author!.isNotEmpty)
                          ? widget.book.author!
                          : "Yazar Belirtilmemiş",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                              fontSize: 15),
                        ),
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.book.university ?? "BEÜ",
                              style: const TextStyle(
                                  color: primaryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
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
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 35),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text("Satın Al",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
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

                if (_isFavorite) {
                  favoriteBooks.add(widget.book);
                } else {
                  favoriteBooks
                      .removeWhere((item) => item.bookId == widget.book.bookId);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4)
                  ],
                ),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
