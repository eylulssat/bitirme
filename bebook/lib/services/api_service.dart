import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.29:8000";
  static const String baseUrl = "http://192.168.67.158:8000";
  // Giriş Yap (LOGIN)
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Giriş Hatası: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return null;
    }
  }

  // Kayıt Ol (SIGNUP)
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
      print("Kayıt Hatası: $e");
      return false;
    }
  }


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
  // Ödeme Başlat (Iyzico Formu İçin)
  static Future<Map<String, dynamic>?> createPayment(int userId, int bookId, double price) async {
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
        print("Ödeme Hatası: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Ödeme Bağlantı Hatası: $e");
      return null;
    }
  }

  // 🔍 Sipariş Durumunu Sorgula
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

  // ✉️ İletişim Formu
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

  // 📂 Kullanıcının İlanlarını Getir
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
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Backend Hatası: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return false;
    }
  }

  // 🛒 Toplu Ödeme İşlemi
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "error", "message": "Ödeme sırasında bir sorun oluştu."};
      }
    } catch (e) {
      debugPrint("Toplu Ödeme API Hatası: $e");
      return {"status": "error", "message": "Bağlantı hatası oluştu."};
    }
  }
} // Sınıfın bittiği yer artık BURASI.
  // Yeni Kitap İlanı Yayınla
  static Future<bool> uploadBook({
    required String title,
    required String author,
    required String category,
    required double price,
    String? publisher,
    required String description,
    required String sellerEmail,
    String imagePath = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/books"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "author": author,
          "category": category,
          "publisher": publisher ?? "",
          "price": price,
          "description": description,
          "seller_email": sellerEmail,
          "image_path": imagePath,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Yükleme Hatası: $e");
      return false;
    }
  }
}
