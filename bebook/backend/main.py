from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
import bcrypt
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

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
        password="senem2003", 
        port="5432"
    )

class UserSignup(BaseModel):
    email: str
    password: str
    university: str
    department: str

class UserLogin(BaseModel):
    email: str
    password: str

# --- KAYIT OLMA (SIGNUP) ---
@app.post("/signup")
async def signup(user: UserSignup):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
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
        print(f"Signup Hatası: {e}")
        raise HTTPException(status_code=400, detail="Bu e-posta zaten kayıtlı.")
    finally:
        if conn:
            conn.close()

# --- GİRİŞ YAPMA (LOGIN) ---
@app.post("/login")
async def login(user: UserLogin):
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute("SELECT password_hash, university, department FROM users WHERE email = %s", (user.email,))
        result = cur.fetchone()
        
        if result is None:
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")
            
        stored_hash = result[0]
        university = result[1]
        department = result[2]
        
        # Şifre kontrolü
        user_password_bytes = user.password.encode('utf-8')[:72]
        if bcrypt.checkpw(user_password_bytes, stored_hash.encode('utf-8')):
            return {
                "status": "success",
                "user_email": user.email,
                "university": university,
                "department": department
            }
        else:
            raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")
            
    except Exception as e:
        print(f"Login Hatası: {e}")
        raise HTTPException(status_code=500, detail="Sunucu hatası.")
    finally:
        if conn:
            conn.close()