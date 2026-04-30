import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  // Sadece senin çalışan güncel IP adresini bıraktık
  static const String baseUrl = "http://192.168.67.144:8000";

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
  // ApiService.dart içinde


  static Future<List<dynamic>> getMyBooks(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/my-books/$userId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("İlanlar alınamadı");
  }

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

    // EĞER imagePath bir dosya yoluysa (Base64 değilse) burası çalışır
    if (imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        imagePath,
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("Hata: $e");
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
  required List<int> bookIds, // Burası Liste (List<int>) olmalı
  required double totalPrice,
}) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/create-payment"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "book_id": bookIds.isNotEmpty ? bookIds.first : 0, // Listeyi burada tekile indiriyoruz
        "price": totalPrice
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"status": "error"};
    }
  } catch (e) {
    debugPrint("Hata: $e");
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
  static Future<Map<String, dynamic>> sendOtp(String email) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {"status": "error", "message": e.toString()};
  }
}
static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "error", "message": "Sunucu hatası: ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": "error", "message": "Bağlantı hatası: $e"};
    }
  }
  static Future<Map<String, dynamic>> resetPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Sunucudan hata kodu dönerse (örn: 400, 500)
        final errorBody = jsonDecode(response.body);
        return {"status": "error", "message": errorBody['message'] ?? "Sunucu hatası"};
      }
    } catch (e) {
      // İnternet yoksa veya sunucuya hiç ulaşılamıyorsa
      return {"status": "error", "message": "Bağlantı hatası: $e"};
    }
  }
  static Future<bool> uploadProfilePhoto(int userId, File imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/user/upload_profile_photo/$userId'),
  );
  
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  
  var response = await request.send();
  return response.statusCode == 200;
}
static Future<void> markMessagesAsRead(int receiverId, int senderId, int bookId) async {
  try {
    final url = Uri.parse(
      "$baseUrl/mark_messages_as_read?receiver_id=$receiverId&sender_id=$senderId&book_id=$bookId"
    );
    final response = await http.post(url);
    print("OKUNDU İŞLEMİ: ${response.statusCode} - URL: $url"); // Bunu ekle ki terminalde gör!
  } catch (e) {
    print("Okundu hatası: $e");
  }
}
// --- SEPET İŞLEMLERİ ---
// --- SEPET İŞLEMLERİ (Kırmızı yanan yer burasıydı) ---
  // --- SEPET İŞLEMLERİ ---
  static Future<List<dynamic>> getCartItems(int userId) async {
    print("API SERVICE CART USER ID: $userId");
    try {
      final String url = "$baseUrl/cart/$userId";
      print("DEBUG: Sepet isteği gönderiliyor: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("DEBUG: Backend'den gelen veri: $data");
        return data;
      } else {
        print("DEBUG: Backend hatası! Kod: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("DEBUG: Sepet Çekme Hatası (ApiService): $e");
      return [];
    }
  }
  static Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/books"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Kitaplar yüklenirken hata oluştu: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("fetchBooks Hatası: $e");
      return [];
    }
  }

  static Future<bool> addToCart(int userId, int bookId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-to-cart'), // baseUrl değişkeninin tanımlı olduğundan emin ol
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "book_id": bookId,
        }),
      );
      
      if (response.statusCode == 200) {
        return response.statusCode == 200 || response.statusCode == 201;
      }
      return false;
    } catch (e) {
      print("ApiService addToCart Hatası: $e");
      return false;
    }
  }
 // addToCart sonu
  static Future<bool> removeFromCart(int userId, int bookId) async {
  try {
    // URL: .../remove-from-cart/4/15 -> Python'daki {user_id}/{book_id} ile aynı sırada!
    final response = await http.delete(
      Uri.parse("$baseUrl/remove-from-cart/$userId/$bookId"),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
} // ApiService Class sonu - DOSYA BURADA BİTMELİ

  

  
 