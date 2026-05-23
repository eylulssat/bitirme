# -*- coding: utf-8 -*-
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
import smtplib
import random
import string
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

otp_storage = {}

# ============================================
# 1. APP OLUSTURMA
# ============================================
app = FastAPI()

# --- AYARLAR VE KLASORLER ---
UPLOAD_DIR = "uploads" 
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
BASE_URL = "http://192.168.1.6:8001" 

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- VERITABANI BAGLANTISI ---
def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="bebook",
        user="postgres",
        password="1414",
        port="5432"
    )

# --- IYZICO AYARLARI ---
IYZICO_OPTIONS = {
    'api_key': 'sandbox-2uvQ8EgewWnsUzYohEY9bAe9iHqZwQkB',
    'secret_key': 'sandbox-uA0wxzWZMBF4m7RKBqEf9rNtAYBWEzkr',
    'base_url': 'sandbox-api.iyzipay.com'
}

# --- VERI MODELLERI ---
class UserSignup(BaseModel):
    full_name: Optional[str] = None
    email: str
    password: str
    university: str
    department: str
    profile_image_path: Optional[str] = None

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

class CreatePayment(BaseModel):
    user_id: int
    book_id: int
    price: float

class BulkPaymentRequest(BaseModel):
    user_id: int
    book_ids: List[int]
    total_price: float

class CreatePayment(BaseModel):
    user_id: int
    book_id: int
    price: float

class BulkPaymentRequest(BaseModel):
    user_id: int
    book_ids: List[int]
    total_price: float

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

        # Önce tabloyu kontrol edelim
        cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'users'")
        columns = [row[0] for row in cur.fetchall()]
        print(f"Users tablosundaki sütunlar: {columns}")

        # full_name sütunu varsa onu kullan, yoksa sadece email, password vs. kullan
        if 'full_name' in columns:
            cur.execute(
                "INSERT INTO public.users (full_name, email, password_hash, university, department) VALUES (%s, %s, %s, %s, %s)",
                (user.full_name or "", user.email, hashed_password, user.university, user.department)
            )
        else:
            # full_name sütunu yoksa sadece temel bilgileri kaydet
            cur.execute(
                "INSERT INTO public.users (email, password_hash, university, department) VALUES (%s, %s, %s, %s)",
                (user.email, hashed_password, user.university, user.department)
            )
        
        conn.commit()
        return {"status": "success", "message": "Kullanici basariyla kaydedildi!"}
    except Exception as e:
        if conn: conn.rollback()
        print(f"Kayıt hatası: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()

# --- KULLANICI GIRISI ---
@app.post("/login")
async def login(user: UserLogin):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        # Önce tabloyu kontrol edelim
        cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'users'")
        columns = [row[0] for row in cur.fetchall()]
        print(f"Users tablosundaki sütunlar: {columns}")
        
        # Temel sütunları seç
        select_columns = ["user_id", "password_hash"]
        if 'university' in columns:
            select_columns.append("university")
        if 'department' in columns:
            select_columns.append("department")
        if 'profile_image_path' in columns:
            select_columns.append("profile_image_path")
        if 'full_name' in columns:
            select_columns.append("full_name")
        
        query = f"SELECT {', '.join(select_columns)} FROM public.users WHERE email = %s"
        cur.execute(query, (user.email,))
        result = cur.fetchone()

        if not result:
            raise HTTPException(status_code=401, detail="E-posta veya sifre hatali.")

        # Sonuçları parse et
        user_id = result[0]
        stored_hash = result[1]
        
        if bcrypt.checkpw(user.password.encode('utf-8')[:72], stored_hash.encode('utf-8')):
            response_data = {
                "status": "success",
                "user_id": user_id,
                "user_email": user.email
            }
            
            # Varsa diğer bilgileri ekle
            idx = 2
            if 'university' in columns:
                response_data["university"] = result[idx] if len(result) > idx else None
                idx += 1
            if 'department' in columns:
                response_data["department"] = result[idx] if len(result) > idx else None
                idx += 1
            if 'profile_image_path' in columns:
                response_data["profile_image_path"] = result[idx] if len(result) > idx else None
                idx += 1
            if 'full_name' in columns:
                response_data["full_name"] = result[idx] if len(result) > idx else None
                
            return response_data
        else:
            raise HTTPException(status_code=401, detail="E-posta veya sifre hatali.")
    except Exception as e:
        print(f"Giriş hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

# --- TUM KITAPLARI GETIR (Ana Sayfa) ---
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

# --- YENI KITAP EKLEME ---
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
        return {"status": "success", "message": "Kitap ve resim yuklendi!"}
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- KULLANICININ KITAPLARINI GETIR ---
@app.get("/my-books/{user_id}")
async def get_my_books(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
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

# --- KITAP GUNCELLEME ---
@app.put("/update-book")
async def update_book(book: UpdateBook):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT email FROM users WHERE user_id = %s", (book.user_id,))
        user_result = cur.fetchone()
        
        if not user_result:
            raise HTTPException(status_code=404, detail="Kullanici bulunamadi")
        
        user_email = user_result[0]
        
        cur.execute(
            "UPDATE books SET title = %s, price = %s, description = %s WHERE id = %s AND seller_email = %s", 
            (book.title, book.price, book.description, book.book_id, user_email)
        )
        conn.commit()
        return {"status": "success"}
    finally:
        conn.close()

# --- KITAP SILME ---
@app.delete("/delete-book/{book_id}/{user_id}")
async def delete_book(book_id: int, user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT email FROM users WHERE user_id = %s", (user_id,))
        user_result = cur.fetchone()
        
        if not user_result:
            raise HTTPException(status_code=404, detail="Kullanici bulunamadi")
        
        user_email = user_result[0]
        
        cur.execute("DELETE FROM books WHERE id = %s AND seller_email = %s", (book_id, user_email))
        conn.commit()
        return {"status": "success"}
    finally:
        conn.close()

# --- MESAJLASMA ENDPOINTLERI ---

# Mesaj gonderme icin gerekli veri modeli
class MessageCreate(BaseModel):
    sender_id: int
    receiver_id: int
    book_id: int
    message_text: str

@app.get("/chats/{my_id}")
async def get_chat_list(my_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # EN BASİT VE KESİN ÇALIŞAN SORGU
        # Önce tüm mesajları alalım
        query = """
        SELECT 
            m.book_id,
            m.sender_id,
            m.receiver_id,
            m.message_text,
            m.created_at,
            b.title
        FROM usermessages m
        LEFT JOIN books b ON m.book_id = b.id
        WHERE m.sender_id = %s OR m.receiver_id = %s
        ORDER BY m.created_at DESC
        """
        
        cursor.execute(query, (my_id, my_id))
        all_messages = cursor.fetchall()
        
        # Şimdi gruplayalım: her (book_id, diğer_kullanıcı) çifti için en son mesajı al
        chat_dict = {}
        for msg in all_messages:
            book_id = msg[0]
            sender_id = msg[1]
            receiver_id = msg[2]
            
            # Diğer kullanıcıyı bul
            other_user_id = receiver_id if sender_id == my_id else sender_id
            
            key = f"{book_id}_{other_user_id}"
            
            # Eğer bu sohbet daha önce eklenmediyse veya daha yeni bir mesajsa
            if key not in chat_dict or msg[4] > chat_dict[key]['created_at']:
                # Diğer kullanıcının bilgilerini al
                # Önce users tablosundaki sütunları kontrol et
                cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'users'")
                columns = [row[0] for row in cursor.fetchall()]
                
                # Hangi sütunları seçeceğimizi belirle
                select_columns = ["email"]  # email her zaman var
                if 'profile_image_path' in columns:
                    select_columns.append("profile_image_path")
                if 'full_name' in columns:
                    select_columns.append("full_name")
                
                user_query = f"SELECT {', '.join(select_columns)} FROM users WHERE user_id = %s"
                cursor.execute(user_query, (other_user_id,))
                user_info = cursor.fetchone()
                
                # Bilgileri parse et
                email = user_info[0] if user_info else None
                profile_image = None
                full_name = None
                
                idx = 1
                if 'profile_image_path' in columns and len(user_info) > idx:
                    profile_image = user_info[idx]
                    idx += 1
                if 'full_name' in columns and len(user_info) > idx:
                    full_name = user_info[idx]
                
                # Okunmamış mesaj sayısını al
                unread_query = """
                SELECT COUNT(*) FROM usermessages 
                WHERE receiver_id = %s 
                AND sender_id = %s 
                AND book_id = %s 
                AND is_read = FALSE
                """
                cursor.execute(unread_query, (my_id, other_user_id, book_id))
                unread_count = cursor.fetchone()[0]
                
                chat_dict[key] = {
                    "book_id": book_id,
                    "receiver_id": other_user_id,
                    "receiver_name": full_name if full_name else email,
                    "full_name": full_name,
                    "book_title": msg[5] if msg[5] else f"Kitap #{book_id}",
                    "last_message": msg[3],
                    "profile_image": profile_image,
                    "created_at": msg[4],
                    "unread_count": unread_count
                }
        
        # Dictionary'den listeye çevir ve tarihe göre sırala
        chats = list(chat_dict.values())
        chats.sort(key=lambda x: x['created_at'], reverse=True)
        
        return chats

    except Exception as e:
        print(f"Sohbet Listesi Hatasi: {e}")
        return []
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.get("/messages/{sender_id}/{receiver_id}/{book_id}")
async def get_messages_with_book(sender_id: int, receiver_id: int, book_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
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
                "is_delivered": m[5]
            })
        return result
    except Exception as e:
        print(f"Hata: {e}")
        return []
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
        print(f"Mesaj Kayit Hatasi: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        cursor.close()
        conn.close()

@app.post("/mark_messages_as_read")
async def mark_messages_as_read(receiver_id: int, sender_id: int, book_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
        UPDATE usermessages 
        SET is_read = TRUE 
        WHERE receiver_id = %s AND sender_id = %s AND book_id = %s AND is_read = FALSE
        """
        cursor.execute(query, (receiver_id, sender_id, book_id))
        conn.commit()
        return {"status": "success", "message": "Mesajlar okundu olarak isaretlendi"}
    except Exception as e:
        print(f"Okundu isaretleme hatasi: {e}")
        return {"status": "error"}
    finally:
        cursor.close()
        conn.close()

@app.put("/mark_as_delivered/{receiver_id}")
async def mark_as_delivered(receiver_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
            UPDATE usermessages 
            SET is_delivered = TRUE 
            WHERE receiver_id = %s AND is_delivered = FALSE
        """
        cursor.execute(query, (receiver_id,))
        conn.commit()
        
        print(f"Bilgi: {receiver_id} ID'li kullanici icin mesajlar iletildi olarak isaretlendi.")
        return {"status": "success", "message": "Mesajlar iletildi yapildi"}
    except Exception as e:
        print(f"Hata olustu: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        cursor.close()
        conn.close()

@app.delete("/chats/delete")
async def delete_chat(my_id: int, other_id: int, book_id: int):
    conn = get_db_connection()
    cursor = None
    try:
        cursor = conn.cursor()
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
        return {"message": "Sohbet basariyla silindi"}
    except Exception as e:
        print(f"Silme hatasi: {e}")
        raise HTTPException(status_code=500, detail="Sohbet silinemedi")
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# --- FAVORILER SISTEMI ---
@app.post("/favorites/toggle")
async def toggle_favorite(favorite: FavoriteToggle):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        cur.execute(
            "SELECT id FROM public.favorites WHERE user_id = %s AND book_id = %s",
            (favorite.user_id, favorite.book_id)
        )
        existing = cur.fetchone()
        
        if existing:
            cur.execute(
                "DELETE FROM public.favorites WHERE user_id = %s AND book_id = %s",
                (favorite.user_id, favorite.book_id)
            )
            conn.commit()
            return {"status": "removed", "message": "Favorilerden cikarildi"}
        else:
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
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT 
                b.id, b.title, b.author, b.category, b.price, b.description, 
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

@app.get("/favorites/check/{user_id}/{book_id}")
async def check_favorite(user_id: int, book_id: int):
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

# --- ILETISIM FORMU ---
@app.post("/contact")
async def contact(req: ContactRequest):
    return {"status": "success", "message": "Mesajiniz iletildi."}

# --- ONERI SISTEMI ---
@app.get("/recommendations/{user_id}")
async def get_recommendations_endpoint(user_id: int, top_n: int = 6):
    """
    Kullanicinin bolumune gore kisisellestirilmis kitap onerileri dondurur.
    """
    import pandas as pd
    from recommendation_engine import get_recommendations
    
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        # Kullanicilari cek
        cur.execute("SELECT user_id, email, university, department FROM users")
        users_data = cur.fetchall()
        users_df = pd.DataFrame(users_data, columns=["user_id", "email", "university", "department"])
        
        # Kitaplari cek
        cur.execute("""
            SELECT id as book_id, title, author, category, price, description, 
                   seller_email, image_path, publisher
            FROM books
        """)
        books_data = cur.fetchall()
        books_df = pd.DataFrame(books_data, columns=[
            "book_id", "title", "author", "category", "price", 
            "description", "seller_email", "image_path", "publisher"
        ])
        
        # Kullanicinin department bilgisini al
        user_row = users_df[users_df["user_id"] == user_id]
        if user_row.empty:
            return {"error": "Kullanici bulunamadi"}
        
        # Her kitaba department ekle (seller'in department'i)
        books_with_dept = []
        for _, book in books_df.iterrows():
            seller = users_df[users_df["email"] == book["seller_email"]]
            dept = seller.iloc[0]["department"] if not seller.empty else "Diger"
            
            # Resim yolunu tam URL'e cevir
            image_path = book["image_path"]
            if image_path:
                if image_path.startswith('http'):
                    image_url = image_path
                elif image_path.startswith('/uploads/'):
                    image_url = f"{BASE_URL}{image_path}"
                else:
                    image_url = f"{BASE_URL}/uploads/{image_path}"
            else:
                image_url = None
            
            books_with_dept.append({
                "book_id": book["book_id"],
                "title": book["title"],
                "author": book["author"],
                "category": book["category"],
                "price": book["price"],
                "description": book["description"],
                "seller_email": book["seller_email"],
                "image_path": image_url,
                "publisher": book["publisher"],
                "department": dept,
                "is_sold": False
            })
        
        books_df = pd.DataFrame(books_with_dept)
        
        # Onerileri al
        recommendations = get_recommendations(user_id, users_df, books_df, top_n=top_n)
        
        return recommendations
        
    except Exception as e:
        print(f"Oneri sistemi hatasi: {e}")
        import traceback
        traceback.print_exc()
        return {"error": str(e), "recommendations": []}
    finally:
        conn.close()

# --- ODEME SISTEMI ---

# TEK KITAP ICIN ODEME BASLATMA
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
        print(f"Odeme hatasi: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        cur.close()
        conn.close()

# TOPLU ODEME (Sepet)
@app.post("/bulk-payment")
async def bulk_payment(request: BulkPaymentRequest):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        # Ilk kitabin ID'sini orders tablosuna kaydediyoruz
        first_book_id = request.book_ids[0] if request.book_ids else None

        cur.execute(
            "INSERT INTO orders (user_id, book_id, price, status) VALUES (%s, %s, %s, %s) RETURNING order_id",
            (request.user_id, first_book_id, request.total_price, "PENDING")
        )
        order_id = cur.fetchone()[0]
        conn.commit()

        # Sepetteki tum kitaplari basket_items'a ekliyoruz
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
        print(f"Iyzipay Hatasi: {e}")
        return {"status": "failure", "errorMessage": str(e)}
    finally:
        conn.close()

# ODEME CALLBACK
@app.post("/payment-callback")
async def payment_callback(request: Request):
    form_data = await request.form()
    token = form_data.get('token')

    if not token:
        return HTMLResponse(content="Token yok", status_code=400)

    # Iyzipay'e token ile sonucu sorguluyoruz
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
            print(f"DB Guncelleme Hatasi: {e}")

        status_text = "Odeme Basarili!"
        main_color = "#2ecc71"
        description = "Isleminiz basariyla tamamlandi. Diger ilanlari incelemek icin ana sayfaya donebilirsiniz!"
    else:
        status_text = "Odeme Basarisiz"
        main_color = "#e74c3c"
        error_msg = result.get('errorMessage', 'Odeme onaylanmadi.')
        description = f"Sorun olustu: {error_msg}"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="tr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <title>Odeme Sonucu</title>
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
                transition: all 0.3s ease;
            ">ANA SAYFAYA DON</a>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)

# SIPARIS DURUMU SORGULAMA
@app.get("/order-status/{order_id}")
async def get_order_status(order_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT status FROM orders WHERE order_id = %s", (order_id,))
        result = cur.fetchone()
        if result:
            return {"status": result[0]}
        raise HTTPException(status_code=404, detail="Siparis bulunamadi")
    finally:
        conn.close()

# --- SIFRE SIFIRLAMA SISTEMI ---

# Rastgele 6 haneli kod uretme
def generate_otp():
    return ''.join(random.choices(string.digits, k=6))

# E-posta gonderme fonksiyonu
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
        print(f"!!! DOGRULAMA KODU GONDERILDI: {otp_code} !!!")
        return True
    except Exception as e:
        print(f"MAIL HATASI: {e}")
        return False

# SIFRE SIFIRLAMA ISTEGI
@app.post("/forgot-password")
async def forgot_password(data: dict):
    try:
        email = data.get("email")
        if not email:
            return {"status": "error", "message": "Email adresi eksik"}
            
        otp = generate_otp()
        
        # Kodu hafizaya kaydediyoruz
        otp_storage[email] = otp 
        
        print(f"Email: {email}, OTP: {otp}") 
        
        success = send_otp_email(email, otp) 
        
        if success:
            return {"status": "success", "message": "Kod gonderildi"}
        else:
            return {"status": "error", "message": "Mail gonderimi basarisiz"}
            
    except Exception as e:
        print(f"Sistem Hatasi: {str(e)}")
        return {"status": "error", "message": str(e)}

# OTP DOGRULAMA
@app.post("/verify-otp")
async def verify_otp(data: dict):
    print("!!! DOGRULAMA ISTEGI GELDI !!!")
    print(f"Gelen Veri: {data}")
    
    email = str(data.get("email")).strip().lower()
    user_otp = str(data.get("otp")).strip()

    if email in otp_storage and str(otp_storage[email]) == user_otp:
        return {"status": "success", "message": "Kod dogrulandi"}
    
    print(f"Hata detayi -> Hafizadaki: {otp_storage.get(email)}, Girilen: {user_otp}")
    return {"status": "error", "message": "Kod eslesmedi!"}

# SIFRE SIFIRLAMA
@app.post("/reset-password")
async def reset_password(data: dict):
    conn = None
    try:
        email = str(data.get("email")).strip().lower()
        new_password = data.get("password")

        # Sifreyi Bcrypt ile sifreliyoruz
        hashed_password = bcrypt.hashpw(
            new_password.encode('utf-8'), 
            bcrypt.gensalt()
        ).decode('utf-8')

        conn = get_db_connection()
        cursor = conn.cursor()

        query = 'UPDATE users SET password_hash = %s WHERE email = %s'
        
        cursor.execute(query, (hashed_password, email))
        conn.commit()

        if cursor.rowcount == 0:
            return {"status": "error", "message": "Kullanici bulunamadi."}

        cursor.close()
        print(f"BASARILI: {email} sifresi sifrelenerek guncellendi.")
        return {"status": "success", "message": "Sifreniz basariyla guncellendi."}

    except Exception as e:
        print(f"Sifirlama Hatasi: {e}")
        return {"status": "error", "message": "Sistem hatasi olustu."}
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)