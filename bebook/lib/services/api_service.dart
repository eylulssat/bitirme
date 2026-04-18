import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ApiService {
  // LOKAL IP ADRESİNİZ - DEĞİŞTİRİLMEDİ
  static const String baseUrl = "http://192.168.1.30:8000";

  // ============================================================
  // KULLANICI İŞLEMLERİ
  // ============================================================

  // Giriş Yap
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

  // Kayıt Ol
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

  // ============================================================
  // KİTAP İŞLEMLERİ
  // ============================================================

  // Kitapları Getir (Ana Sayfa)
  static Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/books"));
      if (response.statusCode == 200) {
        // Backend'den gelen image_path'leri tam URL'ye çevir
        List<dynamic> books = jsonDecode(response.body);
        for (var book in books) {
          if (book['image_path'] != null && book['image_path'].toString().startsWith('/uploads/')) {
            book['image_path'] = '$baseUrl${book['image_path']}';
          }
        }
        return books;
      }
      return [];
    } catch (e) {
      debugPrint("Kitaplar Getirme Hatası: $e");
      return [];
    }
  }

  // Kullanıcının Kitaplarını Getir
  static Future<List<dynamic>> getMyBooks(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/my-books/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> books = jsonDecode(response.body);
        // Görselleri tam URL'ye çevir
        for (var book in books) {
          if (book['image_path'] != null && book['image_path'].toString().startsWith('/uploads/')) {
            book['image_path'] = '$baseUrl${book['image_path']}';
          }
        }
        return books;
      }
      return [];
    } catch (e) {
      debugPrint("İlanlar Getirme Hatası: $e");
      return [];
    }
  }

  // Kitap İlanı Yayınla (Multipart - Resim Destekli)
  static Future<bool> uploadBook({
    int? userId,
    required String title,
    required String author,
    required String category,
    required double price,
    String? publisher,
    required String description,
    required String sellerEmail,
    Uint8List? imageBytes,
    String? imageName,
    String? imagePath,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/books"));
      
      if (userId != null) request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      request.fields['author'] = author;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['publisher'] = publisher ?? "";
      request.fields['description'] = description;
      request.fields['seller_email'] = sellerEmail;

      // Resim ekleme (her iki yöntem için uyumlu)
      if (imageBytes != null && imageName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
        ));
      } else if (imagePath != null && imagePath.isNotEmpty) {
        File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath('file', imagePath));
        }
      }

      var streamedResponse = await request.send();
      return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;
    } catch (e) {
      debugPrint("Yükleme Hatası: $e");
      return false;
    }
  }

  // Kitap Güncelle
  static Future<Map<String, dynamic>> updateBook(
    int bookId,
    int userId,
    String title,
    double price,
    String description
  ) async {
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

  // Kitap Sil
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

  // ============================================================
  // ÖDEME İŞLEMLERİ
  // ============================================================

  // Tekli Ödeme Başlat
  static Future<Map<String, dynamic>?> createPayment(
    int userId,
    int bookId,
    double price
  ) async {
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
        debugPrint("Ödeme Hatası: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Ödeme Bağlantı Hatası: $e");
      return null;
    }
  }

  // Ödeme Başlatma (Alternatif isim)
  static Future<Map<String, dynamic>> initiatePayment({
    required int userId,
    required int bookId,
    required double price,
  }) async {
    final result = await createPayment(userId, bookId, price);
    return result ?? {"status": "error", "message": "Bağlantı hatası"};
  }

  // Toplu Ödeme (Sepet İçin)
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
      debugPrint("Toplu Ödeme Hatası: $e");
      return {"status": "error", "message": "Bağlantı hatası"};
    }
  }

  // Sipariş Durumunu Sorgula
  static Future<Map<String, dynamic>> getOrderStatus(int? orderId) async {
    if (orderId == null) return {'status': 'FAILURE'};
    try {
      final response = await http.get(Uri.parse('$baseUrl/order-status/$orderId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'FAILURE'};
      }
    } catch (e) {
      debugPrint("Sorgulama Hatası: $e");
      return {'status': 'ERROR'};
    }
  }

  // ============================================================
  // FAVORİLER SİSTEMİ
  // ============================================================

  // Favoriye Ekle/Çıkar
  static Future<Map<String, dynamic>> toggleFavorite(int userId, int bookId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/favorites/toggle"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "book_id": bookId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Favori Toggle Hatası: ${response.body}");
        return {"status": "error", "message": "İşlem başarısız"};
      }
    } catch (e) {
      debugPrint("Favori Toggle Bağlantı Hatası: $e");
      return {"status": "error", "message": "Bağlantı hatası"};
    }
  }

  // Favorileri Getir
  static Future<List<dynamic>> getFavorites(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/favorites/$userId"));
      
      if (response.statusCode == 200) {
        // Backend'den gelen image_path'leri tam URL'ye çevir
        List<dynamic> favorites = jsonDecode(response.body);
        for (var book in favorites) {
          if (book['image_path'] != null && book['image_path'].toString().startsWith('/uploads/')) {
            book['image_path'] = '$baseUrl${book['image_path']}';
          }
        }
        return favorites;
      } else {
        throw Exception("Favoriler yüklenemedi");
      }
    } catch (e) {
      debugPrint("Favoriler Getirme Hatası: $e");
      return [];
    }
  }

  // Favori Kontrolü
  static Future<bool> checkFavorite(int userId, int bookId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/favorites/check/$userId/$bookId")
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorite'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("Favori Kontrol Hatası: $e");
      return false;
    }
  }

  // ============================================================
  // DİĞER İŞLEMLER
  // ============================================================

  // İletişim Formu Mesajını Gönder
  static Future<bool> sendContactMessage(
    String fullName,
    String email,
    String message
  ) async {
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
}
