# 🚀 How to Deploy Flutter Web to Render

Since Render doesn't have Flutter installed by default, the **easiest method** is to push your locally built `build/web` folder to GitHub and just let Render serve it.

I have already updated your `.gitignore` to allow uploading the `build/web` folder.

### Step 1: Push Your Code (Run these in terminal)
```bash
cd flutter_app
# 1. Build the web app ensuring icons are correct
flutter build web --release --no-tree-shake-icons

cd ..
# 2. Commit the build folder
git add flutter_app/build/web -f
git commit -m "Deploy: Upload Flutter Web Build"
git push origin main
```

### Step 2: Configure Render
1. Go to your [Render Dashboard](https://dashboard.render.com/).
2. Click **New +** -> **Static Site**.
3. Connect your GitHub repository.
4. Fill in these details exactly:
   - **Name:** `smart-trip-planner-web` (or anything you like)
   - **Branch:** `main`
   - **Root Directory:** `flutter_app/build/web`  <-- IMPORTANT!
   - **Build Command:** `echo "Build already done"` (We don't need Render to build it)
   - **Publish Directory:** `.` (Current directory, since Root is already set to web)

5. Click **Create Static Site**.

### Step 3: Success! 🎉
Render will deploy your site in seconds. You will get a URL like `https://smart-trip-planner-web.onrender.com`.

Open that link on your phone and use "Add to Home Screen"!
