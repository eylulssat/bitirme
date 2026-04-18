import 'package:flutter/material.dart';
import '../../main.dart' hide ApiService;
import '../models/book_model.dart';
import '../features/home/book_detail_screen.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isLoadingFavorite = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndCheckFavorite();
  }

  Future<void> _loadUserAndCheckFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId != null) {
        setState(() => _currentUserId = userId);
        
        // Favori durumunu kontrol et
        final isFav = await ApiService.checkFavorite(userId, widget.book.id);
        setState(() {
          _isFavorite = isFav;
          _isLoadingFavorite = false;
        });
      } else {
        setState(() => _isLoadingFavorite = false);
      }
    } catch (e) {
      print("Kullanıcı bilgisi yükleme hatası: $e");
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Favorilere eklemek için giriş yapmalısınız"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await ApiService.toggleFavorite(_currentUserId!, widget.book.id);
    
    if (result['status'] == 'added') {
      setState(() => _isFavorite = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Favorilere eklendi ❤️"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } else if (result['status'] == 'removed') {
      setState(() => _isFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Favorilerden çıkarıldı"),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return GestureDetector(
      onTap: () {
        // Detay sayfasına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(book: widget.book),
          ),
        );
      },
      child: Container(
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Hero(
                      tag: 'book_${widget.book.id}',
                      child: Image.network(
                        widget.book.imagePath.isNotEmpty == true
                            ? widget.book.imagePath
                            : "https://via.placeholder.com/150",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print("Görsel yükleme hatası: $error");
                          print("URL: ${widget.book.imagePath}");
                          return const Center(
                            child: Icon(Icons.image, size: 40, color: Colors.grey),
                          );
                        },
                      ),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.book.author,
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
                                fontSize: 16),
                          ),
                          // 🎓 Okul Bilgisi Kutucuğu
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.book.university, 
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
                              widget.book.id, 
                              widget.book.price 
                          );
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
                onTap: _toggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: _isLoadingFavorite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}