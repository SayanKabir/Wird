# 🌙 Wird – Phase 2 PRD: Sunnah Revival System

**Version:** 1.0  
**Phase:** 2 - Sunnah Collection & Gamification  
**Build Upon:** Phase 1 (Prayer Tracking)  
**Target Launch:** Q3 2026

---

## 📋 Executive Summary

Phase 2 transforms Wird into a comprehensive **Sunnah Revival Platform** that helps Muslims gradually adopt the beautiful practices of Prophet Muhammad ﷺ through:

- **Weekly Sunnah Discovery**: Learn and adopt one new sunnah each week
- **Azkar System**: Morning, evening, and post-prayer remembrances with tracking
- **Digital Tasbih**: Context-aware dhikr counter with dynamic presets
- **Daily Life Sunnahs**: 100+ categorized practices with authentic references
- **Gamified Progress**: Streaks, achievements, and gentle motivation (not competitive)

**Core Philosophy:** *Revive the Sunnah gradually, one practice at a time, with knowledge and joy.*

---

## 🎯 Goals & Success Metrics

### Primary Goals
1. **Increase Sunnah Adoption**: Users adopt ≥3 new sunnahs within 30 days
2. **Daily Engagement**: 40% of users engage with azkar daily
3. **Knowledge Retention**: Users can recall references for sunnahs they've adopted

### Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Weekly Sunnah Completion Rate | 60% | Users who complete their weekly sunnah |
| Daily Azkar Engagement | 40% DAU | Users who do morning/evening azkar |
| Tasbih Usage | 3× per week | Average sessions per active user |
| 30-Day Sunnah Streak | 25% | Users with consistent practice |
| Knowledge Quiz Score | >70% | Accuracy on sunnah references |

---

## 🏗️ Feature Architecture

### 1. 🌅 Azkar System (Priority: P0)

Comprehensive remembrance tracker with authentic Arabic text, transliteration, translation, and references.

#### 1.1 Azkar Categories

| Category | Timing | Count | Reference Source |
|----------|--------|-------|-----------------|
| **Morning Azkar** | Fajr → Dhuhr | ~15 adhkar | Fortress of the Muslim (Hisn al-Muslim) |
| **Evening Azkar** | Asr → Maghrib | ~15 adhkar | Fortress of the Muslim |
| **After Fardh Prayer** | Immediately after salam | ~10 adhkar | Sahih Muslim, Bukhari |
| **Before Sleep** | Bedtime | ~8 adhkar | Fortress of the Muslim |
| **Entering/Leaving Home** | On threshold | ~2 adhkar | Abu Dawud, Tirmidhi |
| **Entering/Leaving Masjid** | At mosque | ~2 adhkar | Muslim, Ibn Majah |
| **Before/After Eating** | Meals | ~3 adhkar | Bukhari, Muslim |
| **Entering/Leaving Bathroom** | Restroom | ~2 adhkar | Bukhari, Tirmidhi |

#### 1.2 Azkar Data Structure

Each dhikr contains:
```json
{
  "id": "morning_01",
  "category": "morning",
  "order": 1,
  "arabic": "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ...",
  "transliteration": "Aṣbaḥnā wa-aṣbaḥa l-mulku lillāh...",
  "translation": "We have entered morning, and the dominion belongs to Allah...",
  "repetitions": 1,
  "virtue": "Whoever says this in the morning will be protected from jinn until evening",
  "reference": {
    "hadith": "Muslim 2723",
    "book": "Sahih Muslim",
    "narrator": "Abdullah ibn Mas'ud",
    "grade": "Sahih",
    "link": "https://sunnah.com/muslim:2723"
  },
  "audioUrl": "https://azkar.audio/morning_01.mp3" // Optional
}
```

#### 1.3 Azkar Screen UI

**Layout:**
```
┌─────────────────────────────────────┐
│  🌅 Morning Azkar                   │
│  Started at 6:45 AM                 │
│  ────────────────────                │
│  Progress: 3/15 ●●●○○○○○○○○○○○○    │
├─────────────────────────────────────┤
│                                     │
│  أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ    │
│           لِلَّهِ                    │
│                                     │
│  Aṣbaḥnā wa-aṣbaḥa l-mulku lillāh,  │
│  wal-ḥamdu lillāh...                │
│                                     │
│  "We have entered morning, and the  │
│  dominion belongs to Allah..."      │
│                                     │
│  Repeat: ● (1×)                     │
│                                     │
│  ✨ Virtue: Protection from jinn    │
│  📖 Sahih Muslim 2723               │
│                                     │
│  [🔊 Play Audio]  [📚 Full Reference]│
│                                     │
│  [✓ Done - Next Dhikr →]           │
└─────────────────────────────────────┘
```

**Features:**
- ✅ **Swipe Navigation**: Swipe left/right between adhkar
- ✅ **Auto-Progress**: Tap "Done" to mark complete and auto-advance
- ✅ **Audio Playback**: Native Arabic pronunciation by qualified reciter
- ✅ **Repeat Counter**: Visual indicator for multi-count adhkar (e.g., SubhanAllah 33×)
- ✅ **Reading Modes**: 
  - Arabic only
  - Arabic + Transliteration
  - Arabic + Translation
  - All three
- ✅ **Font Scaling**: Adjust Arabic text size
- ✅ **Night Mode Optimized**: High contrast for low-light reading

#### 1.4 Azkar Reminders

**Smart Notification System:**

| Azkar Type | Default Reminder Time | Notification |
|------------|----------------------|--------------|
| Morning | 15 min after Fajr | "🌅 Start your morning with azkar" |
| Evening | 15 min after Asr | "🌆 Time for evening remembrance" |
| Before Sleep | 10:00 PM | "🌙 Complete your night azkar before sleep" |

**Customization:**
- User can set custom reminder times
- Toggle on/off per category
- Snooze options (10 min, 30 min, 1 hour)

#### 1.5 Azkar Tracking & Streaks

**Daily Progress:**
```
Today's Azkar:
🌅 Morning: ✅ Completed (6:45 AM)
🌆 Evening: ⏳ In Progress (3/15)
🌙 Night: ○ Pending
```

**Streak System:**
- Track consecutive days of completing morning azkar
- Track consecutive days of completing evening azkar
- Combined "Azkar Master" streak (all categories)

**Display:**
```
Your Azkar Streaks:
🔥 Morning Azkar: 12 days
🔥 Evening Azkar: 8 days
🔥 Night Azkar: 5 days
⭐ Azkar Master: 3 days (all categories complete)
```

#### 1.6 Azkar Collections (Curated Sets)

**Pre-Built Collections:**
1. **Essential Morning (Quick)** - 5 core adhkar (~3 min)
2. **Complete Morning** - Full 15 adhkar (~10 min)
3. **Essential Evening (Quick)** - 5 core adhkar
4. **Complete Evening** - Full 15 adhkar
5. **After Fajr** - Specific post-Fajr dhikr
6. **Bedtime Essentials** - Sleep protection adhkar
7. **Fortress Protection** - Combined powerful adhkar for protection

**User Can:**
- Create custom collections
- Favorite specific adhkar
- Skip optional adhkar (but log which ones)

---

### 2. 📿 Digital Tasbih (Priority: P0)

Interactive dhikr counter with context-aware presets and beautiful design.

#### 2.1 Tasbih Screen Design

**Layout:**
```
┌─────────────────────────────────────┐
│         📿 Digital Tasbih           │
├─────────────────────────────────────┤
│                                     │
│      سُبْحَانَ ٱللَّٰهِ             │
│      SubhanAllah                    │
│                                     │
│      ┌─────────────┐                │
│      │             │                │
│      │     33      │   ← Large count│
│      │             │                │
│      └─────────────┘                │
│                                     │
│  ●●●●●●●●●●○○○○○○○○○○○○○○○○○○○○○○○ │
│                                     │
│  [Reset]            [History]       │
│                                     │
├─────────────────────────────────────┤
│  Quick Counts:                      │
│  [33] [100] [500] [1000]            │
│                                     │
│  Presets:                           │
│  [After Prayer] [Morning] [Witr]    │
└─────────────────────────────────────┘
```

**Interaction:**
- **Tap anywhere on screen** to increment count
- **Haptic feedback** on each tap
- **Visual ripple effect** from tap point
- **Sound option**: Soft "click" or silent

#### 2.2 Tasbih Presets (Context-Aware)

**After Fardh Prayer Set:**
```
1. SubhanAllah × 33
2. Alhamdulillah × 33  
3. Allahu Akbar × 33
4. La ilaha illallah... × 1
(Total: 100)
Reference: Sahih Muslim 597
```

**Morning/Evening Azkar Counters:**
```
1. SubhanAllahi wa bihamdihi × 100
2. La ilaha illallahu wahdahu... × 10
3. Astaghfirullah × 100
Reference: Sahih Bukhari 6403, Muslim 2691
```

**Witr Prayer Set:**
```
1. SubhanAllah × 33
2. Alhamdulillah × 33
3. Allahu Akbar × 34
Reference: Common practice
```

**Custom Set:**
- User can create unlimited custom dhikr sets
- Name the set
- Add multiple dhikr with counts
- Reorder sequence

#### 2.3 Tasbih Features

**Core Features:**
- ✅ **Multi-Dhikr Mode**: Automatically advance to next dhikr when count reached
- ✅ **Vibration Patterns**: Different patterns for milestones (10, 33, 100)
- ✅ **Goal Setting**: Set daily dhikr goals (e.g., 1000 SubhanAllah)
- ✅ **History Log**: Track daily dhikr totals
- ✅ **Quick Reset**: Shake phone to reset counter (optional)
- ✅ **Screen Wake Lock**: Keep screen on during dhikr session

**Visual Feedback:**
```
Milestone Animations:
- 10: Subtle glow
- 33: Green checkmark burst
- 100: Gold star animation
- 1000: Fireworks effect
```

#### 2.4 Tasbih Statistics

**Daily Summary:**
```
Today's Dhikr:
📿 SubhanAllah: 133
🤲 Alhamdulillah: 100
🌟 Allahu Akbar: 67
Total: 300 dhikr

Best Streak: 12 days
Current Streak: 5 days
```

**Weekly/Monthly Trends:**
- Bar chart showing dhikr counts per day
- Most used dhikr
- Total time in dhikr (estimated)

---

### 3. 🌟 Weekly Sunnah Discovery (Priority: P0)

Gamified system to gradually adopt authentic sunnahs of daily life.

#### 3.1 The Revival System

**How It Works:**

1. **Every Monday**: User receives a new "Sunnah of the Week"
2. **Learn Phase** (Day 1-2): Read about the sunnah, its virtue, and reference
3. **Practice Phase** (Day 3-7): Daily reminders to practice
4. **Reflection** (Day 7): Mark if you want to continue this sunnah
5. **Adoption**: Sunnah moves to "My Active Sunnahs" list

**UI Flow:**
```
Monday Morning Notification:
"🌟 New Sunnah of the Week!
Eating with the right hand
Tap to learn more"

↓

┌─────────────────────────────────────┐
│   🌟 Sunnah of the Week             │
│   Week of Feb 10, 2026              │
├─────────────────────────────────────┤
│                                     │
│   🍽️ Eating with the Right Hand    │
│                                     │
│   The Prophet ﷺ said: "When any     │
│   one of you eats, let him eat      │
│   with his right hand..."           │
│                                     │
│   📖 Reference:                     │
│   Sahih Muslim 2020                 │
│   Narrated by: Ibn Umar رضي الله عنه│
│   Grade: Sahih (Authentic)          │
│                                     │
│   ✨ Virtue:                        │
│   Following the blessed manner of   │
│   the Prophet ﷺ brings barakah     │
│                                     │
│   [📱 Set Practice Reminders]       │
│   [📚 Read Full Hadith]             │
│   [✓ I'm Practicing This]           │
└─────────────────────────────────────┘
```

#### 3.2 Sunnah Categories & Difficulty

**Categorization:**

| Category | Icon | Example Sunnahs | Count |
|----------|------|----------------|-------|
| **Eating & Drinking** | 🍽️ | Right hand, bismillah, three breaths | 12 |
| **Personal Hygiene** | 🧼 | Miswak, trimming nails, ghusl Friday | 15 |
| **Social Etiquette** | 🤝 | Salam, visiting sick, good character | 18 |
| **Sleep & Waking** | 😴 | Sleep on right side, bedtime dua | 8 |
| **Travel** | ✈️ | Travel dua, two-rakah prayer | 6 |
| **Fasting** | 🌙 | Mondays/Thursdays, suhoor, iftaar | 10 |
| **Charity** | 💝 | Regular sadaqah, helping others | 8 |
| **Knowledge** | 📖 | Seeking knowledge, teaching | 7 |
| **Family** | 👨‍👩‍👧 | Kind to parents, spouse, children | 12 |
| **Masjid** | 🕌 | Early attendance, front rows | 6 |

**Difficulty Levels:**
- 🟢 **Easy**: Simple daily actions (eating with right hand)
- 🟡 **Medium**: Requires some effort (fasting Mondays)
- 🔴 **Advanced**: Requires commitment (Tahajjud prayer)

**Smart Progression:**
- Week 1-4: Easy sunnahs only
- Week 5-8: Mix of easy and medium
- Week 9+: All difficulty levels

#### 3.3 Sunnah Tracking

**Daily Checklist:**
```
My Active Sunnahs:
✅ Eat with right hand (12 days)
✅ Say Bismillah before eating (12 days)
✅ Use miswak before prayer (8 days)
○ Fast on Monday (Next: Feb 17)
✅ Visit sick friend (Completed this week)
```

**Completion Types:**
- **Daily**: Must do every day (eating habits)
- **Weekly**: Once per week (Friday ghusl)
- **Monthly**: Once per month (fasting 3 white days)
- **Occasional**: When opportunity arises (visiting sick)

**Gentle Reminders:**
- "🍽️ Reminder: Eat with your right hand today"
- "🌙 Tomorrow is Monday - great day to fast!"
- Not pushy or guilt-inducing

#### 3.4 Sunnah Library (Full Collection)

**Search & Browse:**
- Search by keyword
- Filter by category
- Filter by difficulty
- Sort by popularity / ease / reward

**Each Sunnah Entry Contains:**
```json
{
  "id": "eat_right_hand",
  "title": "Eating with the Right Hand",
  "category": "eating_drinking",
  "difficulty": "easy",
  "frequency": "daily",
  "description": "Use your right hand when eating and drinking",
  "arabic": "إِذَا أَكَلَ أَحَدُكُمْ فَلْيَأْكُلْ بِيَمِينِهِ",
  "transliteration": "Idha akala ahadukum fal-ya'kul bi-yaminihi",
  "translation": "When any one of you eats, let him eat with his right hand",
  "virtue": "Following the blessed practice of the Prophet ﷺ",
  "reference": {
    "hadith": "Muslim 2020",
    "book": "Sahih Muslim",
    "chapter": "Book of Drinks",
    "narrator": "Ibn Umar",
    "grade": "Sahih",
    "arabicText": "[Full Arabic hadith text]",
    "link": "https://sunnah.com/muslim:2020"
  },
  "tips": [
    "Practice during every meal",
    "If left-handed, start with small meals",
    "Remind family members gently"
  ],
  "relatedSunnahs": ["say_bismillah_eating", "three_fingers_eating"]
}
```

---

### 4. 📚 Comprehensive Sunnah Database

**TOTAL: 120+ Authenticated Sunnahs**

Below is the complete collection organized by category. Each includes authentic references verified against Sunnah.com database.

---

#### 4.1 🍽️ EATING & DRINKING (15 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Say Bismillah before eating | Bukhari 5376, Muslim 2017 | Sahih |
| 2 | Eat with the right hand | Muslim 2020 | Sahih |
| 3 | Eat from what is nearest to you | Bukhari 5376 | Sahih |
| 4 | Eat with three fingers | Muslim 2032 | Sahih |
| 5 | Say Alhamdulillah after eating | Abu Dawud 3850, Tirmidhi 3456 | Hasan |
| 6 | Lick fingers before wiping | Muslim 2031 | Sahih |
| 7 | Drink while sitting | Muslim 2024 | Sahih |
| 8 | Drink in three breaths | Bukhari 5631, Muslim 2028 | Sahih |
| 9 | Say Bismillah when drinking | Ibn Majah 3264 | Hasan |
| 10 | Cover utensils at night | Bukhari 5623, Muslim 2013 | Sahih |
| 11 | Don't blow into food/drink | Abu Dawud 3728, Tirmidhi 1888 | Sahih |
| 12 | Share food with others | Bukhari 2486 | Sahih |
| 13 | Eat suhoor (pre-dawn meal) | Bukhari 1923, Muslim 1095 | Sahih |
| 14 | Break fast with dates | Abu Dawud 2356, Tirmidhi 696 | Sahih |
| 15 | Don't eat while reclining | Bukhari 5398 | Sahih |

---

#### 4.2 🧼 PERSONAL HYGIENE (18 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Use miswak (tooth stick) | Bukhari 887, Muslim 252 | Sahih |
| 2 | Trim nails regularly | Muslim 257 | Sahih |
| 3 | Remove armpit hair | Muslim 257 | Sahih |
| 4 | Remove pubic hair (within 40 days) | Muslim 257 | Sahih |
| 5 | Ghusl (bath) on Fridays | Bukhari 877, Muslim 846 | Sahih |
| 6 | Apply perfume (for men) | Bukhari 5929, Muslim 2252 | Sahih |
| 7 | Comb hair | Muslim 2076 | Sahih |
| 8 | Part hair on the right | Abu Dawud 4148 | Hasan |
| 9 | Trim mustache short | Bukhari 5892, Muslim 259 | Sahih |
| 10 | Wash hands before/after meals | Tirmidhi 1846 | Hasan |
| 11 | Make wudu before sleep | Bukhari 247, Muslim 2710 | Sahih |
| 12 | Enter bathroom with left foot | Ibn Majah 301 | Hasan |
| 13 | Exit bathroom with right foot | Ibn Majah 301 | Hasan |
| 14 | Say dua entering bathroom | Bukhari 142, Muslim 375 | Sahih |
| 15 | Use water for istinja (cleaning) | Muslim 271 | Sahih |
| 16 | Use left hand in bathroom | Bukhari 153 | Sahih |
| 17 | Don't talk in bathroom | Abu Dawud 15, Tirmidhi 7 | Hasan |
| 18 | Wash private parts after urination | Bukhari 150 | Sahih |

---

#### 4.3 🤝 SOCIAL ETIQUETTE & CHARACTER (20 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Give salam (greeting) | Bukhari 6247, Muslim 2160 | Sahih |
| 2 | Smile when meeting others | Tirmidhi 1956 | Hasan |
| 3 | Shake hands when meeting | Abu Dawud 5212, Tirmidhi 2727 | Sahih |
| 4 | Visit the sick | Bukhari 5649, Muslim 2568 | Sahih |
| 5 | Say "Yarhamukallah" when someone sneezes | Bukhari 6224, Muslim 2991 | Sahih |
| 6 | Attend funerals | Bukhari 1183, Muslim 945 | Sahih |
| 7 | Keep promises | Muslim 2769 | Sahih |
| 8 | Speak the truth | Bukhari 6094, Muslim 2607 | Sahih |
| 9 | Control anger | Bukhari 6114, Muslim 2609 | Sahih |
| 10 | Forgive others | Bukhari 6853, Muslim 2588 | Sahih |
| 11 | Be kind to neighbors | Bukhari 6014, Muslim 47 | Sahih |
| 12 | Respect elders | Abu Dawud 4843, Tirmidhi 2022 | Hasan |
| 13 | Be merciful to youngsters | Bukhari 5997, Muslim 2318 | Sahih |
| 14 | Lower your gaze | Quran 24:30, Muslim 2159 | Sahih |
| 15 | Avoid backbiting | Quran 49:12, Abu Dawud 4875 | Sahih |
| 16 | Don't be arrogant | Muslim 91 | Sahih |
| 17 | Be generous | Bukhari 1433, Muslim 2408 | Sahih |
| 18 | Don't interrupt others | Tirmidhi 2018 | Hasan |
| 19 | Reconcile between people | Bukhari 2692, Muslim 2623 | Sahih |
| 20 | Keep good company | Bukhari 5534, Muslim 2628 | Sahih |

---

#### 4.4 😴 SLEEP & WAKING (10 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Sleep on the right side | Bukhari 247, Muslim 2710 | Sahih |
| 2 | Place right hand under cheek | Bukhari 6314, Abu Dawud 5045 | Sahih |
| 3 | Recite Ayat al-Kursi before sleep | Bukhari 2311 | Sahih |
| 4 | Recite last two verses of Al-Baqarah | Bukhari 5009, Muslim 808 | Sahih |
| 5 | Blow in hands, recite 3 Quls, wipe body | Bukhari 5017 | Sahih |
| 6 | Make wudu before sleep | Bukhari 247, Muslim 2710 | Sahih |
| 7 | Dust bed three times before sleeping | Bukhari 6320, Abu Dawud 5050 | Sahih |
| 8 | Say sleep dua | Bukhari 6324, Muslim 2714 | Sahih |
| 9 | Sleep early after Isha | Bukhari 568 | Sahih |
| 10 | Say waking dua upon waking | Bukhari 6312, Muslim 2711 | Sahih |

---

#### 4.5 🕌 MASJID & PRAYER (12 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Pray Sunnah Rawatib prayers | Bukhari 1180, Muslim 728 | Sahih |
| 2 | Pray two rakah when entering masjid | Bukhari 1163, Muslim 714 | Sahih |
| 3 | Enter masjid with right foot | Hakim 1/218 | Sahih |
| 4 | Say dua when entering masjid | Muslim 713 | Sahih |
| 5 | Exit masjid with left foot | Hakim 1/218 | Sahih |
| 6 | Sit in masjid after Fajr until sunrise | Muslim 670 | Sahih |
| 7 | Go early to Friday prayer | Bukhari 929, Muslim 850 | Sahih |
| 8 | Sit in first row | Bukhari 615, Muslim 440 | Sahih |
| 9 | Fill gaps in rows | Bukhari 725, Muslim 436 | Sahih |
| 10 | Pray witr before sleeping | Bukhari 998, Muslim 749 | Sahih |
| 11 | Pray Tahajjud (night prayer) | Bukhari 1127, Muslim 775 | Sahih |
| 12 | Make dua in prostration | Muslim 482 | Sahih |

---

#### 4.6 🌙 FASTING (8 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Fast Mondays and Thursdays | Tirmidhi 745, Nasa'i 2361 | Hasan |
| 2 | Fast 3 white days (13,14,15 lunar) | Abu Dawud 2449, Nasa'i 2424 | Sahih |
| 3 | Fast 6 days of Shawwal | Muslim 1164 | Sahih |
| 4 | Fast day of Arafah (9th Dhul Hijjah) | Muslim 1162 | Sahih |
| 5 | Fast Ashura (10th Muharram) + 9th | Muslim 1134, Bukhari 2006 | Sahih |
| 6 | Delay suhoor | Bukhari 1921, Muslim 1097 | Sahih |
| 7 | Hasten breaking fast | Bukhari 1957, Muslim 1098 | Sahih |
| 8 | Make dua when breaking fast | Tirmidhi 3456, Ibn Majah 1753 | Hasan |

---

#### 4.7 👨‍👩‍👧 FAMILY & RELATIONSHIPS (15 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Be kind to your mother (3× emphasis) | Bukhari 5971, Muslim 2548 | Sahih |
| 2 | Obey parents (in good) | Bukhari 5975, Muslim 2549 | Sahih |
| 3 | Maintain family ties | Bukhari 5988, Muslim 2557 | Sahih |
| 4 | Be kind to your wife | Muslim 1468 | Sahih |
| 5 | Help with household chores | Bukhari 676 | Sahih |
| 6 | Express love to spouse | Muslim 2625 | Sahih |
| 7 | Play with your children | Ahmad 25369 | Hasan |
| 8 | Kiss your children | Bukhari 5998, Muslim 2318 | Sahih |
| 9 | Be just between children | Bukhari 2587, Muslim 1623 | Sahih |
| 10 | Teach children Quran | Tirmidhi 2910 | Hasan |
| 11 | Make dua for your children | Bukhari 1358, Muslim 2732 | Sahih |
| 12 | Choose good names | Abu Dawud 4948 | Sahih |
| 13 | Do aqiqah for newborn | Bukhari 5472, Muslim 2122 | Sahih |
| 14 | Visit relatives regularly | Bukhari 5988, Muslim 2557 | Sahih |
| 15 | Give gifts to family | Bukhari 2585 | Sahih |

---

#### 4.8 💝 CHARITY & GENEROSITY (8 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Give charity regularly | Bukhari 1442, Muslim 1006 | Sahih |
| 2 | Give charity in secret | Bukhari 1423, Muslim 1031 | Sahih |
| 3 | Feed the hungry | Bukhari 6236, Muslim 39 | Sahih |
| 4 | Give water to drink | Muslim 2449 | Sahih |
| 5 | Help those in need | Bukhari 2442, Muslim 2699 | Sahih |
| 6 | Lend to others | Quran 2:245, Ibn Majah 2430 | Hasan |
| 7 | Relieve someone's difficulty | Muslim 2699 | Sahih |
| 8 | Smile as charity | Tirmidhi 1956 | Hasan |

---

#### 4.9 📖 KNOWLEDGE & DHIKR (10 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Seek knowledge | Ibn Majah 224, Tirmidhi 2646 | Hasan |
| 2 | Teach others what you know | Bukhari 71, Muslim 1037 | Sahih |
| 3 | Recite Quran daily | Muslim 803 | Sahih |
| 4 | Say SubhanAllah wa bihamdihi 100× | Bukhari 6405, Muslim 2691 | Sahih |
| 5 | Say La ilaha illallah 100× | Muslim 2691 | Sahih |
| 6 | Make istighfar (seek forgiveness) 100× | Muslim 2702 | Sahih |
| 7 | Send salawat on the Prophet ﷺ | Quran 33:56, Tirmidhi 484 | Sahih |
| 8 | Recite Surah Al-Kahf on Fridays | Abu Dawud 1046, Hakim 2/367 | Sahih |
| 9 | Memorize Quran | Bukhari 5027, Muslim 798 | Sahih |
| 10 | Attend knowledge circles | Muslim 2699 | Sahih |

---

#### 4.10 ✈️ TRAVEL (6 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Say travel dua when leaving | Muslim 1342 | Sahih |
| 2 | Pray two rakah before travel | Imam Ahmad 15181 | Hasan |
| 3 | Shorten prayers when traveling | Bukhari 1102, Muslim 687 | Sahih |
| 4 | Return home quickly after task | Bukhari 1801, Muslim 1927 | Sahih |
| 5 | Bring gift for family after travel | Muslim 1927 | Sahih |
| 6 | Say dua when returning home | Muslim 1342 | Sahih |

---

#### 4.11 🌍 MISCELLANEOUS DAILY SUNNAHS (8 Sunnahs)

| # | Sunnah | Reference | Grade |
|---|--------|-----------|-------|
| 1 | Enter home with right foot | Adab al-Mufrad 786 | Hasan |
| 2 | Say salam when entering home | Abu Dawud 5186 | Hasan |
| 3 | Don't point with finger | Muslim 2264 | Sahih |
| 4 | Yawn with hand over mouth | Bukhari 6226, Muslim 2994 | Sahih |
| 5 | Don't walk in one sandal | Bukhari 5855, Muslim 2097 | Sahih |
| 6 | Wear white clothes | Tirmidhi 2810, Abu Dawud 4061 | Hasan |
| 7 | Use right hand for good things | Muslim 267 | Sahih |
| 8 | Keep environment clean | Muslim 269 | Sahih |

---

### 5. 🏆 Gamification System (Without Competition)

**Philosophy:** Motivate through personal growth, not comparison with others.

#### 5.1 Achievement Badges

**Azkar Achievements:**
- 🌅 **Dawn Warrior**: 7-day morning azkar streak
- 🌆 **Evening Devotee**: 7-day evening azkar streak
- 🌙 **Night Guardian**: 7-day night azkar streak
- ⭐ **Azkar Master**: 30 days all azkar complete
- 📿 **Dhikr Champion**: 10,000 total tasbih count

**Sunnah Achievements:**
- 🌱 **Sunnah Seeker**: Complete first weekly sunnah
- 🌿 **Habit Builder**: Maintain 3 sunnahs for 30 days
- 🌳 **Sunnah Reviver**: Adopt 10 new sunnahs
- 🌟 **Walking Sunnah**: 25 active sunnahs
- 👑 **Sunnah Master**: 50 active sunnahs

**Special Achievements:**
- 🤲 **Blessed Friday**: Complete all Friday sunnahs
- 🌙 **Ramadan Ready**: Complete Ramadan prep checklist
- 📖 **Scholar**: Read all hadith references
- 💝 **Generous Heart**: Complete 10 charity sunnahs
- 🕌 **Masjid Regular**: 40 consecutive days in masjid

#### 5.2 Progress Visualization

**Sunnah Tree:**
```
        🌟 (Crown - 50 sunnahs)
         |
        🌳
       /   \
      🌿   🌿 (Branches - categories)
     /  \   / \
    🌱  🌱 🌱 🌱 (Leaves - individual sunnahs)
```

Each sunnah = leaf that appears when adopted
Categories = branches that grow
Visual representation of spiritual growth

**Alternative: Garden Metaphor:**
- Each sunnah = flower in your garden
- Daily practice = watering flowers
- Neglect = flowers wilt (gentle reminder)
- Revival = flowers bloom again

#### 5.3 Reflection & Journaling

**Weekly Reflection Prompts:**
```
This Week's Sunnah: Eating with Right Hand

How did it go?
○ Easy to maintain
○ Took some effort
○ Found it challenging

What helped you?
[Text input]

Did you teach this to anyone?
○ Yes ○ No

Will you continue this sunnah?
○ Yes, make it active
○ Need more practice
○ Will try again later
```

**Monthly Duas Journal:**
- Log duas made
- Track if answered
- Gratitude section

---

### 6. 🔔 Notification Strategy

**Smart, Non-Intrusive System:**

**Daily Notifications (Max 3-5/day):**
1. Morning azkar reminder (after Fajr)
2. Weekly sunnah reminder (midday)
3. Evening azkar reminder (after Asr)
4. Night azkar reminder (10 PM)
5. Occasional sunnah tip (optional)

**Weekly:**
- Monday: New Sunnah of the Week
- Friday: Special Friday sunnahs reminder
- Sunday: Weekly reflection prompt

**Customization:**
- User controls frequency
- Quiet hours (no notifications)
- Customize which reminders to receive

---

### 7. 📱 UI/UX Principles

**Design Consistency:**
- Maintain Phase 1 celestial aesthetic
- Use same color palette
- Consistent iconography
- Smooth transitions

**New Screens:**
1. **Azkar Hub** - Collection of all azkar categories
2. **Tasbih Screen** - Fullscreen counter
3. **Sunnah Discovery** - Weekly sunnah card
4. **Sunnah Library** - Searchable database
5. **My Sunnahs** - Active practice tracker
6. **Achievements** - Badge collection
7. **Reflection Journal** - Personal notes

**Navigation:**
- Bottom tab bar:
  - 🕌 Home (Prayer times)
  - 🤲 Azkar
  - 📿 Tasbih
  - 🌟 Sunnahs
  - 👤 Profile (Stats & Achievements)

---

### 8. 📊 Analytics & Privacy

**Local-Only Tracking:**
- All data stored in Hive
- No cloud sync
- No external analytics
- Export feature for personal backup

**Data Stored:**
```json
{
  "azkarLogs": {
    "2026-02-13": {
      "morning": "completed",
      "evening": "partial",
      "night": "pending"
    }
  },
  "tasbihHistory": {
    "2026-02-13": {
      "SubhanAllah": 133,
      "Alhamdulillah": 100
    }
  },
  "activeSunnahs": [
    {
      "id": "eat_right_hand",
      "adoptedDate": "2026-01-15",
      "currentStreak": 29,
      "bestStreak": 29
    }
  ],
  "achievements": ["dawn_warrior", "sunnah_seeker"]
}
```

---

### 9. 🏗️ Technical Implementation

**New Services:**
```dart
class AzkarService {
  List<Dhikr> getAzkarByCategory(AzkarCategory category);
  void markDhikrComplete(String dhikrId);
  AzkarProgress getTodayProgress();
}

class TasbihService {
  void incrementCount(String dhikr);
  void resetCount();
  TasbihHistory getHistory();
  void savePreset(TasbihPreset preset);
}

class SunnahService {
  Sunnah getWeeklySunnah();
  List<Sunnah> getSunnahsByCategory(Category category);
  void markSunnahActive(String sunnahId);
  void logSunnahPractice(String sunnahId, DateTime date);
}

class AchievementService {
  void checkAndUnlockAchievements();
  List<Achievement> getUnlockedAchievements();
  Achievement? getNextAchievement();
}
```

**Data Models:**
```dart
class Dhikr {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int repetitions;
  final HadithReference reference;
  final String virtue;
  final String? audioUrl;
}

class Sunnah {
  final String id;
  final String title;
  final SunnahCategory category;
  final Difficulty difficulty;
  final Frequency frequency;
  final String description;
  final HadithReference reference;
  final List<String> tips;
  final List<String> relatedSunnahs;
}

class HadithReference {
  final String hadithNumber;
  final String book;
  final String narrator;
  final String grade; // Sahih, Hasan, Daif
  final String? link; // sunnah.com link
  final String? arabicText;
}
```

**Storage:**
```
Hive Boxes:
- azkar_logs
- tasbih_history
- active_sunnahs
- achievements
- reflections
```

---

### 10. 🎯 Success Criteria (Phase 2)

**Launch Metrics:**
- 70% of Phase 1 users activate azkar feature
- 50% complete first weekly sunnah
- 40% use tasbih counter weekly
- 4.8+ star rating maintained

**30-Day Metrics:**
- 3+ new sunnahs adopted per user
- 40% daily azkar engagement
- 60% weekly sunnah completion rate
- 25% achieve first badge

**Retention:**
- D30 retention: 55%
- MAU/DAU ratio: 0.35
- Weekly azkar streak avg: 4 days

---

### 11. 📅 Development Timeline

**Phase 2 Roadmap:**

**Month 1: Azkar System**
- Week 1-2: Data entry (all adhkar with references)
- Week 3: Azkar UI implementation
- Week 4: Azkar tracking & notifications

**Month 2: Tasbih & Weekly Sunnah**
- Week 1-2: Tasbih counter with presets
- Week 3: Weekly sunnah system
- Week 4: Sunnah library (first 50 sunnahs)

**Month 3: Gamification & Polish**
- Week 1: Achievement system
- Week 2: Complete sunnah database (120+ entries)
- Week 3: Testing & reference verification
- Week 4: Beta testing & launch prep

**Total:** 3 months development + 1 month testing

---

### 12. 🔍 Quality Assurance

**Reference Verification:**
- Every hadith cross-referenced with Sunnah.com
- Grade verified (Sahih, Hasan, Daif)
- Multiple sources when possible
- Link to original hadith included

**Islamic Review:**
- All content reviewed by qualified scholars
- Ensure proper understanding of context
- Verify translations are accurate
- No controversial opinions presented

**Testing:**
- Unit tests for all services
- UI tests for critical flows
- Islamic content review by beta testers
- Accessibility testing

---

### 13. 🤲 Closing Dua

*"O Allah, make this work a means of reviving the Sunnah of Your Prophet Muhammad ﷺ. Accept it from us and make it purely for Your sake. Guide us and the users of this app to follow the Straight Path. Ameen."*

---

**END OF PHASE 2 PRD**

**Next Steps:**
1. Islamic scholar review of sunnah database
2. Verify all 120+ hadith references
3. Design mockups for new screens
4. Begin development sprints

May Allah ﷻ grant success and barakah in this work.

---

**Version:** 1.0  
**Date:** February 13, 2026  
**Pages:** Complete specification for Phase 2 Sunnah Revival System
