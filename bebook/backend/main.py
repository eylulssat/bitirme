from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
import bcrypt
from fastapi.middleware.cors import CORSMiddleware
import requests
import uuid
import iyzipay

app = FastAPI()

# --- CORS AYARI ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Web’den erişim için
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- VERİTABANI BAĞLANTISI ---
def get_db_connection():
    return psycopg2.connect(
        host="localhost",     # Backend’in çalıştığı PC IP’si LAN’da ise onu kullan
        database="bebook",
        user="postgres",
        password="12345",  
        port="5432"
    )

# --- MODELLER ---
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

# --- KAYIT OLMA ---
@app.post("/signup")
async def signup(user: UserSignup):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Şifre hashleme
        password_bytes = user.password.encode('utf-8')[:72]
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')
        
        cur.execute(
            "INSERT INTO users (email, password_hash, university, department) VALUES (%s, %s, %s, %s)",
            (user.email, hashed_password, user.university, user.department)
        )
        conn.commit()
        cur.close()
        return {"status": "success", "message": "Kullanıcı başarıyla kaydedildi!"}
    
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"[SIGNUP ERROR] {e}")
        raise HTTPException(status_code=400, detail="Bu e-posta zaten kayıtlı veya veri tabanı hatası.")
    finally:
        if conn:
            conn.close()

# --- GİRİŞ YAPMA ---
@app.post("/login")
async def login(user: UserLogin):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute("SELECT user_id, password_hash, university, department FROM users WHERE email = %s", (user.email,))
        result = cur.fetchone()
        
        if result is None:
            print("[LOGIN LOG] Kullanıcı bulunamadı")
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")
            
        user_id, stored_hash, university, department = result
        
        user_password_bytes = user.password.encode('utf-8')[:72]
        if bcrypt.checkpw(user_password_bytes, stored_hash.encode('utf-8')):
            return {
                "status": "success",
                "user_id": user_id,
                "user_email": user.email,
                "university": university,
                "department": department
            }
        else:
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")
            
    except Exception as e:
        print(f"[LOGIN ERROR] {e}")
        raise HTTPException(status_code=500, detail="Sunucu hatası.")
    finally:
        if conn:
            conn.close()

# --- ÖDEME BAŞLATMA ---
# Dosyanın en üstüne ekle
import iyzipay

# ÖDEME BAŞLATMA kısmını bununla değiştir
@app.post("/create-payment")
async def create_payment(payment: CreatePayment):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            "INSERT INTO orders (user_id, book_id, price) VALUES (%s, %s, %s) RETURNING order_id",
            (payment.user_id, payment.book_id, payment.price)
        )
        order_id = cur.fetchone()[0]
        conn.commit()
        cur.close()

        # iyzico ayarları
        options = {
            'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
            'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
            'base_url': 'sandbox-api.iyzipay.com'
        }

        request = {
            'locale': 'tr',
            'conversationId': str(uuid.uuid4()),
            'price': str(payment.price),
            'paidPrice': str(payment.price),
            'currency': 'TRY',
            'basketId': str(order_id),
            'paymentGroup': 'PRODUCT',
            'callbackUrl': 'http://192.168.67.99:8000/payment-callback',

            'buyer': {
                'id': str(payment.user_id),
                'name': 'Merve',
                'surname': 'Bebook',
                'gsmNumber': '+905350000000',
                'email': 'email@email.com',
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

        checkout_form_initialize = iyzipay.CheckoutFormInitialize().create(request, options)

        response_data = checkout_form_initialize.read().decode('utf-8')
        print(f"[IYZICO RESPONSE] {response_data}")

        import json
        return json.loads(response_data)

    except Exception as e:
        print(f"[PAYMENT ERROR] {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()
        print("[PAYMENT LOG] DB bağlantısı kapatıldı.")