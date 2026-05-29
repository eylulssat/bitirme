# 📚 BeBook — Üniversite Öğrencileri İçin İkinci El Kitap Platformu

BeBook, üniversite öğrencilerinin ikinci el ders kitaplarını kolayca alıp satabildiği, yapay zeka destekli kişiselleştirilmiş öneri sistemi içeren bir mobil/web uygulamasıdır.

---

## 🚀 Özellikler

- 📖 Kitap ilan verme ve satın alma
- 🤖 Yapay zeka destekli kişiselleştirilmiş kitap önerileri (TF-IDF + Cosine Similarity)
- 📷 ISBN barkod tarama ile otomatik kitap bilgisi doldurma
- 💬 Kullanıcılar arası anlık mesajlaşma
- ❤️ Favori kitap listesi
- 🛒 Sepet ve ödeme sistemi (İyzico entegrasyonu)
- 👤 Profil yönetimi ve fotoğraf yükleme
- 🔐 Şifre sıfırlama (OTP ile e-posta doğrulama)
- 📊 Satış geçmişi ve satın alma geçmişi

---

## 🛠️ Teknoloji Yığını

### Frontend (Mobil/Web)
- **Flutter** (Dart) — Cross-platform uygulama
- **shared_preferences** — Yerel veri saklama
- **http** — API istekleri
- **image_picker** — Fotoğraf seçme
- **google_nav_bar** — Alt navigasyon

### Backend (Ana API)
- **FastAPI** (Python) — REST API
- **PostgreSQL** — Veritabanı
- **psycopg2** — PostgreSQL bağlantısı
- **bcrypt** — Şifre hashleme
- **iyzipay** — Ödeme sistemi

### ISBN Backend
- **Flask** (Python) — ISBN tarama API
- **pyzbar** — Barkod okuma
- **OpenCV** — Görüntü işleme
- **cloudscraper** — Web scraping

### Yapay Zeka
- **scikit-learn** — TF-IDF + Cosine Similarity
- **pandas** — Veri işleme
- **numpy** — Sayısal hesaplama

---

## 📁 Proje Yapısı

```
bitirme-main/
├── bebook/                    # Flutter uygulaması
│   ├── lib/
│   │   ├── features/          # Ekranlar
│   │   │   ├── home/          # Ana sayfa
│   │   │   ├── profile/       # Profil, giriş, kayıt
│   │   │   ├── cart/          # Sepet ve ödeme
│   │   │   ├── chat/          # Mesajlaşma
│   │   │   └── post_ad/       # Kitap ekleme
│   │   ├── models/            # Veri modelleri
│   │   ├── services/          # API servisleri
│   │   └── widgets/           # Ortak widget'lar
│   └── backend/               # Ana Python backend
│       ├── main.py            # FastAPI uygulaması
│       └── recommendation_engine.py  # Yapay zeka motoru
└── isbn_backend/              # ISBN tarama backend
    └── app.py                 # Flask uygulaması
```

---

## ⚙️ Kurulum ve Çalıştırma

### Gereksinimler

- Flutter SDK (3.x)
- Python 3.11+
- PostgreSQL 14+
- pip

---

### 1. PostgreSQL Veritabanı Kurulumu

```sql
CREATE DATABASE bebook;
```

Gerekli tablolar uygulama ilk çalıştığında otomatik oluşturulur.

---

### 2. Ana Backend Kurulumu

```bash
cd bebook/backend

# Gerekli Python paketlerini yükle
pip install fastapi uvicorn psycopg2-binary bcrypt python-multipart
pip install iyzipay scikit-learn pandas numpy

# Backend'i başlat
uvicorn main:app --host 0.0.0.0 --port 8002 --reload
```

Backend çalıştıktan sonra: `http://localhost:8002`

---

### 3. ISBN Backend Kurulumu

```bash
cd isbn_backend

# Gerekli Python paketlerini yükle
pip install flask flask-cors opencv-python pyzbar requests cloudscraper beautifulsoup4

# ISBN backend'i başlat
python app.py
```

ISBN backend çalıştıktan sonra: `http://localhost:8001`

---

### 4. Flutter Uygulaması Kurulumu

```bash
cd bebook

# Flutter bağımlılıklarını yükle
flutter pub get

# Chrome'da çalıştır (web)
flutter run -d chrome

# Android'de çalıştır
flutter run -d android

# iOS'ta çalıştır
flutter run -d ios
```

---

### 5. IP Adresi Güncelleme (Mobil için)

Mobil cihazda test ederken `lib/services/api_service.dart` dosyasındaki IP adresini kendi bilgisayarınızın yerel IP adresiyle güncelleyin:

```dart
static final String baseUrl = kIsWeb
    ? "http://localhost:8002"
    : "http://192.168.x.x:8002";  // ← Kendi IP adresiniz
```

Aynı şekilde `backend/main.py` dosyasında:

```python
BASE_URL = "http://192.168.x.x:8002"  # ← Kendi IP adresiniz
```

---

## 🤖 Yapay Zeka Öneri Sistemi

BeBook, kullanıcının **üniversite bölümüne** göre kişiselleştirilmiş kitap önerileri sunar.

### Algoritma: İçerik Tabanlı Filtreleme (Content-Based Filtering)

1. **TF-IDF Vektörizasyonu** — Kullanıcı profili ve kitap özellikleri metne dönüştürülür
2. **Cosine Similarity** — Kullanıcı vektörü ile kitap vektörleri arasındaki benzerlik hesaplanır
3. **Minimum Eşik Filtresi** — %5 altı benzerlik skoru olan kitaplar gösterilmez
4. **Top-N Seçimi** — En yüksek skorlu 6 kitap önerilir

```bash
# Öneri sistemini test etmek için
cd bebook/backend
python recommendation_engine.py
```

---

## 📷 ISBN Barkod Tarama

Kitap eklerken barkod tarama özelliği ile kitap bilgileri otomatik doldurulur:

1. Google Books API
2. Open Library API
3. D&R web sitesi
4. Kitapseç web sitesi

---

## 🔑 Ortam Değişkenleri

`backend/main.py` dosyasında aşağıdaki ayarları güncelleyin:

```python
# Veritabanı bağlantısı
def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="bebook",
        user="postgres",
        password="YOUR_PASSWORD",  # ← Kendi şifreniz
        port="5432"
    )

# İyzico ödeme sistemi (sandbox)
IYZICO_OPTIONS = {
    'api_key': 'YOUR_API_KEY',
    'secret_key': 'YOUR_SECRET_KEY',
    'base_url': 'sandbox-api.iyzipay.com'
}

# Gmail SMTP (şifre sıfırlama için)
sender_email = "your_email@gmail.com"
password = "your_app_password"  # Gmail App Password
```

---

## 📱 Ekran Görüntüleri

| Ana Sayfa | Kitap Detay | Profil |
|-----------|-------------|--------|
| Kitap listesi ve öneriler | Kitap bilgileri ve satın alma | Kullanıcı bilgileri |

---

## 👥 Geliştirici

- **Nilay Günenç** — Flutter & Backend Geliştirme
- **Ülkü Günenç** — Flutter & Backend Geliştirme

---

## 📄 Lisans

Bu proje bir bitirme projesi olarak geliştirilmiştir.
