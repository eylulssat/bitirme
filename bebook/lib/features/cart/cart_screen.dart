import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/book_card.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback onDiscoverPressed;

  const CartScreen({super.key, required this.onDiscoverPressed});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

// 1. WidgetsBindingObserver ekleyerek uygulama hareketlerini dinliyoruz
class _CartScreenState extends State<CartScreen> with WidgetsBindingObserver {
  bool _isWaitingForPayment = false;
  int? lastOrderId; // Ödeme sürecinde miyiz kontrolü

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Gözlemciyi başlat
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Gözlemciyi temizle
    super.dispose();
  }

  // 2. Uygulama durum değişikliğini yakalayan fonksiyon
  @override
void didChangeAppLifecycleState(AppLifecycleState state) async {
  // Uygulama ön plana geldiğinde ve bir ödeme bekliyorsak
  if (state == AppLifecycleState.resumed && _isWaitingForPayment) {
    
    // 1. Backend'e ödeme durumunu sor
    final statusResult = await ApiService.getOrderStatus(lastOrderId); 

    if (statusResult['status'] == 'SUCCESS') {
      // ✅ SADECE ÖDEME BAŞARILIYSA MESAJ GÖSTER VE SEPETİ SİL
      setState(() {
        cartBooks.clear(); 
        _isWaitingForPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sipariş işleminiz tamamlandı."),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // ❌ ÖDEME BAŞARISIZSA VEYA İPTAL EDİLDİYSE
      // Hiçbir mesaj göstermiyoruz, sadece bekleme modunu kapatıyoruz
      setState(() {
        _isWaitingForPayment = false; 
      });
      
      // Not: Eğer kullanıcıya "Ödeme olmadı" demek istersen buraya SnackBar ekleyebilirsin.
      // Ama senin isteğin üzerine burayı boş (sessiz) bırakıyoruz.
    }
  }
}

  double _calculateTotal() {
    double total = 0;
    for (var book in cartBooks) {
      total += double.tryParse(book.price.toString()) ?? 0;
    }
    return total;
  }

  void _completePayment(Color primaryColor) async {
    if (cartBooks.isEmpty) return;

    List<int> ids = cartBooks.map((b) => int.parse(b.bookId.toString())).toList();
    double total = _calculateTotal();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.makeBulkPayment(
        userId: 4,
        bookIds: ids,
        totalPrice: total,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] == 'success' || result['status'] == 'None') { 
        String? paymentUrl = result['paymentPageUrl'];

        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          final Uri url = Uri.parse(paymentUrl);
          
          // DÜZENLEME: Burada temizlemiyoruz, sadece beklediğimizi işaretliyoruz
          _isWaitingForPayment = true; 
          
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          // Buradan setState(...) kaldırıldı çünkü yukarıdaki didChangeAppLifecycleState halledecek.
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${result['errorMessage'] ?? result['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Ödeme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sepetim", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: cartBooks.isEmpty ? _buildEmptyState(primaryColor) : _buildCartItems(primaryColor),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 100, color: primaryColor),
            const SizedBox(height: 30),
            const Text("Sepetiniz henüz boş", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onDiscoverPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Kitap Keşfet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems(Color primaryColor) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: cartBooks.length,
            itemBuilder: (context, index) {
              final book = cartBooks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.imageUrl ?? "https://via.placeholder.com/150",
                      width: 50, height: 70, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 40),
                    ),
                  ),
                  title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${book.price} TL", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        cartBooks.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
        _buildBottomSection(primaryColor),
      ],
    );
  }

  Widget _buildBottomSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Toplam Tutar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text("${_calculateTotal().toStringAsFixed(2)} TL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _completePayment(primaryColor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("ÖDEMEYİ TAMAMLA", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}