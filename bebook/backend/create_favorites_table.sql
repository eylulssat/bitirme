-- ============================================================
-- Bebook - Favoriler Tablosu Oluşturma Script'i
-- pgAdmin4'te Query Tool ile çalıştırın
-- ============================================================

-- Favoriler tablosunu oluştur
CREATE TABLE IF NOT EXISTS public.favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    book_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_book FOREIGN KEY (book_id) REFERENCES public.books(id) ON DELETE CASCADE,
    
    -- Aynı kullanıcı aynı kitabı birden fazla kez favorilere ekleyemesin
    CONSTRAINT unique_user_book UNIQUE (user_id, book_id)
);

-- Index'ler ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_book_id ON public.favorites(book_id);
CREATE INDEX IF NOT EXISTS idx_favorites_created_at ON public.favorites(created_at DESC);

-- Tablo oluşturuldu mesajı
SELECT 'Favoriler tablosu başarıyla oluşturuldu!' as mesaj;

-- Tablo yapısını kontrol et
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'favorites'
ORDER BY ordinal_position;
