# smart_crop_assistant

A new Flutter project.

## 🔧 Setup for Contributors

1. Copy `android/app/google-services.json.example` → `android/app/google-services.json` and fill in your Firebase credentials.
2. Run `flutterfire configure` to regenerate `lib/firebase_options.dart`.
3. Run the app using the dev script:
   ```
   flutter run \
     --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
     --dart-define=CLOUDINARY_API_KEY=your_api_key \
     --dart-define=CLOUDINARY_API_SECRET=your_api_secret
   ```
