#!/usr/bin/env python3
"""
Upload APK to Google Drive
This script uploads the Gearsh APK to Google Drive for distribution.
"""

import os
import sys
import pickle
from datetime import datetime
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# If modifying these scopes, delete the token.pickle file.
SCOPES = ['https://www.googleapis.com/auth/drive.file']

# APK file path
APK_PATH = r"C:\Users\admin\StudioProjects\thegearsh.com\android\app\build\outputs\apk\debug\gearsh-app.apk"

def get_credentials():
    """Gets valid user credentials from storage or initiates OAuth flow."""
    creds = None
    token_path = 'token.pickle'
    credentials_path = 'credentials.json'

    # Check if we have saved credentials
    if os.path.exists(token_path):
        with open(token_path, 'rb') as token:
            creds = pickle.load(token)

    # If no valid credentials, let the user log in
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists(credentials_path):
                print("\n" + "="*60)
                print("GOOGLE DRIVE UPLOAD SETUP REQUIRED")
                print("="*60)
                print("\nTo upload files to Google Drive, you need to:")
                print("\n1. Go to: https://console.cloud.google.com/")
                print("2. Create a new project or select existing one")
                print("3. Enable the Google Drive API")
                print("4. Go to 'Credentials' and create OAuth 2.0 Client ID")
                print("5. Download the credentials JSON file")
                print("6. Save it as 'credentials.json' in this folder:")
                print(f"   {os.getcwd()}")
                print("\nAlternatively, you can manually upload the APK:")
                print(f"\n   APK Location: {APK_PATH}")
                print("\n   Just drag and drop it to drive.google.com")
                print("="*60)
                return None

            flow = InstalledAppFlow.from_client_secrets_file(credentials_path, SCOPES)
            creds = flow.run_local_server(port=0)

        # Save the credentials for the next run
        with open(token_path, 'wb') as token:
            pickle.dump(creds, token)

    return creds

def upload_file(service, file_path, folder_id=None):
    """Upload a file to Google Drive."""
    file_name = os.path.basename(file_path)

    # Use gearsh-app.apk as the filename with timestamp for versioning
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    versioned_name = f"gearsh-app_{timestamp}.apk"

    file_metadata = {'name': versioned_name}

    if folder_id:
        file_metadata['parents'] = [folder_id]

    media = MediaFileUpload(file_path, mimetype='application/vnd.android.package-archive')

    print(f"\nUploading {file_name} as {versioned_name}...")

    file = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id, name, webViewLink'
    ).execute()

    return file

def main():
    """Main function to upload APK to Google Drive."""
    print("\n" + "="*60)
    print("GEARSH APK UPLOADER")
    print("="*60)

    # Check if APK exists
    if not os.path.exists(APK_PATH):
        print(f"\n❌ APK not found at: {APK_PATH}")
        print("\nPlease build the APK first using:")
        print("   flutter build apk")
        return

    # Get file size
    file_size = os.path.getsize(APK_PATH) / (1024 * 1024)
    print(f"\n✅ APK found: {APK_PATH}")
    print(f"   Size: {file_size:.2f} MB")

    # Get credentials
    creds = get_credentials()
    if not creds:
        return

    # Build the Drive service
    service = build('drive', 'v3', credentials=creds)

    # Upload the file
    try:
        file = upload_file(service, APK_PATH)
        print("\n" + "="*60)
        print("✅ UPLOAD SUCCESSFUL!")
        print("="*60)
        print(f"\n   File Name: {file.get('name')}")
        print(f"   File ID: {file.get('id')}")
        print(f"   View Link: {file.get('webViewLink')}")
        print("\n" + "="*60)
    except Exception as e:
        print(f"\n❌ Upload failed: {e}")

if __name__ == '__main__':
    main()

