# 🚀 How to Run Smart Trip Planner

You have two options to run the backend: **Docker (Recommended)** or **Manual**.

## Option A: Docker (If you have Docker set up)
Since you already have Docker set up, this is the easiest way.

1.  **Start Backend**:
    ```bash
    cd backend
    docker-compose up -d
    ```
    *This runs the database and backend in the background.*

2.  **Stop Backend**:
    ```bash
    docker-compose down
    ```

## Option B: Manual (Python)
Use this only if you don't want to use Docker.

1.  **Start Backend**:
    ```bash
    cd backend
    ./venv/bin/python manage.py runserver 0.0.0.0:8000
    ```

---

## 2. Frontend (Flutter)

Open a **new** terminal window and run:

```bash
cd flutter_app
flutter run -d chrome
```
