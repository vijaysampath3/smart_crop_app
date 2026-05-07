<h1 align="center">🌾 Smart Crop Assistant</h1>

<p align="center">
  <b>An AI-powered Flutter application helping Indian farmers make smarter agricultural decisions.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/AI-GPT--4o%20via%20GitHub%20Models-181717?logo=github&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green" />
</p>

---

## 📱 Overview

**Smart Crop Assistant** is a comprehensive mobile application designed to empower Indian farmers with real-time agricultural intelligence. It combines AI-powered crop recommendations, pest detection, live weather monitoring, live market prices, warehouse planning, and a farming chatbot — all in a single, easy-to-use app.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🌱 **Crop Recommendation** | AI-guided multi-step wizard that analyzes soil data (via photo or manual input), location, and weather to suggest the best crops |
| 🐛 **Pest Detection** | Upload or capture a photo of your crop; GPT-4o vision identifies pests and provides treatment advice |
| 🌤️ **Weather Dashboard** | Real-time weather data with 7-day rainfall forecast, humidity, wind speed, UV index, and AI-generated agricultural alerts |
| 📈 **Market Prices** | Live commodity prices from data.gov.in filtered by your detected state, helping you get the best deal |
| 🏪 **Auction / Product Listing** | List your produce for auction with Cloudinary-powered image uploads |
| 🏭 **Warehouse Planner** | AI-generated warehouse plans with dimensions, budget estimates, construction steps, and alternative storage options |
| 🚚 **Transport Finder** | Discover local transport options for moving your harvest |
| 🤖 **Farming Chatbot** | A conversational AI assistant (GPT-4o) with voice input that answers any agricultural question |
| 🔐 **Authentication** | Firebase Auth with secure login/signup flow |

---

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **Backend / Database**: Firebase (Firestore, Auth, Storage, Messaging)
- **AI Models**: GPT-4o via [GitHub Models](https://github.com/marketplace/models) (Azure Inference API)
- **Weather**: OpenWeatherMap API
- **Market Data**: data.gov.in (Government of India Open Data)
- **Image Hosting**: Cloudinary
- **Charts**: fl_chart
- **On-device ML**: TFLite Flutter
- **State Management**: Provider
- **PDF Generation**: pdf + printing packages
- **Voice Input**: speech_to_text
- **Text-to-Speech**: flutter_tts
- **Location**: Geolocator + Geocoding

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.x`
- [Dart SDK](https://dart.dev/get-dart) `^3.11.1`
- A Firebase project (see [Firebase setup](#-firebase-setup))
- API keys for the external services listed below

### 1. Clone the Repository

```bash
git clone https://github.com/vijaysampath3/smart_crop_app.git
cd smart_crop_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication**, **Cloud Firestore**, **Firebase Storage**, and **Firebase Messaging**
3. Register your Android / iOS app in the Firebase Console
4. Download the config files:
   - Android: `google-services.json` → place in `android/app/`
   - iOS: `GoogleService-Info.plist` → place in `ios/Runner/`
5. Copy the example Firebase options file and fill in your project credentials:
   ```bash
   cp lib/firebase_options.dart.example lib/firebase_options.dart
   ```
   Then replace the placeholder values in `firebase_options.dart` with your actual Firebase project config.

### 4. API Keys

All secrets are injected at build time using `--dart-define` flags. **Do not hardcode any keys in the source code.**

| Variable | Description |
|---|---|
| `CLOUDINARY_CLOUD_NAME` | Your Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret |
| `OPENWEATHER_API_KEY` | OpenWeatherMap API key |
| `GITHUB_API_KEY` | GitHub Personal Access Token with `models:read` permission (used for GPT-4o) |
| `GITHUB_CROP_API_KEY` | (Optional) Separate GitHub PAT for crop recommendation AI |
| `GITHUB_PEST_API_KEY` | (Optional) Separate GitHub PAT for pest detection AI |

### 5. Run the App

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_API_KEY=your_api_key \
  --dart-define=CLOUDINARY_API_SECRET=your_api_secret \
  --dart-define=OPENWEATHER_API_KEY=your_openweather_key \
  --dart-define=GITHUB_API_KEY=your_github_pat
```

> **Tip**: You can create a `.env.sh` script or use VS Code launch configurations to avoid typing these flags every time.

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart        # App-level config
│   │   └── app_secrets.dart       # Secure env-based secrets
│   └── services/
│       ├── weather_service.dart   # OpenWeather integration
│       └── market_service.dart    # data.gov.in integration
├── features/
│   ├── auth/                      # Firebase Auth flow
│   ├── crop_recommendation/       # Multi-step crop wizard + AI
│   ├── pest_detection/            # Camera + GPT-4o vision
│   ├── weather/                   # Weather dashboard & alerts
│   ├── market/                    # Live market prices & auctions
│   ├── warehouse/                 # AI warehouse planner
│   ├── transport/                 # Transport finder
│   ├── chatbot/                   # Farming chatbot (voice + text)
│   └── home/                      # Home screen
├── screens/
│   └── chat_bot_screen.dart
├── theme/
│   └── app_theme.dart
└── main.dart
```

---

## 🔐 Security

- **No secrets are committed to this repository.** All API keys are injected at runtime using `--dart-define`.
- `lib/firebase_options.dart` is gitignored — use the provided `.example` file as a template.
- GitHub Push Protection is enabled on this repository.

---

## 📸 Screenshots

> *(Add screenshots of the app here)*

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👨‍💻 Author

**Vijay Sampath**
- GitHub: [@vijaysampath3](https://github.com/vijaysampath3)
