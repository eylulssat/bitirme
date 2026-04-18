from fastapi import FastAPI, HTTPException, Request, UploadFile, File, Form
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr
import psycopg2
import bcrypt
from fastapi.middleware.cors import CORSMiddleware
import json
import iyzipay
import os
import shutil
import uuid
from typing import List, Optional

# ============================================
# 1. APP OLUŞTURMA
# ============================================
app = FastAPI()

# ============================================
# 2. PYDANTIC MODELLERİ (Tüm modeller burada)
# ============================================
class UserSignup(BaseModel):
    email: str
    password: str
    university: str
    department: str

class UserLogin(BaseModel):
    email: str
    password: str

class BookCreate(BaseModel):
    title: str
    author: str
    category: str
    price: float
    description: str
    seller_email: str
    publisher: Optional[str] = ""
    image_path: Optional[str] = ""

class CreatePayment(BaseModel):
    user_id: int
    book_id: int
    price: float

class BulkPaymentRequest(BaseModel):
    user_id: int
    book_ids: List[int]
    total_price: float

class UpdateBook(BaseModel):
    book_id: int
    user_id: int
    title: str
    price: float
    description: str

class ContactRequest(BaseModel):
    full_name: str
    email: str
    message: str

class FavoriteToggle(BaseModel):
    user_id: int
    book_id: int

# ============================================
# 3. UPLOAD DİZİNİ VE STATİK DOSYALAR
# ============================================
UPLOAD_DIR = "uploads" 
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
BASE_URL = "http://192.168.1.30:8000"  # LOKAL IP KORUNDU 

# ============================================
# 4. CORS AYARLARI (Tek sefer)
# ============================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# 5. VERİTABANI BAĞLANTISI (Tek fonksiyon)
# ============================================
def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="bebook",
        user="postgres",
        password="senem2003",  # LOKAL ŞİFRE KORUNDU
        port="5432"
    )

# ============================================
# 6. IYZICO AYARLARI (Tek sefer)
# ============================================
IYZICO_OPTIONS = {
    'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
    'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
    'base_url': 'sandbox-api.iyzipay.com'
}

# ============================================
# 7. ENDPOINTS
# ============================================

# --- KULLANICI KAYIT ---
@app.post("/signup")
async def signup(user: UserSignup):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        hashed_password = bcrypt.hashpw(
            user.password.encode('utf-8')[:72],
            bcrypt.gensalt()
        ).decode('utf-8')

        cur.execute(
            "INSERT INTO public.users (email, password_hash, university, department) VALUES (%s, %s, %s, %s)",
            (user.email, hashed_password, user.university, user.department)
        )
        conn.commit()
        return {"status": "success", "message": "Kullanıcı başarıyla kaydedildi!"}
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()

# --- KULLANICI GİRİŞ ---
@app.post("/login")
async def login(user: UserLogin):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT user_id, password_hash, university, department FROM public.users WHERE email = %s", (user.email,))
        result = cur.fetchone()

        if not result:
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")

        user_id, stored_hash, university, department = result
        if bcrypt.checkpw(user.password.encode('utf-8')[:72], stored_hash.encode('utf-8')):
            return {
                "status": "success",
                "user_id": user_id,
                "user_email": user.email,
                "university": university,
                "department": department
            }
        else:
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")
    finally:
        conn.close()

# --- TÜM KİTAPLARI GETİR (Ana Sayfa) ---
@app.get("/books")
async def get_all_books():
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT 
                b.id as book_id, u.user_id, b.title, b.author, b.category, b.price, 
                b.description, b.image_path, b.seller_email, b.publisher,
                u.email, u.university, u.department
            FROM public.books b
            LEFT JOIN public.users u ON b.seller_email = u.email
        """
        cur.execute(query)
        books = cur.fetchall()
        
        result = []
        for b in books:
            # Resim yolunu tam URL'e çeviriyoruz
            image_path = b[7]
            if image_path:
                # Eğer zaten tam URL ise olduğu gibi kullan
                if image_path.startswith('http'):
                    image_url = image_path
                # Eğer /uploads/ ile başlıyorsa baseUrl ekle
                elif image_path.startswith('/uploads/'):
                    image_url = f"{BASE_URL}{image_path}"
                # Sadece dosya adı ise /uploads/ ekle
                else:
                    image_url = f"{BASE_URL}/uploads/{image_path}"
            else:
                image_url = None
                
            result.append({
                "book_id": b[0],
                "user_id": b[1],
                "title": b[2],
                "author": b[3],
                "category": b[4],
                "price": float(b[5]),
                "description": b[6],
                "image_path": image_url,
                "seller_email": b[8],
                "publisher": b[9],
                "email": b[10],
                "university": b[11],
                "department": b[12]
            })
        return result
    finally:
        conn.close()

# --- YENİ KİTAP EKLEME (Resim ile) ---
@app.post("/books")
async def add_book(
    title: str = Form(...),
    author: str = Form(...),
    category: str = Form(...),
    price: float = Form(...),
    description: str = Form(...),
    seller_email: str = Form(...),
    publisher: str = Form(""),
    file: UploadFile = File(None)
):
    conn = None
    image_name = None
    
    try:
        # 1. Dosya varsa kaydet
        if file:
            ext = file.filename.split('.')[-1]
            image_name = f"{uuid.uuid4()}.{ext}"
            file_path = os.path.join(UPLOAD_DIR, image_name)

            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

        # 2. Veritabanına sadece dosya ismini kaydet
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO public.books 
            (title, author, category, price, description, seller_email, publisher, image_path) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (title, author, category, price, description, seller_email, publisher, image_name)
        )
        conn.commit()
        cur.close()
        return {"status": "success", "message": "Kitap ve resim yüklendi!"}
    
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- KULLANICININ KİTAPLARINI GETİR ---
@app.get("/my-books/{user_id}")
async def get_my_books(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # user_id'den email'i bulup, o email'e ait kitapları getir
        cur.execute("SELECT email FROM users WHERE user_id = %s", (user_id,))
        user_result = cur.fetchone()
        
        if not user_result:
            return []
        
        user_email = user_result[0]
        
        cur.execute("""
            SELECT id as book_id, title, author, category, publisher, price, description, image_path
            FROM books
            WHERE seller_email = %s
        """, (user_email,))
        books = cur.fetchall()

        result = []
        for b in books:
            image_path = b[7]
            if image_path:
                if image_path.startswith('http'):
                    image_url = image_path
                elif image_path.startswith('/uploads/'):
                    image_url = f"{BASE_URL}{image_path}"
                else:
                    image_url = f"{BASE_URL}/uploads/{image_path}"
            else:
                image_url = None
                
            result.append({
                "book_id": b[0],
                "user_id": user_id,
                "title": b[1],
                "author": b[2],
                "category": b[3],
                "publisher": b[4],
                "price": float(b[5]),
                "description": b[6],
                "image_path": image_url
            })
        return result
    finally:
        conn.close()

# --- KİTAP GÜNCELLEME ---
@app.put("/update-book")
async def update_book(book: UpdateBook):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # user_id'den email'i bul
        cur.execute("SELECT email FROM users WHERE user_id = %s", (book.user_id,))
        user_result = cur.fetchone()
        
        if not user_result:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        
        user_email = user_result[0]
        
        # Kitabı güncelle
        cur.execute(
            "UPDATE books SET title = %s, price = %s, description = %s WHERE id = %s AND seller_email = %s", 
            (book.title, book.price, book.description, book.book_id, user_email)
        )
        conn.commit()
        return {"status": "success"}
    finally:
        conn.close()

# --- KİTAP SİLME ---
@app.delete("/delete-book/{book_id}/{user_id}")
async def delete_book(book_id: int, user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # user_id'den email'i bul
        cur.execute("SELECT email FROM users WHERE user_id = %s", (user_id,))
        user_result = cur.fetchone()
        
        if not user_result:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        
        user_email = user_result[0]
        
        # Kitabı sil
        cur.execute("DELETE FROM books WHERE id = %s AND seller_email = %s", (book_id, user_email))
        conn.commit()
        return {"status": "success"}
    finally:
        conn.close()

# --- TEK KİTAP İÇİN ÖDEME BAŞLATMA ---
@app.post("/create-payment")
async def create_payment(payment: CreatePayment):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO orders (user_id, book_id, price, status) VALUES (%s, %s, %s, %s) RETURNING order_id",
            (payment.user_id, payment.book_id, payment.price, "PENDING")
        )
        order_id = cur.fetchone()[0]
        conn.commit()

        address_info = {
            'contactName': 'Merve Bebook',
            'city': 'Zonguldak',
            'country': 'Turkey',
            'address': 'Universite Caddesi No:100 Incivez',
            'zipCode': '67100'
        }

        request_data = {
            'locale': 'tr',
            'conversationId': str(order_id),
            'price': str(payment.price),
            'paidPrice': str(payment.price),
            'currency': 'TRY',
            'basketId': str(order_id),
            'paymentGroup': 'PRODUCT',
            'callbackUrl': f'{BASE_URL}/payment-callback',
            'buyer': {
                'id': str(payment.user_id),
                'name': 'Eylul',
                'surname': 'Bebook',
                'gsmNumber': '+905350000000',
                'email': 'test@email.com',
                'identityNumber': '11111111110',
                'city': 'Zonguldak',
                'country': 'Turkey',
                'zipCode': '67100',
                'registrationAddress': 'Universite Caddesi No:100 Incivez'
            },
            'shippingAddress': address_info,
            'billingAddress': address_info,
            'basketItems': [
                {
                    'id': str(payment.book_id), 
                    'name': 'Kitap', 
                    'category1': 'Egitim', 
                    'itemType': 'PHYSICAL', 
                    'price': str(payment.price)
                }
            ]
        }
        checkout_form_initialize = iyzipay.CheckoutFormInitialize().create(request_data, IYZICO_OPTIONS)
        return json.loads(checkout_form_initialize.read().decode('utf-8'))
    finally:
        conn.close()

# --- TOPLU ÖDEME (Sepet) ---
@app.post("/bulk-payment")
async def bulk_payment(request: BulkPaymentRequest):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        # İlk kitabın ID'sini orders tablosuna kaydediyoruz
        first_book_id = request.book_ids[0] if request.book_ids else None

        cur.execute(
            "INSERT INTO orders (user_id, book_id, price, status) VALUES (%s, %s, %s, %s) RETURNING order_id",
            (request.user_id, first_book_id, request.total_price, "PENDING")
        )
        order_id = cur.fetchone()[0]
        conn.commit()

        # Sepetteki tüm kitapları basket_items'a ekliyoruz
        basket_items = []
        for b_id in request.book_ids:
            item = {
                'id': str(b_id),
                'name': f'Kitap ID: {b_id}',
                'category1': 'Egitim',
                'itemType': 'PHYSICAL',
                'price': str(request.total_price / len(request.book_ids))
            }
            basket_items.append(item)

        iyzico_request = {
            'locale': 'tr',
            'conversationId': str(order_id),
            'price': str(request.total_price),
            'paidPrice': str(request.total_price),
            'currency': 'TRY',
            'basketId': str(order_id),
            'paymentGroup': 'PRODUCT',
            'callbackUrl': f'{BASE_URL}/payment-callback',
            'buyer': {
                'id': str(request.user_id),
                'name': 'Merve',
                'surname': 'Bebook',
                'gsmNumber': '+905350000000',
                'email': 'test@email.com',
                'identityNumber': '11111111110',
                'city': 'Zonguldak',
                'country': 'Turkey',
                'zipCode': '67100',
                'registrationAddress': 'ZBEU Kampusu'
            },
            'shippingAddress': {
                'contactName': 'Merve Bebook', 
                'city': 'Zonguldak', 
                'country': 'Turkey', 
                'address': 'Incivez Mah.', 
                'zipCode': '67100'
            },
            'billingAddress': {
                'contactName': 'Merve Bebook', 
                'city': 'Zonguldak', 
                'country': 'Turkey', 
                'address': 'Incivez Mah.', 
                'zipCode': '67100'
            },
            'basketItems': basket_items
        }

        checkout_form_initialize = iyzipay.CheckoutFormInitialize().create(iyzico_request, IYZICO_OPTIONS)
        return json.loads(checkout_form_initialize.read().decode('utf-8'))

    except Exception as e:
        print(f"İyzipay Hatası: {e}")
        return {"status": "failure", "errorMessage": str(e)}
    finally:
        conn.close()

# --- ÖDEME CALLBACK (Tek versiyon) ---
@app.post("/payment-callback")
async def payment_callback(request: Request):
    form_data = await request.form()
    token = form_data.get('token')

    if not token:
        return HTMLResponse(content="Geçersiz istek (Token yok)", status_code=400)

    # İyzipay'e token ile sonucu sorguluyoruz
    iyzico_request = {'token': token}
    checkout_form_result = iyzipay.CheckoutForm().retrieve(iyzico_request, IYZICO_OPTIONS)
    
    result = json.loads(checkout_form_result.read().decode('utf-8'))
    
    print("--- IYZICO SORGULAMA SONUCU ---")
    print(json.dumps(result, indent=2))

    payment_status = result.get('paymentStatus')
    order_id = result.get('conversationId')

    if payment_status == 'SUCCESS':
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("UPDATE orders SET status = 'SUCCESS' WHERE order_id = %s", (order_id,))
            conn.commit()
            cur.close()
            conn.close()
        except Exception as e:
            print(f"DB Güncelleme Hatası: {e}")

        status_text = "Ödeme Başarılı!"
        main_color = "#2ecc71"
        description = "İşleminiz başarıyla tamamlandı. Diğer ilanları incelemek için ana sayfaya dönebilirsiniz!"
    else:
        status_text = "Ödeme Başarısız"
        main_color = "#e74c3c"
        error_msg = result.get('errorMessage', 'Ödeme onaylanmadı.')
        description = f"Sorun oluştu: {error_msg}"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="tr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <title>Ödeme Sonucu</title>
    </head>
    <body style="display:flex; align-items:center; justify-content:center; height:100vh; margin:0; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background:#f4f7f6;">
        <div style="text-align:center; padding:30px; background:white; border-radius:28px; box-shadow: 0 15px 35px rgba(0,0,0,0.1); width: 85%; max-width: 400px;">
            <div style="font-size: 60px; margin-bottom: 20px;">{"✓" if payment_status == 'SUCCESS' else "✗"}</div>
            <h1 style="color:{main_color}; font-size: 24px; margin-bottom: 10px;">{status_text}</h1>
            <p style="color:#666; font-size: 16px; line-height: 1.5; margin-bottom: 30px;">{description}</p>
            
            <a href="bebook://home" style="
                display: block;
                text-decoration: none;
                background: white;
                color: black;
                padding: 16px;
                border: 2px solid black;
                border-radius: 16px;
                font-weight: 800;
                font-size: 16px;
                text-transform: uppercase;
            ">ANA SAYFAYA DÖN</a>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)

# --- SİPARİŞ DURUMU SORGULAMA ---
@app.get("/order-status/{order_id}")
async def get_order_status(order_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT status FROM orders WHERE order_id = %s", (order_id,))
        result = cur.fetchone()
        if result:
            return {"status": result[0]}
        else:
            raise HTTPException(status_code=404, detail="Sipariş bulunamadı")
    finally:
        conn.close()

# --- İLETİŞİM FORMU ---
@app.post("/contact")
async def contact(req: ContactRequest):
    return {"status": "success", "message": "Mesajınız iletildi."}

# --- FAVORİLER SİSTEMİ ---
@app.post("/favorites/toggle")
async def toggle_favorite(favorite: FavoriteToggle):
    """Favorilere ekle/çıkar"""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        # Önce bu kitap favorilerde mi kontrol et
        cur.execute(
            "SELECT id FROM public.favorites WHERE user_id = %s AND book_id = %s",
            (favorite.user_id, favorite.book_id)
        )
        existing = cur.fetchone()
        
        if existing:
            # Favorilerde varsa çıkar
            cur.execute(
                "DELETE FROM public.favorites WHERE user_id = %s AND book_id = %s",
                (favorite.user_id, favorite.book_id)
            )
            conn.commit()
            return {"status": "removed", "message": "Favorilerden çıkarıldı"}
        else:
            # Favorilerde yoksa ekle
            cur.execute(
                "INSERT INTO public.favorites (user_id, book_id) VALUES (%s, %s)",
                (favorite.user_id, favorite.book_id)
            )
            conn.commit()
            return {"status": "added", "message": "Favorilere eklendi"}
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()

@app.get("/favorites/{user_id}")
async def get_favorites(user_id: int):
    """Kullanıcının favori kitaplarını getir"""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT 
                b.book_id, b.title, b.author, b.category, b.price, b.description, 
                b.seller_email, b.image_path, b.publisher,
                u.user_id, u.email, u.university, u.department,
                f.created_at as favorited_at
            FROM public.favorites f
            JOIN public.books b ON f.book_id = b.id
            LEFT JOIN public.users u ON b.seller_email = u.email
            WHERE f.user_id = %s
            ORDER BY f.created_at DESC
        """
        cur.execute(query, (user_id,))
        favorites = cur.fetchall()
        
        result = []
        for f in favorites:
            image_url = f"{BASE_URL}/uploads/{f[7]}" if f[7] else None
            result.append({
                "book_id": f[0],
                "title": f[1],
                "author": f[2],
                "category": f[3],
                "price": float(f[4]),
                "description": f[5],
                "seller_email": f[6],
                "image_path": image_url,
                "publisher": f[8],
                "user_id": f[9],
                "email": f[10],
                "university": f[11],
                "department": f[12],
                "favorited_at": str(f[13])
            })
        return result
    finally:
        conn.close()

@app.get("/favorites/check/{user_id}/{book_id}")
async def check_favorite(user_id: int, book_id: int):
    """Bir kitabın favorilerde olup olmadığını kontrol et"""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT id FROM public.favorites WHERE user_id = %s AND book_id = %s",
            (user_id, book_id)
        )
        exists = cur.fetchone() is not None
        return {"is_favorite": exists}
    finally:
        conn.close()
