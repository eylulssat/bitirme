class Book {
  final int bookId;
  final int userId;
  final String title;
  final String author;
  final String price;
  final String imageUrl;
  final String university;
  final String description;

  Book({
    required this.bookId,
    required this.userId,
    required this.title,
    required this.author,
    required this.price,
    required this.imageUrl,
    required this.university,
    required this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookId: json['book_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      price: json['price']?.toString() ?? '0',
      imageUrl: json['image_path'] ?? '',
      university: json['university'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

// Favorileri tutacak global bir liste (Şimdilik test için)
List<Book> favoriteBooks = [];