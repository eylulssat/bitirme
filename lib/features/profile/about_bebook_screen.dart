import 'package:flutter/material.dart';

class AboutBebookScreen extends StatelessWidget {
  const AboutBebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color boxColor = Color(0xFFE5E1FF); 
    const Color titleColor = Color(0xFF1E0E3E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bebook Hakkında", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center( 
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700), 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    const Text("HOŞGELDİN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: titleColor)),
                    const SizedBox(height: 15),
                    const Text(
                      "Kitapları görmek ve satın almak için önce hesabın yoksa üye olmalısın, hesabın varsa giriş yapmalısın.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 40),

                    _buildInfoCard("BEBOOK NEDİR?", "Öğrencilerin okul için alıp kullanmadıkları ders kitaplarını siteye fotoğrafları ile yükleyip haberleşerek birbirlerine elden sattıkları bir e-ticaret sitesidir.", boxColor),
                    _buildInfoCard("BEBOOK KATKILARI", "• İthal Kitap Talebini Azaltma\n• Öğrencilere Ekonomik Fayda\n• Kaynakların Verimli Kullanımı\n• Döngüsel Ekonomi\n• Eğitime Katkı", boxColor),
                    _buildInfoCard("BEBOOK HEDEF KİTLE", "Bülent Ecevit Üniversitesinde okuyan, ders kitaplarını veya notlarını elden çıkartmak ya da almak isteyen tüm öğrenciler için tasarlanmıştır.", boxColor),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2), 
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Text("BEBOOK NASIL KULLANILIR?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                          SizedBox(height: 20),
                          _BulletPoint("Üye değilseniz ilk olarak kendinize hesap oluşturun"),
                          _BulletPoint("Hesabınız oluşturulduktan sonra giriş yap butonundan giriş yapınız"),
                          _BulletPoint("Giriş yaptığınızda anasayfanızdaki kitabın üzerine tıklayıp satıcıya ulaşabilir ve kitabı elden alabilirsiniz"),
                          _BulletPoint("Ürün yükle butonundan kendi kitabınızı satılığa çıkarabilirsiniz"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Text(content, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }
}