import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  // Callback fonksiyonunu tanımlıyoruz
  final VoidCallback onDiscoverPressed;

  const CartScreen({super.key, required this.onDiscoverPressed});

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ... İkon ve Text kısımları aynı kalıyor ...
              const Icon(Icons.shopping_cart_outlined, size: 100, color: primaryColor),
              const SizedBox(height: 30),
              const Text("Sepetiniz henüz boş", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              // KİTAP KEŞFET BUTONU
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: onDiscoverPressed, // BURASI DEĞİŞTİ: Wrapper'daki fonksiyonu çağırıyor
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
      ),
    );
  }
}