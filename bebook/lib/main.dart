import 'package:flutter/material.dart';
import 'features/main_wrapper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  static const String baseUrl = "http://192.168.1.30:8000";  // LOKAL IP KORUNDU 

 
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
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Sunucu Hatası: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }
}

// ------------------- ÖDEME AKIŞI -------------------
void makePayment(BuildContext context, int userId, int bookId, double price) async {
  final api = ApiService();

  try {
    debugPrint("--- Ödeme Başlatılıyor ---");
    final paymentResponse = await api.createPayment(userId, bookId, price);
    
    // Terminalden gelen veriyi kontrol etmek için:
    debugPrint("Backend Yanıtı: $paymentResponse");
    
    // Iyzico verisi bazen doğrudan gelmez, kontrolü esnek tutuyoruz
    String? checkoutUrl = paymentResponse['paymentPageUrl'];
    String? orderId = paymentResponse['conversationId']?.toString();

    // Eğer URL varsa WebView'ı aç
    if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
      if (context.mounted) {
        debugPrint("WebView Açılıyor: $checkoutUrl");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebView(url: checkoutUrl),
          ),
        );
      }

      // WebView kapandıktan sonra (Geri tuşu veya ödeme bitişi)
      if (!context.mounted) return;

      // 2. ADIM: Polling (Durum Sorgulama)
      bool isSuccess = false;
      if (orderId != null) {
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(seconds: 2)); 

          final statusUrl = "${ApiService.baseUrl}/order-status/$orderId";
          try {
            final statusResponse = await http.get(Uri.parse(statusUrl));
            if (statusResponse.statusCode == 200) {
              final statusData = jsonDecode(statusResponse.body);
              String currentStatus = statusData['status']?.toString().toUpperCase() ?? "";

              if (currentStatus == "SUCCESS") {
                isSuccess = true;
                break;
              } else if (currentStatus == "FAILED") {
                break;
              }
            }
          } catch (e) {
            debugPrint("Sorgu hatası: $e");
          }
        }
      }

      // 3. ADIM: Sonuç Gösterimi
      if (context.mounted) {
        if (isSuccess) {
          _showResultDialog(context, "Başarılı", "Ödemeniz onaylandı!", Colors.green, true);
        } else {
          _showResultDialog(context, "Hata", "Ödeme tamamlanamadı veya iptal edildi.", Colors.red, false);
        }
      }
    } else {
      debugPrint("HATA: paymentPageUrl bulunamadı!");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ödeme linki oluşturulamadı."), backgroundColor: Colors.orange)
        );
      }
    }
  } catch (e) {
    debugPrint("Akış Hatası: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)
      );
    }
  }
}

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