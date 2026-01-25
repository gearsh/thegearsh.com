# Twitter API Integration - Setup Guide

## Overview
This guide explains how to set up the Twitter API integration to import your followers as artists on Gearsh.

## Prerequisites
1. A Twitter/X account (@thegearsh)
2. A Twitter Developer account with API access

## Step 1: Create a Twitter Developer Account

1. Go to [developer.twitter.com](https://developer.twitter.com/)
2. Sign in with your @thegearsh Twitter account
3. Apply for a Developer account (choose "Hobbyist" → "Making a bot")
4. Complete the application form explaining you want to import followers

## Step 2: Create a Project and App

1. Once approved, go to the Developer Portal Dashboard
2. Click "Create Project"
   - Project Name: `Gearsh Artist Import`
   - Use Case: `Making a bot`
   - Description: `Import Twitter followers as artists for the Gearsh booking platform`
3. Create an App within the project
   - App Name: `Gearsh Import Tool`

## Step 3: Generate API Keys

1. In your App settings, go to "Keys and Tokens"
2. Generate the following:
   - **API Key** (Consumer Key)
   - **API Key Secret** (Consumer Secret)
   - **Bearer Token** ← This is what you need!

3. Copy the **Bearer Token** - it looks like: `AAAAAAAAAAAAAAAAAAAAAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 4: Configure the App

Open `lib/services/twitter_api_service.dart` and replace the placeholder values:

```dart
class TwitterConfig {
  // Replace with your actual Bearer Token
  static const String bearerToken = 'YOUR_ACTUAL_BEARER_TOKEN_HERE';
  
  // Your Twitter username (without @)
  static const String gearshUsername = 'thegearsh';
}
```

## Step 5: Test the Integration

1. Run the app on your device or emulator
2. Navigate to: `/admin/import-twitter` (you can add a button in the dashboard)
3. Tap "Fetch Followers" or "Fetch Following"
4. Select the users you want to import
5. Set their categories and prices
6. Generate the code and copy it to `gearsh_artists.dart`

## Adding a Quick Access Button

You can add a button to your dashboard or settings to access the import page.
Add this to any page:

```dart
GestureDetector(
  onTap: () => context.go('/admin/import-twitter'),
  child: Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Color(0xFF1DA1F2).withAlpha(26),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.download, color: Color(0xFF1DA1F2)),
        SizedBox(width: 8),
        Text('Import from Twitter'),
      ],
    ),
  ),
),
```

## API Rate Limits

Twitter API has rate limits:
- **Followers endpoint**: 15 requests per 15 minutes
- **Following endpoint**: 15 requests per 15 minutes
- **Max results per request**: 1000 users

## Troubleshooting

### "Unauthorized" Error
- Your Bearer Token is incorrect or expired
- Regenerate the Bearer Token in the Developer Portal

### "Forbidden" Error
- Your app doesn't have the required permissions
- Make sure your Developer account has at least "Basic" access level

### No Users Returned
- The account might have no followers/following
- Check if the username is correct in `TwitterConfig.gearshUsername`

### Rate Limit Exceeded
- Wait 15 minutes and try again
- Twitter enforces strict rate limits

## Security Note

⚠️ **Important**: Never commit your Bearer Token to version control!

For production, consider:
1. Using environment variables
2. Storing tokens securely (e.g., Firebase Remote Config)
3. Using a backend proxy to hide the token

## Access the Import Page

Navigate to: `https://your-app.com/admin/import-twitter`

Or programmatically: `context.go('/admin/import-twitter')`

---

## Quick Start

1. Get Bearer Token from [developer.twitter.com](https://developer.twitter.com/)
2. Update `lib/services/twitter_api_service.dart` with your token
3. Run the app and go to `/admin/import-twitter`
4. Fetch, select, and import your followers!
