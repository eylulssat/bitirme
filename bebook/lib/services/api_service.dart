import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = "http://192.168.1.29:8000";

  // Kitapları Getir (Ana Sayfa İçin)
  static Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/books"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Kitaplar yüklenemedi");
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return [];
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

  // Kitap Güncelle
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

  // Kitap Sil
  static Future<Map<String, dynamic>> deleteBook(int bookId, int userId) async {
    final url = Uri.parse('$baseUrl/delete-book/$bookId/$userId');
    final response = await http.delete(url);
    return jsonDecode(response.body);
  }

  // Kullanıcının Kendi İlanlarını Getir
  static Future<List<dynamic>> getMyBooks(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/my-books/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("İlanlar alınamadı");
    }
  }

  // İletişim Formu Mesajını Gönder
  static Future<bool> sendContactMessage(String fullName, String email, String message) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/contact"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullName,
          "email": email,
          "message": message,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return false;
    }
  }

  // Yeni Kitap İlanı Yayınla
  static Future<bool> uploadBook({
    required int userId, // EKLEDİK: Kitabın sahibini belirlemek için şart!
    required String title,
    required String author,
    required String category,
    required double price,
    required String description,
    required String sellerEmail,
    String imagePath = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/books"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId, // Backend bu ID'yi kullanarak veritabanına kaydeder
          "title": title,
          "author": author,
          "category": category,
          "price": price,
          "description": description,
          "seller_email": sellerEmail,
          "image_path": imagePath,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Backend Hatası (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Yükleme Hatası: $e");
      return false;
    }
  }
}