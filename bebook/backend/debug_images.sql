-- ============================================================
-- Bebook - Görsel Sorunlarını Debug Etme Script'i
-- ============================================================

-- 1. Son eklenen 5 kitabın görsel yollarını kontrol et
SELECT 
    id,
    title,
    image_path,
    seller_email,
    created_at,
    CASE 
        WHEN image_path LIKE 'http://%' THEN '❌ Tam URL (yanlış)'
        WHEN image_path LIKE '/uploads/%' THEN '✅ Göreceli yol (doğru)'
        WHEN image_path IS NULL OR image_path = '' THEN '⚠️ Görsel yok'
        ELSE '⚠️ Bilinmeyen format'
    END as durum
FROM public.books
ORDER BY created_at DESC
LIMIT 5;

-- 2. Tüm kitapların görsel durumunu özetle
SELECT 
    COUNT(*) as toplam_kitap,
    COUNT(CASE WHEN image_path LIKE '/uploads/%' THEN 1 END) as dogru_format,
    COUNT(CASE WHEN image_path LIKE 'http://%' THEN 1 END) as yanlis_format,
    COUNT(CASE WHEN image_path IS NULL OR image_path = '' THEN 1 END) as gorselsiz
FROM public.books;

-- 3. Aynı görsel yolunu kullanan kitapları bul (görsel karışıklığı)
SELECT 
    image_path,
    COUNT(*) as kullanim_sayisi,
    STRING_AGG(title, ', ') as kitaplar
FROM public.books
WHERE image_path IS NOT NULL AND image_path != ''
GROUP BY image_path
HAVING COUNT(*) > 1
ORDER BY kullanim_sayisi DESC;

-- 4. Bugün eklenen kitapları göster
SELECT 
    id,
    title,
    image_path,
    created_at
FROM public.books
WHERE DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC;
