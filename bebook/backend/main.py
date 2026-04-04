from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
import psycopg2
import bcrypt
from fastapi.middleware.cors import CORSMiddleware
import uuid
import iyzipay
import json

app = FastAPI()

# --- CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- DATABASE ---
def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="bebook",
        user="postgres",
        password="12345",
        port="5432"
    ) # Parantez burada kapalı olmalı

# --- IYZICO OPTIONS ---
IYZICO_OPTIONS = {
    'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
    'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
    'base_url': 'sandbox-api.iyzipay.com'
}

# --- MODELS ---
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

# --- SIGNUP ---
class ContactRequest(BaseModel):
    full_name: str
    email: str
    message: str

# --- KAYIT OLMA (SIGNUP) ---
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

# --- LOGIN ---
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

# --- CREATE PAYMENT ---
@app.post("/create-payment")
async def create_payment(payment: CreatePayment):

    conn = get_db_connection()
    try:
        cur = conn.cursor()

        # Order oluştur
        cur.execute(
            "INSERT INTO orders (user_id, book_id, price, status) VALUES (%s, %s, %s, %s) RETURNING order_id",
            (payment.user_id, payment.book_id, payment.price, "PENDING")
        )
        order_id = cur.fetchone()[0]
        conn.commit()
        cur.close()

        request_data = {
            'locale': 'tr',
            'conversationId': str(order_id),  # ÖNEMLİ
            'price': str(payment.price),
            'paidPrice': str(payment.price),
            'currency': 'TRY',
            'basketId': str(order_id),
            'paymentGroup': 'PRODUCT',
            'callbackUrl': 'http://192.168.1.29:8000/payment-callback',
            'buyer': {
                'id': str(payment.user_id),
                'name': 'Merve',
                'surname': 'Bebook',
                'gsmNumber': '+905350000000',
                'email': 'test@email.com',
                'identityNumber': '11111111110',
                'lastLoginDate': '2023-10-05 12:43:35',
                'registrationDate': '2023-10-05 12:43:35',
                'registrationAddress': 'Adres',
                'ip': '127.0.0.1',
                'city': 'Istanbul',
                'country': 'Turkey',
                'zipCode': '34732'
            },
            'shippingAddress': {
                'contactName': 'Merve Bebook',
                'city': 'Istanbul',
                'country': 'Turkey',
                'address': 'Adres',
                'zipCode': '34732'
            },
            'billingAddress': {
                'contactName': 'Merve Bebook',
                'city': 'Istanbul',
                'country': 'Turkey',
                'address': 'Adres',
                'zipCode': '34732'
            },
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
        response = checkout_form_initialize.read().decode('utf-8')

        print("IYZICO INIT RESPONSE:", response)

        return json.loads(response)

    finally:
        conn.close()

# --- PAYMENT CALLBACK ---
@app.post("/payment-callback")
async def payment_callback(request: Request):

    form_data = await request.form()
    token = form_data.get("token")

    print("🔥 CALLBACK TOKEN:", token)

    retrieve_request = {
        'locale': 'tr',
        'conversationId': '0',  # Önemli değil burada
        'token': token
    }

    checkout_form = iyzipay.CheckoutForm().retrieve(retrieve_request, IYZICO_OPTIONS)
    result = json.loads(checkout_form.read().decode('utf-8'))

    print("🔥 IYZICO SONUÇ:", result)

    order_id = result.get("conversationId")
    payment_status = result.get("paymentStatus")

    conn = get_db_connection()
    try:
        cur = conn.cursor()

        if payment_status == "SUCCESS":
            cur.execute("UPDATE orders SET status = %s WHERE order_id = %s",
                        ("SUCCESS", order_id))
        
        if result is None:
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")
            
        stored_hash = result[0]
        university = result[1]
        department = result[2]
        
        user_password_bytes = user.password.encode('utf-8')[:72]
        if bcrypt.checkpw(user_password_bytes, stored_hash.encode('utf-8')):
            return {
                "status": "success",
                "user_email": user.email,
                "university": university,
                "department": department
            }
        else:
            cur.execute("UPDATE orders SET status = %s WHERE order_id = %s",
                        ("FAILED", order_id))

        conn.commit()
        cur.close()
    finally:
        conn.close()

    return {"status": payment_status}

@app.get("/order-status/{order_id}")
async def order_status(order_id: int):

    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT status FROM orders WHERE order_id = %s", (order_id,))
        result = cur.fetchone()
        cur.close()

        if not result:
            return {"status": "NOT_FOUND"}

        return {"status": result[0]}

    finally:
        conn.close()

@app.put("/update-book")
async def update_book(book: UpdateBook):
    conn = get_db_connection()
    try:
        cur = conn.cursor()

        # Güvenlik: sadece kendi ilanını güncelleyebilsin
        cur.execute(
            "SELECT user_id FROM books WHERE book_id = %s",
            (book.book_id,)
        )
        result = cur.fetchone()

        if not result:
            raise HTTPException(status_code=404, detail="İlan bulunamadı")

        if result[0] != book.user_id:
            raise HTTPException(status_code=403, detail="Yetkisiz işlem")

        # Güncelle
        cur.execute("""
            UPDATE books
            SET title = %s, price = %s, description = %s
            WHERE book_id = %s
        """, (book.title, book.price, book.description, book.book_id))
        print("GELEN BOOK ID:", book.book_id)
        print("GELEN USER ID:", book.user_id)
        print("GÜNCELLENEN SATIR:", cur.rowcount)
        

        conn.commit()
        cur.close()

        return {"status": "success", "message": "İlan güncellendi"}

    finally:
        conn.close()        

@app.delete("/delete-book/{book_id}/{user_id}")
async def delete_book(book_id: int, user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()

        # Yetki kontrolü
        cur.execute(
            "SELECT user_id FROM books WHERE book_id = %s",
            (book_id,)
        )
        result = cur.fetchone()

        if not result:
            raise HTTPException(status_code=404, detail="İlan bulunamadı")

        if result[0] != user_id:
            raise HTTPException(status_code=403, detail="Yetkisiz işlem")

        cur.execute("DELETE FROM books WHERE book_id = %s", (book_id,))
        conn.commit()
        cur.close()

        return {"status": "success", "message": "İlan silindi"}

    finally:
        conn.close()    
@app.get("/my-books/{user_id}")
async def get_my_books(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()

        cur.execute("""
            SELECT book_id, user_id, title, price, description
            FROM books
            WHERE user_id = %s
        """, (user_id,))

        books = cur.fetchall()

        result = []
        for b in books:
            result.append({
                "book_id": b[0],
                "user_id": b[1],
                "title": b[2],
                "price": b[3],
                "description": b[4],
            })

        return result

    finally:
        conn.close()            
        if conn:
            conn.close()

# --- İLETİŞİM MESAJI (CONTACT) ---
@app.post("/contact")
async def send_contact_message(request: ContactRequest):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # public. şemasıyla tam yol gösteriyoruz
        cur.execute(
            "INSERT INTO public.contact_messages (full_name, email, message) VALUES (%s, %s, %s)",
            (request.full_name, request.email, request.message)
        )
        
        conn.commit()
        cur.close()
        return {"status": "success", "message": "Mesajınız başarıyla iletildi!"}
    
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"İletişim Hatası: {e}")
        raise HTTPException(status_code=500, detail="Mesaj gönderilirken bir hata oluştu.")
    finally:
        if conn:
            conn.close()

            # --- KİTAP EKLEME MODELİ ---
class BookCreate(BaseModel):
    title: str
    author: str
    category: str
    price: float
    description: str
    seller_email: str
    image_path: str = None # Fotoğraf yolu şimdilik boş olabilir

# --- KİTAP YÜKLEME ENDPOINT'İ (ADD BOOK) ---
@app.post("/books")
async def add_book(book: BookCreate):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Hazırladığımız public.books tablosuna verileri gönderiyoruz
        cur.execute(
            """INSERT INTO public.books 
            (title, author, category, price, description, seller_email, image_path) 
            VALUES (%s, %s, %s, %s, %s, %s, %s)""",
            (book.title, book.author, book.category, book.price, 
             book.description, book.seller_email, book.image_path)
        )
        
        conn.commit()
        cur.close()
        return {"status": "success", "message": "Kitap ilanı başarıyla oluşturuldu!"}
    
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"Kitap Ekleme Hatası: {e}")
        raise HTTPException(status_code=500, detail="Kitap eklenirken bir hata oluştu.")
    finally:
        if conn:
            conn.close()
