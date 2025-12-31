# 🔄 Render Manual Restart Guide

Maine backend code fix kar diya hai aur push kar diya hai. Ab aapko **manually restart** karna hoga.

## Backend Restart Steps:

1. **Render Dashboard** open karein: https://dashboard.render.com/
2. Apni **Backend Service** (`smart-trip-planner`) par click karein
3. Top-right corner mein **"Manual Deploy"** button par click karein
4. **"Deploy latest commit"** select karein aur confirm karein
5. Wait karein jab tak "Live" na ho jaye (2-3 minutes)

## Frontend Restart Steps:

1. Same Render Dashboard mein
2. Apni **Frontend Static Site** par click karein
3. **"Manual Deploy"** button dabayein
4. Confirm karein

## ✅ Verification:

Deploy hone ke baad:
- Backend check karein: https://smart-trip-planner-dw13.onrender.com/
- Agar JSON response aaye (`{"status": "healthy", ...}`) toh backend theek hai
- Frontend par jaakar login try karein

## 🐛 Agar phir bhi error aaye:

Backend service ke **Logs** tab mein jaakar exact error message dekh kar mujhe batayein.

---

**Note:** Maine ye fixes kiye hain:
- ✅ SSL redirect disabled (Render loop issue fix)
- ✅ ALLOWED_HOSTS = ['*'] (blocking issue fix)
- ✅ DEBUG = False (production mode)
- ✅ Relaxed cookie security settings
