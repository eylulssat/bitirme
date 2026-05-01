# 📚 Bebook - İkinci El Kitap Alım Satım Uygulaması

Bebook, üniversite öğrencilerinin ikinci el kitaplarını kolayca alıp satabildiği bir Flutter + FastAPI uygulamasıdır.

---

## 🚀 Nasıl Çalıştırılır?

### Gereksinimler
- Python 3.10+
- Flutter 3.x
- PostgreSQL (pgAdmin 4)

---

### 1. Veritabanı Kurulumu

pgAdmin 4'te `bebook` adında bir veritabanı oluşturun.  
Aşağıdaki tabloların mevcut olduğundan emin olun:

```sql
-- Kullanıcılar tablosu
CREATE TABLE public.users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    university VARCHAR(255),
    department VARCHAR(255)
);

-- Kitaplar tablosu
CREATE TABLE public.books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255),
    category VARCHAR(100),
    publisher VARCHAR(255),
    price NUMERIC(10,2),
    description TEXT,
    seller_email VARCHAR(255),
    image_path TEXT,
    is_sold BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Siparişler tablosu
CREATE TABLE public.orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    book_id INTEGER,
    price NUMERIC(10,2),
    status VARCHAR(50)
);

-- Favoriler tablosu
CREATE TABLE public.favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES public.users(user_id),
    book_id INTEGER REFERENCES public.books(id),
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

### 2. Backend Kurulumu

```bash
cd bebook/backend

# Gerekli paketleri yükle
pip install fastapi uvicorn psycopg2-binary bcrypt python-multipart iyzipay

# Sunucuyu başlat
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Backend `http://192.168.1.30:8000` adresinde çalışır.  
> ⚠️ IP adresini kendi ağınıza göre `backend/main.py` ve `lib/services/api_service.dart` dosyalarında güncelleyin.

---

### 3. Flutter Kurulumu

```bash
cd bebook

# Paketleri yükle
flutter pub get

# Uygulamayı başlat (Chrome)
flutter run -d chrome

# veya Android/iOS için
flutter run
```

---

## 📁 Proje Yapısı

```
bebook/
├── backend/
│   ├── main.py          # FastAPI backend (tüm API endpoint'leri)
│   └── uploads/         # Yüklenen kitap görselleri
├── lib/
│   ├── features/
│   │   ├── home/
│   │   │   ├── home_screen.dart         # Ana sayfa
│   │   │   └── book_detail_screen.dart  # Kitap detay sayfası
│   │   ├── profile/
│   │   │   ├── login_screen.dart        # Giriş ekranı
│   │   │   ├── profile_screen.dart      # Profil sayfası
│   │   │   └── favorites_screen.dart    # Favoriler sayfası
│   │   ├── post_ad/
│   │   │   ├── add_product_screen.dart  # Kitap ekleme
│   │   │   └── edit_book_screen.dart    # Kitap düzenleme
│   │   ├── cart/
│   │   │   └── cart_screen.dart         # Sepet sayfası
│   │   └── payment/
│   │       └── payment_web_view.dart    # Ödeme sayfası
│   ├── models/
│   │   └── book_model.dart              # Book veri modeli
│   ├── services/
│   │   └── api_service.dart             # API çağrıları
│   └── widgets/
│       └── book_card.dart               # Kitap kartı widget'ı
└── pubspec.yaml
```

---

## 🔧 Yapılan Değişiklikler (Son Güncelleme)

### Backend (`main.py`)
- **Temizlendi:** Tüm duplicate (tekrarlanan) kod blokları kaldırıldı
- **Düzeltildi:** `books` tablosunda `user_id` sütunu olmadığı tespit edildi; tüm SQL sorguları `seller_email` üzerinden `users` tablosuyla JOIN yapacak şekilde güncellendi
- **Eklendi:** `FavoriteToggle` modeli ve favoriler sistemi endpoint'leri (`/favorites/toggle`, `/favorites/{user_id}`, `/favorites/check/{user_id}/{book_id}`)
- **Eklendi:** `/bulk-payment` endpoint'i (sepet ödemesi)
- **Düzeltildi:** Resim yolu (`image_path`) akıllı URL oluşturma — çift `/uploads/` sorunu giderildi
- **Korundu:** IP adresi `192.168.1.30:8000` ve veritabanı bağlantı bilgileri

### Flutter
- **`home_screen.dart`:** `StatelessWidget` → `StatefulWidget` dönüştürüldü; kitap eklenince liste **anında yenileniyor**, arama çubuğu gerçek zamanlı filtreliyor, aşağı çekerek yenileme (pull-to-refresh) eklendi
- **`book_card.dart`:** Karta tıklanınca kitap detay sayfasına gidiyor; favori butonu backend ile senkronize; `Book` sınıfı çakışması giderildi
- **`book_detail_screen.dart`:** `main.dart` bağımlılığı kaldırıldı, null safety hataları düzeltildi
- **`api_service.dart`:** `uploadBook` metodu `XFile` alacak şekilde güncellendi (web + mobil uyumlu); `getFavorites`, `checkFavorite` metodları eklendi; `toggleFavorite` return değeri eklendi
- **`add_product_screen.dart`:** `File/XFile` tip uyuşmazlığı düzeltildi; resim önizleme `MemoryImage` ile web uyumlu hale getirildi
- **`book_model.dart`:** `fromJson` hem `book_id` hem `id` alanlarını destekliyor
- **`pubspec.yaml`:** `shared_preferences` paketi eklendi

---

## 🌐 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| POST | `/signup` | Kullanıcı kaydı |
| POST | `/login` | Kullanıcı girişi |
| GET | `/books` | Tüm kitapları getir |
| POST | `/books` | Yeni kitap ekle (resimli) |
| GET | `/my-books/{user_id}` | Kullanıcının kitapları |
| PUT | `/update-book` | Kitap güncelle |
| DELETE | `/delete-book/{book_id}/{user_id}` | Kitap sil |
| POST | `/create-payment` | Tekli ödeme başlat |
| POST | `/bulk-payment` | Sepet ödemesi başlat |
| POST | `/payment-callback` | İyzico ödeme callback |
| GET | `/order-status/{order_id}` | Sipariş durumu |
| POST | `/favorites/toggle` | Favoriye ekle/çıkar |
| GET | `/favorites/{user_id}` | Favorileri getir |
| GET | `/favorites/check/{user_id}/{book_id}` | Favori kontrolü |
| POST | `/contact` | İletişim formu |

---

## 👥 Geliştirici Ekibi

- **Eylül** - [@eylulssat](https://github.com/eylulssat)
- **Nilay**
- **Merve**

---

## 📝 Notlar

- Ödeme sistemi **İyzico Sandbox** ile test modunda çalışmaktadır
- Resimler `backend/uploads/` klasörüne kaydedilir
- Uygulama aynı Wi-Fi ağında çalışan cihazlarda test edilmelidir
