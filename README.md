[![Project Demo](https://img.shields.io/badge/▶-Watch_Demo-red?style=for-the-badge)](https://drive.google.com/file/d/1hbc1YBjGkz-dZyeLnWvyWm-IXzJWt-i5/view)


# Smart Trip Planner 🌍✈️

**Kya hai ye project?**
Yeh ek **Smart Trip Planner** application hai. Isme aap apni trips plan kar sakte hain, destinations explore kar sakte hain, aur apna travel itinerary manage kar sakte hain.
Iska system do parts mein divided hai:
1.  **Backend**: Jo Django (Python) mein bana hai.
2.  **Frontend**: Jo Flutter mein bana hai (Web aur Mobile ke liye).

---

## 🚀 Project Kaise Start Karein (MacBook Terminal)

Project ko run karne ke liye neeche diye gaye steps follow karein. Aapko do alag terminals ki zaroorat padegi (ek backend ke liye aur ek frontend ke liye).

### Step 1: Backend Start Karein (Server) 🖥️

Sabse pehle backend server chalu karna padega taaki app data fetch kar sake.

1.  Apna **Terminal** open karein.
2.  Project ke root folder mein jaayein.
3.  Backend folder mein jaane ke liye aur server start karne ke liye ye commands run karein:

```bashs
cd backend
python3 -m pip install -r requirements.txt
python3 manage.py runserver 0.0.0.0:8000
```

Ab aapka backend server `http://0.0.0.0:8000` par chal raha hai! ✅

---

### Step 2: Frontend Start Karein (App) 📱💻

Ab app ko chalane ki baari hai.

1.  Ek **Naya Terminal Tab** kholo (Shortkey: `Cmd + T`).
2.  Wapis apne main project folder mein hone chahiye.
3.  Frontend chalane ke liye ye commands run karein:

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

## IMPORTANT

## Terminal 1: Backend (Server)
cd /Users/ashwanirai/Documents/smart-trip-planner/backend
python3 -m venv venv
source venv/bin/activate
python manage.py runserver
* API Documentation (Swagger): http://127.0.0.1:8000/api/docs/
* Admin Panel: http://127.0.0.1:8000/admin/


## Terminal 2: Frontend (App)
cd /Users/ashwanirai/Documents/smart-trip-planner/flutter_app
flutter run -d chrome

**You can login with: Username: admin Password: admin123  You can access the admin panel at http://localhost:8000/admin .**


Chrome browser open ho jayega aur aapka **Smart Trip Planner** app waha chal jayega! 🎉

---

**Note:** Agar koi error aaye toh check karein ki aapne sahi folder (`backend` ya `flutter_app`) mein commands run kiye hain ya nahi.

**Happy Coding!** 🚀
