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
from typing import List
import smtplib
import random
import string
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import bcrypt
from datetime import datetime
from fastapi import UploadFile, File

otp_storage = {}

from typing import List, Optional

# ============================================
# 1. APP OLUŞTURMA
# ============================================
app = FastAPI()
from fastapi.staticfiles import StaticFiles

# directory kısmına "uploads/profiles" yazıyoruz
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
# --- AYARLAR VE KLASÖRLER ---
UPLOAD_DIR = "uploads" 
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
BASE_URL = "http://192.168.67.144:8000" 

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
    print("DB CONNECT OK")
    print(conn.get_dsn_parameters())

    return conn

# --- IYZICO AYARLARI ---
IYZICO_OPTIONS = {
    'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
    'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
    'base_url': 'sandbox-api.iyzipay.com'
}

# --- VERİ MODELLERİ ---
# ============================================
# 2. PYDANTIC MODELLERİ (Tüm modeller burada)
# ============================================
class UserSignup(BaseModel):
    full_name: str
    email: str
    password: str
    university: str
    department: str
    profile_image_path: str | None = None

class UserLogin(BaseModel):
    email: str
    password: str

class BulkPaymentRequest(BaseModel):
    user_id: int
    book_ids: List[int]
    total_price: float
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

# --- KULLANICI İŞLEMLERİ ---
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

        # 1. full_name'i hem sütun listesine hem de %s olarak VALUES'a ekledik
        cur.execute(
            "INSERT INTO public.users (full_name, email, password_hash, university, department) VALUES (%s, %s, %s, %s, %s)",
            (user.full_name, user.email, hashed_password, user.university, user.department)
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
        # 1. Sorguya profile_image_path sütununu ekledik
        cur.execute("SELECT user_id, password_hash, university, department, profile_image_path FROM public.users WHERE email = %s", (user.email,))
        cur.execute("SELECT user_id, password_hash, university, department FROM public.users WHERE email = %s", (user.email,))
        result = cur.fetchone()

        if not result:
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")

        # 2. Sonucu yeni değişkene parçalıyoruz
        user_id, stored_hash, university, department, profile_image_path = result
        
        if bcrypt.checkpw(user.password.encode('utf-8')[:72], stored_hash.encode('utf-8')):
            return {
                "status": "success",
                "user_id": user_id,
                "user_email": user.email,
                "university": university,
                "department": department,
                "profile_image_path": profile_image_path  # 3. Flutter'a bu bilgiyi gönderiyoruz
            }
        else:
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")
    finally:
        conn.close()

# --- İLAN (KİTAP) İŞLEMLERİ ---

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
            image_url = f"{BASE_URL}/uploads/{b[7]}" if b[7] else None
            result.append({
                "book_id": b[0], "user_id": b[1], "title": b[2], "author": b[3],
                "category": b[4], "price": b[5], "description": b[6], "image_path": image_url
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
    file: UploadFile = File(None) 
    publisher: str = Form(""),
    file: UploadFile = File(None)
):
    conn = None
    image_name = None
    try:
        if file:
            ext = file.filename.split('.')[-1]
            image_name = f"{uuid.uuid4()}.{ext}"
            file_path = os.path.join(UPLOAD_DIR, image_name)
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO public.books 
            (title, author, category, price, description, seller_email, publisher, image_path) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (title, author, category, price, description, seller_email, publisher, image_name)
        )
        conn.commit()
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
        cur.execute("""
            SELECT book_id, user_id, title, author, price, description, image_path, category
            FROM books WHERE user_id = %s
        """, (user_id,))
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
            image_url = f"{BASE_URL}/uploads/{b[6]}" if b[6] else None
            result.append({
                "book_id": b[0], "user_id": b[1], "title": b[2], "author": b[3], 
                "price": b[4], "description": b[5], "image_path": image_url, "category": b[7]
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

# --- ÖDEME SİSTEMİ (DOKUNULMADI) ---

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
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO orders (user_id, book_id, price, status) VALUES (%s, %s, %s, %s) RETURNING order_id",
            (payment.user_id, payment.book_id, payment.price, "PENDING")
        )
        order_id = cur.fetchone()[0]
        conn.commit()

        request_data = {
            'locale': 'tr', 'conversationId': str(order_id), 'price': str(payment.price),
            'paidPrice': str(payment.price), 'currency': 'TRY', 'basketId': str(order_id),
            'paymentGroup': 'PRODUCT', 'callbackUrl': f'{BASE_URL}/payment-callback',
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
                'id': str(payment.user_id), 'name': 'Merve', 'surname': 'Bebook',
                'gsmNumber': '+905350000000', 'email': 'test@email.com', 'identityNumber': '11111111110',
                'city': 'Zonguldak', 'country': 'Turkey', 'zipCode': '67100', 'registrationAddress': 'ZBEU'
            },
            'shippingAddress': { 'contactName': 'Merve', 'city': 'Zonguldak', 'country': 'Turkey', 'address': 'Adres', 'zipCode': '67100' },
            'billingAddress': { 'contactName': 'Merve', 'city': 'Zonguldak', 'country': 'Turkey', 'address': 'Adres', 'zipCode': '67100' },
            'basketItems': [{'id': str(payment.book_id), 'name': 'Kitap', 'category1': 'Egitim', 'itemType': 'PHYSICAL', 'price': str(payment.price)}]
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
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        cur.close()
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
    token = form_data.get('token')

    if not token:
        return HTMLResponse(content="Token yok", status_code=400)

    iyzico_request = {'token': token}
    checkout_form_result = iyzipay.CheckoutForm().retrieve(iyzico_request, IYZICO_OPTIONS)
    result = json.loads(checkout_form_result.read().decode('utf-8'))

    payment_status = result.get('paymentStatus') 
    order_id = result.get('conversationId')      

    if payment_status == 'SUCCESS':
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("UPDATE orders SET status = 'SUCCESS' WHERE order_id = %s", (order_id,))
        conn.commit()
        conn.close()
        status_text, main_color = "Ödeme Başarılı!", "#2ecc71"
    else:
        status_text, main_color = "Ödeme Başarısız", "#e74c3c"

    html_content = f"<html><body style='text-align:center;padding-top:50px;'><h1 style='color:{main_color}'>{status_text}</h1><a href='bebook://home'>ANA SAYFAYA DÖN</a></body></html>"
    return HTMLResponse(content=html_content)

@app.get("/order-status/{order_id}")
async def get_order_status(order_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT status FROM orders WHERE order_id = %s", (order_id,))
        result = cur.fetchone()
        if result:
            return {"status": result[0]}
        raise HTTPException(status_code=404, detail="Sipariş bulunamadı")
    finally:
        conn.close()

@app.post("/contact")
async def contact(req: ContactRequest):
    return {"status": "success", "message": "Mesajınız iletildi."}
# Rastgele 6 haneli kod üretme
def generate_otp():
    # random.choices olarak kullanman daha güvenlidir
    return ''.join(random.choices(string.digits, k=6))
# SADECE BU KALSIN, DİĞER FORGOT-PASSWORD'LARI SİL
@app.post("/forgot-password")
async def forgot_password(data: dict):
    try:
        email = data.get("email")
        if not email:
            return {"status": "error", "message": "Email adresi eksik"}
            
        # 1. Kod üret
        otp = generate_otp()
        
        # 2. Kodu hafızaya kaydet (Verify aşaması için)
        otp_storage[email] = otp 
        
        print(f"Email: {email}, OTP: {otp}") # Terminalden takip et
        
        # 3. GERÇEK Mail gönderme fonksiyonunu çağır
        success = send_otp_email(email, otp) 
        
        if success:
            return {"status": "success", "message": "Kod gönderildi"}
        else:
            return {"status": "error", "message": "Mail gönderimi başarısız. Lütfen terminali kontrol edin."}
            
    except Exception as e:
        print(f"Sistem Hatası: {str(e)}")
        return {"status": "error", "message": str(e)}
    
    #bhib ibgw lyjd rtsf

# E-posta gönderme fonksiyonu
# 1. Önce yardımcı fonksiyon kalsın
def generate_otp():
    return ''.join(random.choices(string.digits, k=6))

# 2. Mail gönderme fonksiyonu (Burası doğru)
def send_otp_email(receiver_email, otp_code):
    sender_email = "merveyilmazz0703@gmail.com" 
    password = "bhib ibgw lyjd rtsf" 
    
    subject = "BEBOOK Dogrulama Kodu"
    body = f"Merhaba,\n\nSifrenizi sifirlamak icin kullanmaniz gereken kod: {otp_code}"
    email_text = f"Subject: {subject}\n\n{body}"
    
    try:
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        server.login(sender_email, password.replace(" ", ""))
        server.sendmail(sender_email, receiver_email, email_text.encode('utf-8'))
        server.quit()
        print(f"!!! DOĞRULAMA KODU GÖNDERİLDİ: {otp_code} !!!")
        return True
    except Exception as e:
        print(f"MAİL HATASI: {e}")
        return False

# 3. TEK BİR endpoint olarak forgot-password (Bunu kullan, diğerlerini sil)
@app.post("/forgot-password")
async def forgot_password(data: dict):
    try:
        email = data.get("email")
        if not email:
            return {"status": "error", "message": "Email adresi eksik"}
            
        otp = generate_otp()
        
        # BU SATIR ÇOK ÖNEMLİ: Kodu hafızaya alıyoruz ki verify-otp çalışabilsin
        otp_storage[email] = otp 
        
        print(f"Email: {email}, OTP: {otp}") 
        
        success = send_otp_email(email, otp) 
        
        if success:
            return {"status": "success", "message": "Kod gönderildi"}
        else:
            return {"status": "error", "message": "Mail gönderimi başarısız"}
            
    except Exception as e:
        print(f"Sistem Hatası: {str(e)}")
        return {"status": "error", "message": str(e)}
@app.post("/verify-otp")
async def verify_otp(data: dict):
    # Terminale bu yazı düşecek mi bakacağız
    print("!!! DOĞRULAMA İSTEĞİ GELDİ !!!")
    print(f"Gelen Veri: {data}")
    
    email = str(data.get("email")).strip().lower()
    user_otp = str(data.get("otp")).strip()

    # Eğer e-posta hafızada varsa ve kod doğruysa direkt onay ver
    if email in otp_storage and str(otp_storage[email]) == user_otp:
        return {"status": "success", "message": "Kod doğrulandı"}
    
    # Hata durumunda terminale detay yazdıralım
    print(f"Hata detayı -> Hafızadaki: {otp_storage.get(email)}, Girilen: {user_otp}")
    return {"status": "error", "message": "Kod eşleşmedi!"}


@app.post("/reset-password")
async def reset_password(data: dict):
    conn = None
    try:
        email = str(data.get("email")).strip().lower()
        new_password = data.get("password")

        # 1. Şifreyi Bcrypt ile şifreliyoruz (Hashleme)
        # Login fonksiyonunun okuyabileceği formata getiriyoruz
        hashed_password = bcrypt.hashpw(
            new_password.encode('utf-8'), 
            bcrypt.gensalt()
        ).decode('utf-8')

        conn = get_db_connection()
        cursor = conn.cursor()

        # 2. SQL Sorgusu (password_hash sütununa şifrelenmiş halini yazıyoruz)
        query = 'UPDATE users SET password_hash = %s WHERE email = %s'
        
        cursor.execute(query, (hashed_password, email))
        conn.commit()

        if cursor.rowcount == 0:
            return {"status": "error", "message": "Kullanıcı bulunamadı."}

        cursor.close()
        print(f"BAŞARILI: {email} şifresi şifrelenerek güncellendi.")
        return {"status": "success", "message": "Şifreniz başarıyla güncellendi."}

    except Exception as e:
        print(f"Sıfırlama Hatası: {e}")
        return {"status": "error", "message": "Sistem hatası oluştu."}
    finally:
        if conn:
            conn.close()

    # Mesaj göndermek için gerekli veri modeli
class MessageCreate(BaseModel):
    sender_id: int
    receiver_id: int
    book_id: int
    message_text: str

@app.get("/chats/{my_id}")
async def get_chat_list(my_id: int):
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
    cursor = conn.cursor()
    try:
        # Bu sorgu hem sohbet listesini getirir hem de okunmamışları sayar (Gerekli tüm alanlar eklendi)
        query = """
        SELECT DISTINCT ON (m.book_id, LEAST(m.sender_id, m.receiver_id), GREATEST(m.sender_id, m.receiver_id))
            m.sender_id, 
            m.receiver_id, 
            m.message_text, 
            m.book_id, 
            m.created_at,
            u.email, 
            b.title,
            u.profile_image_path,
            u.full_name,
            (SELECT COUNT(*) FROM usermessages 
             WHERE receiver_id = %s 
             AND sender_id = (CASE WHEN m.sender_id = %s THEN m.receiver_id ELSE m.sender_id END) 
             AND book_id = m.book_id 
             AND is_read = FALSE) as unread_count
        FROM usermessages m
        LEFT JOIN users u ON (CASE WHEN m.sender_id = %s THEN m.receiver_id = u.user_id ELSE m.sender_id = u.user_id END)
        LEFT JOIN books b ON m.book_id = b.book_id
        WHERE m.sender_id = %s OR m.receiver_id = %s
        ORDER BY m.book_id, LEAST(m.sender_id, m.receiver_id), GREATEST(m.sender_id, m.receiver_id), m.created_at DESC
        """
        
        # 5 tane %s için 5 adet my_id gönderiyoruz
        cursor.execute(query, (my_id, my_id, my_id, my_id, my_id))
        rows = cursor.fetchall()
        
        # Tarihe göre sıralama (En yeni mesaj en üstte)
        from datetime import datetime
        rows = sorted(rows, key=lambda x: x[4] if x[4] else datetime.min, reverse=True)
        
        chats = []
        for row in rows:
            other_id = row[1] if row[0] == my_id else row[0]
            chats.append({
                "receiver_id": other_id,
                "receiver_name": row[8] if row[8] else row[5], # full_name varsa onu, yoksa email'i kullanır
                "full_name": row[8],
                "book_title": row[6] if row[6] else f"Kitap #{row[3]}",
                "book_id": row[3],
                "last_message": row[2],
                "profile_image": row[7],
                "unread_count": row[9] # Flutter'daki yuvarlak için gereken kritik veri
            })
        return chats

    except Exception as e:
        print(f"Sohbet Listesi Hatası: {e}")
        return []
    finally:
        if cursor: cursor.close()
        if conn: conn.close()
# Fotoğrafların kaydedileceği klasörü oluştur (yoksa)
UPLOAD_DIR = "uploads/profiles"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/user/upload_profile_photo/{user_id}")
async def upload_profile_photo(user_id: int, file: UploadFile = File(...)):
    conn = get_db_connection()
    try:
        # Klasör ve dosya adı işlemleri (Burayı zaten başardın)
        file_extension = file.filename.split(".")[-1]
        file_name = f"profile_{user_id}.{file_extension}"
        file_path = os.path.join(UPLOAD_DIR, file_name)

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # --- SORUN BURADA OLABİLİR ---
        cur = conn.cursor()
        # Dikkat: Tablo adın 'public.users' ise öyle yaz, sadece 'users' ise öyle kalsın.
        # Sütun adının veritabanındakiyle (profile_image_path) tam aynı olduğundan emin ol.
        query = "UPDATE public.users SET profile_image_path = %s WHERE user_id = %s"
        
        # Log atalım ki terminalde görelim ne gönderdiğimizi
        print(f"Güncelleniyor: User: {user_id}, Path: {file_path}")
        
        cur.execute(query, (file_path, user_id))
        
        # BU SATIR ÇOK KRİTİK! Commit yapmazsan veritabanına yazmaz.
        conn.commit() 

        return {"status": "success", "image_url": file_path}
    except Exception as e:
        print(f"Hata detayı: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        conn.close()    
@app.delete("/chats/delete")
async def delete_chat(my_id: int, other_id: int, book_id: int):
    conn = get_db_connection()
    cursor = None
    try:
        cursor = conn.cursor()
        # Karşılıklı tüm mesajları siliyoruz
        query = """
        DELETE FROM usermessages 
        WHERE book_id = %s 
        AND (
            (sender_id = %s AND receiver_id = %s) OR 
            (sender_id = %s AND receiver_id = %s)
        )
        """
        cursor.execute(query, (book_id, my_id, other_id, other_id, my_id))
        conn.commit()
        return {"message": "Sohbet başarıyla silindi"}
    except Exception as e:
        print(f"Silme hatası: {e}")
        raise HTTPException(status_code=500, detail="Sohbet silinemedi")
    finally:
        if cursor: cursor.close()
        if conn: conn.close()         
         
# BU FONKSİYONUN EKSİK OLMASI 404 HATASINA VE MESAJLARIN KAYBOLMASINA NEDEN OLUYOR
@app.get("/messages/{sender_id}/{receiver_id}/{book_id}")
async def get_messages_with_book(sender_id: int, receiver_id: int, book_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
            -- 1. ADIM: SELECT kısmına is_delivered sütununu ekliyoruz
            SELECT sender_id, receiver_id, message_text, created_at, is_read, is_delivered 
            FROM usermessages 
            WHERE ((sender_id = %s AND receiver_id = %s) OR (sender_id = %s AND receiver_id = %s))
            AND book_id = %s
            ORDER BY created_at ASC
        """
        cursor.execute(query, (sender_id, receiver_id, receiver_id, sender_id, book_id))
        messages = cursor.fetchall()
        
        result = []
        for m in messages:
            result.append({
                "sender_id": m[0],
                "receiver_id": m[1],
                "message_text": m[2],
                "created_at": m[3].isoformat() if m[3] else None,
                "is_read": m[4],
                "is_delivered": m[5]  # <-- 2. ADIM: Flutter'a bu bilgiyi de gönderiyoruz
            })
        return result
    except Exception as e:
        print(f"Hata: {e}")
        return []
        cur.execute("SELECT status FROM orders WHERE order_id = %s", (order_id,))
        result = cur.fetchone()
        if result:
            return {"status": result[0]}
        else:
            raise HTTPException(status_code=404, detail="Sipariş bulunamadı")
    finally:
        cursor.close()
        conn.close()
        
@app.post("/messages/send")
async def send_message_fixed(data: dict):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        sender_id = data.get("sender_id")
        receiver_id = data.get("receiver_id")
        book_id = data.get("book_id")
        message_text = data.get("message_text")

        query = """
            INSERT INTO usermessages (sender_id, receiver_id, book_id, message_text, is_read) 
            VALUES (%s, %s, %s, %s, FALSE)
        """
        cursor.execute(query, (sender_id, receiver_id, book_id, message_text))
        conn.commit()
        return {"status": "success"}
    except Exception as e:
        print(f"Mesaj Kayıt Hatası: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        cursor.close()
        conn.close()        
@app.post("/mark_messages_as_read")
async def mark_messages_as_read(receiver_id: int, sender_id: int, book_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Bana gelen mesajları okundu olarak işaretle
        query = """
        UPDATE usermessages 
        SET is_read = TRUE 
        WHERE receiver_id = %s AND sender_id = %s AND book_id = %s AND is_read = FALSE
        """
        cursor.execute(query, (receiver_id, sender_id, book_id))
        conn.commit()
        return {"status": "success", "message": "Mesajlar okundu olarak işaretlendi"}
    except Exception as e:
        print(f"Okundu işaretleme hatası: {e}")
        return {"status": "error"}
    finally:
        cursor.close()
        conn.close()        
@app.put("/mark_as_delivered/{receiver_id}")
async def mark_as_delivered(receiver_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Sorgu: Alıcısı bu kişi olan ve okunmamış tüm mesajları 'iletildi' yap
        query = """
            UPDATE usermessages 
            SET is_delivered = TRUE 
            WHERE receiver_id = %s AND is_delivered = FALSE
        """
        cursor.execute(query, (receiver_id,))
        conn.commit()
        
        print(f"Bilgi: {receiver_id} ID'li kullanıcı için mesajlar iletildi olarak işaretlendi.")
        return {"status": "success", "message": "Mesajlar iletildi yapıldı"}
    except Exception as e:
        print(f"Hata oluştu: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        cursor.close()
        conn.close()        
# --- SEPET İŞLEMLERİ ---

# --- SEPETİ GETİRME ---
@app.get("/cart/{user_id}")
async def get_cart(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT b.book_id, b.title, b.author, b.price, b.image_path
            FROM public.cart c
            JOIN public.books b ON c.book_id = b.book_id
            WHERE c.user_id = %s
        """
        cur.execute(query, (user_id,))
        items = cur.fetchall()
        
        result = []
        for item in items:
            # Flutter tarafı 'imageUrl' beklediği için anahtarı değiştirdik
            result.append({
                "book_id": item[0], 
                "title": item[1], 
                "author": item[2], 
                "price": float(item[3]), # Decimal hatası almamak için float'a çevirdik
                "imageUrl": item[4]      # image_path yerine imageUrl yaparsan Flutter direkt tanır
            })
        return result
    finally:
        conn.close()

# --- SEPETE EKLEME ---
# --- SEPETE EKLEME (GÜNCEL) ---
@app.post("/add-to-cart")
async def add_to_cart(data: dict):
    print(f"\n--- 📥 YENİ SEPET İSTEĞİ GELDİ ---")
    print(f"Gelen Ham Veri: {data}")

    # Tip dönüşümü güvenli şekilde
    try:
        user_id = int(data.get("user_id"))
        book_id = int(data.get("book_id"))
    except (TypeError, ValueError):
        print("❌ HATA: user_id veya book_id sayıya çevrilemedi!")
        return {"status": "error", "message": "Geçersiz veri tipi"}


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

        # 🔍 Ürün zaten var mı kontrol et
        cur.execute(
            "SELECT 1 FROM public.cart WHERE user_id = %s AND book_id = %s",
            (user_id, book_id)
        )

        if cur.fetchone():
            print("ℹ️ Ürün zaten sepette")
            return {"status": "exists", "message": "Zaten sepette"}

        # ➕ Sepete ekle
        cur.execute(
            "INSERT INTO public.cart (user_id, book_id) VALUES (%s, %s)",
            (user_id, book_id)
        )

        conn.commit()

        print(f"✅ BAŞARILI: Kullanıcı {user_id}, Kitap {book_id} eklendi.")
        return {"status": "success"}

    except Exception as e:
        print(f"❌ VERİTABANI HATASI: {str(e)}")
        return {"status": "error", "message": str(e)}

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
        cur.close()
        conn.close()
@app.delete("/remove-from-cart/{user_id}/{book_id}")
async def remove_from_cart(user_id: int, book_id: int):

@app.get("/favorites/check/{user_id}/{book_id}")
async def check_favorite(user_id: int, book_id: int):
    """Bir kitabın favorilerde olup olmadığını kontrol et"""
    conn = get_db_connection()
    cur = None
    try:
        cur = conn.cursor()

        cur.execute(
            "DELETE FROM cart WHERE user_id = %s AND book_id = %s",
            (user_id, book_id)
        )

        conn.commit()
        return {"status": "success", "message": "Ürün sepetten çıkarıldı"}

    except Exception as e:
        print(f"Hata: {e}")
        return {"status": "error", "message": str(e)}

    finally:
        if cur:
            cur.close()
        conn.close()      
        cur.execute(
            "SELECT id FROM public.favorites WHERE user_id = %s AND book_id = %s",
            (user_id, book_id)
        )
        exists = cur.fetchone() is not None
        return {"is_favorite": exists}
    finally:
        conn.close()
