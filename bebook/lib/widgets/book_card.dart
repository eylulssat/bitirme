import 'package:flutter/material.dart';
import '../../main.dart' hide ApiService;
import '../../services/api_service.dart';
import '../features/post_ad/edit_book_screen.dart';

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

  // --- BU KISMI EKLEMEN GEREKİYOR ---
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      // Veritabanındaki 'book_id' kolonunu Flutter'daki 'bookId'ye bağlar
      bookId: json['book_id'] ?? 0, 
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      author: json['author'] ?? "Yazar Belirtilmemiş",
      price: json['price']?.toString() ?? "0", // String beklediği için toString yaptık
      imageUrl: json['image_path'], // Veritabanında image_path olarak tutuyorsun
      university: json['university'] ?? "BEÜ",
      description: json['description'] ?? '',
    );
  }
}

List<Book> favoriteBooks = [];
List<Book> cartBooks = []; 

class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onUpdated;
  final bool isMyPost;

  const BookCard({
    super.key,
    required this.book,
    this.onUpdated,
    this.isMyPost = false,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite =
        favoriteBooks.any((item) => item.bookId == widget.book.bookId);
  }

  void _deleteAd() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İlanı Sil"),
        content: const Text("Bu ilanı silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Vazgeç")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final res =
          await ApiService.deleteBook(widget.book.bookId, widget.book.userId);
      if (res['status'] == 'success') {
        widget.onUpdated?.call(); 
      }
    }
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
              offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.book.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(widget.book.author ?? "Yazar Belirtilmemiş",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${widget.book.price} TL",
                            style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(widget.book.university ?? "BEÜ",
                            style: const TextStyle(
                                color: primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (widget.isMyPost)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditBookScreen(
                                      book: {
                                        'book_id': widget.book.bookId,
                                        'user_id': widget.book.userId,
                                        'title': widget.book.title,
                                        'price': widget.book.price,
                                        'description': widget.book.description,
                                      },
                                    ),
                                  ),
                                );
                                if (result == true) widget.onUpdated?.call();
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text("Düzenle",
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _deleteAd,
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            bool isAlreadyInCart = cartBooks.any(
                                (item) => item.bookId == widget.book.bookId);

                            if (!isAlreadyInCart) {
                              cartBooks.add(widget.book);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "${widget.book.title} sepete eklendi!"),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Bu kitap zaten sepetinizde!"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 35),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Sepete Ekle", 
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (!widget.isMyPost)
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() => _isFavorite = !_isFavorite);
                  _isFavorite
                      ? favoriteBooks.add(widget.book)
                      : favoriteBooks.removeWhere(
                          (item) => item.bookId == widget.book.bookId);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle),
                  child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.grey,
                      size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
