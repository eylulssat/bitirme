import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.29:8000";

  // 📘 Kitapları Getir
  static Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/books"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Kitaplar yüklenemedi");
      }
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
      return [];
    }
  }

  // 💳 Ödeme İşlemini Başlat
  static Future<Map<String, dynamic>> initiatePayment({
    required int userId,
    required int bookId,
    required double price,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/create-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "book_id": bookId,
          "price": price,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "error", "message": "Sunucu hatası: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("Ödeme API Hatası: $e");
      return {"status": "error", "message": "Bağlantı hatası"};
    }
  }

  // ✉️ İletişim Formu Mesajını Gönder (Kırmızı yanan kısım burasıydı, eklendi)
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
      // Backend 200 veya 201 döndüğünde başarılı kabul ediyoruz
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("İletişim Hatası: $e");
      return false;
    }
  }

  // ⭐ Favoriye Ekle/Çıkar
  static Future<void> toggleFavorite(int userId, int bookId) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/favorites"),
        body: jsonEncode({"user_id": userId, "book_id": bookId}),
        headers: {"Content-Type": "application/json"},
      );
    } catch (e) {
      debugPrint("Favori hatası: $e");
    }
  }

  // 📝 Kitap Güncelle
  static Future<Map<String, dynamic>> updateBook(int bookId, int userId,
      String title, double price, String description) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update-book'),
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
    } catch (e) {
      debugPrint("Güncelleme Hatası: $e");
      return {"status": "error"};
    }
  }

  // 🗑️ Kitap Sil
  static Future<Map<String, dynamic>> deleteBook(int bookId, int userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/delete-book/$bookId/$userId'));
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Silme Hatası: $e");
      return {"status": "error"};
    }
  }

  // 📂 Kullanıcının Kendi İlanlarını Getir
  static Future<List<dynamic>> getMyBooks(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/my-books/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("İlanlar alınamadı");
    }
  }

  // 📤 Yeni Kitap İlanı Yayınla
  static Future<bool> uploadBook({
    required int userId,
    required String title,
    required String author,
    required String category,
    required double price,
    required String description,
    required String sellerEmail,
    String imagePath = "",
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/books"));
      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      request.fields['author'] = author;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['description'] = description;
      request.fields['seller_email'] = sellerEmail;

      if (imagePath.isNotEmpty) {
        File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath('file', imagePath));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Yükleme Hatası: $e");
      return false;
    }
  }
}