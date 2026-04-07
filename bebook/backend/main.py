from fastapi import FastAPI, HTTPException, Request, UploadFile, File, Form
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import psycopg2
import bcrypt
from fastapi.middleware.cors import CORSMiddleware
import json
import iyzipay
import os
import shutil
import uuid
from typing import List

# 1. ÖNCE APP NESNESİNİ OLUŞTUR
app = FastAPI()

# 2. PYDANTIC MODELLERİ
class BulkPaymentRequest(BaseModel):
    user_id: int
    book_ids: List[int]
    total_price: float

class UserSignup(BaseModel):
    email: str
    password: str
    university: str
    department: str

class UserLogin(BaseModel):
    email: str
    password: str

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

# --- 🖼️ STATİK DOSYA VE CORS AYARLARI ---
UPLOAD_DIR = "uploads" 
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
BASE_URL = "http://192.168.1.29:8000" 

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
        password="12345",
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
            "INSERT INTO users (email, password_hash, university, department) VALUES (%s, %s, %s, %s)",
            (user.email, hashed_password, user.university, user.department)
        )
        conn.commit()
        cur.close()
        return {"status": "success"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()

# ... (Buradan sonraki /login, /books vb. tüm kodlarını altına yapıştırabilirsin)



        

@app.post("/login")
async def login(user: UserLogin):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT user_id, password_hash, university, department FROM users WHERE email = %s", (user.email,))
        result = cur.fetchone()

        if not result:
            raise HTTPException(status_code=401, detail="Hatalı giriş")

        user_id, stored_hash, university, department = result

        if not bcrypt.checkpw(user.password.encode('utf-8')[:72], stored_hash.encode('utf-8')):
            raise HTTPException(status_code=401, detail="Hatalı giriş")

        return {
            "status": "success",
            "user_id": user_id,
            "university": university,
            "department": department
        }
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
        cur.close()

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
            'callbackUrl': f'{BASE_URL}/payment-callback',
            'buyer': {
                'id': str(payment.user_id),
                'name': 'Merve',
                'surname': 'Bebook',
                'gsmNumber': '+905350000000',
                'email': 'test@email.com',
                'identityNumber': '11111111110',
                'city': 'Zonguldak',
                'country': 'Turkey',
                'zipCode': '67100',
                'registrationAddress': 'Universite Caddesi No:100 Incivez'
            },
            'shippingAddress': address_info, # 🔥 Teslimat Adresi Eklendi
            'billingAddress': address_info,  # 🔥 Fatura Adresi Eklendi
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
    token = form_data.get("token")
    retrieve_request = {'locale': 'tr', 'token': token}
    checkout_form = iyzipay.CheckoutForm().retrieve(retrieve_request, IYZICO_OPTIONS)
    result = json.loads(checkout_form.read().decode('utf-8'))

    order_id = result.get("conversationId") or result.get("basketId")
    payment_status = result.get("paymentStatus")

    conn = get_db_connection()
    try:
        cur = conn.cursor()
        status_db = "SUCCESS" if payment_status == "SUCCESS" else "FAILED"
        cur.execute("UPDATE orders SET status = %s WHERE order_id = %s", (status_db, int(order_id)))
        conn.commit()
        
        main_color = "#2ecc71" if status_db == "SUCCESS" else "#e74c3c"
        icon = "✔️" if status_db == "SUCCESS" else "❌"
        status_text = "Ödeme Başarılı!" if status_db == "SUCCESS" else "Ödeme Başarısız!"
    finally:
        conn.close()

    # payment_callback içindeki mevcut html_content kısmını silip bunu yapıştır:
    html_content = f"""
    <!DOCTYPE html>
    <html lang="tr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <title>Ödeme Sonucu</title>
    </head>
    <body style="display:flex; align-items:center; justify-content:center; height:100vh; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background:#f4f7f6; margin:0; padding: 20px; box-sizing: border-box;">
        <div style="text-align:center; padding:40px 20px; background:white; border-radius:24px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); width: 100%; max-width: 350px;">
            <div style="font-size:80px; margin-bottom: 20px;">{icon}</div>
            <h2 style="color:{main_color}; font-size:26px; margin: 0 0 10px 0;">{status_text}</h2>
            <p style="color:#666; font-size:16px; line-height: 1.5; margin-bottom: 30px;">
                İşleminiz başarıyla tamamlandı.<br>Uygulamaya güvenle dönebilirsiniz.
            </p>
            <button style="background:{main_color}; color:white; padding:16px; border:none; border-radius:16px; font-weight:bold; cursor:pointer; width:100%; font-size:16px; transition: opacity 0.2s;" 
                    onclick="window.close()">
                TAMAM
            </button>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)

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