import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class ApiService {
  static const String baseUrl = "http://192.168.1.30:8000";
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


  // Kitapları Getir (Ana Sayfa İçin)
  static Future<List<dynamic>> fetchBooks() async {
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
    } else {
      throw Exception("Kitaplar yüklenemedi");
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
        print("Favori Toggle Hatası: ${response.body}");
        return {"status": "error", "message": "İşlem başarısız"};
      }
    } catch (e) {
      print("Favori Toggle Bağlantı Hatası: $e");
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
      print("Favoriler Getirme Hatası: $e");
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
      print("Favori Kontrol Hatası: $e");
      return false;
    }
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

  // Yeni Kitap İlanı Yayınla
  static Future<bool> uploadBook({
    required String title,
    required String author,
    required String category,
    required double price,
    String? publisher,
    required String description,
    required String sellerEmail,
    Uint8List? imageBytes, // RESMİN KENDİSİ
    String? imageName,
  }) async {
    try {
      var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/books"));
      
      request.fields['title'] = title;
      request.fields['author'] = author;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['publisher'] = publisher ?? "";
      request.fields['description'] = description;
      request.fields['seller_email'] = sellerEmail;

      // Resim varsa pakete ekle
      if (imageBytes != null && imageName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
        ));
      }

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Yükleme Hatası: $e");
      return false;
    }
  }
}