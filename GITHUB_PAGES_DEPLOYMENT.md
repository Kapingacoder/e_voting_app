# E-Voting App - Flutter Web Deployment Guide (GitHub Pages)

## 🎯 Completely FREE Password Reset System

Mfumo huu unatumia **GitHub Pages** (FREE) ku-host password reset page. Hakuna web hosting inayohitajika!

---

## 🏗️ Architecture

```
Mobile App → Voter clicks "Forgot Password"
      ↓
Email sent with link: https://kapingacoder.github.io/e_voting_app/#/reset?data=ENCRYPTED
      ↓
Voter opens link → Flutter Web Page (GitHub Pages)
      ↓
Voter answers security question + CAPTCHA
      ↓
Password reset automatic + Email sent
```

---

## 📋 Step-by-Step Deployment

### **Step 1: Build Flutter Web**

```bash
cd /Users/apple/Desktop/e_voting_app

# Build for web (release mode)
flutter build web --release

# OR for debugging
flutter build web --web-renderer html
```

**Output:** Files zinaenda kwenye `build/web/` folder

---

### **Step 2: Prepare for GitHub Pages**

#### a) Create `gh-pages` branch

```bash
# Create and checkout gh-pages branch
git checkout --orphan gh-pages

# Remove all files from staging
git rm -rf .

# Copy web build files
cp -r build/web/* .

# Add .gitignore for gh-pages
echo "!build/web/" > .gitignore

# Stage all web files
git add .

# Commit
git commit -m "Deploy Flutter Web to GitHub Pages"

# Push to GitHub
git push origin gh-pages
```

#### b) OR Use Simple Method (Recommended)

```bash
# Build web
flutter build web --release

# Create gh-pages branch if not exists
git branch gh-pages 2>/dev/null || git checkout gh-pages

# Copy build files to root
rm -rf !(build|.git)
cp -r build/web/* .

# Commit and push
git add .
git commit -m "Deploy to GitHub Pages"
git push -f origin gh-pages

# Go back to main
git checkout main
```

---

### **Step 3: Enable GitHub Pages**

1. **Nenda GitHub Repository:**
   ```
   https://github.com/Kapingacoder/e_voting_app
   ```

2. **Click "Settings"** (top menu)

3. **Scroll down to "Pages"** (left sidebar)

4. **Configure:**
   - **Source:** Deploy from a branch
   - **Branch:** `gh-pages`
   - **Folder:** `/ (root)`

5. **Click "Save"**

6. **Wait 2-5 minutes** for deployment

7. **Your site will be live at:**
   ```
   https://kapingacoder.github.io/e_voting_app/
   ```

---

### **Step 4: Test Reset Password Link**

1. **Open mobile app**
2. **Click "Forgot Password?"**
3. **Enter admission number** (e.g., 1001)
4. **Check email** for reset link
5. **Click link** - inapaswa kufungua web page
6. **Answer security question + CAPTCHA**
7. **Submit** - password mpya itatumwa kwa email

---

## 🔧 Configuration Updates

### Update Base URL (if needed)

Kama GitHub Pages URL yako ni different, update `lib/web/reset_password_helper.dart`:

```dart
static String generateResetLink(...) {
  // ...
  
  // Change this URL to match your GitHub Pages URL
  return 'https://YOUR-USERNAME.github.io/YOUR-REPO-NAME/#/reset?data=$encoded';
}
```

---

## 🚀 Deployment Script (Automatic)

Tengeneza script ya ku-deploy kwa urahisi:

**File:** `deploy_web.sh`

```bash
#!/bin/bash

echo "🚀 Deploying E-Voting Web to GitHub Pages..."

# Build web
echo "📦 Building Flutter Web..."
flutter build web --release

# Checkout gh-pages
echo "🌿 Switching to gh-pages branch..."
git checkout gh-pages || git checkout --orphan gh-pages

# Clean old files
echo "🧹 Cleaning old files..."
rm -rf assets icons index.html flutter* manifest.json favicon.png

# Copy new build
echo "📋 Copying new build..."
cp -r build/web/* .

# Commit and push
echo "📤 Pushing to GitHub..."
git add .
git commit -m "Deploy: $(date +%Y-%m-%d\ %H:%M:%S)"
git push -f origin gh-pages

# Back to main
echo "🔙 Returning to main branch..."
git checkout main

echo "✅ Deployment complete!"
echo "🌐 Visit: https://kapingacoder.github.io/e_voting_app/"
```

**Make it executable:**
```bash
chmod +x deploy_web.sh
```

**Run deployment:**
```bash
./deploy_web.sh
```

---

## 📧 Email Template

Email ya voter itakuwa na link hii:

```
Subject: Password Recovery - Reset Your Password

Habari [Name],

Umetuma ombi la kubadili password yako.

Bofya link hii chini ili kubadili password yako:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
https://kapingacoder.github.io/e_voting_app/#/reset?data=XXXXXXXXX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Utaulizwa kujibu swali lako la usalama, kisha password mpya 
itatumwa kwa email yako automatic.

LINK HII NI VALID KWA SAA 1 TU.

Kama link haifanyi kazi, copy na paste kwenye browser yako.

Kama hukuomba kubadili password, puuza email hii.

Asante,
E-Voting System Team
```

---

## 🧪 Testing Checklist

- [ ] Build Flutter Web successfully
- [ ] Deploy to GitHub Pages
- [ ] GitHub Pages site is accessible
- [ ] SMTP settings configured in mobile app
- [ ] Test forgot password flow:
  - [ ] Email received with link
  - [ ] Link opens web page
  - [ ] Security question displays correctly
  - [ ] CAPTCHA works
  - [ ] Submit answer
  - [ ] Password reset email received
  - [ ] Can login with new password

---

## 🔒 Security Features

1. **Encrypted URL Parameters:**
   - Data encoded with Base64URL
   - Contains timestamp for expiry

2. **Link Expiry:**
   - Valid for 1 hour only
   - Automatic validation

3. **CAPTCHA Verification:**
   - Checkbox + Math question
   - Prevents automated attacks

4. **Security Answer Hash:**
   - SHA-256 hashing
   - Case-insensitive comparison

---

## 🐛 Troubleshooting

### Issue: "404 Not Found" on GitHub Pages

**Solution:**
```bash
# Make sure gh-pages branch exists and has files
git checkout gh-pages
git push -f origin gh-pages

# Wait 2-5 minutes
# Check: https://github.com/USERNAME/REPO/settings/pages
```

### Issue: Link not working

**Solution:**
1. Check email has correct URL
2. Try opening in different browser
3. Check if link expired (>1 hour old)
4. Request new reset link

### Issue: Web page shows blank

**Solution:**
```bash
# Rebuild with HTML renderer
flutter build web --web-renderer html --release

# Redeploy
./deploy_web.sh
```

### Issue: CAPTCHA not showing

**Solution:**
- Clear browser cache
- Try incognito mode
- Check browser console for errors

---

## 📊 GitHub Pages Limits

**Free Tier Includes:**
- ✅ 100GB bandwidth/month
- ✅ 10 builds/hour
- ✅ Free HTTPS
- ✅ Custom domain support

**More than enough for e-voting system!**

---

## 🔄 Update Workflow

**When you make changes:**

```bash
# 1. Make changes in main branch
git checkout main
# ... edit files ...

# 2. Commit changes
git add .
git commit -m "Updated password reset page"
git push origin main

# 3. Rebuild and redeploy web
./deploy_web.sh
```

---

## 🎯 Next Steps

1. ✅ **Deploy to GitHub Pages** (follow steps above)
2. ✅ **Test complete flow**
3. ✅ **Configure SMTP** (if not done)
4. ⭐ **Optional:** Add custom domain
5. ⭐ **Optional:** Add analytics

---

## 🌟 Advanced: Custom Domain

Ikiwa una domain yako (e.g., `evoting.example.com`):

1. **Add CNAME file to gh-pages:**
   ```bash
   echo "evoting.example.com" > CNAME
   git add CNAME
   git commit -m "Add custom domain"
   git push origin gh-pages
   ```

2. **Configure DNS:**
   - Add CNAME record pointing to: `kapingacoder.github.io`

3. **Enable HTTPS in GitHub Settings**

---

## 📞 Support

**Deployment Issues:**
- Check GitHub Actions tab for errors
- Verify gh-pages branch has files
- Wait 5 minutes after each push

**Reset Link Issues:**
- Test link manually
- Check URL encoding
- Verify timestamp not expired

---

## ✅ Success Indicators

Mfumo inafanya kazi vizuri kama:
- ✅ GitHub Pages site ina-load
- ✅ Reset link inafungua web page
- ✅ Security question ina-display
- ✅ CAPTCHA inafanya kazi
- ✅ Password reset email inatumwa
- ✅ Voter anaweza kuingia na password mpya

---

**Status:** 🚀 Ready for Deployment  
**Cost:** 💰 COMPLETELY FREE  
**Hosting:** GitHub Pages  
**SSL:** ✅ Free HTTPS  

**Deploy NOW!** 🎉
