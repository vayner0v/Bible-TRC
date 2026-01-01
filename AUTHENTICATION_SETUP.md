# Authentication Setup Guide

This guide walks you through completing the AWS Cognito authentication setup for the Bible App.

## Overview

The authentication system consists of:
1. **AWS CDK Infrastructure** (`infrastructure/`) - Cognito User Pool with Email/Password authentication
2. **iOS AuthService** - Swift service wrapping AWS Amplify Auth API
3. **Auth UI Views** - Login, Sign Up, and related views
4. **Privacy Integration** - Auth prompt when disabling local-only mode

## Deployed Infrastructure

Your Cognito infrastructure is already deployed with the following values:

| Resource | Value |
|----------|-------|
| **User Pool ID** | `us-east-1_Lx9Qq82TV` |
| **Client ID** | `51a7mmev10jrg044j9jp38vese` |
| **Domain** | `bible-app-auth-186509.auth.us-east-1.amazoncognito.com` |
| **Region** | `us-east-1` |

## Current Status

- ✅ Email/Password authentication is **enabled and ready**
- ⏳ Apple Sign-In - Requires OAuth setup (optional)
- ⏳ Google Sign-In - Requires OAuth setup (optional)

---

## Remaining iOS Setup

## Step 4: Add Swift Packages

In Xcode, add the following Swift Package dependencies:

1. Go to **File → Add Package Dependencies**
2. Add: `https://github.com/aws-amplify/amplify-swift`
3. Select these products:
   - `Amplify`
   - `AWSCognitoAuthPlugin`

## Step 5: Configure URL Scheme

1. Open `Bible v1.xcodeproj` in Xcode
2. Select the **Bible v1** target
3. Go to **Info** tab
4. Under **URL Types**, add a new entry:
   - **Identifier**: `com.yourcompany.biblev1`
   - **URL Schemes**: `biblev1`
   - **Role**: Editor

## Step 6: Configure Social Providers

### Google Sign-In

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Navigate to **APIs & Services → Credentials**
4. Create **OAuth 2.0 Client ID** (iOS type)
5. Add your app's Bundle ID
6. Update AWS Secrets Manager secret `bible-app/google-oauth`:
   ```json
   {
     "clientId": "YOUR_GOOGLE_CLIENT_ID",
     "clientSecret": "YOUR_GOOGLE_CLIENT_SECRET"
   }
   ```

### Sign in with Apple

1. Go to [Apple Developer Console](https://developer.apple.com/)
2. Create an **App ID** with Sign in with Apple capability
3. Create a **Service ID** for web authentication
4. Create a **Sign in with Apple Key**
5. Update AWS Secrets Manager secret `bible-app/apple-oauth`:
   ```json
   {
     "clientId": "YOUR_SERVICE_ID",
     "teamId": "YOUR_TEAM_ID",
     "keyId": "YOUR_KEY_ID",
     "privateKey": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
   }
   ```

6. In Xcode, add **Sign in with Apple** capability:
   - Select the **Bible v1** target
   - Go to **Signing & Capabilities**
   - Click **+ Capability**
   - Add **Sign in with Apple**

## Step 7: Test Authentication

1. Build and run the app in Xcode
2. Go to **Settings → Privacy & Security**
3. Toggle off **Local-Only Mode**
4. The authentication sheet should appear
5. Test each method:
   - Email/Password sign-up and login
   - Sign in with Apple
   - Sign in with Google

---

## Files Created/Modified

### New Files

| File | Description |
|------|-------------|
| `infrastructure/` | AWS CDK project for Cognito |
| `Bible v1/Services/AuthService.swift` | Authentication service |
| `Bible v1/Views/Auth/AuthView.swift` | Main auth container |
| `Bible v1/Views/Auth/LoginView.swift` | Login view with social buttons |
| `Bible v1/Views/Auth/SignUpView.swift` | Sign-up view |
| `Bible v1/Resources/amplifyconfiguration.json` | Amplify configuration |

### Modified Files

| File | Changes |
|------|---------|
| `Bible v1/Utilities/PrivacyManager.swift` | Added auth flow integration |
| `Bible v1/Views/Hub/Settings/PrivacySettingsView.swift` | Added auth sheet presentation |
| `Bible v1/Bible_v1App.swift` | Added Amplify initialization |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   PrivacyManager                         │ │
│  │  localOnlyMode: Bool                                     │ │
│  │  shouldShowAuthSheet: Bool                               │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            │                                  │
│                            ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                      AuthView                            │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │ │
│  │  │  LoginView  │  │ SignUpView  │  │ Social Buttons  │  │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘  │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            │                                  │
│                            ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                    AuthService                           │ │
│  │  signUp() signIn() signInWithApple() signInWithGoogle() │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            │                                  │
└────────────────────────────┼──────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      AWS Cognito                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   User Pool                              │ │
│  │  • Email/Password Auth                                   │ │
│  │  • Apple Identity Provider                               │ │
│  │  • Google Identity Provider                              │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### "No such module 'Amplify'"
- Ensure Swift packages are added to the Xcode project
- Clean build folder (Cmd+Shift+K) and rebuild

### OAuth callback not working
- Verify URL scheme `biblev1` is configured in Info.plist
- Check callback URLs match in Cognito User Pool Client

### Social login fails
- Verify secrets are updated in AWS Secrets Manager
- Check Apple/Google developer console configurations
- Ensure bundle ID matches in all configurations

### "User pool does not exist"
- Verify `amplifyconfiguration.json` has correct Pool ID
- Ensure CDK stack deployed successfully

