# 🔄 Merge Planı - IP Adresleri Korunacak

## ✅ Tamamlanan
- [x] backend/main.py - Birleştirildi, IP korundu

## 📋 Yapılacaklar

### Kritik Dosyalar (IP Adresleri İçeren)
1. lib/services/api_service.dart - baseUrl: "http://192.168.1.30:8000" KORUNACAK
2. lib/main.dart - baseUrl: "http://192.168.1.30:8000" KORUNACAK  
3. lib/features/profile/login_screen.dart - apiUrl KORUNACAK

### Diğer Dosyalar (Güvenli Birleştirme)
4. lib/features/home/home_screen.dart
5. lib/features/post_ad/add_product_screen.dart
6. lib/features/profile/profile_screen.dart
7. lib/features/profile/signup_screen.dart
8. lib/widgets/book_card.dart
9. pubspec.yaml

### Yeni Dosyalar (Arkadaşınızdan)
- lib/features/payment/payment_web_view.dart
- lib/features/cart/cart_screen.dart
- lib/features/post_ad/edit_book_screen.dart

## 🎯 Strateji
1. Backend'i commit et
2. Flutter dosyalarını tek tek birleştir
3. Her adımda IP adreslerini kontrol et
4. Test et
