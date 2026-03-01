# 🌙 Wird – Phase 3 PRD: Quran Reading Module

**Version:** 1.0  
**Phase:** 3 - Quran Integration  
**Build Upon:** Phase 1 (Prayer Tracking) + Phase 2 (Sunnah Revival)  
**Target Launch:** Q4 2026

---

## 📋 Executive Summary

Phase 3 adds a **minimal, distraction-free Quran reading experience** to Wird, focusing on:

- **Clean Reading Interface**: Beautiful typography, no clutter
- **Offline-First**: Download surahs for reading without internet
- **Integrated Experience**: Read Quran alongside prayer times and azkar
- **Audio Recitation**: High-quality audio from multiple reciters
- **Progress Tracking**: Simple reading log, no social features
- **Privacy**: All reading data stays local

**What This IS:**
- A focused Quran reader for daily spiritual practice
- Integrated with prayer times (read after Fajr, etc.)
- Minimal, respectful, beautiful

**What This IS NOT:**
- A full-featured Quran app (no tafsir, translations into 50 languages, etc.)
- A memorization tool (Phase 4 possibility)
- A social platform for sharing verses

---

## 🎯 Goals & Success Metrics

### Primary Goals
1. **Daily Quran Engagement**: 35% of users read Quran at least 3× per week
2. **Post-Prayer Integration**: 25% of users read after Fajr prayer
3. **Completion Rate**: 10% of users complete one full Quran reading
4. **Offline Usage**: 80% of reading done offline

### Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Daily Quran Readers | 35% of DAU | Users who open Quran tab daily |
| Pages Read per Session | 3-5 pages | Average reading length |
| Audio Usage | 50% | Users who use audio recitation |
| Surah Download Rate | 60% | Users who download for offline |
| Bookmark Usage | 70% | Users who save reading position |
| Reading Streak (7-day) | 20% | Users with consistent reading |

---

## 🏗️ Core Features

### 1. 📖 Quran Reading Interface (Priority: P0)

#### 1.1 Data Source: Quran.com API (api.quran.com)

**Why Quran.com Foundation API:**
- ✅ Comprehensive, well-maintained API
- ✅ Multiple translations (30+ languages)
- ✅ Multiple reciters with high-quality audio
- ✅ Verse-by-verse synchronization
- ✅ Free for non-commercial use
- ✅ Active community and support
- ✅ Follows Uthmani script standards

**Alternative Considered:** 
- AlQuran Cloud (api.alquran.cloud) - Good but less features
- Quran API (api.quran.sutanlab.id) - Limited reciters
- Tanzil API - Good for text, limited audio

**Decision:** Use **Quran.com API** for comprehensive features

#### 1.2 API Endpoints to Use

**Base URL:** `https://api.quran.com/api/v4/`

**Key Endpoints:**

| Endpoint | Purpose | Example |
|----------|---------|---------|
| `/chapters` | Get list of all surahs | 114 surahs with metadata |
| `/chapters/{id}` | Get specific surah info | Surah Al-Fatiha details |
| `/verses/by_chapter/{id}` | Get verses of a surah | All verses with Arabic + translation |
| `/recitations` | List of reciters | Mishary Rashid, Sudais, etc. |
| `/chapter_recitations/{recitation_id}/{chapter_id}` | Audio for entire surah | MP3 file for surah |
| `/verses/by_page/{page}` | Get verses by Mushaf page | Madani Mushaf page layout |
| `/juzs` | Get Juz information | 30 Juz divisions |

**Example API Call:**
```dart
// Get Surah Al-Fatiha with English translation
GET https://api.quran.com/api/v4/verses/by_chapter/1?translations=131

Response:
{
  "verses": [
    {
      "id": 1,
      "verse_number": 1,
      "verse_key": "1:1",
      "text_uthmani": "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
      "translations": [
        {
          "id": 131,
          "language_name": "english",
          "text": "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
          "resource_name": "Dr. Mustafa Khattab, The Clear Quran"
        }
      ]
    }
  ]
}
```

#### 1.3 Reading Modes

**Three Reading Layouts:**

**A. Mushaf Mode (Default)**
- Traditional Quran page layout
- Madani Mushaf standard (604 pages)
- Shows page number (e.g., "Page 1 of 604")
- Verses laid out as in printed Quran
- Ayah numbers displayed
- Juz markers visible

```
┌─────────────────────────────────────┐
│  📖 Surah Al-Fatiha                 │
│  مكية • 7 verses • Page 1           │
├─────────────────────────────────────┤
│                                     │
│      بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ      │
│           ٱلرَّحِيمِ ١               │
│                                     │
│    ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ ٢│
│                                     │
│      ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ٣          │
│                                     │
│      مَٰلِكِ يَوۡمِ ٱلدِّينِ ٤         │
│                                     │
│  إِيَّاكَ نَعۡبُدُ وَإِيَّاكَ نَسۡتَعِينُ ٥│
│                                     │
│   ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ ٦    │
│                                     │
│  صِرَٰطَ ٱلَّذِينَ أَنۡعَمۡتَ عَلَيۡهِمۡ  │
│   غَيۡرِ ٱلۡمَغۡضُوبِ عَلَيۡهِمۡ         │
│    وَلَا ٱلضَّآلِّينَ ٧                │
│                                     │
│  🔊 [Play Surah]                    │
└─────────────────────────────────────┘
```

**B. Reading Mode (With Translation)**
- Verse-by-verse layout
- Arabic verse + translation below
- Larger text for easier reading
- Optional transliteration
- Better for study and understanding

```
┌─────────────────────────────────────┐
│  📖 Surah Al-Fatiha • 1:1           │
├─────────────────────────────────────┤
│                                     │
│   بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ │
│                                     │
│   Bismillāhi r-raḥmāni r-raḥīm      │
│   (Optional transliteration)        │
│                                     │
│   In the name of Allah, the Entirely│
│   Merciful, the Especially Merciful.│
│                                     │
│   🔊                                │
├─────────────────────────────────────┤
│                                     │
│   ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ   │
│                                     │
│   Alḥamdu lillāhi rabbi l-ʿālamīn   │
│                                     │
│   [All] praise is [due] to Allah,   │
│   Lord of the worlds.               │
│                                     │
│   🔊                                │
└─────────────────────────────────────┘
```

**C. Arabic-Only Mode**
- Pure Arabic text
- No translations or distractions
- Traditional reading experience
- Optimized for those who understand Arabic

#### 1.4 Typography & Visual Design

**Arabic Font:**
- **Primary:** Uthmanic Hafs font (from King Fahd Complex)
- **Alternative:** KFGQPC Uthmani Script (if licensing allows)
- **Fallback:** Noto Naskh Arabic (open source)
- **Size Range:** 20sp - 40sp (user adjustable)

**Translation Font:**
- **Primary:** Inter / Lato
- **Size Range:** 14sp - 24sp

**Color Scheme:**
- **Background:** Soft cream (#FFF8E7) for paper-like feel
- **Text:** Deep black (#1A1A1A) for high contrast
- **Verse Numbers:** Gold accent (#D4AF37)
- **Surah Headers:** Rich green (#2E7D32)
- **Night Mode:** Dark background with warm white text

**Reading Comfort:**
- Line height: 1.8-2.0 (generous spacing)
- Margins: 16dp minimum
- Paragraph spacing for verses
- No justified text for translations (easier to read)

#### 1.5 Navigation System

**Surah List Screen:**
```
┌─────────────────────────────────────┐
│  📖 Quran                    [Search]│
├─────────────────────────────────────┤
│                                     │
│  Recently Read:                     │
│  ┌───────────────────────────────┐ │
│  │ 📖 Al-Baqarah                 │ │
│  │ Page 45 • Last read 2h ago    │ │
│  └───────────────────────────────┘ │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  📚 All Surahs (114)                │
│                                     │
│  🕌 1. Al-Fatiha        Makkah • 7  │
│  🐄 2. Al-Baqarah       Madinah • 286│
│  👨‍👩‍👧 3. Al-Imran         Madinah • 200│
│  👩 4. An-Nisa          Madinah • 176│
│  📜 5. Al-Ma'idah       Madinah • 120│
│  🐑 6. Al-An'am         Makkah • 165│
│  🏔️ 7. Al-A'raf         Makkah • 206│
│                                     │
│  [Filter: All | Makki | Madani]    │
│  [Sort: Number | Name | Length]     │
└─────────────────────────────────────┘
```

**Navigation Features:**
- ✅ **Search**: Search by surah name or number
- ✅ **Juz Navigation**: Jump to any Juz (1-30)
- ✅ **Page Navigation**: Jump to specific Mushaf page
- ✅ **Bookmarks**: Save reading position
- ✅ **Recently Read**: Quick access to last opened surahs
- ✅ **Filter**: Makki vs Madani surahs
- ✅ **Surah Info**: See revelation context, theme, virtues

#### 1.6 Surah Information Panel

**Each surah shows:**
```
┌─────────────────────────────────────┐
│  Surah 2: Al-Baqarah (The Cow)      │
├─────────────────────────────────────┤
│  📍 Revealed in: Madinah            │
│  📝 Verses: 286                     │
│  📄 Pages: 2-49 (48 pages)          │
│  📦 Juz: 1, 2, 3                    │
│  🎯 Order of Revelation: 87         │
│                                     │
│  Theme:                             │
│  Legislation, faith, history of     │
│  Children of Israel, jihad, family  │
│  laws, and social guidance.         │
│                                     │
│  Notable Verses:                    │
│  • Verse 255: Ayat al-Kursi         │
│  • Verse 282: Longest verse         │
│  • Last 2 verses: Protection        │
│                                     │
│  [Start Reading] [Download Audio]   │
└─────────────────────────────────────┘
```

---

### 2. 🔊 Audio Recitation (Priority: P0)

#### 2.1 Reciter Selection

**Available Reciters (via Quran.com API):**

| Reciter | ID | Style | Language |
|---------|-----|-------|----------|
| **Mishary Rashid Alafasy** | 7 | Murattal (clear, slow) | Arabic |
| **Abdul Basit** | 1 | Murattal | Arabic |
| **Mahmoud Khalil Al-Hussary** | 2 | Murattal + Mujawwad | Arabic |
| **Saad Al-Ghamdi** | 3 | Murattal | Arabic |
| **AbdulRahman Al-Sudais** | 8 | Murattal | Arabic |
| **Hani ar-Rifai** | 10 | Murattal | Arabic |
| **Ibrahim Walk** | 9 | Translation recitation | English |

**Default:** Mishary Rashid Alafasy (most popular, clear pronunciation)

#### 2.2 Audio Features

**Playback Options:**
- ✅ **Play Entire Surah**: Continuous playback
- ✅ **Play Single Verse**: Tap verse to hear it
- ✅ **Play Page**: All verses on current page
- ✅ **Repeat Mode**: Repeat verse/surah/page
- ✅ **Playback Speed**: 0.75×, 1.0×, 1.25× (for memorization)
- ✅ **Auto-Scroll**: Text follows audio playback
- ✅ **Verse Highlighting**: Current verse highlighted during playback

**Audio Controls:**
```
┌─────────────────────────────────────┐
│  🔊 Now Playing: Al-Fatiha          │
│  Mishary Rashid Alafasy             │
│                                     │
│  ━━━━━━●━━━━━━━━━ 1:23 / 3:45      │
│                                     │
│  ⏮️  ⏪  ▶️  ⏩  ⏭️               │
│                                     │
│  🔁 Repeat  🎚️ Speed: 1.0×         │
└─────────────────────────────────────┘
```

#### 2.3 Offline Audio

**Download System:**
- Download entire surah audio (5-50 MB each)
- Download by Juz (larger files)
- Download individual verse audio (for memorization - Phase 4)
- Storage indicator: "1.2 GB of 2 GB used"
- Smart deletion: Auto-delete old downloaded audio if storage low

**Download UI:**
```
Surah Downloads:
✅ Al-Fatiha (2.1 MB)
✅ Al-Baqarah (48.3 MB)
⬇️ Al-Imran (Downloading... 45%)
○ An-Nisa (Not downloaded)

Total: 450 MB / 2 GB available

[Download All Quran] (1.2 GB)
[Delete All Downloads]
```

---

### 3. 📑 Reading Progress & Bookmarks (Priority: P0)

#### 3.1 Reading Log

**Track Progress:**
```dart
class ReadingSession {
  final DateTime date;
  final String surahName;
  final int surahNumber;
  final int startVerse;
  final int endVerse;
  final int pagesRead;
  final Duration readingTime;
  final bool completedSurah;
}
```

**Statistics Screen:**
```
┌─────────────────────────────────────┐
│  📊 Reading Statistics              │
├─────────────────────────────────────┤
│                                     │
│  This Week:                         │
│  📖 12 pages read                   │
│  ⏱️ 45 minutes                      │
│  🔥 5-day reading streak            │
│                                     │
│  This Month:                        │
│  📖 48 pages                        │
│  📚 4 surahs completed              │
│                                     │
│  All Time:                          │
│  📖 342 pages (56% of Quran)        │
│  📚 23 surahs completed             │
│  🏆 Longest streak: 18 days         │
│  ⏱️ Total time: 12h 34m             │
│                                     │
│  Recently Read:                     │
│  📖 Al-Baqarah (Pages 12-15) • Today│
│  📖 Al-Kahf (Complete) • Friday     │
│  📖 Yasin (Complete) • 3 days ago   │
└─────────────────────────────────────┘
```

#### 3.2 Bookmark System

**Types of Bookmarks:**

**A. Last Read Position (Auto)**
- Automatically saves when you close the app
- "Continue Reading" button on home screen
- Shows: "Al-Baqarah, Page 15, Verse 106"

**B. Manual Bookmarks**
- Long-press on any verse to bookmark
- Add optional note/label
- Unlimited bookmarks
- Organize by category (optional)

**Bookmark UI:**
```
┌─────────────────────────────────────┐
│  🔖 Bookmarks                       │
├─────────────────────────────────────┤
│                                     │
│  📍 Last Read Position              │
│  Al-Baqarah • Page 15 • Verse 106   │
│  [Continue Reading]                 │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  My Bookmarks (5):                  │
│                                     │
│  📌 Ayat al-Kursi                   │
│  Al-Baqarah • Verse 255             │
│  Note: Protection verse             │
│                                     │
│  📌 Surah Al-Kahf                   │
│  Page 293 • Friday reading          │
│                                     │
│  📌 Dua for Guidance                │
│  Al-Baqarah • Verse 286             │
│                                     │
│  [+ Add Bookmark]                   │
└─────────────────────────────────────┘
```

#### 3.3 Reading Goals (Optional)

**Simple Goal System:**
- Daily: Read 1 page, 2 pages, or 5 pages
- Weekly: Complete 1 surah
- Monthly: Complete 1 Juz
- Custom: User-defined goals

**Goal Tracking:**
```
Today's Goal: Read 2 Pages
Progress: 1/2 pages ●○

This Week's Goal: Complete Surah Yasin
Progress: 38/83 verses

Monthly Goal: Complete Juz 1
Progress: 12/21 pages
```

---

### 4. 🌐 Translation System (Priority: P1)

#### 4.1 Available Translations

**Prioritize Quality Over Quantity:**

**English (5 translations):**
1. **Dr. Mustafa Khattab** - The Clear Quran (Modern, easy to understand)
2. **Sahih International** (Most popular, accurate)
3. **Yusuf Ali** (Classic, poetic)
4. **Pickthall** (Classic)
5. **Dr. Ghali** (Literal)

**Other Languages (2-3 per major language):**
- **Urdu**: Maududi, Jalandhry
- **Arabic Tafsir**: Jalalayn (brief)
- **French**: Hamidullah
- **Turkish**: Diyanet
- **Malay**: Abdullah Basmeih
- **Bengali**: Muhiuddin Khan
- **Indonesian**: Ministry of Religious Affairs

**Total:** 15-20 high-quality translations (not 50+)

#### 4.2 Translation Selection

**Settings:**
```
Translation Settings:

Primary Translation:
○ Dr. Mustafa Khattab (The Clear Quran)
○ Sahih International
○ Yusuf Ali
○ Pickthall
○ Dr. Ghali

Show Second Translation:
☐ Enable side-by-side comparison
Secondary: [Select...]

Show Transliteration:
☑ Enable transliteration
```

**Reading View with Translation:**
- Default: Arabic + one translation
- Optional: Arabic + two translations side-by-side
- Optional: Show transliteration between Arabic and translation

---

### 5. 🔍 Search & Discovery (Priority: P1)

#### 5.1 Search Functionality

**Search Types:**

**A. Surah Search**
- Search by surah name (English or Arabic)
- Search by surah number
- Examples: "Baqarah", "البقرة", "2"

**B. Verse Search (Text Search)**
- Search within Arabic text
- Search within translation
- Examples: "those who believe", "الذين آمنوا"

**C. Topic Search (Curated)**
- Pre-defined topics with verse collections
- Examples: "Patience", "Gratitude", "Prayer", "Parents"

**Search UI:**
```
┌─────────────────────────────────────┐
│  🔍 Search Quran                    │
├─────────────────────────────────────┤
│                                     │
│  [Search box: "those who believe"]  │
│                                     │
│  Results (127 verses):              │
│                                     │
│  📖 Al-Baqarah 2:3                  │
│  "Who believe in the unseen..."     │
│                                     │
│  📖 Al-Baqarah 2:4                  │
│  "And who believe in what has..."   │
│                                     │
│  📖 Al-Baqarah 2:82                 │
│  "But they who believe and do..."   │
│                                     │
│  [Load More]                        │
└─────────────────────────────────────┘
```

#### 5.2 Quick Access Collections

**Curated Verse Collections:**

| Collection | Verses | Use Case |
|------------|--------|----------|
| **Daily Essentials** | Al-Fatiha, Ayat al-Kursi, last 2 of Baqarah | Daily protection |
| **Friday Surahs** | Al-Kahf | Weekly reading |
| **Morning Surahs** | Al-Mulk, As-Sajdah | Before sleep |
| **Duas from Quran** | 40+ supplications | Reference |
| **Stories of Prophets** | Selected verses | Learning |
| **Tawheed & Iman** | Verses on belief | Strengthening faith |
| **Patience & Trials** | Verses on sabr | Difficult times |
| **Gratitude** | Verses on shukr | Thankfulness |

**UI:**
```
┌─────────────────────────────────────┐
│  📚 Collections                     │
├─────────────────────────────────────┤
│                                     │
│  📖 Daily Essentials (5 verses)     │
│  Essential daily readings           │
│                                     │
│  📖 Friday Surah: Al-Kahf           │
│  Complete Surah Al-Kahf (110 verses)│
│                                     │
│  📖 Duas from Quran (42 duas)       │
│  Supplications from Quran           │
│                                     │
│  📖 Stories of Prophets (23 passages)│
│  Learn from prophetic examples      │
│                                     │
│  [+ Create Custom Collection]       │
└─────────────────────────────────────┘
```

---

### 6. 🎨 Reading Experience Enhancements

#### 6.1 Reading Settings

**Customization Options:**
```
┌─────────────────────────────────────┐
│  ⚙️ Reading Settings                │
├─────────────────────────────────────┤
│                                     │
│  Display Mode:                      │
│  ○ Mushaf (Page View)               │
│  ○ Reading (Verse-by-Verse)         │
│  ○ Arabic Only                      │
│                                     │
│  Arabic Font:                       │
│  ○ Uthmani Hafs (Traditional)       │
│  ○ Noto Naskh (Modern)              │
│                                     │
│  Font Size:                         │
│  Arabic: [Slider: S  M  L  XL]      │
│  Translation: [Slider: S  M  L]     │
│                                     │
│  Theme:                             │
│  ○ Cream (Default)                  │
│  ○ White                            │
│  ○ Sepia                            │
│  ○ Dark                             │
│                                     │
│  Translation:                       │
│  ☑ Show translation                 │
│  Primary: Dr. Mustafa Khattab       │
│  ☐ Show second translation          │
│                                     │
│  Transliteration:                   │
│  ☑ Show transliteration             │
│                                     │
│  Audio:                             │
│  Reciter: Mishary Rashid Alafasy    │
│  ☑ Auto-scroll during playback      │
│  ☑ Highlight current verse          │
│                                     │
│  Reading Features:                  │
│  ☑ Screen always on while reading   │
│  ☑ Swipe to change page             │
│  ☑ Volume buttons change page       │
└─────────────────────────────────────┘
```

#### 6.2 Accessibility Features

**For Visually Impaired:**
- ✅ Extra large fonts (up to 50sp)
- ✅ High contrast mode
- ✅ Screen reader support (TalkBack)
- ✅ Audio-only mode (listen without reading)

**For Learning:**
- ✅ Transliteration for non-Arabic readers
- ✅ Word-by-word translation (Phase 4 possibility)
- ✅ Slow audio playback (0.75× speed)

---

### 7. 📲 Integration with Existing Features

#### 7.1 Prayer Time Integration

**Suggested Reading Times:**

**After Fajr Prayer:**
```
✅ Fajr prayed at 5:34 AM

Suggested Reading:
📖 Read Quran after Fajr?
   (Quran recited at Fajr is witnessed)

[Read 1 Page] [Read Surah Al-Mulk]
```

**Reference:** "Establish prayer at the decline of the sun until the darkness of the night and [recite] the Quran at dawn. Indeed, the recitation of dawn is ever witnessed." (Quran 17:78)

**Friday:**
```
📅 It's Friday!

Sunnah Reminder:
📖 Read Surah Al-Kahf today

[Start Reading Al-Kahf]
```

**After Any Prayer:**
- Quick link: "Read Quran" button
- "Continue from bookmark" option

#### 7.2 Azkar Integration

**Post-Prayer Flow:**
```
After Maghrib Prayer:
1. [✓] Pray Maghrib
2. [✓] Complete post-prayer azkar
3. [ ] Read Quran (2 pages)?

[Start Reading]
```

#### 7.3 Sunnah Integration

**Weekly Sunnah:**
```
🌟 This Week's Sunnah:
Read Quran Daily

The Prophet ﷺ said: "Read the Quran, 
for it will come as an intercessor for 
its reciters on the Day of Resurrection."
(Sahih Muslim 804)

Your Progress: 3/7 days
[Continue Reading]
```

#### 7.4 Home Screen Widget

**Quran Quick Access:**
```
┌─────────────────────────────────────┐
│  🕌 Wird                             │
├─────────────────────────────────────┤
│  Next Prayer: Maghrib in 2h 15m     │
│                                     │
│  📖 Continue Reading:               │
│  Al-Baqarah • Page 15 • Verse 106   │
│  [Resume]                           │
│                                     │
│  🤲 Today's Azkar:                  │
│  Morning: ✅  Evening: ⏳           │
│                                     │
│  🌟 Weekly Sunnah: Day 3/7          │
│  Eat with right hand ✅             │
└─────────────────────────────────────┘
```

---

### 8. 💾 Offline-First Architecture

#### 8.1 Data Storage Strategy

**What's Stored Locally:**

**Tier 1: Essential (Always Cached)**
- All 114 surah metadata (names, verse counts, revelation info)
- Arabic text for all 6,236 verses (~5 MB)
- Verse numbers and surah divisions
- Madani Mushaf page mappings

**Tier 2: User-Selected**
- Downloaded translations (per language, ~2-5 MB each)
- Downloaded audio files (per reciter, per surah)
- Bookmarks and reading history
- Personal notes (future feature)

**Tier 3: Cache**
- Recently viewed pages
- Recently played audio
- Search results

**Storage Breakdown:**
```
Essential Data: 5 MB (always present)
1 Translation: 3 MB
Audio (full Quran, one reciter): 1.2 GB

Typical User:
- 1 translation: 3 MB
- 10 downloaded surahs (audio): 250 MB
- Personal data: <1 MB
Total: ~260 MB
```

#### 8.2 Sync Strategy

**Initial App Install:**
1. Download essential data (5 MB)
2. Download default translation (Dr. Mustafa Khattab, 3 MB)
3. User can optionally download more

**Offline Behavior:**
- ✅ Read Arabic text (always available)
- ✅ Read downloaded translations
- ✅ Play downloaded audio
- ❌ Search new verses (requires online first time)
- ❌ Download new audio (obviously)
- ❌ Switch to non-downloaded translation

**Online-Only Features:**
- Downloading new content
- Updating verse data (rarely needed)
- Accessing non-downloaded translations

#### 8.3 Smart Caching

**Auto-Download Suggestions:**
```
Would you like to download for offline use?

📖 Surah Al-Kahf (Friday reading)
   Arabic + Translation + Audio: 45 MB
   [Download]

📖 Juz Amma (Last Juz, most-read)
   Arabic + Translation + Audio: 120 MB
   [Download]

These are commonly read and will be 
available without internet.
```

---

### 9. 🎯 User Flows

#### 9.1 First-Time Quran User Flow

```
1. User opens Quran tab
   ↓
2. Welcome screen:
   "Assalamu Alaikum! Let's set up your Quran reading experience."
   ↓
3. Select translation:
   "Choose your preferred translation"
   [Dr. Mustafa Khattab (Recommended)]
   [Sahih International]
   [Other...]
   ↓
4. Download prompt:
   "Download for offline reading? (3 MB)"
   [Download] [Skip]
   ↓
5. Reciter selection:
   "Choose your preferred reciter"
   [Mishary Rashid Alafasy (Default)]
   [Abdul Basit]
   [Other...]
   ↓
6. Quick tutorial:
   "Swipe left/right to change pages"
   "Tap a verse to hear recitation"
   "Long-press to bookmark"
   ↓
7. Suggested starting point:
   "Where would you like to start?"
   [Surah Al-Fatiha]
   [Juz Amma (Short surahs)]
   [Browse All Surahs]
```

#### 9.2 Daily Reading Flow

```
Scenario: User wants to read after Fajr

1. Home screen shows:
   "Fajr prayed ✅ • Read Quran?"
   ↓
2. User taps "Continue Reading"
   ↓
3. Opens to last bookmark (Al-Baqarah, Page 15)
   ↓
4. User reads 2 pages
   ↓
5. Closes app → auto-bookmark saves position
   ↓
6. Stats update:
   "2 pages read today • 5-day streak 🔥"
```

#### 9.3 Friday Surah Al-Kahf Flow

```
Friday Morning:

1. Notification:
   "📅 It's Friday! Read Surah Al-Kahf today"
   ↓
2. User opens notification
   ↓
3. Opens directly to Surah Al-Kahf, Page 293
   ↓
4. Option to play audio or read silently
   ↓
5. Progress bar shows: "Page 1 of 21"
   ↓
6. User completes surah
   ↓
7. Achievement unlocked:
   "📖 Al-Kahf Master: Read Al-Kahf on Friday"
```

---

### 10. 📊 Analytics & Privacy

**Local-Only Tracking:**
```dart
class QuranAnalytics {
  // Stored in Hive, never sent anywhere
  int totalPagesRead;
  int totalVerseCount;
  int totalReadingTimeMinutes;
  int currentStreak;
  int longestStreak;
  Map<String, int> surahsCompleted; // Surah name → count
  Map<String, int> dailyPageCount; // Date → pages
  List<Bookmark> bookmarks;
  DateTime lastReadDate;
}
```

**No External Analytics:**
- No tracking of what verses you read
- No sharing of reading habits
- All statistics stay on device
- Export feature for personal backup only

---

### 11. 🏗️ Technical Implementation

#### 11.1 Data Models

```dart
class Surah {
  final int id; // 1-114
  final String nameArabic; // الفاتحة
  final String nameTranslation; // The Opening
  final String nameTransliteration; // Al-Fatiha
  final int versesCount;
  final String revelationPlace; // Makkah or Madinah
  final int revelationOrder; // 5
  final List<int> pages; // [1] or [2, 3, 4...]
  final List<int> juz; // [1] or [1, 2]
}

class Verse {
  final int surahId;
  final int verseNumber;
  final String verseKey; // "1:1"
  final String textUthmani; // Arabic text
  final String? textSimple; // Simplified Arabic
  final int page; // Madani Mushaf page
  final int juz;
  final Map<String, String> translations; // language code → translation
  final String? transliteration;
  final String? audioUrl;
}

class Bookmark {
  final String id;
  final int surahId;
  final int verseNumber;
  final int page;
  final String? label;
  final String? note;
  final DateTime createdAt;
  final bool isLastRead; // Auto-bookmark
}

class ReadingSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int surahId;
  final int startVerse;
  final int endVerse;
  final int pagesRead;
  final Duration duration;
}
```

#### 11.2 API Service Layer

```dart
class QuranApiService {
  final String baseUrl = 'https://api.quran.com/api/v4';
  
  // Surahs
  Future<List<Surah>> getAllSurahs();
  Future<Surah> getSurah(int surahId);
  
  // Verses
  Future<List<Verse>> getVersesBySurah(int surahId, {List<int>? translationIds});
  Future<List<Verse>> getVersesByPage(int page, {List<int>? translationIds});
  Future<List<Verse>> getVersesByJuz(int juz, {List<int>? translationIds});
  
  // Audio
  Future<List<Reciter>> getReciters();
  Future<String> getAudioUrl(int reciterId, int surahId);
  Future<String> getVerseAudioUrl(int reciterId, String verseKey);
  
  // Search
  Future<List<Verse>> searchVerses(String query, {String? language});
  
  // Translations
  Future<List<Translation>> getAvailableTranslations();
}

class QuranCacheService {
  // Offline storage
  Future<void> cacheEssentialData();
  Future<void> cacheTranslation(int translationId);
  Future<void> cacheSurahAudio(int reciterId, int surahId);
  Future<bool> isDataCached(String key);
  Future<dynamic> getCachedData(String key);
}

class QuranPlayerService {
  // Audio playback
  void play(String audioUrl);
  void pause();
  void seekTo(Duration position);
  void setSpeed(double speed);
  void setRepeatMode(RepeatMode mode);
  Stream<PlaybackState> get playbackState;
}
```

#### 11.3 State Management (BLoC)

```dart
// QuranBloc
abstract class QuranState {}
class QuranLoading extends QuranState {}
class QuranLoaded extends QuranState {
  final List<Surah> surahs;
  final Surah? currentSurah;
  final List<Verse> currentVerses;
  final Bookmark? lastBookmark;
}

abstract class QuranEvent {}
class LoadSurahs extends QuranEvent {}
class OpenSurah extends QuranEvent {
  final int surahId;
}
class OpenPage extends QuranEvent {
  final int page;
}
class AddBookmark extends QuranEvent {
  final Bookmark bookmark;
}

// AudioBloc
abstract class AudioState {}
class AudioPlaying extends AudioState {
  final String currentVerseKey;
  final Duration position;
  final Duration duration;
}

// ReadingBloc
abstract class ReadingEvent {}
class LogReadingSession extends ReadingEvent {
  final ReadingSession session;
}
class UpdateReadingProgress extends ReadingEvent {}
```

#### 11.4 Storage (Hive Boxes)

```
Hive Boxes:
- quran_settings
  - translation_id
  - reciter_id
  - font_size_arabic
  - font_size_translation
  - theme
  - show_transliteration
  
- quran_bookmarks
  - List<Bookmark>
  
- quran_reading_history
  - List<ReadingSession>
  
- quran_downloads
  - downloaded_translations
  - downloaded_audio_files
  
- quran_cache
  - surahs
  - verses (by page/surah)
  - audio_urls
```

---

### 12. 🎨 UI/UX Specifications

#### 12.1 Screen Hierarchy

```
Home Screen (Prayer Times)
    ├── Bottom Nav: Quran Tab
    │   ├── Surah List Screen
    │   │   ├── Search Screen
    │   │   ├── Surah Info Screen
    │   │   └── Reading Screen
    │   │       ├── Audio Player
    │   │       ├── Bookmark Menu
    │   │       └── Settings Menu
    │   ├── Bookmarks Screen
    │   ├── Reading Statistics Screen
    │   └── Collections Screen
    └── Settings
        └── Quran Settings
            ├── Translation Settings
            ├── Audio Settings
            ├── Display Settings
            └── Download Management
```

#### 12.2 Design Tokens

**Colors:**
```dart
// Light Theme (Default: Cream)
background: Color(0xFFFFF8E7)
text: Color(0xFF1A1A1A)
textSecondary: Color(0xFF757575)
accent: Color(0xFFD4AF37) // Gold
primary: Color(0xFF2E7D32) // Green
verseNumber: Color(0xFFD4AF37)

// Dark Theme
background: Color(0xFF1A1A1A)
text: Color(0xFFF5F5F5)
accent: Color(0xFFFFD700)
```

**Typography Scale:**
```dart
arabicXLarge: 40sp
arabicLarge: 32sp
arabicMedium: 24sp
arabicSmall: 20sp

translationLarge: 20sp
translationMedium: 16sp
translationSmall: 14sp

verseNumber: 14sp
surahTitle: 24sp
```

#### 12.3 Animations

**Reading Transitions:**
- Page turn: 300ms slide animation
- Verse highlight (audio): 200ms fade in/out
- Bookmark save: 150ms scale animation
- Audio controls: 200ms slide up/down

**Loading States:**
- Skeleton screens for verse loading
- Shimmer effect while downloading
- Progress bar for audio downloads

---

### 13. 📱 Accessibility

**Screen Reader Support:**
- All Arabic text has transliteration as contentDescription
- Verse numbers announced clearly
- Navigation controls properly labeled
- Audio playback states announced

**Vision Accessibility:**
- Extra large fonts (up to 50sp)
- High contrast mode (WCAG AAA)
- Adjustable line spacing
- Color blind friendly (no color-only indicators)

**Hearing Accessibility:**
- Visual indicators for audio playback
- Waveform visualization
- Verse highlighting during audio

---

### 14. ⚡ Performance Requirements

**Loading Times:**
- App launch to Quran tab: <2 seconds
- Surah list load: <500ms
- Open surah: <1 second
- Page navigation: <200ms
- Audio start: <3 seconds (network) / <500ms (cached)

**Memory Usage:**
- Background: <50 MB
- Active reading: <150 MB
- Audio playback: <200 MB

**Battery:**
- Reading only: <5% per hour
- Audio playback: <10% per hour
- Background audio: <8% per hour

---

### 15. 🧪 Testing Strategy

**Unit Tests:**
- API service methods
- Verse parsing logic
- Bookmark management
- Reading statistics calculation

**Integration Tests:**
- API to UI data flow
- Audio playback with verse highlighting
- Offline mode functionality
- Translation switching

**Manual Testing:**
- Arabic text rendering on different devices
- Audio synchronization accuracy
- Gesture navigation
- Accessibility with TalkBack

**Islamic Content Review:**
- Verify all translations are authentic
- Check verse numbering accuracy
- Validate page mappings with physical Mushaf
- Confirm audio matches text

---

### 16. 🚀 Launch Strategy

#### 16.1 Phased Rollout

**Alpha (Internal - Week 1-2)**
- Team testing
- Fix critical bugs
- Verify all Arabic text renders correctly

**Beta (50 users - Week 3-4)**
- Real user feedback
- Test on various devices
- Verify download/offline functionality
- Islamic content accuracy check

**Limited Release (1000 users - Week 5)**
- Monitor performance
- Track usage patterns
- Fix remaining issues

**Full Launch (All users - Week 6)**
- Push to all Phase 1 & 2 users
- App store feature request
- Marketing push

#### 16.2 Launch Checklist

**Technical:**
- ✅ All 114 surahs load correctly
- ✅ All translations accurate
- ✅ Audio playback stable
- ✅ Offline mode works
- ✅ Bookmarks save/load
- ✅ Statistics track correctly
- ✅ App doesn't crash on low-end devices

**Content:**
- ✅ Arabic text verified against King Fahd Complex
- ✅ Translations from reputable sources
- ✅ Audio from licensed reciters
- ✅ Verse numbering matches Madani Mushaf

**Legal:**
- ✅ Quran.com API terms accepted
- ✅ Reciter audio licensing confirmed
- ✅ Translation copyrights verified
- ✅ Privacy policy updated

---

### 17. 📊 Success Metrics (Phase 3)

**Adoption:**
- 60% of existing users open Quran tab in first week
- 35% read at least 1 page in first week
- 20% download audio for offline use

**Engagement:**
- Average 3 pages read per session
- 35% of users read Quran 3× per week
- 15% maintain 7-day reading streak
- 50% use audio recitation

**Integration:**
- 25% of users read after Fajr prayer
- 40% read Surah Al-Kahf on Fridays
- 30% use Quran alongside azkar

**Retention:**
- D30 retention: 60% (maintain Phase 2 level)
- MAU/DAU ratio: 0.40
- 4.8+ star rating maintained

---

### 18. 🔮 Future Enhancements (Phase 4+)

**Not in Phase 3 Scope, But Planned:**

**Memorization Tools:**
- Hide translation to test memory
- Verse-by-verse practice mode
- Progress tracking for memorization
- Spaced repetition system

**Tafsir Integration:**
- Brief tafsir (Jalalayn, Sa'di)
- Tap verse to see explanation
- Downloadable tafsir books

**Word-by-Word:**
- Tap Arabic word to see root, meaning
- Grammar explanations
- Build vocabulary

**Social Features (Privacy-Respecting):**
- Share progress with family (opt-in, local only)
- Family reading goals
- Mosque community challenges

**Advanced Audio:**
- Verse-by-verse repeat (memorization)
- AB repeat for specific range
- Multiple reciter comparison

**Smart Features:**
- AI-powered verse recommendations based on mood
- "Verse of the Day" with context
- Reading plan generator

---

### 19. 🤲 Islamic Scholarship Review

**Required Before Launch:**

1. **Arabic Text Verification**
   - Compare with King Fahd Complex standard
   - Verify diacritical marks (tashkeel)
   - Check verse divisions

2. **Translation Review**
   - Confirm translators' credentials
   - Check for theological accuracy
   - Ensure no controversial interpretations

3. **Audio Verification**
   - Confirm reciter qualifications
   - Check for recitation errors
   - Verify Hafs 'an Asim style

4. **Consultation with Scholars**
   - Review app concept
   - Approve UI design (respectful presentation)
   - Confirm feature appropriateness

**Scholarship Partners:**
- Local Islamic centers
- Quran teachers
- Arabic language experts
- Islamic app developers community

---

### 20. 📎 Appendix

#### 20.1 Quran.com API Reference

**Documentation:** https://api-docs.quran.com/
**Rate Limits:** 1000 requests/hour (sufficient for our use)
**Attribution:** Must credit Quran.com in app

**Key Endpoints:**
```
GET /chapters
GET /chapters/{id}
GET /verses/by_chapter/{chapter_id}
GET /verses/by_page/{page_number}
GET /verses/by_juz/{juz_number}
GET /recitations
GET /chapter_recitations/{recitation_id}/{chapter_id}
GET /translations
GET /search
```

#### 20.2 Madani Mushaf Standard

**Pages:** 604 total
**Lines per page:** 15
**Juz:** 30 divisions
**Standard:** King Fahd Complex (Madinah)

#### 20.3 Reciter Licensing

**Free for Non-Commercial Use:**
- Quran.com provides audio under their terms
- Must not modify audio
- Must attribute to reciter
- No redistribution outside app

---

## 🎯 Definition of Done (Phase 3)

**Phase 3 is COMPLETE when:**
- ✅ All 114 surahs load correctly with Arabic text
- ✅ At least 1 English translation works perfectly
- ✅ Audio playback from at least 1 reciter
- ✅ Offline mode functional (read Arabic + downloaded translation)
- ✅ Bookmarks save and load correctly
- ✅ Reading statistics track accurately
- ✅ Integration with prayer times works
- ✅ Friday Al-Kahf reminder functions
- ✅ Islamic content verified by scholars
- ✅ <5% crash rate in beta
- ✅ Performance targets met
- ✅ Accessibility requirements met
- ✅ Privacy policy updated

---

## 🤲 Closing Dua

*"O Allah, make this Quran the spring of our hearts, the light of our chests, the remover of our sorrows, and the reliever of our worries. O Allah, teach us from it what we do not know, remind us of what we have forgotten, and grant us its recitation in the manner that pleases You. Ameen."*

---

**END OF PHASE 3 PRD**

**Next Steps:**
1. Research Quran.com API thoroughly
2. Test API endpoints and response times
3. Design mockups for reading interface
4. Consult with Islamic scholars
5. Begin development

May Allah ﷻ make this work a means of connecting people with His Noble Book.

---

**Version:** 1.0  
**Date:** February 13, 2026  
**Document Type:** Product Requirements Document - Quran Module
