# 🌙 Wird
> *Your daily companion for prayer, sunnah, and spiritual growth.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.8.0-success.svg?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

**Wird** is a minimalist, beautifully designed Islamic companion app built with Flutter. It goes beyond simple prayer times to help you build lasting spiritual habits through the revival of Sunnah practices, consistent prayer tracking, and authentic adhkar.

Designed with a **modern glassmorphic UI**, Wird focuses on serenity, focus, and gradual improvement.

---

## 📥 Download

Grab the latest signed APK from the **[Releases page](https://github.com/SayanKabir/Wird/releases/latest)**.

Wird works **fully offline** — there are no accounts, no servers, and no API keys to configure. Everything you track stays on your device.

---

## ✨ Key Features

### 🕌 **Smart Prayer Times**
- **Accurate Calculations**: Powered by the `adhan` library with support for all major calculation methods and madhabs.
- **Sunnah Prayers**: Explicit tracking for **Tahajjud**, **Ishraq**, and **Duha** prayers.
- **Dynamic Countdown**: soothing countdown timer to the next prayer, with color-coded gradients reflecting the time of day.
- **Intelligent Status**: Automatically detects "Missed" prayers if not logged in time (including Sunnahs like Fajr/Tahajjud).

### 📊 **Insightful Tracking & Analytics**
- **Habit Building**: Track your 5 daily prayers + Sunnahs.
- **Streaks & Heatmaps**: Visualize your consistency (Baraka Streaks) with beautiful graphs.
- **Missed Prayer Log**: Keep track of what you owe (Qadha) with easy makeup logging.
- **Detailed Insights**: Weekly and lifetime statistics to help you improve.

### 🌱 **Sunnah Revival System**
- **Weekly Challenges**: Adopt one new Sunnah habit per week (e.g., *Salat al-Duha*, *Surah al-Kahf on Friday*).
- **Gamified Progress**: Earn points, level up, and unlock authentic badges (Starter, Explorer, Reviver).
- **Authentic Evidence**: Learn *how* and *why* to practice each Sunnah, with every entry graded sahih or hasan and cited to its source.

### 📿 **Digital Tasbih & Dhikr**
- **Focused Experience**: Clean interface for counting Dhikr.
- **Dynamic Flows**: Guided step-by-step sequences for Morning, Evening, and After-Salah Azkar, powered by authentic Hadith.
- **Lifetime Stats**: Tracks every generic bead counted.

### 📖 **Noble Quran Reader**
- **Beautiful Typography**: Uthmani script rendered in a proper mushaf face, with its orthography marks intact.
- **Translations & Transliterations**: Available per ayah for deeper understanding.
- **Seamless Navigation**: Keep track of your reading progress effortlessly.

### 🗓️ **Islamic Calendar**
- **Hijri Dates**: Full Hijri calendar alongside Gregorian dates.
- **Significant Days**: Ramadan, Ashura, the White Days, and other events surfaced ahead of time.

### 🌤️ **Living Backgrounds**
- **Real Conditions**: Live weather from [Open-Meteo](https://open-meteo.com) — no API key required.
- **Celestial Sky**: The background tracks sun and moon position, prayer period, and moon phase.
- **Weather Effects**: Rain, clouds, and haze reflect what's actually outside, or pick a fixed theme instead.

### 🔔 **Smart Notifications**
- **Flexible Alerts**: Adhan, simple ping, or silent notifications.
- **Pre-Prayer Reminders**: Get notified 10 mins before time ends.
- **Sunnah Reminders**: Gentle weekly nudges to practice your active Sunnah.
- **Islamic Events**: Warnings for important days (White Days, Ashura, etc.).

### 📱 **System Integration**
- **Home Screen Widgets**: See next prayer and countdown directly on your home screen.
- **Background Updates**: Reliable background fetching for prayer times and notifications.

### 🎛️ **Comfort & Accessibility**
- **Adjustable Haptics**: Softened by default, and fully switchable off.
- **Reduce Motion**: Stills the animated backgrounds for a calmer, lighter screen.
- **Battery Conscious**: All timers and polling pause the moment the app leaves the foreground.

---

## 🛠️ Tech Stack

Built with ❤️ using the best of the Flutter ecosystem:

| Category | Technology | Description |
|----------|------------|-------------|
| **Core** | [Flutter](https://flutter.dev) | Framework |
| **State Management** | [flutter_bloc](https://pub.dev/packages/flutter_bloc) | Clean, testable state management |
| **Local Storage** | [Hive](https://pub.dev/packages/hive) | Fast, NoSQL database for offline data |
| **Logic** | [Adhan](https://pub.dev/packages/adhan) | High-precision astronomical prayer calculations |
| **Notifications** | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | Robust local scheduling |
| **UI/UX** | [flutter_animate](https://pub.dev/packages/flutter_animate) | Smooth, performant animations |
| **Location** | [geolocator](https://pub.dev/packages/geolocator) | Privacy-focused location services |
| **Weather** | [Open-Meteo](https://open-meteo.com) | Keyless, free weather data |
| **Widgets** | [home_widget](https://pub.dev/packages/home_widget) | Native home screen widgets |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.2+)
- Dart SDK (3.7.2+)

No API keys or environment variables are needed — clone and run.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/SayanKabir/Wird.git
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate TypeAdapters (for Hive)**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building a release APK

```bash
flutter build apk --release
```

---

## 🔒 Privacy

Wird has no backend. Prayer logs, streaks, and preferences never leave your device, and location is used only on-device to calculate prayer times and the Qibla direction. See the full [Privacy Policy](Privacy_policy.md).

---

## 🗺️ Roadmap

- [x] **Core Prayer Tracking** (Fardh + Sunnah)
- [x] **Basic Notifications**
- [x] **Sunnah Revival System**
- [x] **Statistics & Insights**
- [x] **Qibla Compass**
- [x] **Full Azkar Library & Dynamic Flows**
- [x] **Quran Reader Module**
- [x] **Islamic Calendar**
- [x] **Live Weather & Celestial Backgrounds**
- [ ] **Cloud Sync & Backup**
- [ ] **Home Screen Widgets** (Expansion)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

<center>
Requires Android 7.0+ (Nougat) • iOS 13+<br>
<sub>Exact-time prayer alarms use Android 12+ scheduling where available, falling back gracefully on older versions.</sub>
</center>
