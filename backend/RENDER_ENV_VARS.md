# Render Environment Variables Configuration

## Required Environment Variables for Render Deployment

Set these in your Render Dashboard → Web Service → Environment:

### 1. SECRET_KEY (CRITICAL)
```
SECRET_KEY=<generate-a-strong-random-key>
```

**Generate a secure key:**
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 2. DEBUG
```
DEBUG=False
```

### 3. ALLOWED_HOSTS
```
ALLOWED_HOSTS=.onrender.com,smart-trip-planner-dw13.onrender.com
```

### 4. DATABASE_URL
```
DATABASE_URL=<your-render-postgres-internal-url>
```

**Note:** Render automatically provides this if you create a PostgreSQL database and link it to your web service.

### 5. CORS_ALLOW_ALL_ORIGINS (Development Only)
```
CORS_ALLOW_ALL_ORIGINS=True
```

**For Production (Recommended):**
```
CORS_ALLOWED_ORIGINS=https://your-flutter-app.onrender.com,https://your-custom-domain.com
```

---

## Optional Environment Variables

### Database Configuration (if not using DATABASE_URL)
```
DB_ENGINE=postgresql
DB_NAME=smart_trip_planner
DB_USER=postgres
DB_PASSWORD=<your-db-password>
DB_HOST=<your-db-host>
DB_PORT=5432
```

---

## Render Deployment Checklist

### Backend Deployment
1. ✅ Create Web Service on Render
2. ✅ Connect GitHub repository
3. ✅ Set Build Command: `./build.sh`
4. ✅ Set Start Command: `gunicorn config.wsgi:application`
5. ✅ Add PostgreSQL database (or use external)
6. ✅ Set all environment variables above
7. ✅ Deploy and check logs

### Frontend Deployment (Flutter Web)
1. ✅ Build Flutter web: `flutter build web --release`
2. ✅ Create Static Site on Render
3. ✅ Set Publish Directory: `build/web`
4. ✅ Deploy

---

## Troubleshooting

### HTTP 500 on Login
**Causes:**
- Missing `SECRET_KEY` environment variable
- Database connection issues (check `DATABASE_URL`)
- Missing migrations (ensure `build.sh` runs `python manage.py migrate`)
- Missing `rest_framework_simplejwt.token_blacklist` in `INSTALLED_APPS`

**Solution:**
1. Check Render logs: Dashboard → Logs
2. Verify all environment variables are set
3. Ensure database is connected
4. Redeploy if needed

### CORS Errors
**Solution:**
- Set `CORS_ALLOW_ALL_ORIGINS=True` for testing
- For production, set specific origins in `CORS_ALLOWED_ORIGINS`

### Static Files Not Loading
**Solution:**
- Ensure `build.sh` runs `python manage.py collectstatic --no-input`
- Check `STATIC_ROOT` and `STATICFILES_STORAGE` in `settings.py`

---

## Production-Ready Settings Summary

Current `settings.py` is configured for:
- ✅ Environment-based configuration (python-decouple)
- ✅ PostgreSQL with DATABASE_URL support
- ✅ Whitenoise for static files
- ✅ CORS headers
- ✅ JWT authentication with SimpleJWT
- ✅ Secure settings when DEBUG=False
- ✅ Logging to console and file
- ✅ Custom exception handler (no stack traces exposed)

---

## Quick Deploy Commands

### Local Testing
```bash
# Set environment variables
export SECRET_KEY="django-insecure-dev-key"
export DEBUG=True
export ALLOWED_HOSTS="*"

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run server
python manage.py runserver
```

### Render Deploy
```bash
# Render automatically runs:
./build.sh  # Installs deps, collects static, runs migrations
gunicorn config.wsgi:application  # Starts production server
```

---

## Support

If you encounter issues:
1. Check Render logs
2. Verify environment variables
3. Test endpoints with curl:
   ```bash
   curl https://smart-trip-planner-dw13.onrender.com/
   curl -X POST https://smart-trip-planner-dw13.onrender.com/api/auth/token/ \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"admin123"}'
   ```
