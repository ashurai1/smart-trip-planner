# Smart Trip Planner 🌍✈️

![Backend CI](https://github.com/ashurai1/REPO/actions/workflows/backend.yml/badge.svg)
![Frontend CI](https://github.com/ashurai1/REPO/actions/workflows/frontend.yml/badge.svg)

A production-ready collaborative trip planning application built with a scalable **Django** backend and a responsive **Flutter** frontend.

## 🚀 Tech Stack

### Backend (Django)
-   **Framework**: Django Rest Framework (DRF)
-   **Database**: PostgreSQL (Production) / SQLite (Dev fallback)
-   **Authentication**: JWT (JSON Web Tokens)
-   **Infrastructure**: Docker & Docker Compose
-   **CI/CD**: GitHub Actions (Linting & Unit Tests)

### Frontend (Flutter)
-   **Architecture**: BLoC-style (Business Logic Component) pattern
-   **State Management**: Stream-based reactive UI
-   **Networking**: Dio with Interceptors
-   **CI/CD**: GitHub Actions (Analysis & Widget Tests)

## ✨ Features
-   **Authentication**: Secure Signup, Login, and Profile management with OTP logic.
-   **Trip Collaboration**: Invite friends to trips and manage shared itineraries.
-   **Real-time Chat**: Group chat for each trip (Polling/WebSocket ready).
-   **Voting & Polls**: Democratic decision making for trip activities.
-   **Itinerary Management**: day-by-day planning with drag-and-drop support.

## 🛠️ How to Run Locally

### Prerequisites
-   Docker Desktop
-   Flutter SDK (3.x)

### 1. Start Backend (Docker)
This spins up the Django API and PostgreSQL database.
```bash
cd backend
docker-compose up --build -d
```
> **Note**: This runs the migrations and loads initial data automatically if configured.

### 2. Run Frontend (Flutter)
```bash
cd flutter_app
flutter pub get
flutter run
```

## 🏗️ Architecture
-   **Modular Backend**: Separate apps for `trips`, `users`, `chat`, and `polls`.
-   **Clean Frontend**: Clear separation of UI (Screens/Widgets), State (Models), and Business Logic (Services).
-   **Scalable**: Containerized architecture ready for deployment on platforms like Render, Railway, or AWS.

## 🧪 Testing
Run the automated test suites:

**Backend:**
```bash
docker-compose exec web python manage.py test
```

**Frontend:**
```bash
cd flutter_app
flutter test
```
