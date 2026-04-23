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

app = FastAPI()

# --- AYARLAR VE KLASÖRLER ---
UPLOAD_DIR = "uploads" 
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
BASE_URL = "http://192.168.67.75:8000" 

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

# --- VERİ MODELLERİ ---
class UserSignup(BaseModel):
    email: str
    password: str
    university: str
    department: str

class UserLogin(BaseModel):
    email: str
    password: str

class BulkPaymentRequest(BaseModel):
    user_id: int
    book_ids: List[int]
    total_price: float

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

# --- KULLANICI İŞLEMLERİ ---
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

# --- İLAN (KİTAP) İŞLEMLERİ ---

@app.get("/books")
async def get_all_books():
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT book_id, user_id, title, author, category, price, description, image_path FROM public.books")
        books = cur.fetchall()
        
        result = []
        for b in books:
            image_url = f"{BASE_URL}/uploads/{b[7]}" if b[7] else None
            result.append({
                "book_id": b[0], "user_id": b[1], "title": b[2], "author": b[3],
                "category": b[4], "price": b[5], "description": b[6], "image_path": image_url
            })
        return result
    finally:
        conn.close()

@app.post("/books")
async def add_book(
    user_id: int = Form(...),
    title: str = Form(...),
    author: str = Form(...),
    category: str = Form(...),
    price: float = Form(...),
    description: str = Form(...),
    seller_email: str = Form(...),
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
            (user_id, title, author, category, price, description, seller_email, image_path) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (user_id, title, author, category, price, description, seller_email, image_name)
        )
        conn.commit()
        return {"status": "success", "message": "Kitap ve resim yüklendi!"}
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

@app.get("/my-books/{user_id}")
async def get_my_books(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT book_id, user_id, title, author, price, description, image_path, category
            FROM books WHERE user_id = %s
        """, (user_id,))
        books = cur.fetchall()

        result = []
        for b in books:
            image_url = f"{BASE_URL}/uploads/{b[6]}" if b[6] else None
            result.append({
                "book_id": b[0], "user_id": b[1], "title": b[2], "author": b[3], 
                "price": b[4], "description": b[5], "image_path": image_url, "category": b[7]
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
        conn.commit()
        return {"status": "success"}
    finally:
        conn.close()

# --- ÖDEME SİSTEMİ (DOKUNULMADI) ---

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
            'buyer': {
                'id': str(payment.user_id), 'name': 'Merve', 'surname': 'Bebook',
                'gsmNumber': '+905350000000', 'email': 'test@email.com', 'identityNumber': '11111111110',
                'city': 'Zonguldak', 'country': 'Turkey', 'zipCode': '67100', 'registrationAddress': 'ZBEU'
            },
            'shippingAddress': { 'contactName': 'Merve', 'city': 'Zonguldak', 'country': 'Turkey', 'address': 'Adres', 'zipCode': '67100' },
            'billingAddress': { 'contactName': 'Merve', 'city': 'Zonguldak', 'country': 'Turkey', 'address': 'Adres', 'zipCode': '67100' },
            'basketItems': [{'id': str(payment.book_id), 'name': 'Kitap', 'category1': 'Egitim', 'itemType': 'PHYSICAL', 'price': str(payment.price)}]
        }
        checkout_form_initialize = iyzipay.CheckoutFormInitialize().create(request_data, IYZICO_OPTIONS)
        return json.loads(checkout_form_initialize.read().decode('utf-8'))
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        cur.close()
        conn.close()

@app.post("/payment-callback")
async def payment_callback(request: Request):
    form_data = await request.form()
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