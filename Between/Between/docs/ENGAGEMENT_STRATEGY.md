# Between - Long-term Engagement Strategy

## The Problem You Identified

**Week 1-2**: "Oh cool! I have lunch overlap with John on Wed/Fri!"  
**Week 3+**: "I already know my schedule overlaps. Why am I checking this?"

Static schedule visualization becomes **learned behavior** after 2-3 weeks. The novelty wears off.

## Solution: Shift from Static → Dynamic

### Phase 1: Real-time Context (Already Building)

#### Activity Modes (Live Intent)
**Current Implementation** ✅
- Quiet (2h) - "Don't match me"
- Hungry (1h) - "Looking for lunch"
- Study (2h) - "Library session" 
- Gym (1.5h) - "Heading to McComas"
- Social (1h) - "Free to hang"

**Why This Works:**
- Not about schedule overlap, about RIGHT NOW
- Shows live intent: "John set Hungry mode 5 min ago at Turner"
- Creates FOMO: "3 friends are in Study mode at Newman"

#### Campus Events (Social Proof)
**Current Implementation** ✅
- Partner matching for IM volleyball
- Newcomer matching for pickup soccer
- Interest counts: "48 interested · 9 need a partner"

**Why This Works:**
- Not about your schedule, about who's GOING
- Solves "nobody will be there" fear
- Updates in real-time as people opt in

### Phase 2: Location-Based Matching (Next Priority)

#### Nearby Friends
```
"John is at Squires (4 min walk)"
"Rachel just checked in at Newman Library"
"2 starred friends within 5 min - say hi?"
```

**Privacy Model:**
- Location only visible during activity modes (not 24/7)
- Rough zones, not GPS coords: "Turner Place" not "37.2296° N"
- Opt-in per session: "Share location for next 2 hours while Hungry"

#### Smart Nudges
```
11:45 AM - "You're free until 2pm. John's free and at Squires!"
[Quick Actions: "👋 Say hi" | "☕ Coffee?" | "🍔 Grab lunch"]
```

**Algorithm:**
- Your current free block
- Friends in activity mode nearby
- Walking time < 10 min
- Minimum 30min shared window remaining

### Phase 3: Habit Learning (Weeks 4-8)

#### Actual Behavior Tracking
**What to Learn:**
- You and John actually meet at Turner Wed/Fri 12:30-1pm
- Not Squires (even though you're both free there)
- Not 11:30am lunch (even though schedule says free)
- The real pattern: Turner, 12:30, after CS 2114

**Smart Defaults:**
- "Heading to Turner for lunch? John usually is too 🍔"
- "You both grab coffee at Squires on Tuesdays after 3pm ☕"

#### Pattern Suggestions
```
"You and Rachel both have Thursday 2-4pm free.
In the past 3 weeks, you've met at Newman Library 2/3 times.
Study session today?"
```

### Phase 4: Spontaneous Plans (Weeks 8+)

#### Quick Plans API
```swift
struct QuickPlan {
    let suggestedTime: Date // "In 15 min"
    let location: String    // "Turner Place"
    let activity: String    // "Coffee" | "Lunch" | "Study"
    let friends: [String]   // ["John", "Rachel"]
    let confidence: Double  // Based on past acceptance
}
```

**UI Flow:**
1. App suggests: "Coffee with John at Squires in 15 min?"
2. You tap "Yes" → John gets notification
3. John accepts → Both get countdown + walking directions
4. 5 min before: "Head out now! 4 min walk"

#### Confidence Scoring
- Past plan acceptance rate
- Current activity modes
- Location proximity
- Time remaining in free block
- Weather (if raining, suggest indoor spots)

## Implementation Priority

### Ship Now (P0)
- ✅ Activity modes (already built)
- ✅ Campus events (already built)
- ⏳ Single timeline view (building now)

### Ship Week 2 (P1)
- [ ] Location zones during activity modes
- [ ] "Friends nearby" card on Today view
- [ ] Smart nudges: "John's free at Squires now"

### Ship Week 4 (P2)
- [ ] Habit learning (track actual meetups)
- [ ] Pattern-based suggestions
- [ ] "You usually meet here" reminders

### Ship Week 8 (P3)
- [ ] Quick plans API
- [ ] Spontaneous plan suggestions
- [ ] Confidence-based auto-scheduling

## Privacy Principles

**Location Data:**
- Only during activity modes (time-boxed)
- Rough zones, not GPS
- Deleted after mode expires
- Cannot reconstruct movement history

**Habit Learning:**
- Patterns stay on-device initially
- Server only sees: "meetup happened: Y/N"
- No tracking between friends without mutual activity mode

**User Control:**
- "Don't suggest John for a week" (friend taking a break)
- "Never suggest this location" (ex's dorm)
- "Quiet hours" (no nudges during study time)

## Success Metrics

**Engagement Beyond Schedule Learning (Week 3+):**
- Daily active users (DAU) retention after week 3
- Activity mode activations per week
- "Friends nearby" card tap rate
- Spontaneous plan acceptance rate
- Average plans created per week (vs. scheduled overlap views)

**The Goal:**
Week 1: "Cool, I see my overlaps"  
Week 3: "I know my overlaps, but I still check for who's free RIGHT NOW"  
Week 8: "I don't plan meetups anymore, Between just suggests them"
