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

      // 1. ADIM: WebView açılır ve kapanana kadar beklenir
      if (context.mounted) {
        // BURADA await KALDIRILDI: Böylece sorgulama hemen arkasından başlar.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebView(url: checkoutUrl),
          ),
        );
      }

      

      // WebView kapandıktan sonra buraya devam eder
      if (!context.mounted) return;
      
      // 2. ADIM: Sorgulama diyaloğunu göster
      /*showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Ödeme doğrulanıyor, lütfen bekleyin..."),
            ],
          ),
        ),
      );*/

      // --- POLLING (SORGULAMA) BAŞLANGICI ---
      bool isSuccess = false;
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 4));
        final statusUrl = "${api.baseUrl}/order-status/$orderId";
        
        try {
          final statusResponse = await http.get(Uri.parse(statusUrl));
          // ... döngü içindeki ilgili kısım ...
if (statusResponse.statusCode == 200) {
  final statusData = jsonDecode(statusResponse.body);
  debugPrint("Backend'den Gelen Ham Veri: $statusData"); // Terminalde ne geldiğini görelim

  // statusData bir Map mi yoksa direkt String mi kontrol edip esnek arama yapıyoruz
  String currentStatus = "";
  if (statusData is Map && statusData.containsKey('status')) {
    currentStatus = statusData['status'].toString();
  } else {
    currentStatus = statusData.toString();
  }

  // Küçük-büyük harf duyarlılığını ortadan kaldırıyoruz
  if (currentStatus.toUpperCase() == "SUCCESS") {
    isSuccess = true; 
    debugPrint("Tebrikler Merve, SUCCESS yakalandı!");
    break; 
  } else if (currentStatus.toUpperCase() == "FAILED") {
    isSuccess = false;
    break;
  }
}
        } catch (e) {
          debugPrint("Sorgu hatası (denemeye devam ediliyor): $e");
        }
      }

      // Bekleme diyaloğunu kapat
      /*if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }*/
      
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. ADIM: Sonuç diyaloğunu göster
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