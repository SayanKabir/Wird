# 🌙 Wird
> *Your daily companion for prayer, sunnah, and spiritual growth.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

**Wird** is a minimalist, beautifully designed Islamic companion app built with Flutter. It goes beyond simple prayer times to help you build lasting spiritual habits through the revival of Sunnah practices, consistent prayer tracking, and authentic adhkar.

Designed with a **modern glassmorphic UI**, Wird focuses on serenity, focus, and gradual improvement.

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
- **Weekly Challenges**: Adopt one new Sunnah habit per week (e.g., "Smiling," "Using Siwak").
- **Gamified Progress**: Earn points, level up, and unlock authentic badges (Starter, Explorer, Reviver).
- **Video & Evidence**: Learn *how* and *why* to practice each Sunnah with authentic Hadith references.

### 📿 **Digital Tasbih & Dhikr**
- **Focused Experience**: Clean interface for counting Dhikr.
- **Lifetime Stats**: tracks every generic bead counted.
- **Presets**: Coming soon (Morning/Evening Adhkar).

### 🔔 **Smart Notifications**
- **Flexible Alerts**: Adhan, simple ping, or silent notifications.
- **Pre-Prayer Reminders**: Get notified 10 mins before time ends.
- **Sunnah Reminders**: Gentle weekly nudges to practice your active Sunnah.
- **Islamic Events**: Warnings for important days (White Days, Ashura, etc.).

### 📱 **System Integration**
- **Home Screen Widgets**: See next prayer and countdown directly on your home screen.
- **Background Updates**: Reliable background fetching for prayer times and notifications.

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

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.0+)
- Dart SDK (3.0.0+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/wird.git
   cd wird
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

---

## 🗺️ Roadmap (Phase 2 & Beyond)

- [x] **Core Prayer Tracking** (Fardh + Sunnah)
- [x] **Basic Notifications**
- [x] **Sunnah Revival System** (Beta)
- [x] **Statistics & Insights**
- [ ] **Qibla Compass** (Refining UI)
- [ ] **Full Azkar Library** (Morning/Evening)
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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<center>
Requires Android 12+ (for exact alarms) • iOS 14+
</center>
