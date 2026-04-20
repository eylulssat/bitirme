import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  // Sadece senin çalışan güncel IP adresini bıraktık
  static const String baseUrl = "http://192.168.67.42:8000";

  // --- GİRİŞ VE KAYIT İŞLEMLERİ ---
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint("Giriş Hatası: $e");
      return null;
    }
  }

  static Future<bool> signup({
    required String email,
    required String password,
    required String university,
    required String department,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "university": university,
          "department": department,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Kayıt Hatası: $e");
      return false;
    }
  }

  // --- KİTAP İŞLEMLERİ ---
  static Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/books"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception("Kitaplar yüklenemedi");
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getMyBooks(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/my-books/$userId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("İlanlar alınamadı");
  }

  // RESİM YÜKLEME DESTEKLİ EN GÜNCEL VERSİYON
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

  static Future<Map<String, dynamic>> deleteBook(int bookId, int userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/delete-book/$bookId/$userId'));
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Silme Hatası: $e");
      return {"status": "error"};
    }
  }

  // --- ÖDEME İŞLEMLERİ ---
  static Future<Map<String, dynamic>?> createPayment(int userId, int bookId, double price) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/create-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "book_id": bookId, "price": price}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint("Ödeme Bağlantı Hatası: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> makeBulkPayment({
    required int userId,
    required List<int> bookIds,
    required double totalPrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/bulk-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "book_ids": bookIds, "total_price": totalPrice}),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : {"status": "error"};
    } catch (e) {
      debugPrint("Toplu Ödeme Hatası: $e");
      return {"status": "error"};
    }
  }

  static Future<Map<String, dynamic>> getOrderStatus(int? orderId) async {
    if (orderId == null) return {'status': 'FAILURE'};
    try {
      final response = await http.get(Uri.parse('$baseUrl/order-status/$orderId'));
      return response.statusCode == 200 ? json.decode(response.body) : {'status': 'FAILURE'};
    } catch (e) {
      return {'status': 'ERROR'};
    }
  }

  // --- DİĞER (FAVORİ, İLETİŞİM) ---
  static Future<void> toggleFavorite(int userId, int bookId) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/favorites"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "book_id": bookId}),
      );
    } catch (e) {
      debugPrint("Favori hatası: $e");
    }
  }

  static Future<bool> sendContactMessage(String fullName, String email, String message) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/contact"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"full_name": fullName, "email": email, "message": message}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("İletişim Hatası: $e");
      return false;
    }
  }
}