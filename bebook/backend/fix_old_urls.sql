-- ============================================================
-- Eski Yanlış URL'leri Temizle
-- ============================================================

-- 1. Mevcut durumu göster
SELECT 
    id,
    title,
    image_path,
    CASE 
        WHEN image_path LIKE 'http://%' OR image_path LIKE 'https://%' THEN '❌ Tam URL'
        WHEN image_path LIKE '/uploads/%' THEN '✅ Doğru format'
        WHEN image_path IS NULL OR image_path = '' THEN '⚠️ Görsel yok'
        ELSE '⚠️ Bilinmeyen'
    END as durum
FROM public.books
ORDER BY id;

-- 2. Yedek al
DROP TABLE IF EXISTS public.books_backup_urls;
CREATE TABLE public.books_backup_urls AS 
SELECT * FROM public.books;

SELECT 'Yedek alındı: books_backup_urls' as mesaj;

-- 3. Tam URL'leri temizle (eski kayıtlar için)
-- Seçenek A: Amazon URL'lerini boşalt (önerilir - çünkü dosya yok)
UPDATE public.books 
SET image_path = ''
WHERE image_path LIKE 'https://m.media-amazon.com%';

-- Seçenek B: Veya tamamen sil (eğer test kayıtlarıysa)
-- DELETE FROM public.books WHERE image_path LIKE 'https://m.media-amazon.com%';

-- 4. Diğer tam URL'leri düzelt
UPDATE public.books 
SET image_path = REPLACE(image_path, 'http://127.0.0.1:8000', '')
WHERE image_path LIKE 'http://127.0.0.1:8000%';

UPDATE public.books 
SET image_path = REPLACE(image_path, 'http://192.168.1.30:8000', '')
WHERE image_path LIKE 'http://192.168.1.30:8000%';

UPDATE public.books 
SET image_path = REPLACE(image_path, 'http://localhost:8000', '')
WHERE image_path LIKE 'http://localhost:8000%';

-- 5. Sonuçları kontrol et
SELECT 
    id,
    title,
    image_path,
    CASE 
        WHEN image_path LIKE 'http://%' OR image_path LIKE 'https://%' THEN '❌ Hala tam URL'
        WHEN image_path LIKE '/uploads/%' THEN '✅ Düzeltildi'
        WHEN image_path IS NULL OR image_path = '' THEN '⚠️ Görsel yok'
        ELSE '⚠️ Kontrol et'
    END as durum
FROM public.books
ORDER BY id;

-- 6. Özet
SELECT 
    COUNT(*) as toplam_kitap,
    COUNT(CASE WHEN image_path LIKE '/uploads/%' THEN 1 END) as dogru_format,
    COUNT(CASE WHEN image_path LIKE 'http%' THEN 1 END) as yanlis_format,
    COUNT(CASE WHEN image_path IS NULL OR image_path = '' THEN 1 END) as gorselsiz
FROM public.books;

SELECT '✅ URL düzeltmeleri tamamlandı!' as mesaj;
