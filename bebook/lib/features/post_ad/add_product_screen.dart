import 'package:flutter/material.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Kırık beyaz zemin
      appBar: AppBar(
        title: const Text("Kitap Sat", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kitabını Hızlıca Listele 📚",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "İster barkodu taratıp bilgileri otomatik getir, ister manuel doldur.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // --- AI BARKOD TAR5A BUTONU ---
            InkWell(
              onTap: () {
                // Arkadaşın buraya kamera kodunu bağlayacak
                print("Barkod tarama başlatıldı");
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4B45B2)], // Indigo geçişi
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 50),
                    SizedBox(height: 15),
                    Text(
                      "ISBN Barkodunu Tara",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("veya manuel")),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 30),

            // --- MANUEL GİRİŞ ALANLARI ---
            _buildInput(label: "Kitap Adı", icon: Icons.book_outlined),
            const SizedBox(height: 15),
            _buildInput(label: "Yazar", icon: Icons.person_outline),
            const SizedBox(height: 15),
            _buildInput(label: "Tür", icon: Icons.category_outlined),
            const SizedBox(height: 15),
            _buildInput(label: "Fiyat (TL)", icon: Icons.sell_outlined, isNumber: true),
            const SizedBox(height: 40),


// --- İLANI YAYINLA BUTONU ---
SizedBox(
  width: double.infinity,
  height: 55,
  child: ElevatedButton(
    onPressed: () {
      print("İlan yayınlanıyor...");
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
    ),
    child: const Text(
      "İlanı Yayınla",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
),
const SizedBox(height: 20), // Sayfanın en altında biraz nefes payı
          ],
        ),
      ),
    );
  }

  Widget _buildInput({required String label, required IconData icon, bool isNumber = false}) {
    return TextField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}