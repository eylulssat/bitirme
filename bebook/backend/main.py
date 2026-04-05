from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, EmailStr
import psycopg2
import bcrypt
from fastapi.middleware.cors import CORSMiddleware
import iyzipay
import json
from typing import Optional

app = FastAPI()

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

# --- GİRİŞ YAPMA (LOGIN) ---
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

        request_data = {
            'locale': 'tr',
            'conversationId': str(order_id),
            'price': str(payment.price),
            'paidPrice': str(payment.price),
            'currency': 'TRY',
            'basketId': str(order_id),
            'paymentGroup': 'PRODUCT',
            'callbackUrl': 'http://192.168.67.158:8000/payment-callback',
            'buyer': {
                'id': str(payment.user_id),
                'name': 'Eylul',
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
            'shippingAddress': {'contactName': 'Eylul Bebook', 'city': 'Istanbul', 'country': 'Turkey', 'address': 'Adres', 'zipCode': '34732'},
            'billingAddress': {'contactName': 'Eylul Bebook', 'city': 'Istanbul', 'country': 'Turkey', 'address': 'Adres', 'zipCode': '34732'},
            'basketItems': [
                {'id': str(payment.book_id), 'name': 'Kitap', 'category1': 'Egitim', 'itemType': 'PHYSICAL', 'price': str(payment.price)}
            ]
        }

        checkout_form_initialize = iyzipay.CheckoutFormInitialize().create(request_data, IYZICO_OPTIONS)
        return json.loads(checkout_form_initialize.read().decode('utf-8'))
    finally:
        conn.close()

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
        cur.execute("UPDATE public.books SET title = %s, price = %s, description = %s WHERE book_id = %s AND user_id = %s", 
                    (book.title, book.price, book.description, book.book_id, book.user_id))
        conn.commit()
        return {"status": "success", "message": "İlan güncellendi"}
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