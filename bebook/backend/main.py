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

# 1. ÖNCE APP NESNESİNİ OLUŞTUR
app = FastAPI()

# 2. PYDANTIC MODELLERİ
class BulkPaymentRequest(BaseModel):
    user_id: int
    book_ids: List[int]
    total_price: float


# --- CORS AYARLARI ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- VERİTABANI BAĞLANTISI ---
def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="bebook",
        user="postgres",
        password="senem2003", 
        port="5432"
    )

# --- IYZICO AYARLARI ---
IYZICO_OPTIONS = {
    'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
    'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
    'base_url': 'sandbox-api.iyzipay.com'
}

# --- VERİ MODELLERİ ---

class UserSignup(BaseModel):
    email: str
    password: str
    university: str
    department: str

class UserLogin(BaseModel):
    email: str
    password: str

class BookCreate(BaseModel):  # YENİ EKLENDİ/GÜNCELLENDİ
    title: str
    author: str
    category: str
    price: float
    description: str
    seller_email: str
    publisher: Optional[str] = "" # Yayınevi alanı
    image_path: Optional[str] = ""

class CreatePayment(BaseModel):
    user_id: int
    book_id: int
    price: float

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

    description: str


# --- 🖼️ STATİK DOSYA VE CORS AYARLARI ---
UPLOAD_DIR = "uploads" 
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
BASE_URL = "http://192.168.1.7:8000" 

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- VERİTABANI BAĞLANTISI ---
def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="bebook",
        user="postgres",
        password="senem2003",
        port="5432"
    )

# --- IYZICO AYARLARI ---
IYZICO_OPTIONS = {
    'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
    'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
    'base_url': 'sandbox-api.iyzipay.com'
}

# --- 🛒 YENİ EKLENEN: TOPLU ÖDEME ROTASI ---
@app.post("/bulk-payment")
async def bulk_payment(request: BulkPaymentRequest):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        # HATA ALAN KISIM BURASIYDI: 
        # Ana tabloya (orders) kayıt atarken sepetteki ilk kitabın ID'sini veriyoruz 
        # ki 'NOT NULL' kısıtlaması bozulmasın.
        first_book_id = request.book_ids[0] if request.book_ids else None

        cur.execute(
            "INSERT INTO orders (user_id, book_id, price, status) VALUES (%s, %s, %s, %s) RETURNING order_id",
            (request.user_id, first_book_id, request.total_price, "PENDING")
        )
        order_id = cur.fetchone()[0]
        conn.commit()

        # ... (İyzipay sepet hazırlama kısımları aynı kalıyor) ...
        
        # İyzipay basket_items kısmında tüm kitapları tek tek eklemeye devam et
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

        # İyzipay isteğini gönder...

        # 3. İyzipay Form Başlatma İsteği
        iyzico_request = {
            'locale': 'tr',
            'conversationId': str(order_id),
            'price': str(request.total_price),
            'paidPrice': str(request.total_price),
            'currency': 'TRY',
            'basketId': str(order_id),
            'paymentGroup': 'PRODUCT',
            'callbackUrl': f'{BASE_URL}/payment-callback', # Ödeme bitince döneceği adres
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
                'contactName': 'Merve Bebook', 'city': 'Zonguldak', 'country': 'Turkey', 
                'address': 'Incivez Mah.', 'zipCode': '67100'
            },
            'billingAddress': {
                'contactName': 'Merve Bebook', 'city': 'Zonguldak', 'country': 'Turkey', 
                'address': 'Incivez Mah.', 'zipCode': '67100'
            },
            'basketItems': basket_items
        }

        checkout_form_initialize = iyzipay.CheckoutFormInitialize().create(iyzico_request, IYZICO_OPTIONS)
        # İyzipay'den gelen veriyi JSON olarak Flutter'a gönderiyoruz
        return json.loads(checkout_form_initialize.read().decode('utf-8'))

    except Exception as e:
        print(f"İyzipay Hatası: {e}")
        return {"status": "failure", "errorMessage": str(e)}
    finally:
        conn.close()

# --- DİĞER ENDPOINTS (Geri Kalanlar Aynı) ---

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

# ... (Buradan sonraki /login, /books vb. tüm kodlarını altına yapıştırabilirsin)



        

@app.post("/login")
async def login(user: UserLogin):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT user_id, password_hash, university, department FROM public.users WHERE email = %s", (user.email,))
        result = result = cur.fetchone()

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

@app.get("/books")
async def get_all_books():
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT book_id, user_id, title, author, category, price, description, image_path FROM public.books")
        books = cur.fetchall()
        
        result = []
        for b in books:
            # Resim ismini tam URL'e çeviriyoruz
            image_url = f"{BASE_URL}/uploads/{b[7]}" if b[7] else None
            result.append({
                "book_id": b[0],
                "user_id": b[1],
                "title": b[2],
                "author": b[3],
                "category": b[4],
                "price": b[5],
                "description": b[6],
                "image_path": image_url
            })
        return result
    finally:
        conn.close()

@app.get("/my-books/{user_id}")
async def get_my_books(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # SORGUDAN SONRA 'author' alanını ekledik:
        cur.execute("""
            SELECT book_id, user_id, title, author, price, description, image_path
            FROM books
            WHERE user_id = %s
        """, (user_id,))
        books = cur.fetchall()

        result = []
        for b in books:
            image_url = f"{BASE_URL}/uploads/{b[6]}" if b[6] else None
            result.append({
                "book_id": b[0],
                "user_id": b[1],
                "title": b[2],
                "author": b[3], # Artık yazar bilgisi listede
                "price": b[4],
                "description": b[5],
                "image_path": image_url
            })
        return result
    finally:
        conn.close()

# --- 🔥 GÜNCELLENEN: RESİM YÜKLEMELİ KİTAP EKLEME ---
@app.post("/books")
async def add_book(
    user_id: int = Form(...),
    title: str = Form(...),
    author: str = Form(...),
    category: str = Form(...),
    price: float = Form(...),
    description: str = Form(...),
    seller_email: str = Form(...),
    file: UploadFile = File(None) # Resim dosyası buradan gelir
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
            (user_id, title, author, category, price, description, seller_email, image_path) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (user_id, title, author, category, price, description, seller_email, image_name)
        )
        conn.commit()
        cur.close()
        return {"status": "success", "message": "Kitap ve resim yüklendi!"}
    
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


# --- YENİ KİTAP İLANI YAYINLA ---
@app.post("/books")
async def upload_book(book: BookCreate):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # SQL sorgusuna 'publisher' alanı eklendi
        query = """
            INSERT INTO public.books 
            (title, author, category, publisher, price, description, seller_email, image_path) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        cur.execute(query, (
            book.title, 
            book.author, 
            book.category, 
            book.publisher, 
            book.price, 
            book.description, 
            book.seller_email, 
            book.image_path
        ))
        conn.commit()
        return {"status": "success", "message": "İlan başarıyla oluşturuldu!"}
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()

# --- TÜM KİTAPLARI GETİR (Ana Sayfa) ---
@app.get("/books")
async def fetch_books():
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # Publisher'ı da çekiyoruz ki Flutter'da görebilelim
        cur.execute("SELECT id, title, author, category, publisher, price, description, image_path FROM public.books WHERE is_sold = FALSE")
        books = cur.fetchall()
        return [
            {
                "id": b[0], "title": b[1], "author": b[2], "category": b[3], 
                "publisher": b[4], "price": b[5], "description": b[6], "image_path": b[7]
            } for b in books
        ]
    finally:
        conn.close()

# --- ÖDEME BAŞLATMA (CREATE PAYMENT) ---

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

        # Ortak adres objesi (Hem fatura hem teslimat için kullanabiliriz)
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
            'callbackUrl': 'http://192.168.1.7:8000/payment-callback',
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

@app.post("/payment-callback")
async def payment_callback(request: Request):
    form_data = await request.form()
    token = form_data.get('token') # Iyzico'dan gelen tek veri bu

    if not token:
        return HTMLResponse(content="Geçersiz istek (Token yok)", status_code=400)

    # 1. İyzipay'e bu token ile sonucun ne olduğunu soruyoruz
    iyzico_request = {'token': token}
    checkout_form_result = iyzipay.CheckoutForm().retrieve(iyzico_request, IYZICO_OPTIONS)
    
    # Gelen yanıtı JSON'a çevirip kontrol edelim
    result = json.loads(checkout_form_result.read().decode('utf-8'))
    
    # Debug için terminale detayları yazdıralım
    print("--- IYZICO SORGULAMA SONUCU ---")
    print(json.dumps(result, indent=2))

    payment_status = result.get('paymentStatus') # 'SUCCESS' veya 'FAILURE' döner
    order_id = result.get('conversationId')      # Veritabanındaki order_id

    if payment_status == 'SUCCESS':
        # 2. Veritabanını Güncelle
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
        description = "İşleminiz başarıyla tamamlandı. Diğer ilanları incelemek için ana sayfaya dönebilirsiniz.!"
    else:
        status_text = "Ödeme Başarısız"
        main_color = "#e74c3c"
        error_msg = result.get('errorMessage', 'Ödeme onaylanmadı.')
        description = f"Sorun oluştu: {error_msg}"

    # HTML içeriği (Aynı kalabilir)
    # HTML içeriği (Mobil uyumlu hale getirildi)
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
            <div style="font-size: 60px; margin-bottom: 20px;">{"" if payment_status == 'SUCCESS' else ""}</div>
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


# --- ÖDEME CALLBACK ---
@app.post("/payment-callback")
async def payment_callback(request: Request):
    form_data = await request.form()
    token = form_data.get("token")
    retrieve_request = {'locale': 'tr', 'conversationId': '0', 'token': token}

    checkout_form = iyzipay.CheckoutForm().retrieve(retrieve_request, IYZICO_OPTIONS)
    result = json.loads(checkout_form.read().decode('utf-8'))
    order_id = result.get("conversationId")
    payment_status = result.get("paymentStatus")

    conn = get_db_connection()
    try:
        cur = conn.cursor()
        status = "SUCCESS" if payment_status == "SUCCESS" else "FAILED"
        cur.execute("UPDATE orders SET status = %s WHERE order_id = %s", (status, order_id))
        conn.commit()
    finally:
        conn.close()
    return {"status": payment_status}

# --- İLAN GÜNCELLEME VE LİSTELEME ---

@app.put("/update-book")
async def update_book(book: UpdateBook):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("UPDATE books SET title = %s, price = %s, description = %s WHERE book_id = %s AND user_id = %s", 
                    (book.title, book.price, book.description, book.book_id, book.user_id))
        conn.commit()
        return {"status": "success"}
    finally:
        conn.close()

@app.delete("/delete-book/{book_id}/{user_id}")
async def delete_book(book_id: int, user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM books WHERE book_id = %s AND user_id = %s", (book_id, user_id))
        conn.commit()
        return {"status": "success"}
    finally:
        conn.close()

@app.post("/contact")
async def contact(req: ContactRequest):
    # İletişim mesajlarını buraya kaydedebilir veya e-posta atabilirsin.
    return {"status": "success", "message": "Mesajınız iletildi."}
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

@app.get("/my-books/{user_id}")
async def get_my_books(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # Burada da publisher alanını çekecek şekilde güncelledik
        cur.execute("SELECT id, title, author, category, publisher, price, description FROM public.books WHERE user_id = %s", (user_id,))
        books = cur.fetchall()
        return [
            {
                "book_id": b[0], "title": b[1], "author": b[2], "category": b[3], 
                "publisher": b[4], "price": b[5], "description": b[6]
            } for b in books
        ]
    finally:
        conn.close()