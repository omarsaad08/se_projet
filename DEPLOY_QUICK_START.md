# Quick Firebase Deployment Steps

## Pre-Deployment Checklist

- [ ] Node.js and npm installed
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Flutter SDK updated (`flutter upgrade`)
- [ ] Firebase project created at https://console.firebase.google.com
- [ ] Updated backend URL in `lib/data/ndvi_services.dart`
- [ ] Updated CORS headers in backend `src/index.php`

## One-Command Deployment

### Using PowerShell (Windows):
```powershell
cd d:\projects\se_project
.\deploy.ps1
```

### Using Batch (Windows):
```cmd
cd d:\projects\se_project
deploy.bat
```

### Using Terminal (macOS/Linux):
```bash
cd ~/path/to/se_project
flutter clean && flutter pub get && flutter build web --release --minify && firebase deploy --only hosting
```

## Manual Step-by-Step

If you prefer to run commands individually:

```powershell
# 1. Navigate to project
cd d:\projects\se_project

# 2. Login to Firebase (first time only)
firebase login

# 3. Clean project
flutter clean

# 4. Get dependencies
flutter pub get

# 5. Build for production
flutter build web --release --minify

# 6. Deploy to Firebase
firebase deploy --only hosting
```

## After Deployment

1. **Get Your URL**: Firebase will show your hosting URL in the console
   - Format: `https://[PROJECT-ID].firebaseapp.com`

2. **Update Backend URL**: If needed, update the API endpoint:
   ```dart
   // lib/data/ndvi_services.dart
   static const String _baseUrl = "https://your-deployed-url.com";
   ```

3. **Test Live App**: Visit the URL and test all features

4. **Monitor Performance**: Check Firebase Console for analytics

## Troubleshooting

### "firebase: command not found"
```powershell
npm install -g firebase-tools
```

### "Flutter not found"
```powershell
flutter upgrade
```

### "No hosting url in firebase.json"
The `firebase.json` file is already configured. If missing, re-run:
```powershell
firebase init hosting
```

### "Blank white page after deployment"
- Check browser console for errors
- Verify ngrok/backend URL is updated
- Clear browser cache

### "CORS errors"
Update backend CORS headers with your Firebase URL:
```php
header("Access-Control-Allow-Origin: https://[YOUR-FIREBASE-URL]");
```

## Build Size Optimization

If build is too large:

```powershell
# Check what's taking space
flutter build web --release --analyze-size

# Use aggressive minification
flutter build web --release --minify

# Optional: Enable skwasm for better performance
flutter build web --release --minify --dart-define=FLUTTER_WEB_USE_SKWASM=true
```

## Rollback to Previous Version

```powershell
# List all versions
firebase hosting:versions:list

# Promote a previous version to live
firebase hosting:versions:promote [VERSION-ID]
```

## Custom Domain Setup

1. Go to Firebase Console → Hosting
2. Click "Connect domain"
3. Add your domain
4. Update DNS records as shown
5. Wait for SSL certificate (can take 24 hours)

## Need Help?

- Firebase Console: https://console.firebase.google.com
- Firebase CLI Docs: https://firebase.google.com/docs/cli
- Flutter Web Docs: https://flutter.dev/platform/web
- This Project: Check `FIREBASE_DEPLOYMENT.md` for detailed guide

## Environment Setup (for CI/CD)

If you want automated deployments via GitHub Actions, see `FIREBASE_DEPLOYMENT.md` for the GitHub Actions workflow example.
