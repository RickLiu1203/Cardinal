# Firebase Configuration Setup

This project uses Firebase for backend services. The Firebase configuration files have been excluded from version control for security reasons.

## Setup Instructions

### 1. iOS App Configuration

1. Copy the template file:
   ```bash
   cp Cardinal/GoogleService-Info-template.plist Cardinal/GoogleService-Info.plist
   ```

2. Replace the placeholder values in `Cardinal/GoogleService-Info.plist` with your actual Firebase project values:
   - `YOUR_CLIENT_ID` → Your Firebase client ID
   - `YOUR_API_KEY` → Your Firebase API key  
   - `YOUR_SENDER_ID` → Your Firebase sender ID
   - `YOUR_PROJECT_ID` → Your Firebase project ID
   - `YOUR_APP_ID` → Your Firebase app ID

3. Get these values from your Firebase Console:
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project
   - Go to Project Settings → Your apps → iOS app
   - Download the `GoogleService-Info.plist` file and use its values

### 2. App Clip Configuration

If you're using the App Clip feature, also create:
```bash
cp Cardinal/GoogleService-Info-template.plist CardinalPortfolioClip/GoogleService-Info.plist
```

Update the values in the App Clip version as well.

### 3. Security Note

**Never commit the actual `GoogleService-Info.plist` files to version control!** 

These files are already added to `.gitignore` to prevent accidental commits.

### 4. Firebase Cloud Functions

The Firebase Cloud Functions are configured to automatically detect the project from the deployment environment, so no additional configuration is needed for the backend services.

### 5. Verification

Once configured, the app should:
- Successfully authenticate with Firebase
- Connect to Firestore database
- Access Firebase Storage
- Call Cloud Functions

If you encounter issues, verify:
1. Bundle ID matches your Firebase app configuration
2. All placeholder values have been replaced
3. The Firebase project has the necessary services enabled (Auth, Firestore, Storage, Functions)
