import 'package:flutter/material.dart';
import 'features/main_wrapper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'features/payment/payment_web_view.dart';

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
  // YANLIŞ: final String baseUrl = "http://192.168.1.29.8000"; (Nokta varsa hata verir)
  // DOĞRU:
  final String baseUrl = "http://192.168.1.29:8000"; 

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

// ------------------- ÖDEME AKIŞI (TEK FONKSİYON) -------------------
// ------------------- ÖDEME AKIŞI (DÜZENLENMİŞ POLLING) -------------------

 // ------------------- ÖDEME AKIŞI (DÜZENLENMİŞ) -------------------
void makePayment(BuildContext context, int userId, int bookId, double price) async {
  final api = ApiService();

  try {
    debugPrint("--- İstek Gönderiliyor: $userId, $bookId, $price ---");
    final paymentResponse = await api.createPayment(userId, bookId, price);
    
    if (paymentResponse.containsKey('paymentPageUrl')) {
      final String checkoutUrl = paymentResponse['paymentPageUrl'];
      final String orderId = paymentResponse['conversationId'].toString(); 

      // ✅ 1. ADIM: WebView açılır ve KAPANANA KADAR BEKLENİR
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebView(url: checkoutUrl),
          ),
        );
      }

      if (!context.mounted) return;

      // --- POLLING BAŞLANGICI (ARTIK DOĞRU YERDE) ---
      bool isSuccess = false;

      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 3)); // biraz hızlandırdım

        final statusUrl = "${api.baseUrl}/order-status/$orderId";

        try {
          final statusResponse = await http.get(Uri.parse(statusUrl));

          if (statusResponse.statusCode == 200) {
            final statusData = jsonDecode(statusResponse.body);
            debugPrint("Backend'den Gelen Ham Veri: $statusData");

            String currentStatus = "";
            if (statusData is Map && statusData.containsKey('status')) {
              currentStatus = statusData['status'].toString();
            } else {
              currentStatus = statusData.toString();
            }

            final statusUpper = currentStatus.toUpperCase();

            if (statusUpper == "SUCCESS") {
              isSuccess = true;
              debugPrint("SUCCESS yakalandı!");
              break;
            } else if (statusUpper == "FAILED") {
              isSuccess = false;
              break;
            }

            // PENDING ise devam eder (ama artık doğru zamanda)
          }
        } catch (e) {
          debugPrint("Sorgu hatası: $e");
        }
      }

      // küçük bekleme (UI için)
      await Future.delayed(const Duration(milliseconds: 200));

      // ✅ SONUÇ
      if (isSuccess) {
        if (context.mounted) {
          _showResultDialog(context, "Başarılı", "Ödemeniz onaylandı!", Colors.green, true);
        }
      } else {
        if (context.mounted) {
          _showResultDialog(context, "Hata", "Ödeme onaylanamadı.", Colors.red, false);
        }
      }
    }
  } catch (e) {
    debugPrint("Hata: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Hata: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }
}

// ------------------- SONUÇ DİYALOĞU VE ANA SAYFAYA DÖNÜŞ -------------------
void _showResultDialog(BuildContext context, String title, String msg, Color color, bool isSuccess) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () {
            if (isSuccess) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainWrapper()),
                (route) => false,
              );
            } else {
              Navigator.pop(context);
            }
          },
          child: const Text("Tamam"),
        ),
      ],
    ),
  );
}   