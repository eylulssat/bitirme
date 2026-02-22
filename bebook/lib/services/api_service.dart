import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Bilgisayarının yerel IP adresi (Örn: 192.168.1.x)
  static const String baseUrl = "http://YOUR_IP:8000";

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
}