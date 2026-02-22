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

// Favorileri tutacak global bir liste (Şimdilik test için)
List<Book> favoriteBooks = [];