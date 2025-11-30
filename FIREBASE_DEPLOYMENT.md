# Firebase Hosting Deployment Guide

## Prerequisites
- Flutter SDK installed and configured
- Firebase CLI installed (`npm install -g firebase-tools`)
- Node.js and npm installed
- A Firebase project set up in the Firebase Console

## Step-by-Step Deployment

### 1. Install Firebase CLI
```powershell
npm install -g firebase-tools
```

### 2. Login to Firebase
```powershell
firebase login
```
This will open a browser window to authenticate with your Google account.

### 3. Initialize Firebase in Project (if not already done)
```powershell
cd d:\projects\se_project
firebase init hosting
```
When prompted:
- Select "Use an existing project" (or create a new one)
- Choose your Firebase project
- Set public directory to: `build/web`
- Configure as single-page app: `Yes`
- Don't overwrite index.html: `No`

### 4. Build Flutter Web App for Production
```powershell
cd d:\projects\se_project
flutter clean
flutter pub get
flutter build web --release
```

This will create optimized production build in `build/web/` directory.

### 5. Deploy to Firebase Hosting
```powershell
firebase deploy
```

Or deploy specific resources:
```powershell
firebase deploy --only hosting
```

### 6. Get Your Live URL
After successful deployment, Firebase will show your app URL:
```
Hosting URL: https://[PROJECT_ID].firebaseapp.com
or
https://[CUSTOM_DOMAIN].com (if custom domain is configured)
```

## Configuration

### Update ngrok URL for Production
Before deploying, update the base URL in your Dart service layer to use your actual backend:

**File**: `lib/data/ndvi_services.dart`
```dart
static const String _baseUrl = "https://your-backend-url.com";
// or use an environment variable
```

### Important: CORS Headers
Ensure your PHP backend has proper CORS headers configured:

**File**: `src/index.php`
```php
header("Access-Control-Allow-Origin: https://[YOUR_FIREBASE_URL]");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: *");
```

### Environment Configuration
Create different configurations for development and production:

```dart
class Environment {
  static const String devBaseUrl = "https://your-dev-backend.com";
  static const String prodBaseUrl = "https://your-prod-backend.com";
}
```

## Troubleshooting

### Issue: "No Firebase project selected"
**Solution**: Run `firebase init` and select/create a project

### Issue: Build folder not found
**Solution**: Run `flutter build web --release` first

### Issue: CORS errors after deployment
**Solution**: Update CORS headers on backend to include your Firebase URL

### Issue: Blank page or 404 errors
**Solution**: Check firebase.json rewrite configuration for single-page app setup

### Issue: Large app bundle size
**Solution**: 
- Enable minification: `flutter build web --release --minify`
- Use tree-shaking: `flutter build web --release --dart-define=FLUTTER_WEB_USE_SKWASM=true`

## Monitoring Deployment

### View Logs
```powershell
firebase hosting:log
```

### Check Deployment Status
```powershell
firebase hosting:channels:list
```

### Deploy to Preview Channel (before production)
```powershell
firebase hosting:channel:deploy [CHANNEL_NAME]
```
This creates a preview URL for testing before going live.

## Domain Configuration

To use a custom domain:

1. Go to Firebase Console → Hosting
2. Click "Connect domain"
3. Follow the DNS configuration steps
4. Update `_baseUrl` in your Dart code to match domain

## Automatic Deployments (CI/CD)

### GitHub Actions Example
Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'latest'
      
      - run: flutter pub get
      - run: flutter build web --release
      
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: '[YOUR_PROJECT_ID]'
```

## Security Checklist

- [ ] Update backend CORS headers with Firebase URL
- [ ] Update `_baseUrl` to production backend
- [ ] Remove debug mode: `flutter build web --release`
- [ ] Enable HTTPS (automatic with Firebase)
- [ ] Set up security rules if using Firestore
- [ ] Configure authentication if needed

## Performance Optimization

### Pre-deployment Checklist
- [ ] Run `flutter analyze` for code issues
- [ ] Run `flutter test` for unit tests
- [ ] Test on mobile browser (responsive design)
- [ ] Check web app manifest: `web/manifest.json`
- [ ] Optimize images in `assets/`

### Optimize Build Size
```powershell
flutter build web --release --analyze-size
```

## Rollback

If you need to rollback to a previous version:

```powershell
firebase hosting:versions:list
firebase hosting:versions:promote [VERSION_ID]
```

## Helpful Commands

```powershell
# View hosting config
firebase hosting:channels:list

# Check project info
firebase projects:list

# Test locally before deploy (optional)
firebase emulators:start

# View deployment history
firebase hosting:log
```

## After Deployment

1. Test all features on the live URL
2. Monitor performance with Firebase Analytics
3. Check error logs with Firebase Crashlytics
4. Update any hardcoded URLs if needed
5. Share the URL with stakeholders

## Need Help?

- Firebase Docs: https://firebase.google.com/docs/hosting
- Flutter Web: https://flutter.dev/platform/web
- Firebase CLI: https://firebase.google.com/docs/cli
