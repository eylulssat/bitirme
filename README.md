Backend (FastAPI)
cd bebook/backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Flutter
cd bebook
flutter pub get
flutter run

Backend ve Flutter'ı aynı anda iki ayrı terminalde çalıştırman gerekiyor. Önce backend'i başlat, sonra Flutter'ı.
