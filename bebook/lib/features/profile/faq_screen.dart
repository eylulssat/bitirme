import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Senin o meşhur "hoş mor" tonun
    const Color primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      // Arka planı çok hafif bir gri yaparak beyaz kartların öne çıkmasını sağladık
      backgroundColor: const Color(0xFFF9FAFF),
      appBar: AppBar(
        title: const Text(
          "Sıkça Sorulan Sorular",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5, // Çok hafif bir derinlik çizgisi
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: ListView(
        // BouncingScrollPhysics: Sayfayı kaydırırken o yumuşak "yay" efektini verir (iOS stili)
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildFAQItem(
            "💳", // İkon ekledik
            "Ödemeyi nasıl yapabilirim?",
            "BEBOOK, iyzico güvenli ödeme altyapısını kullanır. Kitap satın alırken kart bilgilerinizle iyzico güvencesinde ödeme yapabilir, işleminiz tamamlanana kadar paranızı koruma altında tutabilirsiniz.",
            primaryColor,
          ),
          _buildFAQItem(
            "📖",
            "Kitap anlatıldığı gibi gelmezse?",
            "Eğer teslim aldığınız kitap ilan açıklamasındaki gibi değilse, 'Destek' kısmından bizimle iletişime geçebilirsiniz. Gerekli incelemelerden sonra iyzico üzerinden iade süreciniz başlatılacaktır.",
            primaryColor,
          ),
          _buildFAQItem(
            "✨",
            "Uygulamayı kullanmak ücretli mi?",
            "Hayır, BEBOOK tamamen ücretsiz bir platformdur. İlan vermek, kitapları incelemek ve üye olmak için herhangi bir ücret ödemezsiniz.",
            primaryColor,
          ),
          _buildFAQItem(
            "🔐",
            "Şifremi unuttum, ne yapmalıyım?",
            "Giriş ekranındaki 'Şifremi Unuttum' butonuna tıklayarak sisteme kayıtlı e-posta adresinizi giriniz. E-postanıza gönderilen 6 haneli doğrulama kodunu uygulamaya girerek yeni şifrenizi güvenle oluşturabilirsiniz.",
            primaryColor,
          ),
          _buildFAQItem(
            "⏳",
            "İlanım ne kadar süre yayında kalır?",
            "İlanınız, siz manuel olarak silene veya kitap satılana kadar yayında kalmaya devam eder.",
            primaryColor,
          ),
          _buildFAQItem(
            "💬",
            "Mesaj ikonları (tikler) ne anlama geliyor?",
            "• Tek Beyaz Tik: Mesajınız gönderildi.\n• Çift Beyaz Tik: Mesajınız alıcıya iletildi.\n• Çift Yeşil Tik: Mesajınız alıcı tarafından okundu.",
            primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            "Başka bir sorun mu var? Destek ekibine ulaşın.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(
      String icon, String question, String answer, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Daha oval, daha modern
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06), // Morun çok hafif bir yansıması
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        // ExpansionTile'ın içindeki o varsayılan çizgileri tamamen yok eder
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: color,
          collapsedIconColor: Colors.grey.shade400,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading:
              Text(icon, style: const TextStyle(fontSize: 20)), // Başta ikon
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 20, top: 4),
              child: Text(
                answer,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.6, // Satır aralığını açtık, okuması kolaylaştı
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
