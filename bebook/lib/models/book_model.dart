class Book {
  final int bookId;
  final int userId;
  // --- public.books tablosundan gelenler ---
  final int id;
  final String title;
  final String author;
  final String category;
  final double price;
  final String description;
  final String sellerEmail;
  final String imagePath;
  final bool isSold;
  final String createdAt;
  final String publisher;

  // --- public.users tablosundan gelenler ---
  final int userId;
  final String email;
  final String university;
  final String description;

  Book({
    required this.bookId,
    required this.userId,
  final String department;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.price,
    required this.description,
    required this.sellerEmail,
    required this.imagePath,
    required this.isSold,
    required this.createdAt,
    required this.publisher,
    required this.userId,
    required this.email,
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
    required this.department,
  });

  // Gelen JSON'ı Flutter nesnesine dönüştüren fonksiyon
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['book_id'] ?? json['id'] ?? 0,
      title: json['title'] ?? 'İsimsiz Kitap',
      author: json['author'] ?? 'Bilinmeyen Yazar',
      category: json['category'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      sellerEmail: json['seller_email'] ?? '',
      imagePath: json['image_path'] ?? '', // DB'deki sütun adıyla birebir aynı
      isSold: json['is_sold'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      publisher: json['publisher'] ?? '',
      userId: json['user_id'] ?? 0,
      email: json['email'] ?? '',
      university: json['university'] ?? 'Belirtilmemiş', // Okul bilgisi buraya oturacak
      department: json['department'] ?? '',
    );
  }
}