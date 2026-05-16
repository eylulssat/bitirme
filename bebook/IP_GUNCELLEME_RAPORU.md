# IP Adresi Güncelleme Raporu

**Tarih:** 13 Mayıs 2026  
**İşlem:** Ağ IP adresinin güncellenmesi  
**Eski IP:** `192.168.1.19:8000` (ve `192.168.1.30:8000`)  
**Yeni IP:** `10.108.206.156:8000`

---

## ✅ Güncellenen Dosyalar

### Backend (Python)
1. **`bebook/backend/main.py`**
   - Satır 90: `BASE_URL = "http://10.108.206.156:8000"`
   - Bu URL tüm resim yollarında kullanılıyor

2. **`bebook/backend/test_upload.py`**
   - Satır 12: `BASE_URL = "http://10.108.206.156:8000"`
   - Test scriptleri için

3. **`isbn_backend/app.py`**
   - Satır 261: ISBN tarayıcı backend başlangıç mesajı
   - Port: 8001 (ISBN servisi)

### Frontend (Flutter/Dart)
4. **`bebook/lib/services/api_service.dart`**
   - Satır 9: `static const String baseUrl = "http://10.108.206.156:8000"`
   - Ana API servisi - tüm backend istekleri buradan yapılıyor

5. **`bebook/lib/main.dart`**
   - Satır 27: `static const String baseUrl = "http://10.108.206.156:8000"`
   - Ödeme işlemleri için kullanılan API servisi

6. **`bebook/lib/features/profile/login_screen.dart`**
   - Satır 38: `const String apiUrl = "http://10.108.206.156:8000/login"`
   - Giriş endpoint'i

7. **`bebook/lib/features/profile/profile_screen.dart`**
   - Satır 29: `final String baseUrl = "http://10.108.206.156:8000/uploads/"`
   - Profil resimlerinin gösterilmesi için

8. **`bebook/lib/features/post_ad/add_product_screen.dart`**
   - Satır 101: `Uri.parse("http://10.108.206.156:8001/scan")`
   - ISBN tarayıcı servisi (port 8001)

### Yedek Dosyalar
9. **`.local_config_backup.txt`**
   - Güncel IP adresleri kaydedildi

---

## 🔍 Doğrulama

### Kontrol Edilen Noktalar:
- ✅ Tüm `.dart` dosyalarında eski IP kalmadı
- ✅ Tüm `.py` dosyalarında eski IP kalmadı
- ✅ Yeni IP `10.108.206.156` tüm dosyalarda doğru şekilde uygulandı
- ✅ Port numaraları korundu (8000: Backend, 8001: ISBN)
- ✅ Veritabanı şifresi korundu (`senem2003`)

---

## 📋 Sonraki Adımlar

### Backend'i Başlatmak İçin:
```bash
cd c:\Users\nilay\bitirme\bebook\backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### ISBN Backend'i Başlatmak İçin:
```bash
cd c:\Users\nilay\bitirme\isbn_backend
python app.py
```

### Flutter Uygulamasını Çalıştırmak İçin:
```bash
cd c:\Users\nilay\bitirme\bebook
flutter run
```

---

## ⚠️ Önemli Notlar

1. **Ağ Değişikliği:** Eğer tekrar farklı bir ağa bağlanırsanız (örneğin evde farklı IP), bu dosyalardaki IP adreslerini yeniden güncellemeniz gerekecek.

2. **Mobil Cihazlar:** Flutter uygulamasını mobil cihazda test ederken, cihazın bilgisayarınızla **aynı ağda** olması gerekiyor.

3. **Firewall:** Windows Firewall'un 8000 ve 8001 portlarına izin verdiğinden emin olun.

4. **Veritabanı:** PostgreSQL'in çalıştığından ve `bebook` veritabanının erişilebilir olduğundan emin olun.

---

## 📊 Güncelleme İstatistikleri

- **Toplam Güncellenen Dosya:** 9
- **Backend Dosyaları:** 3
- **Frontend Dosyaları:** 5
- **Yedek Dosyaları:** 1
- **Değiştirilen IP Adresi:** 8 farklı konumda

---

**Durum:** ✅ Tamamlandı  
**Sonuç:** Tüm IP adresleri başarıyla güncellendi. Sistem yeni ağ yapılandırmasıyla çalışmaya hazır.
