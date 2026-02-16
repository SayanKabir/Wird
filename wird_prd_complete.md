# 🌙 Wird – Product Requirements Document (PRD)

**Version:** 2.0  
**Last Updated:** January 30, 2026  
**Platform:** Android (min SDK 31 / Android 12)  
**Framework:** Flutter 3.16+  
**Phase Focus:** Prayer Tracking + Notifications (MVP)  
**Document Owner:** Product Team

---

## 📋 Table of Contents

1. [Executive Summary](#1--executive-summary)
2. [Product Vision](#2--product-vision)
3. [Success Metrics](#3--success-metrics)
4. [Target User](#4--target-user)
5. [Core Features](#5--core-features)
6. [Prayer System](#6--prayer-system)
7. [Live Prayer Intelligence](#7--live-prayer-intelligence)
8. [Notification System](#8--notification-system)
9. [Location Handling](#9--location-handling)
10. [Qibla Direction](#10--qibla-direction)
11. [UI/UX: Celestial Zen System](#11--uiux-celestial-zen-system)
12. [Streak & Analytics](#12--streak--analytics)
13. [Settings & Preferences](#13--settings--preferences)
14. [Onboarding Flow](#14--onboarding-flow)
15. [Edge Cases & Error Handling](#15--edge-cases--error-handling)
16. [Accessibility Requirements](#16--accessibility-requirements)
17. [Performance & Battery](#17--performance--battery)
18. [Privacy & Data](#18--privacy--data)
19. [Technical Architecture](#19--technical-architecture)
20. [Phase Roadmap](#20--phase-roadmap)
21. [Appendix](#21--appendix)

---

## 1. 📊 Executive Summary

**Wird** is a minimalist Islamic prayer companion app that helps Muslims maintain consistent daily prayer discipline through precision timing, low-friction tracking, and a calming, time-aware interface.

### Key Differentiators
- **Celestial Zen UI**: Dynamic interface that reflects real-time sun position and prayer phases
- **Offline-First**: No account, no cloud, complete privacy
- **Smart Notifications**: Exact timing with intelligent end-time warnings and snooze logic
- **Detailed Tracking**: Beyond simple checkboxes - track on-time vs. late vs. missed vs. congregation

### Target Launch
Phase 1 MVP: Q2 2026

---

## 2. 🎯 Product Vision

### Mission Statement
*"To help Muslims strengthen their connection with Allah through consistent prayer practice, using technology that respects their time, privacy, and spiritual focus."*

### Core Principles
1. **Spiritual Focus**: Technology serves worship, not vice versa
2. **Respect Time**: Precise calculations, no bloat
3. **Privacy First**: Your prayers are between you and Allah
4. **Meaningful Design**: Every pixel has purpose
5. **Accessibility**: Serve all Muslims, regardless of ability

### What Wird Is NOT
❌ A social network  
❌ A Quran app  
❌ A content feed  
❌ A monetization platform  

---

## 3. 📈 Success Metrics

### North Star Metric
**Weekly Prayer Completion Rate (PCR)**  
= (Prayers Prayed On Time / Total Scheduled Fardh Prayers) × 100

**Target:** 15% improvement in PCR within 30 days of use

### Primary Metrics (Track Weekly)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Daily Active Users (DAU) | 70% of MAU | App opens per day |
| Prayer Completion Rate | 75% on-time | Local analytics |
| Notification Click-Through | 60% | Notification → App open |
| Streak Retention (7-day) | 40% | Users with 7+ day streak |
| First-Week Retention | 65% | D1, D3, D7 retention |

### Secondary Metrics
- Average time to mark prayer (goal: <3 seconds)
- Notification snooze rate (track if >30% = UX issue)
- Qibla screen usage (engagement indicator)
- Settings modification rate (complexity indicator)

### Analytics Implementation
- **Local-only analytics** using Hive
- Daily summary stats stored locally
- No external tracking/telemetry
- Optional anonymous usage report (opt-in only, Phase 2)

---

## 4. 👤 Target User

### Primary Persona: "Consistent Seeker"

**Name:** Ahmed, 28  
**Occupation:** Software developer  
**Location:** Urban area (good connectivity)  
**Prayer Status:** Prays regularly but inconsistent with timing

**Goals:**
- Improve prayer consistency
- Track progress without judgment
- Minimize friction in daily routine
- Maintain privacy

**Pain Points:**
- Other apps are cluttered with ads/features
- Generic notifications easy to ignore
- Unsure if prayer was on-time or late
- Wants to improve but lacks accountability

**Tech Comfort:** High (can navigate settings)

### Secondary Persona: "Elder Worshipper"

**Name:** Fatima, 58  
**Occupation:** Retired teacher  
**Tech Comfort:** Low-Medium

**Needs:**
- Large, readable text
- Simple interface
- Reliable notifications
- Accessible without reading glasses

**Constraints:**
- May not understand complex settings
- Needs clear visual feedback
- Requires high-contrast modes

---

## 5. 🎯 Core Features (Phase 1)

### Must Have (P0)
✅ Accurate prayer time calculations  
✅ Fardh prayer tracking (5 daily prayers)  
✅ Start-time notifications  
✅ End-time warning notifications  
✅ Live countdown to next prayer  
✅ Basic streak tracking  
✅ Qibla compass  
✅ Dynamic celestial UI  
✅ Offline functionality  

### Should Have (P1)
✅ Optional Sunnah prayers (Tahajjud, Ishraq, Duha)  
✅ Snooze functionality  
✅ Congregation tagging  
✅ Prayer-specific streaks  
✅ Multiple calculation methods  
✅ Madhab selection  

### Could Have (P2 - Future)
⏳ Rawatib Sunnah tracking  
⏳ Monthly heatmap  
⏳ Achievement badges  
⏳ Azkar & Tasbih counter  
⏳ Smart location change detection  

---

## 6. 🕌 Prayer System

### 6.1 Prayer Types

#### Fardh Prayers (Always Included)

| Prayer | Arabic | Typical Time |
|--------|--------|--------------|
| Fajr | الفجر | Before sunrise |
| Dhuhr* | الظهر | Midday |
| Asr | العصر | Afternoon |
| Maghrib | المغرب | Sunset |
| Isha | العشاء | Night |

*Dhuhr is **replaced** with Jumuah (الجمعة) on Fridays

#### Optional Sunnah Prayers (User-Selectable)

| Prayer | Arabic | Calculation |
|--------|--------|-------------|
| Tahajjud | التهجد | Last third of night (Isha + 2/3 × night duration) |
| Ishraq | الإشراق | 15 minutes after sunrise |
| Duha | الضحى | Mid-morning (sunrise + 1/4 day until zenith) |

**Note:** Rawatib prayers (before/after Fardh) are planned for Phase 2

### 6.2 Prayer Status States

Each prayer can be marked with **one primary state** plus optional **modifiers**:

#### Primary States

| Status | Icon | Meaning | Affects Streak |
|--------|------|---------|----------------|
| **Prayed On Time** | ✅ | Completed within valid window | ✅ Positive |
| **Prayed Late (Qadha)** | 🕓 | Completed after time window ended | ⚠️ Neutral |
| **Missed** | ❌ | Time ended, not completed | ❌ Breaks streak |
| **Pending** | ⏳ | Current prayer, not yet completed | — |
| **Upcoming** | 🔵 | Future prayer today | — |

#### Optional Modifiers

| Modifier | Icon | Meaning | UI Display |
|----------|------|---------|------------|
| **Congregation (Jama'ah)** | 🕌 | Prayed in group | Small badge on card |

**Interaction Rules:**
- User can mark prayer complete **anytime** (even before its time starts = early Qadha)
- Once marked, user can **edit status** until midnight
- After midnight, prayer log is **locked** (maintains historical integrity)

### 6.3 Time Window Definitions

Prayer windows are calculated using the **adhan** package:

| Prayer | Start Time | End Time |
|--------|-----------|----------|
| Fajr | Fajr adhan | Sunrise |
| Dhuhr | Dhuhr adhan | Asr adhan |
| Asr | Asr adhan | Maghrib adhan |
| Maghrib | Maghrib adhan | Isha adhan |
| Isha | Isha adhan | Midnight (Islamic) |
| Tahajjud | Last 1/3 of night begins | Fajr adhan |
| Ishraq | Sunrise + 15 min | Dhuhr adhan - 10 min |
| Duha | Ishraq end | 15 min before Dhuhr |

**Islamic Midnight Calculation:**  
`Midnight = Maghrib + (Fajr - Maghrib) / 2`

### 6.4 Friday (Jumuah) Logic

**Behavioral Changes:**
- Dhuhr prayer is **replaced** by Jumuah in the UI
- Timing remains the same (Dhuhr time slot)
- Notification says "It is time for Jumuah" instead of "Dhuhr"
- Prayer card shows "Jumuah الجمعة" instead of "Dhuhr الظهر"

**Technical Implementation:**
```dart
bool isFriday = DateTime.now().weekday == DateTime.friday;
String displayName = (prayer == Prayer.dhuhr && isFriday) ? "Jumuah" : "Dhuhr";
```

### 6.5 Calculation Methods

Users can select from standard Islamic calculation methods:

| Method | Organization | Fajr Angle | Isha Angle | Regions |
|--------|--------------|------------|------------|---------|
| **MWL** | Muslim World League | 18° | 17° | Europe, Americas |
| **ISNA** | Islamic Society of North America | 15° | 15° | North America |
| **Umm al-Qura** | Makkah | 18.5° | 90 min after Maghrib | Saudi Arabia |
| **Egyptian** | Egyptian General Authority | 19.5° | 17.5° | Africa |
| **Karachi** | University of Karachi | 18° | 18° | Pakistan, India |
| **Tehran** | Institute of Geophysics | 17.7° | 14° | Iran |
| **Jafari** | Shia Ithna-Ashari | 16° | 14° | Shia communities |

**Default Selection Logic:**
- Use IP-based geolocation on first launch to suggest method
- Show **recommended** tag on suggested method
- User can override anytime

**High Latitude Issue:**
- For latitudes >48°, show warning: *"Prayer times may be approximate in polar regions"*
- Use "Middle of the Night" or "One-Seventh of the Night" methods

### 6.6 Madhab (Jurisprudence) Selection

Affects **Asr calculation only**:

| Madhab | Asr Starts When... | Shadow Length |
|--------|-------------------|---------------|
| **Shafi'i / Maliki / Hanbali** | Shadow = Object length + sun's shadow at zenith | 1× |
| **Hanafi** | Shadow = 2× object length + sun's shadow at zenith | 2× |

Hanafi Asr is typically **20-40 minutes later** than Standard.

**UI Display:**
- Setting: "Madhab" → Radio buttons: "Standard (Shafi'i)" / "Hanafi"
- No need to explain juristic differences in-app

---

## 7. ⏳ Live Prayer Intelligence

### 7.1 Home Screen Priority Logic

The home screen always shows the **most relevant prayer** based on current time:

```
IF current time is within ANY prayer window:
    SHOW: Active prayer card with countdown to END time
    IF prayer is already marked complete:
        SHOW: Next upcoming prayer countdown instead
    
ELSE IF all prayers for today are complete:
    SHOW: "All prayers complete 🎉"
    SHOW: Countdown to Tahajjud (if enabled) or tomorrow's Fajr
    
ELSE:
    SHOW: Next upcoming prayer with countdown to START time
```

### 7.2 Prayer Card States

| State | Visual Treatment | Countdown Shows |
|-------|------------------|-----------------|
| **Active (current prayer)** | Glowing border, pulsing animation | Time until prayer ENDS |
| **Completed** | Frosted glass, ✅ checkmark | N/A |
| **Missed** | Low opacity, red tint, ❌ icon | N/A |
| **Upcoming** | Outlined glass, medium opacity | Time until prayer STARTS |
| **Past (uncompleted)** | Dimmed, shows "Mark as Qadha?" button | N/A |

### 7.3 Countdown Display Logic

**Format:**
- If >1 hour: "2h 34m remaining"
- If <1 hour: "45m remaining"
- If <5 minutes: "3m 12s remaining" (shows seconds)
- If <1 minute: "42s remaining" (large, pulsing)

**Update Frequency:**
- >1 hour: Update every 60 seconds
- <1 hour: Update every 30 seconds
- <5 minutes: Update every 1 second

---

## 8. 🔔 Notification System

### 8.1 Notification Types

All prayers use **identical notification style** for consistency.

#### A. Start-Time Notification

**Trigger:** Exact prayer time (using `android_alarm_manager_plus`)

**Content:**
```
Title: 🕌 It is time for Asr
Body: The time for Asr prayer has begun
Sound: Soft chime (non-intrusive)
Priority: High
Actions: [Open App] [Snooze]
```

**Behavior:**
- Shows even if app is closed
- Heads-up notification (appears on screen)
- Persistent until dismissed or prayer marked complete
- Auto-dismiss when prayer time ends

#### B. End-Time Warning Notification

**Trigger:** 15 minutes before prayer window closes (configurable)

**Condition:** Only if prayer is **not yet marked as prayed**

**Content:**
```
Title: ⚠️ Asr ending soon
Body: 15 minutes remaining to pray Asr on time
Sound: Gentle alert
Priority: High
Actions: [Open App] [I've Prayed]
```

**Behavior:**
- Does not show if prayer already marked complete
- "I've Prayed" action marks prayer as complete without opening app
- Auto-dismiss when prayer time ends

### 8.2 Notification Settings (Per-Prayer)

Users can toggle for **each prayer**:
- ☑️ Start-time notification
- ☑️ End-time warning notification
- ⏰ End-time warning duration (5 / 10 / 15 / 20 / 30 minutes before)

**Default State:** All notifications ON, 15-minute warning

### 8.3 Snooze System

**Available Durations:**
- 5 minutes
- 10 minutes
- 15 minutes
- 20 minutes

**Snooze Rules:**
1. **Cannot extend beyond prayer end time**
   - If 8 minutes remain and user selects "10 min snooze" → caps at 8 minutes
   - Shows warning: "Snooze limited to 8 min (prayer ends soon)"

2. **Maximum snoozes:** 3 per prayer
   - After 3rd snooze, "Snooze" button becomes "I'll Pray Later" (marks as Qadha)

3. **Auto-cancel conditions:**
   - Prayer is marked as prayed
   - Prayer time window ends
   - User dismisses notification manually

4. **Visual feedback:**
   - Snoozed notification shows: "Snoozed until 3:45 PM"
   - Home screen shows snooze badge on prayer card

### 8.4 Technical Implementation

**Required Packages:**
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  android_alarm_manager_plus: ^3.0.0
  timezone: ^0.9.0
  permission_handler: ^11.0.0
```

**Permissions Required:**
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> <!-- Android 13+ -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

**Battery Optimization:**
- On first launch, prompt user to disable battery optimization for Wird
- Show dialog: *"To ensure prayer notifications arrive on time, please allow Wird to run in the background."*
- Deep link to system settings: `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`

**Notification Channel Setup:**
```dart
AndroidNotificationChannel channel = AndroidNotificationChannel(
  'prayer_times',
  'Prayer Time Notifications',
  description: 'Notifications for prayer times',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);
```

**Handling Missed Alarms:**
- If phone was off during prayer time, check on next boot
- Show "Missed Notification" summary if prayers were missed
- Do NOT spam multiple notifications for past prayers

---

## 9. 📍 Location Handling

### 9.1 Phase 1 Behavior (Static Location)

**Initial Location Fetch:**
1. On first app launch, request location permission
2. Fetch GPS coordinates once
3. Store coordinates in Hive: `{lat: 40.7128, lng: -74.0060}`
4. Use stored coordinates for all calculations going forward

**Permission Flow:**
```
App Launch (First Time)
    ↓
[Location Permission Dialog]
    ↓
Permission Granted ——→ Fetch GPS ——→ Store ——→ Calculate Prayers
    ↓
Permission Denied ——→ [Manual Entry Screen]
    ↓
User enters city/country
    ↓
Geocode to coordinates ——→ Store ——→ Calculate Prayers
```

**Behavior After Initial Setup:**
- GPS can be turned OFF after first launch
- App continues using stored coordinates
- No background location tracking
- No automatic updates

### 9.2 Manual Location Refresh

**Settings Screen:**
- Button: "Refresh Location"
- On tap: Re-fetch current GPS coordinates
- Show loading: "Updating location..."
- Success: "Location updated. Prayer times recalculated."
- Failure: "Unable to get location. Please check GPS and try again."

**When to Refresh:**
- User travels to new city (>50 km)
- User notices incorrect prayer times
- User relocates permanently

### 9.3 Location Permission Handling

**Android 12+ (API 31+):**
```
1. Request COARSE location first (sufficient for prayer times)
2. If denied, show rationale dialog
3. If denied again, deep link to app settings
```

**Rationale Dialog Content:**
```
Title: Location Needed
Message: Wird needs your approximate location to calculate accurate prayer times for your area. This is used once and stored locally—no tracking.
Actions: [Allow] [Enter Manually]
```

**Privacy Note:**
- Only coarse location needed (~1-5 km accuracy)
- Stored as coordinates only (not address)
- Never sent to external servers
- No location history

### 9.4 Edge Cases

| Scenario | Behavior |
|----------|----------|
| User denies location twice | Show manual city entry screen |
| GPS unavailable indoors | Show "Move to open area or enter city manually" |
| Airplane mode | Use last stored coordinates |
| Location services disabled system-wide | Show settings link + manual entry option |
| Coordinates invalid (e.g., 0,0) | Show error + force location refresh or manual entry |

### 9.5 Phase 2: Smart Location Detection

**Planned Features:**
- Background check every 24 hours (if location permission granted)
- If >50 km from stored location → show notification: "Moved to new city? Update prayer times."
- User approves → update coordinates + recalculate
- User denies → keep old coordinates

**Technical Approach:**
- Use `geolocator` package background mode
- Check distance using Haversine formula
- Respect battery life (max 1 check per day)

---

## 10. 🧭 Qibla Direction

### 10.1 Features (Phase 1)

**Core Functionality:**
- Real-time compass pointing toward Kaaba (Makkah)
- Uses device magnetometer + accelerometer
- Visual direction indicator
- Haptic feedback when aligned

**Calculation:**
```dart
// Qibla bearing from user's location to Kaaba (21.4225° N, 39.8262° E)
double qiblaBearing = Geolocator.bearingBetween(
  userLat, userLng,
  21.4225, 39.8262
);
```

### 10.2 UI Components

**Visual Elements:**
1. **Compass Rose**
   - Circular design with cardinal directions (N, E, S, W)
   - Rotates based on device orientation
   - Kaaba icon fixed at Qibla direction

2. **Alignment Indicator**
   - Centered arrow showing device heading
   - Changes color when aligned:
     - Red: >10° off
     - Yellow: 5-10° off
     - Green: <5° off (aligned)

3. **Degree Display**
   - Shows Qibla bearing: "Qibla: 58° NE"
   - Shows current heading: "Heading: 62° NE"
   - Shows offset: "3° to the right"

**Haptic Feedback:**
- Gentle buzz when entering ±2° alignment zone
- Stronger buzz when perfectly aligned (±0.5°)

### 10.3 Calibration Flow

**Magnetometer Calibration:**
- Show instruction on first use: "Move your phone in a figure-8 motion to calibrate"
- Detect if magnetometer accuracy is LOW
- Show persistent banner if accuracy < MEDIUM: "Compass accuracy low. Calibrate your device."

**Accuracy Indicators:**
```dart
// SensorStatus from flutter_compass
HIGH = Green checkmark "Calibrated"
MEDIUM = Yellow warning "Fair accuracy"
LOW = Red warning "Needs calibration"
UNRELIABLE = Error "Compass not available"
```

### 10.4 Technical Requirements

**Required Sensors:**
- Magnetometer (compass)
- Accelerometer (tilt compensation)

**Packages:**
```yaml
flutter_compass: ^0.7.0
flutter_qiblah: ^2.1.0  # For accurate calculations
permission_handler: ^11.0.0
```

**Permissions:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-feature android:name="android.hardware.sensor.compass" android:required="true"/>
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="true"/>
```

### 10.5 Error Handling

| Error | User Message | Action |
|-------|-------------|--------|
| No magnetometer | "Your device doesn't have a compass sensor" | Hide Qibla screen |
| Location unavailable | "Enable location to determine Qibla direction" | Link to settings |
| Low accuracy | "Move phone in figure-8 to calibrate compass" | Show animation |
| Interference detected | "Move away from metal objects or electronics" | Show warning banner |

### 10.6 Phase 2 Enhancements

⏳ **Planned:**
- Map view showing Kaaba location
- Distance to Makkah in km/miles
- Travel direction arc on map
- Prayer time in Makkah (for reference)
- Photo overlay mode (AR-style Qibla finder)

---

## 11. 🎨 UI/UX: Celestial Zen System

### 11.1 Design Philosophy

**Core Principles:**
1. **Time-Aware**: Interface reflects actual sun position and time of day
2. **Calming**: Soft animations, no jarring transitions
3. **Meaningful Motion**: Every animation serves a purpose
4. **Spiritual Aesthetic**: Evokes contemplation, not distraction
5. **Accessibility First**: Usable by all, beautiful for all

**NOT:**
- Gamified
- Flashy
- Distracting
- Overwhelming

### 11.2 Dynamic Gradient Background

**Gradient Changes Based on Time Anchors:**

| Time Period | Gradient Colors | Mood |
|-------------|----------------|------|
| **Tahajjud** (Last third of night) | Deep indigo → Dark blue | Spiritual stillness |
| **Fajr** (Dawn) | Soft purple → Peach → Light blue | Hopeful awakening |
| **Sunrise** | Golden amber → Warm orange | Energizing warmth |
| **Dhuhr** (Noon) | Bright sky blue → White | Clear brightness |
| **Asr** (Afternoon) | Soft amber → Light orange | Gentle warmth |
| **Maghrib** (Sunset) | Orange → Purple → Deep pink | Contemplative beauty |
| **Isha** (Night) | Deep purple → Dark indigo | Peaceful closure |

**Transition Logic:**
- Gradients transition **smoothly** over 5-minute windows
- Based on **actual prayer times**, not clock time (e.g., Fajr gradient starts at Fajr adhan)
- Use bezier easing for natural feel

**Performance:**
- Update gradient every 60 seconds (not real-time)
- Use GPU-accelerated shaders
- Freeze gradient when app is in background

### 11.3 Celestial Elements

**Sun/Moon Position Indicator:**
- Small sun ☀️ or moon 🌙 icon moves across top of screen
- Position based on **actual solar altitude angle**
- Calculated using astronomical formulas (sun's azimuth)

**Visual Implementation:**
```dart
// Simplified sun position calculation
double sunAltitude = calculateSolarAltitude(lat, lng, currentTime);
double xPosition = mapAltitudeToScreenPosition(sunAltitude);

// Moon visible between Maghrib and Fajr
bool showMoon = currentTime.isAfter(maghribTime) && currentTime.isBefore(fajrTime);
```

**Behavior:**
- Sun visible from sunrise to sunset
- Moon visible from Maghrib to Fajr
- Subtle glow effect around icon
- No dramatic movement (updates every 5 minutes)

### 11.4 Prayer Cards Design

**Card Structure:**
```
┌─────────────────────────────────┐
│ 🕌 Asr                          │  ← Prayer name + icon
│ العصر                           │  ← Arabic name
│                                 │
│ ⏳ 1h 23m remaining             │  ← Countdown (if active)
│                                 │
│ 3:45 PM - 6:12 PM              │  ← Time window
│                                 │
│ [✓ Mark as Prayed]  [🕌 Jama'ah]│  ← Action buttons
└─────────────────────────────────┘
```

**State-Based Visual Treatment:**

| State | Background | Border | Opacity | Animation |
|-------|-----------|--------|---------|-----------|
| **Active (current)** | Frosted glass | 2px glowing cyan | 100% | Subtle breathing pulse (2s cycle) |
| **Completed** | Frosted glass | 1px solid green | 90% | None |
| **Missed** | Frosted glass | 1px solid red | 60% | None |
| **Upcoming** | Outlined glass | 1px dashed white | 70% | None |
| **Past (uncompleted)** | Dark overlay | 1px dotted red | 50% | None |

**Glassmorphism Effect:**
```css
background: rgba(255, 255, 255, 0.1);
backdrop-filter: blur(10px);
border-radius: 16px;
box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.1);
```

**Responsive Sizing:**
- Mobile (portrait): Cards stack vertically, full width
- Tablet (landscape): 2-column grid
- Large screens: 3-column grid with max-width: 1200px

### 11.5 Typography

**Font Family:**
- Primary: **Inter** (clean, highly legible)
- Arabic: **Amiri** or **Scheherazade New** (traditional, readable)

**Text Hierarchy:**
| Element | Size | Weight | Use Case |
|---------|------|--------|----------|
| H1 | 32px | Bold | Screen titles |
| H2 | 24px | Semibold | Section headers |
| Body Large | 18px | Regular | Prayer names |
| Body | 16px | Regular | Times, descriptions |
| Small | 14px | Regular | Labels, captions |
| Tiny | 12px | Regular | Metadata |

**Accessibility:**
- Minimum contrast ratio: 4.5:1 (WCAG AA)
- Support system text scaling (up to 200%)
- No text smaller than 12px

### 11.6 Iconography

**Style:** Outlined, minimalist, 24px base size

**Prayer Icons:**
- Fajr: 🌅 (sunrise)
- Dhuhr: ☀️ (sun)
- Asr: 🌤️ (afternoon sun)
- Maghrib: 🌆 (sunset)
- Isha: 🌙 (moon)
- Jumuah: 🕌 (mosque)

**Status Icons:**
- Completed: ✅ (green checkmark)
- Late: 🕓 (orange clock)
- Missed: ❌ (red X)
- Pending: ⏳ (hourglass)
- Congregation: 🕌 (small mosque badge)

### 11.7 Motion Design

**Animation Principles:**
1. **Purposeful**: Every animation communicates state change
2. **Subtle**: No distracting or aggressive motion
3. **Fast**: Animations complete in <300ms
4. **Natural**: Use ease-out curves

**Key Animations:**

| Interaction | Animation | Duration | Easing |
|-------------|-----------|----------|--------|
| Prayer card tap | Scale 0.98 → 1.0 | 150ms | ease-out |
| Status change | Fade in checkmark | 200ms | ease-in-out |
| Screen transition | Slide + fade | 300ms | ease-out |
| Countdown update | Subtle number roll | 400ms | ease-in-out |
| Background gradient shift | Cross-fade | 5000ms | linear |
| Active prayer pulse | Scale 1.0 → 1.02 → 1.0 | 2000ms (loop) | ease-in-out |

**Reduced Motion:**
- Respect `AccessibilityFeatures.reduceMotion`
- Disable all decorative animations
- Keep only essential state-change animations

### 11.8 Dark Mode

**Strategy:** No separate dark mode—app is always dark-themed

**Rationale:**
- Aligns with spiritual, calming aesthetic
- Reduces eye strain during Tahajjud/Fajr
- Better for battery (OLED displays)
- Celestial gradients work best on dark canvas

**Base Colors:**
- Background: Dynamic gradient (see 11.2)
- Text: White with varying opacity (100% / 80% / 60%)
- Cards: Frosted glass (white with 10-20% opacity)
- Accents: Prayer-time-dependent (warm vs. cool tones)

---

## 12. 📊 Streak & Analytics

### 12.1 Streak Definition

**"Perfect Day" Criteria:**
- All 5 Fardh prayers marked as "Prayed On Time" ✅
- All user-enabled Sunnah prayers marked as "Prayed On Time" ✅

**Important:**
- Praying "Late (Qadha)" does NOT count toward perfect day
- Missing even one prayer breaks the streak
- Streak resets to 0 at first missed prayer

### 12.2 Streak Types

#### A. Overall Streak
- Consecutive "Perfect Days"
- Displayed prominently on home screen
- Example: "🔥 7-day streak"

#### B. Prayer-Specific Streaks
- Track consistency for each individual prayer
- Example: "Fajr: 12 days on-time"
- Useful for identifying weak points

**Display:**
```
Your Streaks:
🔥 Overall: 5 days
🌅 Fajr: 12 days
☀️ Dhuhr: 5 days
🌤️ Asr: 8 days
🌆 Maghrib: 5 days
🌙 Isha: 7 days
```

### 12.3 Metrics Tracked (Daily)

**Stored in Hive:**
```dart
class DailyPrayerLog {
  final DateTime date;
  final Map<Prayer, PrayerStatus> prayers; // Prayer → Status
  final bool isPerfectDay;
  final int overallStreak;
  final int completionPercentage; // (Prayed on-time / Total prayers) × 100
}
```

**Example:**
```json
{
  "date": "2026-01-30",
  "prayers": {
    "fajr": "on_time",
    "dhuhr": "on_time",
    "asr": "late",
    "maghrib": "on_time",
    "isha": "missed"
  },
  "isPerfectDay": false,
  "overallStreak": 0,
  "completionPercentage": 60
}
```

### 12.4 Statistics Screen (Phase 1 - Simple)

**Metrics Displayed:**
1. **Current Streak**: "🔥 5 days"
2. **Longest Streak**: "Best: 18 days"
3. **This Week**: "21/35 prayers on-time (60%)"
4. **This Month**: "87/155 prayers on-time (56%)"
5. **Prayer-Specific Breakdown**: Bar chart showing on-time % per prayer

**No Gamification:**
- No badges or achievements (Phase 2)
- No leaderboards or social features
- Focus on personal growth, not competition

### 12.5 Phase 2: Advanced Analytics

⏳ **Planned Features:**
- Monthly heatmap (GitHub-style calendar view)
- Time-of-day patterns (e.g., "You pray Asr late 40% of the time")
- Trends over time (line graph of completion %)
- Exportable prayer journal (CSV)
- Achievement badges (e.g., "30-day streak unlocked")

---

## 13. ⚙️ Settings & Preferences

### 13.1 Settings Screen Structure

**Organized in Sections:**

#### 1. Location & Prayer Times
- 📍 **Current Location**: Shows city/coordinates
- 🔄 **Refresh Location** (button)
- 📖 **Calculation Method**: Dropdown (MWL, ISNA, Umm al-Qura, etc.)
- ⚖️ **Madhab**: Radio buttons (Standard / Hanafi)

#### 2. Prayer Selection
- ☑️ **Include Tahajjud**
- ☑️ **Include Ishraq**
- ☑️ **Include Duha**

#### 3. Notifications
- Per-prayer toggles:
  - ☑️ **Fajr**: Start notification, End warning
  - ☑️ **Dhuhr**: Start notification, End warning
  - ... (repeat for all prayers)
- 🔔 **End-Time Warning**: Dropdown (5 / 10 / 15 / 20 / 30 min before)
- 🔊 **Notification Sound**: Dropdown (Default / Silent / Custom)

#### 4. Appearance
- 🎨 **Dynamic Background**: Toggle (Enable celestial gradients)
- 🌡️ **Reduce Motion**: Toggle (Accessibility)
- 🔤 **Text Size**: Slider (Small / Medium / Large / Extra Large)
- 🌐 **Language**: Dropdown (English / Arabic / Both) *[Phase 2]*

#### 5. About
- ℹ️ **Version**: 1.0.0
- 📧 **Contact Support**: Opens email
- 📜 **Privacy Policy**: Opens in-app text
- 🤲 **Make Dua for Developer**: Fun easter egg

### 13.2 Default Settings

**First-Launch Defaults:**
```dart
{
  "calculationMethod": "MWL", // Or geo-suggested
  "madhab": "standard", // Shafi'i
  "includeTahajjud": false,
  "includeIshraq": false,
  "includeDuha": false,
  "notificationsEnabled": true,
  "endTimeWarning": 15, // minutes
  "dynamicBackground": true,
  "textSize": "medium",
  "language": "english"
}
```

### 13.3 Smart Defaults (Based on Location)

**Calculation Method Suggestions:**

| Region Detected | Suggested Method |
|----------------|------------------|
| North America | ISNA |
| Europe | MWL |
| Saudi Arabia | Umm al-Qura |
| Pakistan/India | Karachi |
| Iran | Tehran |
| Shia-majority regions | Jafari |
| Other | MWL (most widely used) |

**Detection Method:**
- Use IP geolocation API (free tier): `https://ipapi.co/json/`
- Fallback: Default to MWL
- Always allow user override

### 13.4 Settings Validation

**Rules:**
- Changing calculation method → Recalculate all prayer times immediately
- Changing madhab → Recalculate Asr time only
- Changing location → Recalculate all prayer times + reset today's schedule
- Disabling Sunnah prayer → Remove from today's schedule (but keep historical logs)
- Changing end-time warning → Reschedule all pending end-time notifications

### 13.5 Data Export (Phase 2)

⏳ **Planned:**
- Export prayer logs as CSV
- Export settings as JSON (for backup)
- Import settings from file (restore)

---

## 14. 🚀 Onboarding Flow

### 14.1 Welcome Screens (First Launch)

**Screen 1: Welcome**
```
════════════════════════
     🌙 Welcome to Wird
════════════════════════

A minimalist companion for
consistent prayer practice

         [Get Started]
```

**Screen 2: Privacy Promise**
```
════════════════════════
      🔒 Your Privacy
════════════════════════

• All data stays on your device
• No accounts or sign-ups
• No tracking or analytics
• Your prayers are private

         [Continue]
```

**Screen 3: Location Permission**
```
════════════════════════
   📍 Location Needed
════════════════════════

We need your approximate location
to calculate accurate prayer times.

This is used once and stored locally.
No tracking.

   [Allow Location]  [Enter Manually]
```

**If Location Granted:**
→ Fetch GPS → Store coordinates → Continue

**If Location Denied:**
→ Show manual city entry screen

**Manual City Entry Screen:**
```
════════════════════════
   Enter Your Location
════════════════════════

City: [_____________]
Country: [_____________]

      [Find Location]

We'll use this to calculate prayer times.
You can change this anytime in Settings.
```

**Screen 4: Calculation Method**
```
════════════════════════
    📖 Calculation Method
════════════════════════

Select your preferred method for
calculating prayer times:

○ MWL (Muslim World League) [RECOMMENDED]
○ ISNA (North America)
○ Umm al-Qura (Saudi Arabia)
○ Egyptian General Authority
○ Karachi (Pakistan/India)
○ Tehran
○ Jafari (Shia)

      [Continue]

Not sure? We've suggested the most
common method for your region.
```

**Screen 5: Madhab**
```
════════════════════════
       ⚖️ Madhab
════════════════════════

This affects Asr prayer timing:

○ Standard (Shafi'i, Maliki, Hanbali)
○ Hanafi

      [Continue]

Not sure? Select "Standard"
```

**Screen 6: Notification Permission (Android 13+)**
```
════════════════════════
  🔔 Stay on Time
════════════════════════

Allow notifications to receive:

• Prayer time reminders
• End-time warnings
• Gentle nudges to stay consistent

We'll never spam you.

   [Allow Notifications]  [Skip]
```

**If Notifications Allowed:**
→ Request `POST_NOTIFICATIONS` permission

**If Notifications Denied:**
→ Continue (user can enable later in Settings)

**Screen 7: Battery Optimization**
```
════════════════════════
  🔋 Reliable Notifications
════════════════════════

To ensure prayer notifications arrive
exactly on time, please allow Wird to
run in the background.

This won't drain your battery.

   [Allow]  [Skip]
```

**If Allowed:**
→ Request `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`

**Screen 8: Optional Prayers**
```
════════════════════════
  ✨ Optional Prayers
════════════════════════

Include these Sunnah prayers?

☐ Tahajjud (Last third of night)
☐ Ishraq (After sunrise)
☐ Duha (Mid-morning)

You can change this anytime.

      [Finish Setup]
```

**Screen 9: All Set!**
```
════════════════════════
        ✅ All Set!
════════════════════════

Your prayer times are ready.

May Allah make it easy for you to
maintain consistent prayer practice.

      [Go to Home]
```

### 14.2 Onboarding UX Principles

**Design Guidelines:**
1. **Progress Indicator**: Show steps (e.g., "Step 3 of 9")
2. **Skippable**: Allow "Skip" or "Later" for non-critical steps
3. **Back Navigation**: Allow going back to change selections
4. **No Overwhelm**: One decision per screen
5. **Visual Consistency**: Use same gradient background as main app
6. **Clear CTAs**: Large, obvious buttons

**Accessibility:**
- All text must be screen-reader friendly
- Buttons must be tappable (min 44×44 dp)
- High contrast for all text

### 14.3 Re-Onboarding (Edge Cases)

**Trigger Re-Onboarding If:**
- Location coordinates are invalid (0, 0)
- No calculation method selected
- App crashes during initial setup

**Don't Re-Onboard If:**
- User manually skipped optional steps
- Permissions were denied (just show in-app prompts later)

---

## 15. ⚠️ Edge Cases & Error Handling

### 15.1 Location Errors

| Error | Cause | User Message | Recovery Action |
|-------|-------|--------------|-----------------|
| **GPS Unavailable** | No GPS hardware | "Your device doesn't support GPS" | Show manual city entry |
| **Location Permission Denied** | User denied permission | "We need location to calculate prayer times. Allow in Settings or enter manually." | [Open Settings] [Enter Manually] |
| **Location Timeout** | GPS took too long | "Unable to get location. Please try again or enter manually." | [Retry] [Enter Manually] |
| **Invalid Coordinates** | GPS returned 0,0 or corrupted data | "Location error. Please refresh location in Settings." | [Go to Settings] |
| **No Internet (Geocoding)** | Offline during manual city entry | "No internet connection. Please connect and try again." | [Retry] |

### 15.2 Notification Errors

| Error | Cause | User Message | Recovery Action |
|-------|-------|--------------|-----------------|
| **Permission Denied** | User denied notification permission | Banner: "Enable notifications in Settings to receive prayer reminders" | [Enable] [Dismiss] |
| **Exact Alarm Denied** | Android 14+ denied exact alarm | "Prayer notifications may be delayed. Allow exact alarms in Settings." | [Open Settings] |
| **Battery Optimization** | App killed by system | "Enable background activity in Settings for reliable notifications" | [Open Settings] |
| **Notification Spam** | Too many notifications queued | Consolidate into summary notification | Auto-clear old notifications |

### 15.3 Prayer Calculation Errors

| Error | Cause | User Message | Recovery Action |
|-------|-------|--------------|-----------------|
| **High Latitude** | Latitude >65° | "Prayer times may be approximate in polar regions. Please verify with local mosque." | Show warning banner |
| **No Calculation Method** | Method not set | "Please select a calculation method in Settings" | Deep link to Settings |
| **Invalid Date** | System clock wrong | "Your device clock seems incorrect. Please check date/time settings." | [Open Settings] |
| **Adhan Package Error** | Calculation failed | "Unable to calculate prayer times. Please check your location and settings." | [Refresh] [Contact Support] |

### 15.4 Data Corruption

| Error | Cause | Recovery Action |
|-------|-------|-----------------|
| **Hive Box Corrupted** | Storage corrupted | Delete corrupted box, recreate with defaults, show "Settings reset" message |
| **Prayer Log Missing** | Log deletion/corruption | Initialize empty log, mark today as incomplete |
| **Settings Invalid** | Corrupted JSON | Reset to defaults, notify user |

### 15.5 Device Compatibility

| Issue | Affected Devices | Fallback |
|-------|------------------|----------|
| **No Magnetometer** | Some budget phones | Hide Qibla screen, show "Compass unavailable" |
| **No Vibration** | Rare devices | Disable haptics silently |
| **Low Memory** | Old devices | Reduce animation complexity |
| **Android <12** | Unsupported | Show "Minimum Android 12 required" on Play Store |

### 15.6 Network Errors (Geocoding)

| Scenario | Handling |
|----------|----------|
| **No Internet During Manual Entry** | Show "Connect to internet to search for city" |
| **Geocoding API Down** | Retry 3 times, then show "Service unavailable, try again later" |
| **City Not Found** | Show "City not found. Try 'City, Country' format (e.g., 'London, UK')" |
| **Ambiguous City** | Show dropdown with multiple matches (e.g., "Portland, OR" vs "Portland, ME") |

### 15.7 Timezone Changes

| Scenario | Handling |
|----------|----------|
| **Daylight Saving Time** | Automatically adjust prayer times when DST changes |
| **User Travels Across Timezones** | If >2 hours difference, show: "Timezone changed. Refresh location?" |
| **Manual Time Change** | Detect and recalculate prayers immediately |

### 15.8 App Lifecycle Edge Cases

| Event | Behavior |
|-------|----------|
| **App Killed by System** | Reschedule all notifications on next launch |
| **Phone Reboot** | Use `BOOT_COMPLETED` broadcast to reschedule notifications |
| **Date Change at Midnight** | Clear old day's data, generate new prayer schedule |
| **User Changes System Date** | Detect and recalculate prayers for "current" date |

### 15.9 User Error Prevention

**Prevent Accidental Actions:**
- **Deleting Logs**: Require confirmation dialog
- **Changing Madhab Mid-Day**: Warn "This will recalculate today's Asr time"
- **Disabling All Notifications**: Show warning "You won't receive any prayer reminders"

**Input Validation:**
- Latitude: -90 to 90
- Longitude: -180 to 180
- Snooze duration: >0 and ≤ time remaining
- Custom times (Phase 2): Must be within valid ranges

---

## 16. ♿ Accessibility Requirements

### 16.1 WCAG Compliance

**Target:** WCAG 2.1 Level AA

**Key Requirements:**
- ✅ Color contrast ≥4.5:1 for normal text
- ✅ Color contrast ≥3:1 for large text (≥18px)
- ✅ All interactive elements ≥44×44 dp touch target
- ✅ Semantic HTML/widget structure
- ✅ Keyboard navigation support (for Android TV, future)
- ✅ No content that flashes >3 times per second

### 16.2 Screen Reader Support

**Required:**
- All buttons have semantic labels
- Prayer cards announce status clearly
- Countdown timers update screen reader
- Form fields have labels
- Error messages are announced

**Example Labels:**
```dart
Semantics(
  label: "Asr prayer, starts at 3:45 PM, ends at 6:12 PM, 1 hour 23 minutes remaining, not yet prayed",
  button: true,
  child: PrayerCard(...)
)
```

**Testing:**
- Test with TalkBack (Android)
- Ensure all content is navigable with screen reader
- No visual-only information (e.g., color-coded status must also have icon/text)

### 16.3 Text Scaling

**Support System Text Scaling:**
- Test at 100%, 150%, 200% scaling
- Ensure no text truncation or overlap
- Re-flow layouts as needed
- Minimum font size: 12sp (scales with system)

**Implementation:**
```dart
Text(
  'Prayer Time',
  style: TextStyle(
    fontSize: 16, // Automatically scales with MediaQuery.textScaleFactor
  ),
)
```

### 16.4 Color Blindness

**Ensure Status is Not Color-Dependent:**

| Status | Color | Additional Indicator |
|--------|-------|---------------------|
| Completed | Green | ✅ Checkmark icon |
| Late | Orange | 🕓 Clock icon |
| Missed | Red | ❌ X icon |
| Active | Cyan | Animated border |

**Never rely on color alone** to convey status.

**Testing:**
- Use color blindness simulators (Deuteranopia, Protanopia, Tritanopia)
- Ensure all states are distinguishable

### 16.5 Reduce Motion

**Respect `AccessibilityFeatures.disableAnimations`:**

```dart
bool reduceMotion = MediaQuery.of(context).disableAnimations;

if (!reduceMotion) {
  // Show gradient transitions, breathing pulse, etc.
} else {
  // Instant state changes, no animations
}
```

**When Reduce Motion is ON:**
- Disable breathing pulse on active prayer card
- Disable gradient transitions (instant snap)
- Disable sun/moon movement
- Keep only essential UI state changes

### 16.6 Focus Indicators

**Keyboard/D-Pad Navigation:**
- All interactive elements must show focus state
- Focus order must be logical (top-to-bottom, left-to-right)
- Focus should be visible (2px border or glow)

**Example:**
```dart
Focus(
  onFocusChange: (hasFocus) {
    setState(() {
      isFocused = hasFocus;
    });
  },
  child: Container(
    decoration: BoxDecoration(
      border: isFocused ? Border.all(color: Colors.cyan, width: 2) : null,
    ),
    child: Button(...),
  ),
)
```

### 16.7 Haptic Feedback

**Use Responsibly:**
- Provide haptic feedback for important actions (e.g., marking prayer complete)
- Make haptics **optional** (respect system settings)
- Never use haptics for decorative purposes

**Accessibility Consideration:**
- Some users find vibrations disorienting
- Respect `SemanticsService.announce` for screen reader users instead

### 16.8 Language & RTL Support (Phase 2)

⏳ **Planned:**
- Full Arabic localization
- RTL layout support
- Bi-directional text rendering
- Arabic date formats (Hijri calendar)

---

## 17. 🔋 Performance & Battery

### 17.1 Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| **App Launch Time** | <2 seconds (cold start) | Time to first meaningful paint |
| **Prayer Calculation** | <100ms | Time to generate daily schedule |
| **Screen Transition** | <300ms | Frame time during navigation |
| **Memory Usage** | <100 MB | Average RAM usage |
| **APK Size** | <15 MB | Installed size |

### 17.2 Battery Optimization

**Strategies:**
1. **Update Gradients Sparingly**
   - Update every 60 seconds, not real-time
   - Freeze updates when app is in background
   - Use GPU shaders instead of CPU redraws

2. **Minimize Wake Locks**
   - Only wake device for notifications
   - Release wake locks immediately after notification

3. **Efficient Notifications**
   - Use `exact` alarms only when necessary
   - Batch notification updates
   - Cancel unnecessary pending notifications

4. **Location**
   - Fetch GPS once on first launch
   - No background location tracking (Phase 1)
   - Use coarse location (less battery than fine)

5. **Storage I/O**
   - Batch Hive writes
   - Avoid frequent small writes
   - Use lazy loading for prayer logs

### 17.3 Background Restrictions

**Android 12+ Restrictions:**
- Exact alarms require `SCHEDULE_EXACT_ALARM` permission
- Foreground service restrictions
- Background location access limits

**Compliance:**
- Request only necessary permissions
- Use WorkManager for non-urgent tasks
- Explain why exact alarms are needed

**Battery Optimization Prompt:**
```
To ensure prayer notifications arrive
exactly on time, please allow Wird to
run in the background.

This setting prevents Android from
delaying notifications. It won't drain
your battery significantly.

[Allow]  [Skip]
```

### 17.4 Performance Monitoring

**Local Monitoring (No External Analytics):**
- Track app crashes (store locally in Hive)
- Log slow operations (>1 second)
- Monitor memory spikes

**No External Services:**
- No Firebase Analytics
- No Crashlytics
- All monitoring is local-only

---

## 18. 🔒 Privacy & Data

### 18.1 Privacy Principles

1. **Local-Only Storage**: All data stays on device
2. **No Accounts**: No sign-up, no authentication
3. **No Cloud Sync**: No data leaves the device
4. **No Tracking**: No analytics, no telemetry
5. **No Third-Party SDKs**: No ad networks, no trackers
6. **Minimal Permissions**: Only request what's necessary

### 18.2 Data Stored Locally

**Hive Storage Structure:**

**Box 1: `settings`**
```json
{
  "location": {
    "lat": 40.7128,
    "lng": -74.0060,
    "city": "New York",
    "country": "USA"
  },
  "calculationMethod": "ISNA",
  "madhab": "standard",
  "includeTahajjud": false,
  "includeIshraq": false,
  "includeDuha": false,
  "notificationsEnabled": true,
  "endTimeWarning": 15,
  "textSize": "medium"
}
```

**Box 2: `prayer_logs`**
```json
{
  "2026-01-30": {
    "fajr": {
      "status": "on_time",
      "timestamp": "2026-01-30T05:34:12Z",
      "isJamaah": false
    },
    "dhuhr": {
      "status": "late",
      "timestamp": "2026-01-30T13:45:00Z",
      "isJamaah": true
    },
    // ...
  }
}
```

**Box 3: `streaks`**
```json
{
  "currentStreak": 7,
  "longestStreak": 18,
  "lastPerfectDay": "2026-01-30",
  "prayerStreaks": {
    "fajr": 12,
    "dhuhr": 5,
    "asr": 8,
    "maghrib": 5,
    "isha": 7
  }
}
```

### 18.3 What Data is NOT Stored

❌ IP address  
❌ Device identifiers (IMEI, Android ID)  
❌ Advertising ID  
❌ User name or email  
❌ Social media profiles  
❌ Usage analytics  
❌ Crash reports (except locally)  
❌ Search history  
❌ Location history  
❌ Contacts or calendar  

### 18.4 Permissions Required

**Minimal Permission Set:**

| Permission | Use Case | Required? |
|------------|----------|-----------|
| `ACCESS_COARSE_LOCATION` | Calculate prayer times | Yes (or manual entry) |
| `POST_NOTIFICATIONS` | Show prayer reminders (Android 13+) | Yes (functional) |
| `SCHEDULE_EXACT_ALARM` | Ensure on-time notifications | Yes (functional) |
| `RECEIVE_BOOT_COMPLETED` | Reschedule notifications after reboot | Yes (functional) |
| `VIBRATE` | Haptic feedback | No (nice-to-have) |
| `WAKE_LOCK` | Wake device for notifications | Yes (functional) |

**Never Request:**
- Fine location (coarse is sufficient)
- Camera
- Microphone
- Contacts
- SMS
- Phone state
- External storage (use scoped storage)

### 18.5 Privacy Policy (In-App)

**Simple, Clear Language:**

```
Wird Privacy Policy

We respect your privacy. Here's what you need to know:

1. Data Storage
   All your prayer data is stored locally on your device.
   We never send your data to any server.

2. Location
   We use your approximate location once to calculate
   prayer times. This is stored locally as coordinates.
   We never track your location.

3. No Accounts
   Wird doesn't require sign-up or authentication.
   You remain completely anonymous.

4. No Third Parties
   We don't share data with anyone because we don't
   collect any data to share.

5. Notifications
   We only send prayer time reminders. No marketing,
   no spam, no tracking.

6. Deletion
   Uninstalling the app deletes all your data permanently.

Questions? Contact us at privacy@wird.app
```

### 18.6 Google Play Store Compliance

**Data Safety Section:**
- ✅ "Data is not collected"
- ✅ "Data is not shared with third parties"
- ✅ "Data is not stored in encrypted form"
- ✅ "Users can request data deletion" (via uninstall)

**Age Rating:** Everyone

**Content Guidelines:**
- No ads
- No in-app purchases
- No social features
- No user-generated content

---

## 19. 🏗️ Technical Architecture

### 19.1 Tech Stack

**Framework:** Flutter 3.16+  
**Language:** Dart 3.2+  
**State Management:** flutter_bloc 8.1+  
**Local Storage:** Hive 2.2+  
**Notifications:** flutter_local_notifications + android_alarm_manager_plus  
**Prayer Calculations:** adhan 2.0+  
**Geolocation:** geolocator 10.0+  
**Compass:** flutter_compass 0.7+  

### 19.2 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # Root MaterialApp
│   └── routes.dart                 # Navigation
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   ├── text_styles.dart
│   │   └── durations.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── validators.dart
│   │   └── formatters.dart
│   └── services/
│       ├── prayer_service.dart      # Wraps adhan package
│       ├── notification_service.dart
│       ├── location_service.dart
│       └── storage_service.dart     # Wraps Hive
├── features/
│   ├── onboarding/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── widgets/
│   │   │   ├── prayer_card.dart
│   │   │   ├── countdown_timer.dart
│   │   │   └── celestial_background.dart
│   │   └── bloc/
│   │       └── prayer_bloc.dart
│   ├── qibla/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   ├── statistics/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   └── settings/
│       ├── screens/
│       ├── widgets/
│       └── bloc/
├── models/
│   ├── prayer.dart
│   ├── prayer_status.dart
│   ├── prayer_log.dart
│   └── settings.dart
└── widgets/
    └── common/
        ├── custom_button.dart
        ├── loading_indicator.dart
        └── error_message.dart
```

### 19.3 Core Services

#### A. PrayerService
**Responsibilities:**
- Wrap `adhan` package
- Calculate daily prayer times
- Generate prayer schedule
- Handle high latitude edge cases

**Key Methods:**
```dart
class PrayerService {
  PrayerTimes calculateTodaysPrayers(Coordinates coords, CalculationMethod method);
  PrayerTimes calculatePrayersForDate(DateTime date, Coordinates coords);
  bool isWithinPrayerWindow(Prayer prayer, DateTime time);
  DateTime getNextPrayerTime();
  Prayer getCurrentPrayer();
}
```

#### B. NotificationService
**Responsibilities:**
- Schedule prayer notifications
- Handle snooze logic
- Cancel notifications
- Reschedule after reboot

**Key Methods:**
```dart
class NotificationService {
  Future<void> scheduleStartNotification(Prayer prayer, DateTime time);
  Future<void> scheduleEndWarning(Prayer prayer, DateTime time, int minutesBefore);
  Future<void> snooze(Prayer prayer, Duration duration);
  Future<void> cancelAll();
  Future<void> rescheduleAll();
}
```

#### C. LocationService
**Responsibilities:**
- Fetch GPS coordinates
- Geocode city names
- Store location
- Detect location changes (Phase 2)

**Key Methods:**
```dart
class LocationService {
  Future<Coordinates> getCurrentLocation();
  Future<Coordinates> geocodeCity(String city, String country);
  Future<void> saveLocation(Coordinates coords);
  Coordinates? getStoredLocation();
}
```

#### D. StorageService
**Responsibilities:**
- Initialize Hive boxes
- CRUD operations on settings and logs
- Data validation

**Key Methods:**
```dart
class StorageService {
  Future<void> init();
  Future<void> saveSetting(String key, dynamic value);
  T? getSetting<T>(String key);
  Future<void> savePrayerLog(DateTime date, Map<Prayer, PrayerStatus> logs);
  Map<Prayer, PrayerStatus>? getPrayerLog(DateTime date);
}
```

### 19.4 State Management (BLoC Pattern)

**PrayerBloc** (Main Business Logic)

**States:**
```dart
abstract class PrayerState {}

class PrayerLoading extends PrayerState {}

class PrayerLoaded extends PrayerState {
  final List<Prayer> prayers;
  final Prayer? currentPrayer;
  final Prayer? nextPrayer;
  final Duration? countdown;
  final Map<Prayer, PrayerStatus> statuses;
}

class PrayerError extends PrayerState {
  final String message;
}
```

**Events:**
```dart
abstract class PrayerEvent {}

class LoadPrayers extends PrayerEvent {}

class MarkPrayerComplete extends PrayerEvent {
  final Prayer prayer;
  final PrayerStatus status;
  final bool isJamaah;
}

class UpdateCountdown extends PrayerEvent {} // Triggered every second

class RefreshPrayerTimes extends PrayerEvent {} // When location/settings change
```

### 19.5 Data Models

**Prayer Enum:**
```dart
enum Prayer {
  tahajjud,
  fajr,
  ishraq,
  duha,
  dhuhr,
  asr,
  maghrib,
  isha,
}
```

**PrayerStatus Enum:**
```dart
enum PrayerStatus {
  pending,
  onTime,
  late,
  missed,
  upcoming,
}
```

**PrayerLog Model:**
```dart
@HiveType(typeId: 1)
class PrayerLog {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final Map<Prayer, PrayerEntry> entries;

  @HiveField(2)
  final bool isPerfectDay;

  @HiveField(3)
  final int completionPercentage;
}

@HiveType(typeId: 2)
class PrayerEntry {
  @HiveField(0)
  final PrayerStatus status;

  @HiveField(1)
  final DateTime? timestamp;

  @HiveField(2)
  final bool isJamaah;
}
```

### 19.6 Testing Strategy

**Unit Tests:**
- PrayerService calculations (edge cases: high latitude, DST, midnight)
- Notification scheduling logic
- Streak calculation
- Date/time utilities

**Widget Tests:**
- Prayer card states
- Countdown timer accuracy
- Settings screen interactions

**Integration Tests:**
- Onboarding flow
- Complete prayer tracking workflow
- Notification delivery

**No E2E Tests** (Phase 1)

**Coverage Target:** >70%

---

## 20. 🗺️ Phase Roadmap

### Phase 1: MVP (Current Scope)
**Timeline:** Q2 2026  
**Goal:** Launch functional prayer tracking app

**Deliverables:**
- ✅ Prayer time calculation engine
- ✅ Fardh + 3 Sunnah prayers
- ✅ Start & end-time notifications
- ✅ Snooze functionality
- ✅ Live countdown
- ✅ Streak tracking (basic)
- ✅ Qibla compass
- ✅ Celestial Zen UI
- ✅ Settings screen
- ✅ Onboarding flow
- ✅ Offline-first architecture

**Success Criteria:**
- 1,000 downloads in first month
- 65% D7 retention
- 15% improvement in PCR for active users
- <5% crash rate

---

### Phase 2: Enhanced Analytics & Sunnah
**Timeline:** Q3 2026  
**Goal:** Deepen engagement with insights and more prayers

**Planned Features:**
- 📊 **Monthly Heatmap**: GitHub-style calendar showing perfect days
- 📈 **Trend Analysis**: "You pray Fajr late 40% of the time"
- 🏅 **Achievement Badges**: "30-day streak", "100 prayers on-time"
- 🤲 **Rawatib Sunnah**: Before/after Fardh prayers
- 📖 **Azkar Integration**: Post-prayer remembrances
- 📿 **Tasbih Counter**: Digital dhikr beads
- 🌍 **Smart Location Detection**: Auto-update when traveling >50 km
- 📂 **Data Export**: CSV export of prayer logs
- 🌐 **Arabic Localization**: Full RTL support

**Success Criteria:**
- 50% of users enable at least one Rawatib
- 30% engagement with heatmap screen
- 20% of users earn at least one badge

---

### Phase 3: Community & Advanced Features
**Timeline:** Q4 2026  
**Goal:** Build community features while maintaining privacy

**Planned Features:**
- 🕌 **Mosque Finder**: Nearby mosques with prayer times
- 👥 **Family Sharing**: Share stats with family (opt-in, local network only)
- 📅 **Hijri Calendar**: Islamic date integration
- 🌙 **Ramadan Mode**: Suhoor/Iftar times, Tarawih tracking
- 🎙️ **Custom Adhan Audio**: Upload personal adhan recordings
- ⏰ **Adjustments**: Manual time adjustments (±5 minutes)
- 🔔 **Custom Notification Sounds**: User-uploaded audio
- 📱 **Widget Support**: Home screen widgets for countdown
- ⌚ **Wear OS Support**: Smartwatch notifications

**Success Criteria:**
- 10% adoption of family sharing
- 80% user retention during Ramadan
- 4.5+ star rating on Play Store

---

### Phase 4: iOS & Beyond
**Timeline:** 2027  
**Goal:** Cross-platform expansion

**Planned:**
- 🍎 **iOS Version**: Native SwiftUI or Flutter port
- 🌐 **Web Version**: Progressive Web App
- 💻 **Desktop Apps**: Windows/macOS/Linux

---

## 21. 📎 Appendix

### 21.1 Glossary

| Term | Definition |
|------|------------|
| **Adhan** | Call to prayer |
| **Fajr** | Pre-dawn prayer |
| **Dhuhr** | Midday prayer |
| **Asr** | Afternoon prayer |
| **Maghrib** | Sunset prayer |
| **Isha** | Night prayer |
| **Jumuah** | Friday congregational prayer (replaces Dhuhr) |
| **Tahajjud** | Optional night prayer (last third of night) |
| **Ishraq** | Optional morning prayer (after sunrise) |
| **Duha** | Optional forenoon prayer |
| **Rawatib** | Sunnah prayers before/after Fardh |
| **Qadha** | Makeup prayer (prayed late) |
| **Jama'ah** | Congregational prayer |
| **Qibla** | Direction of prayer (toward Kaaba in Makkah) |
| **Madhab** | School of Islamic jurisprudence |
| **Fardh** | Obligatory act |
| **Sunnah** | Recommended act (following Prophet's example) |

### 21.2 Calculation Method Details

**Fajr & Isha Angles Explained:**
- **Fajr Angle**: Degrees below horizon when dawn begins
- **Isha Angle**: Degrees below horizon when twilight ends
- Lower angle = earlier Fajr / later Isha
- Higher angle = later Fajr / earlier Isha

**Common Differences:**
- MWL (18°) vs ISNA (15°): ~10-15 min difference
- Affects high latitude regions more significantly

### 21.3 High Latitude Methods

For latitudes >48°:

| Method | Description |
|--------|-------------|
| **Middle of the Night** | Isha = Maghrib + ½ (Fajr - Maghrib) |
| **One-Seventh** | Isha = Maghrib + 1/7 (Fajr - Maghrib) |
| **Angle-Based** | Fixed angle even if sun doesn't reach it |

**Recommendation:** Use "Middle of the Night" for latitudes >55°

### 21.4 Islamic Midnight Calculation

**Not 12:00 AM!**

Islamic midnight = midpoint between Maghrib (sunset) and next day's Fajr (dawn)

Example:
- Maghrib: 6:30 PM
- Fajr (next day): 5:30 AM
- Duration: 11 hours
- Islamic midnight: 6:30 PM + 5h 30m = **12:00 AM** (coincidentally)

But in summer:
- Maghrib: 8:30 PM
- Fajr: 4:30 AM
- Islamic midnight: 8:30 PM + 4h = **12:30 AM**

### 21.5 Asr Shadow Calculations

**Standard (Shafi'i):**
- Shadow length = Object height + Zenith shadow
- Example: 6 ft pole, 1 ft zenith shadow → Asr when shadow = 7 ft

**Hanafi:**
- Shadow length = 2 × Object height + Zenith shadow
- Example: 6 ft pole, 1 ft zenith shadow → Asr when shadow = 13 ft

**Result:** Hanafi Asr is typically 20-40 minutes later

### 21.6 Dependencies

**Complete `pubspec.yaml`:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  
  # Prayer Calculations
  adhan: ^2.0.0
  
  # Location
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Notifications
  flutter_local_notifications: ^17.0.0
  android_alarm_manager_plus: ^3.0.4
  timezone: ^0.9.2
  
  # Qibla
  flutter_compass: ^0.7.0
  flutter_qiblah: ^2.1.1
  
  # Permissions
  permission_handler: ^11.1.0
  
  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  
  # Utils
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
  flutter_lints: ^3.0.0
  mockito: ^5.4.4
```

### 21.7 Figma Design Files

⏳ **To Be Created:**
- Onboarding flow mockups
- Home screen states (active, completed, missed)
- Prayer card variations
- Qibla compass
- Settings screens
- Celestial background gradients
- Notification templates

**Link:** [Figma - Wird Design System] (TBD)

### 21.8 API References

**Adhan Package:**
- Documentation: https://pub.dev/packages/adhan
- GitHub: https://github.com/iamriajul/adhan-dart

**Calculation Methods:**
- MWL: https://www.muslimworldleague.org/
- ISNA: https://www.isna.net/
- Umm al-Qura: https://uqcrg.gov.sa/

### 21.9 Contact & Support

**Development Team:**
- Product Manager: [Name]
- Lead Developer: [Name]
- UI/UX Designer: [Name]

**Feedback Channels:**
- Email: feedback@wird.app
- GitHub Issues: github.com/wird/mobile-app/issues
- In-App: Thumbs down button → Contact Support

---

## 22. 🎯 Definition of Done

**Phase 1 is COMPLETE when:**
- ✅ All P0 features implemented and tested
- ✅ Onboarding flow complete
- ✅ 100% of accessibility requirements met (WCAG AA)
- ✅ Privacy policy finalized
- ✅ Google Play Store listing approved
- ✅ Beta testing with 50+ users complete
- ✅ <5% crash rate in beta
- ✅ Unit test coverage >70%
- ✅ Performance targets met (see 17.1)
- ✅ All edge cases documented and handled (see Section 15)

---

## 🤲 Closing Note

*This app is built with the intention of helping Muslims strengthen their prayer practice. May Allah accept this effort and make it a means of benefit for the Ummah.*

*"Indeed, prayer has been decreed upon the believers a decree of specified times." (Quran 4:103)*

**Ameen.**

---

**END OF DOCUMENT**

Version 2.0 | Last Updated: January 30, 2026
