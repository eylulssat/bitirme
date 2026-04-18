-- ============================================================
-- Bebook Veritabanı - Görsel URL'lerini Düzeltme Script'i
-- Bu script, eski tam URL'leri göreceli yollara çevirir
-- ============================================================

-- ADIM 1: Mevcut durumu kontrol et
-- Bu sorgu, hangi kayıtların düzeltilmesi gerektiğini gösterir
SELECT 
    id, 
    title, 
    image_path,
    CASE 
        WHEN image_path LIKE 'http://%' THEN '❌ Tam URL (düzeltilecek)'
        WHEN image_path LIKE '/uploads/%' THEN '✅ Göreceli yol (doğru)'
        WHEN image_path IS NULL OR image_path = '' THEN '⚠️ Görsel yok'
        ELSE '⚠️ Diğer format'
    END as durum
FROM public.books
ORDER BY id DESC;

-- ADIM 2: Yedek tablo oluştur (güvenlik için - opsiyonel)
-- Eğer bir şeyler ters giderse geri dönebilirsiniz
DROP TABLE IF EXISTS public.books_backup;
CREATE TABLE public.books_backup AS 
SELECT * FROM public.books;

-- Yedek oluşturuldu mesajı
SELECT 'Yedek tablo oluşturuldu: books_backup' as mesaj;

-- ADIM 3: URL'leri düzelt
-- Tüm olası IP ve localhost kombinasyonlarını temizle

-- 3a. 127.0.0.1 içeren URL'leri düzelt
UPDATE public.books 
SET image_path = REPLACE(image_path, 'http://127.0.0.1:8000', '')
WHERE image_path LIKE 'http://127.0.0.1:8000%';

-- 3b. localhost içeren URL'leri düzelt
UPDATE public.books 
SET image_path = REPLACE(image_path, 'http://localhost:8000', '')
WHERE image_path LIKE 'http://localhost:8000%';

-- 3c. 192.168.x.x içeren URL'leri düzelt (kendi IP'nizi buraya yazın)
UPDATE public.books 
SET image_path = REPLACE(image_path, 'http://192.168.1.30:8000', '')
WHERE image_path LIKE 'http://192.168.1.30:8000%';

-- 3d. Diğer olası IP'ler için genel temizleme
-- Eğer farklı bir IP kullandıysanız, yukarıdaki gibi ekleyin

-- Güncelleme tamamlandı mesajı
SELECT 'URL düzeltmeleri tamamlandı' as mesaj;

-- ADIM 4: Sonuçları kontrol et
-- Düzeltmenin başarılı olup olmadığını gösterir
SELECT 
    id, 
    title, 
    image_path,
    CASE 
        WHEN image_path LIKE 'http://%' THEN '❌ Hala tam URL (manuel kontrol gerekli)'
        WHEN image_path LIKE '/uploads/%' THEN '✅ Düzeltildi'
        WHEN image_path IS NULL OR image_path = '' THEN '⚠️ Görsel yok'
        ELSE '⚠️ Kontrol et'
    END as durum
FROM public.books
ORDER BY id DESC;

-- 7. Güncellenen kayıt sayısını göster
SELECT 
    COUNT(*) as toplam_kitap,
    COUNT(CASE WHEN image_path LIKE '/uploads/%' THEN 1 END) as dogru_format,
    COUNT(CASE WHEN image_path LIKE 'http://%' THEN 1 END) as yanlis_format
FROM public.books
WHERE image_path IS NOT NULL AND image_path != '';

-- NOT: Eğer bir şeyler ters giderse, yedekten geri yükle:
-- UPDATE public.books SET image_path = books_backup.image_path 
-- FROM books_backup WHERE books.id = books_backup.id;
