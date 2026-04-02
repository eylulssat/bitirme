import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Bilgisayarının yerel IP adresi (Örn: 192.168.1.x)
  static const String baseUrl = "http://192.168.67.86:8000";

  // Kitapları Getir (Ana Sayfa İçin)
  static Future<List<dynamic>> fetchBooks() async {
    final response = await http.get(Uri.parse("$baseUrl/books"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Kitaplar yüklenemedi");
    }
  }

  // Favoriye Ekle/Çıkar
  static Future<void> toggleFavorite(int userId, int bookId) async {
    await http.post(
      Uri.parse("$baseUrl/favorites"),
      body: jsonEncode({"user_id": userId, "book_id": bookId}),
      headers: {"Content-Type": "application/json"},
    );
  }

  static Future<Map<String, dynamic>> updateBook(int bookId, int userId,
      String title, double price, String description) async {
    final url = Uri.parse('$baseUrl/update-book');

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "book_id": bookId,
        "user_id": userId,
        "title": title,
        "price": price,
        "description": description,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteBook(int bookId, int userId) async {
    final url = Uri.parse('$baseUrl/delete-book/$bookId/$userId');

    final response = await http.delete(url);

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getMyBooks(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/my-books/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("İlanlar alınamadı");
    }
  }
}
