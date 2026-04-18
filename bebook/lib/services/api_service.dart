import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  // LOKAL IP ADRESİNİZ - DEĞİŞTİRİLMEDİ
  static const String baseUrl = "http://192.168.1.30:8000";

  // --- Giriş Yap ---
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      debugPrint("Giriş Hatası: $e");
      return null;
    }
  }

  // --- Kayıt Ol ---
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

  // --- Kitapları Getir ---
  static Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/books"));
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
      return [];
    }
  }

  // --- Ödeme İşlemini Başlat (Merve'nin eklediği) ---
  static Future<Map<String, dynamic>> initiatePayment({
    required int userId,
    required int bookId,
    required double price,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/create-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "book_id": bookId, "price": price}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Bağlantı hatası"};
    }
  }

  // --- Toplu Ödeme (Sepet İçin) ---
  static Future<Map<String, dynamic>> makeBulkPayment({
    required int userId,
    required List<int> bookIds,
    required double totalPrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/bulk-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "book_ids": bookIds,
          "total_price": totalPrice,
        }),
      );
      return response.statusCode == 200 
          ? jsonDecode(response.body) 
          : {"status": "error", "message": "Ödeme hatası"};
    } catch (e) {
      return {"status": "error", "message": "Bağlantı hatası"};
    }
  }

  // --- Kitap İlanı Yayınla (RESİM DESTEKLİ - Multipart, Web+Mobile uyumlu) ---
  static Future<bool> uploadBook({
    required String title,
    required String author,
    required String category,
    required double price,
    required String description,
    required String sellerEmail,
    XFile? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/books"));
      request.fields['title'] = title;
      request.fields['author'] = author;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['description'] = description;
      request.fields['seller_email'] = sellerEmail;

      if (imageFile != null) {
        // Web ve mobil için XFile.readAsBytes() kullan
        final bytes = await imageFile.readAsBytes();
        final fileName = imageFile.name.isNotEmpty ? imageFile.name : 'image.jpg';
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      }

      var streamedResponse = await request.send();
      return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;
    } catch (e) {
      debugPrint("Yükleme Hatası: $e");
      return false;
    }
  }

  // --- Diğer Yardımcı Metotlar ---
  static Future<List<dynamic>> getMyBooks(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/my-books/$userId'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<Map<String, dynamic>?> toggleFavorite(int userId, int bookId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/favorites/toggle"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "book_id": bookId}),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) { 
      debugPrint("Favori hatası: $e"); 
      return null;
    }
  }

  static Future<List<dynamic>> getFavorites(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/favorites/$userId'));
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      debugPrint("Favoriler yükleme hatası: $e");
      return [];
    }
  }

  static Future<bool> checkFavorite(int userId, int bookId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/check/$userId/$bookId')
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorite'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("Favori kontrol hatası: $e");
      return false;
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
    } catch (e) { return false; }
  }
  // 🔍 Sipariş Durumunu Sorgula (CartScreen için gerekli)
  static Future<Map<String, dynamic>> getOrderStatus(int? orderId) async {
    if (orderId == null) return {'status': 'FAILURE'};
    try {
      final response = await http.get(Uri.parse('$baseUrl/order-status/$orderId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'FAILURE'};
      }
    } catch (e) {
      debugPrint("Sorgulama Hatası: $e");
      return {'status': 'ERROR'};
    }
  }

  // 📝 Kitap Güncelle (EditBookScreen için gerekli)
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
  // 🗑️ Kitap Sil (BookCard için gerekli)
  static Future<Map<String, dynamic>> deleteBook(int bookId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-book/$bookId/$userId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "error", "message": "Silme işlemi başarısız."};
      }
    } catch (e) {
      debugPrint("Silme Hatası: $e");
      return {"status": "error", "message": "Bağlantı hatası."};
    }
  }
} // Sınıfın sonu