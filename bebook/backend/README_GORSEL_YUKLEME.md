# 📸 Bebook - Görsel Yükleme Sistemi

## 🎯 Genel Bakış

Bebook projesinde kitap kapak görselleri şu şekilde yönetilir:

1. **Flutter** → Kullanıcı görseli seçer
2. **Backend** → Görseli `uploads/` klasörüne kaydeder
3. **Veritabanı** → Göreceli yolu (`/uploads/uuid.jpg`) saklar
4. **Flutter** → Göreceli yolu tam URL'ye çevirir ve gösterir

## 🔧 Kurulum

### Backend Gereksinimleri

```bash
pip install fastapi uvicorn python-multipart psycopg2-binary bcrypt iyzipay
```

### Backend Başlatma

```bash
cd bebook/backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Önemli:** `--host 0.0.0.0` parametresi, backend'in network üzerinden erişilebilir olmasını sağlar.

### Flutter Ayarları

`lib/services/api_service.dart` dosyasında `baseUrl`'i güncelleyin:

```dart
// Localhost için
static const String baseUrl = "http://127.0.0.1:8000";

// Network üzerinden erişim için (mobil cihazlar)
static const String baseUrl = "http://192.168.1.30:8000";  // Kendi IP'nizi yazın
```

**IP Adresinizi Öğrenmek İçin:**

Windows:
```bash
ipconfig
# "IPv4 Address" satırına bakın
```

Mac/Linux:
```bash
ifconfig
# veya
ip addr show
```

## 📁 Dosya Yapısı

```
bebook/backend/
├── main.py                          # Ana backend dosyası
├── uploads/                         # Yüklenen görseller (otomatik oluşur)
│   ├── 123e4567-e89b-12d3-a456.jpg
│   ├── 987f6543-e21c-34d5-b678.png
│   └── ...
├── test_upload.py                   # Test script'i
├── fix_image_urls.sql              # Veritabanı düzeltme script'i
└── README_GORSEL_YUKLEME.md        # Bu dosya
```

## 🧪 Test Etme

### 1. Manuel Test

1. Flutter uygulamasını başlatın
2. "Kitap Sat" sayfasına gidin
3. Bir görsel seçin
4. Formu doldurup gönderin
5. Ana sayfada görselin göründüğünü kontrol edin

### 2. Otomatik Test

```bash
cd bebook/backend
python test_upload.py
```

Bu script:
- ✅ Uploads klasörünü kontrol eder
- ✅ Test görseli oluşturur
- ✅ Backend'e yükleme yapar
- ✅ Görselin erişilebilir olduğunu doğrular

## 🐛 Sorun Giderme

### Görsel Görünmüyor

**1. Backend loglarını kontrol edin:**
```bash
# Terminal'de backend çalışırken göreceksiniz
INFO:     127.0.0.1:xxxxx - "POST /books HTTP/1.1" 200 OK
```

**2. Uploads klasörünü kontrol edin:**
```bash
ls -la bebook/backend/uploads/
# veya Windows'ta
dir bebook\backend\uploads\
```

**3. Veritabanını kontrol edin:**
```sql
SELECT id, title, image_path FROM public.books ORDER BY id DESC LIMIT 5;
```

Görsel yolu şu formatta olmalı: `/uploads/uuid.jpg`

**4. Flutter debug console'u kontrol edin:**
```
Görsel yükleme hatası: ...
URL: http://192.168.1.30:8000/uploads/...
```

**5. Network isteğini kontrol edin:**
- Chrome DevTools → Network tab
- Görsel isteğinin 200 OK dönüp dönmediğini kontrol edin

### Yaygın Hatalar ve Çözümleri

#### ❌ "Connection refused"
**Sorun:** Backend çalışmıyor veya yanlış IP/port
**Çözüm:**
```bash
# Backend'i doğru parametrelerle başlatın
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### ❌ "404 Not Found" (görsel için)
**Sorun:** Dosya uploads klasöründe yok
**Çözüm:**
1. Backend loglarında dosyanın kaydedildiğini kontrol edin
2. Uploads klasörünün varlığını kontrol edin
3. Dosya izinlerini kontrol edin

#### ❌ Yanlış görsel gösteriliyor
**Sorun:** Veritabanında eski tam URL'ler var
**Çözüm:**
```bash
# SQL script'ini çalıştırın
psql -U postgres -d bebook -f fix_image_urls.sql
```

#### ❌ "CORS error"
**Sorun:** CORS ayarları yanlış
**Çözüm:** `main.py` dosyasında CORS ayarlarını kontrol edin:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Development için
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🔒 Güvenlik

### Geliştirme Ortamı (Şu Anki)
```python
allow_origins=["*"]  # Tüm kaynaklara izin ver
```

### Production Ortamı (Önerilen)
```python
allow_origins=[
    "https://yourdomain.com",
    "https://www.yourdomain.com",
]
```

### Dosya Güvenliği

Şu anki implementasyon temel güvenlik sağlar:
- ✅ UUID ile benzersiz dosya adları
- ✅ Dosya uzantısı korunur

**Önerilen iyileştirmeler:**
```python
# Dosya boyutu kontrolü
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

# İzin verilen uzantılar
ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}

# MIME type kontrolü
import magic
mime = magic.Magic(mime=True)
file_type = mime.from_buffer(await image.read(1024))
```

## 📊 Veri Akışı

```
┌─────────────┐
│   Flutter   │
│  (Kullanıcı)│
└──────┬──────┘
       │ 1. Görsel seç (XFile)
       │
       ▼
┌─────────────┐
│ ApiService  │
│ uploadBook()│
└──────┬──────┘
       │ 2. MultipartRequest
       │    - title, author, etc.
       │    - image: Uint8List
       │
       ▼
┌─────────────┐
│   Backend   │
│ POST /books │
└──────┬──────┘
       │ 3. UUID oluştur
       │ 4. Dosyayı kaydet: uploads/uuid.jpg
       │ 5. DB'ye kaydet: /uploads/uuid.jpg
       │
       ▼
┌─────────────┐
│ PostgreSQL  │
│   Database  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Flutter   │
│ GET /books  │
└──────┬──────┘
       │ 6. Kitapları çek
       │
       ▼
┌─────────────┐
│ ApiService  │
│ fetchBooks()│
└──────┬──────┘
       │ 7. URL'leri tamamla:
       │    /uploads/uuid.jpg
       │    → http://192.168.1.30:8000/uploads/uuid.jpg
       │
       ▼
┌─────────────┐
│  BookCard   │
│Image.network│
└─────────────┘
       │ 8. Görseli göster
       ▼
    👁️ Kullanıcı
```

## 🚀 Production'a Geçiş

### 1. Cloud Storage Kullanın

**AWS S3:**
```python
import boto3

s3 = boto3.client('s3')
s3.upload_fileobj(image.file, 'bucket-name', file_name)
image_url = f"https://bucket-name.s3.amazonaws.com/{file_name}"
```

**Cloudinary:**
```python
import cloudinary.uploader

result = cloudinary.uploader.upload(image.file)
image_url = result['secure_url']
```

### 2. CDN Kullanın

Görselleri CDN üzerinden sunun:
```python
CDN_URL = "https://cdn.yourdomain.com"
image_url = f"{CDN_URL}/uploads/{file_name}"
```

### 3. Görsel Optimizasyonu

```python
from PIL import Image
import io

# Görseli yeniden boyutlandır
img = Image.open(image.file)
img.thumbnail((800, 1200))

# Kaliteyi düşür
buffer = io.BytesIO()
img.save(buffer, format='JPEG', quality=85, optimize=True)
```

## 📝 Veritabanı Şeması

```sql
CREATE TABLE public.books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    publisher VARCHAR(255),
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    seller_email VARCHAR(255) NOT NULL,
    image_path VARCHAR(500),  -- Görsel yolu: /uploads/uuid.jpg
    is_sold BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index ekle (performans için)
CREATE INDEX idx_books_seller_email ON public.books(seller_email);
CREATE INDEX idx_books_is_sold ON public.books(is_sold);
```

## 🔄 Güncelleme Geçmişi

### v2.0 (Mevcut)
- ✅ Göreceli URL kullanımı
- ✅ Mutlak dosya yolu
- ✅ IP değişikliğine karşı esnek
- ✅ Web ve mobil uyumlu önizleme

### v1.0 (Eski)
- ❌ Tam URL kaydediliyordu
- ❌ Göreceli dosya yolu
- ❌ IP değişikliğinde sorun

## 📞 Destek

Sorun yaşıyorsanız:
1. Bu README'yi okuyun
2. `GORSEL_SORUNU_COZUMU.md` dosyasına bakın
3. `test_upload.py` script'ini çalıştırın
4. Hata mesajlarını ve logları kontrol edin

## 📚 Kaynaklar

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
