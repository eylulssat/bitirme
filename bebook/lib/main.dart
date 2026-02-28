import 'package:flutter/material.dart';
import 'features/main_wrapper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bebook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const MainWrapper(),
    );
  }
}

// ------------------- API SERVİSİ -------------------
class ApiService {
  // Yeni IP adresin: 192.168.67.99
  final String baseUrl = "http://192.168.67.99:8000"; 

  Future<Map<String, dynamic>> createPayment(
      int userId, int bookId, double price) async {
    final url = Uri.parse('$baseUrl/create-payment');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "book_id": bookId,
          "price": price,
        }),
      ); // 10 saniye bekleme süresi

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Sunucuya ulaştık ama sunucu hata (404, 500 vb.) döndürdü
        throw Exception("Sunucu Hatası: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      // Bağlantı hatası (IP yanlışlığı, kapalı server vb.) burada fırlatılır
      rethrow;
    }
  }
}

// ------------------- ÖDEME AKIŞI -------------------
void makePayment(
    BuildContext context, int userId, int bookId, double price) async {
  final api = ApiService();

  try {
    debugPrint("--- İstek Gönderiliyor: $userId, $bookId, $price ---");
    
    final paymentResponse = await api.createPayment(userId, bookId, price);
    
    debugPrint("--- Sunucu Yanıtı: $paymentResponse ---");

    if (paymentResponse.containsKey('paymentPageUrl')) {
      final checkoutUrl = paymentResponse['paymentPageUrl'];
      
      final Uri url = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw "Ödeme sayfası açılamadı (URL geçersiz: $checkoutUrl)";
      }
    } else {
      throw "Sunucu 'paymentPageUrl' döndürmedi. Yanıt: $paymentResponse";
    }
    
  } catch (e, stacktrace) {
    // BURASI TERMİNALDE DETAYLI HATA GÖRMENİ SAĞLAR
    debugPrint("========== HATA DETAYI ==========");
    debugPrint("Hata: $e");
    debugPrint("Stacktrace: $stacktrace");
    debugPrint("================================");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ödeme Hatası: $e"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}