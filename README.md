# ExamiQ - Online Quiz & Examination System 🎓📱💻

![Flutter](https://img.shields.io/badge/Flutter-3.32.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20Web%20%7C%20iOS%20%7C%20Desktop-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**ExamiQ** is a cross-platform Online Quiz and Examination System built with Flutter & Dart. It offers interactive exams, real-time score tracking, leaderboards, admin management, and automated certificate generation.

---

## 🌐 Live Demo & Downloads

* 🔗 **Live Web Application:** [https://pranathi062004.github.io/online_quiz_and_examination_system/](https://pranathi062004.github.io/online_quiz_and_examination_system/)
* 📱 **Android Release APK:** [Download app-release.apk](https://github.com/pranathi062004/online_quiz_and_examination_system/raw/main/web/downloads/app-release.apk)
* 📦 **GitHub Repository:** [pranathi062004/online_quiz_and_examination_system](https://github.com/pranathi062004/online_quiz_and_examination_system)

---

## 🌟 Key Features

* 📱 **Cross-Platform Support**: Runs natively on Android, Web, iOS, macOS, Windows, and Linux.
* 🔐 **Authentication & Roles**: Student & Admin portal workflows with auth provider state management.
* 📝 **Interactive Exam Engine**: Real-time timer countdown, question flag navigation, single/multi-choice selection, and submission confirmation.
* 📊 **Instant Score & Analytics**: Performance breakdown, pass/fail status, topic mastery metrics, and detailed answer keys.
* 🏆 **Leaderboard System**: Top rankers and peer score comparisons.
* 🎓 **Certificate Generation**: Automated PDF/Web printable certificates for passed examinations.
* ⚙️ **Admin Control Panel**: Interface to manage question banks, schedule exams, and audit student attempts.
* 🌓 **Modern Dark Design**: Glassmorphism UI tokens, micro-animations, and responsive layouts.

---

## 🛠️ Vercel Deployment & `vercel.json`

The project includes a pre-configured `vercel.json` file in the root directory for instant hosting on Vercel:

```json
{
  "version": 2,
  "cleanUrls": true,
  "outputDirectory": "build/web",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### Hosting on Vercel (Step-by-Step):
1. Go to [Vercel Dashboard](https://vercel.com/new) and log in with GitHub.
2. Select the repository **`pranathi062004/online_quiz_and_examination_system`**.
3. Click **Deploy**. Vercel will automatically read `vercel.json` and serve your single-page app (SPA).

---

## 🚀 How to Run Locally

### Prerequisites
* Flutter SDK (v3.22+)
* Android Studio / Chrome

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/pranathi062004/online_quiz_and_examination_system.git

# 2. Navigate into project folder
cd online_quiz_and_examination_system

# 3. Fetch dependencies
flutter pub get

# 4. Run on local Chrome (Web)
flutter run -d chrome

# 5. Run on Android Device / Emulator
flutter run -d android
```

---

## 📦 Building Production Binaries

### Build Android APK
```bash
flutter build apk --release
```
*Output file:* `build/app/outputs/flutter-apk/app-release.apk`

### Build Web Production Bundle
```bash
flutter build web --release
```
*Output folder:* `build/web/`

---

## 📜 Architecture & Tech Stack

* **State Management**: Provider (`ChangeNotifierProvider`)
* **Dependency Injection**: Service Locator pattern (`GetIt` style locator)
* **Backend Adapter**: Mock Data Service togglable to Firebase Firestore (`AppConfig.useMock`)
* **UI/UX**: Custom Material 3 Dark Theme tokens

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.
