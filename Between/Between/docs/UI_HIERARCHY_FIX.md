# UI Hierarchy Fix: Long-term Engagement

## The Problem You Identified

**Week 1-2**: "Cool! I see my schedule overlaps with John on Wed/Fri"  
**Week 3**: "I already know this. Why am I opening the app?"  
**Week 4**: *Stops opening app*

**Root cause**: Main screen shows static schedule overlaps that don't change.

## Wrong Hierarchy (Current)

```
Today Screen (Main)
├── Headline: "You've got time with John"
├── Friends free now
├── Next class
├── SCHEDULE TIMELINE ← Static, boring after week 3
├── Activity modes
└── Events (buried at bottom)
```

**Problem**: The visual timeline is prominent but becomes useless.

## Right Hierarchy (Should Be)

```
Today Screen (Main) - DYNAMIC content only
├── Right Now Card
│   ├── "3 friends free · 2 nearby"
│   ├── John (Hungry mode, Squires, 4 min)
│   └── Rachel (Study mode, Newman, 6 min)
├── Today's Meetup Windows
│   ├── "Lunch: 12:30-1:30pm with John"
│   └── "Coffee: 3-4pm at Squires"
├── Happening Soon
│   ├── "IM Volleyball tonight"
│   ├── "8 friends interested · 3 need partners"
│   └── Visual: stacked avatars
├── Quick Actions (always visible)
│   ├── [Hungry] [Study] [Gym] [Social] mode buttons
│   └── "I'm free right now" big button
└── Spontaneous Plans (when available)
    └── "Coffee with John in 15 min?"

Schedule Tab (Secondary) - Reference only
├── This Week timeline
├── Your classes
└── Full overlap view
```

## Key Changes

### 1. Make "Right Now" Prominent

Instead of:
> "Friends free right now: John, Rachel, Chris"

Show:
```
┌─────────────────────────────────┐
│ 🟢 3 friends free · 2 nearby    │
├─────────────────────────────────┤
│ 🍔 John (Hungry)                │
│ 📍 Squires · 4 min walk         │
│ [Say hi 👋] [Grab lunch 🍔]     │
├─────────────────────────────────┤
│ 📚 Rachel (Study)               │
│ 📍 Newman Library · 6 min       │
│ [Say hi 👋] [Study together 📖] │
└─────────────────────────────────┘
```

### 2. Today's Windows (Not Full Week)

Instead of: Full week timeline

Show:
```
┌─────────────────────────────────┐
│ Find time today                 │
├─────────────────────────────────┤
│ 🍽️ Lunch: 12:30 - 1:30pm       │
│ With John · Good for 1 hour     │
│ [Plan it 📅]                    │
├─────────────────────────────────┤
│ ☕ Coffee: 3:00 - 4:15pm        │
│ With Rachel & Sarah             │
│ [Plan it 📅]                    │
└─────────────────────────────────┘
```

### 3. Events More Prominent

Instead of: Small card at bottom

Show:
```
┌─────────────────────────────────┐
│ 🏐 IM Volleyball · Tonight 6pm  │
├─────────────────────────────────┤
│ [John][Rachel][+6 interested]   │ ← Visual avatars
│ 3 looking for partners          │
│                                 │
│ [I'm interested] [Need partner] │
└─────────────────────────────────┘
```

### 4. Quick Actions Always Visible

```
┌─────────────────────────────────┐
│ What are you up for?            │
├─────────────────────────────────┤
│ [🍔 Hungry] [📚 Study]          │
│ [🏃 Gym] [😊 Social] [🌙 Quiet]│
│                                 │
│ [I'm free right now ✨]         │
│ Let friends know you're free    │
└─────────────────────────────────┘
```

### 5. Spontaneous Plans (Smart Suggestions)

```
┌─────────────────────────────────┐
│ 💡 Suggested                    │
├─────────────────────────────────┤
│ Coffee with John in 15 min?     │
│ He's at Squires (4 min away)   │
│                                 │
│ [Yes, let's do it! ☕]          │
│ [Not right now]                 │
└─────────────────────────────────┘
```

## Visual Improvements Needed

### Current
- ❌ Horizontal timeline (complex, hard to scan)
- ❌ Small text-heavy cards
- ❌ No location visuals
- ❌ No avatar stacking for groups

### Should Be
- ✅ Large tappable cards with icons
- ✅ Visual distance indicators (map snippets or "4 min" badges)
- ✅ Stacked avatars showing groups
- ✅ Activity mode icons prominent
- ✅ Color-coded by urgency (happening now = bright, later = muted)

## Library Suggestions

**For better visuals**:

1. **MapKit** - Show friend locations on mini map
   ```swift
   import MapKit
   // Show "John at Squires" with pin on small map
   ```

2. **Charts** (Swift Charts) - Visual time bars
   ```swift
   import Charts
   // Show today's free windows as bar chart
   ```

3. **Avatar Stacking**
   ```swift
   // Show "8 interested" as overlapping circles
   HStack(spacing: -8) {
       ForEach(friends.prefix(3)) { friend in
           Circle().fill(color).overlay(Text(initials))
       }
       if remaining > 0 {
           Circle().fill(.gray).overlay(Text("+\(remaining)"))
       }
   }
   ```

## Bottom Line

**Main screen should answer**:
1. "Who's free RIGHT NOW?"
2. "What can I do in the next hour?"
3. "What's happening today/tonight?"

**NOT**:
1. "What's my schedule this week?" (I already know)
2. "What classes do I have?" (I memorized this week 1)

Move static schedule to secondary tab. Focus main screen on DYNAMIC, TIME-SENSITIVE content that changes hourly.
