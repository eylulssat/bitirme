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

app = FastAPI()

# --- 🖼️ STATİK DOSYA SERVİSİ (RESİMLER İÇİN) ---
UPLOAD_DIR = "uploads" 
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

# Flutter'ın resimlere erişebilmesi için bu satır kritik
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# --- KENDİ IP ADRESİN ---
BASE_URL = "http://192.168.1.29:8000" 

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
        password="12345",
        port="5432"
    )

# --- IYZICO AYARLARI ---
IYZICO_OPTIONS = {
    'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
    'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
    'base_url': 'sandbox-api.iyzipay.com'
}

# --- PYDANTIC MODELLERİ (JSON Gelen İstekler İçin) ---
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

# --- ENDPOINTS ---

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
                'zipCode': '67100'
            },
            'basketItems': [{'id': str(payment.book_id), 'name': 'Kitap', 'category1': 'Egitim', 'itemType': 'PHYSICAL', 'price': str(payment.price)}]
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

    html_content = f"""
    <html>
        <body style="display:flex; align-items:center; justify-content:center; height:100vh; font-family:sans-serif; background:#f4f7f6;">
            <div style="text-align:center; padding:50px; background:white; border-radius:30px; box-shadow: 0 15px 35px rgba(0,0,0,0.1);">
                <div style="font-size:80px;">{icon}</div>
                <h2 style="color:{main_color}; font-size:30px;">{status_text}</h2>
                <p style="color:#777;">Uygulamaya dönebilirsiniz.</p>
                <button style="background:{main_color}; color:white; padding:12px 25px; border:none; border-radius:15px; font-weight:bold; cursor:pointer; margin-top:20px;" onclick="window.close()">TAMAM</button>
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