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


UPLOAD_DIR = "uploads" 
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
BASE_URL = "http://192.168.67.42:8000" 

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="bebook",
        user="postgres",
        password="12345",
        port="5432"
    )


IYZICO_OPTIONS = {
    'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
    'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
    'base_url': 'sandbox-api.iyzipay.com'
}


@app.post("/bulk-payment")
async def bulk_payment(request: BulkPaymentRequest):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        
        first_book_id = request.book_ids[0] if request.book_ids else None

        cur.execute(
            "INSERT INTO orders (user_id, book_id, price, status) VALUES (%s, %s, %s, %s) RETURNING order_id",
            (request.user_id, first_book_id, request.total_price, "PENDING")
        )
        order_id = cur.fetchone()[0]
        conn.commit()

        
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
        
        return json.loads(checkout_form_initialize.read().decode('utf-8'))

    except Exception as e:
        print(f"İyzipay Hatası: {e}")
        return {"status": "failure", "errorMessage": str(e)}
    finally:
        conn.close()



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
                "author": b[3], 
                "price": b[4],
                "description": b[5],
                "image_path": image_url
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
    token = form_data.get('token') 

    if not token:
        return HTMLResponse(content="Geçersiz istek (Token yok)", status_code=400)

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
        description = "İşleminiz başarıyla tamamlandı. Diğer ilanları incelemek için ana sayfaya dönebilirsiniz.!"
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