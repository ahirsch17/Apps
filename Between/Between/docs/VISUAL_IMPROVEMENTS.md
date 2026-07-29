# Visual Improvements Summary

## Problem Solved

**Original issue**: Static schedule timeline dominates main screen → boring after week 3 → users stop opening app.

**Solution**: Rebuild main screen to show DYNAMIC, real-time content that changes hourly.

## New UI Hierarchy

### Before (Static Focus)
```
Today Screen
├── Greeting
├── Headline
├── Friends free (small chips)
├── Next class
├── Meetups
├── Events (buried)
├── Activity modes (small bar)
└── TIMELINE (prominent, static) ← Main visual, but boring after week 3
```

### After (Dynamic Focus)
```
Today Screen
├── Greeting
├── Headline (dynamic)
├── Friends Free NOW (large cards with location)
│   ├── John 🍔 at Squires • 4 min
│   ├── Rachel 📚 at Newman • 6 min
│   └── [Message] button for each
├── Next class
├── Meetups (today only)
├── Quick Actions Card ← NEW
│   ├── Activity mode buttons
│   └── "I'm free right now" (prominent)
├── Events
├── Spontaneous Plans Card ← NEW
│   └── "Coffee with John in 15 min?"
└── Schedule (collapsible) ← Moved to bottom
    └── Timeline (hidden by default)
```

## Key Improvements

### 1. Location-Based "Free Now" Cards

**Before**: Small avatar chips with tiny location text
**After**: Full cards with:
- Large avatar with free ring
- Location with map pin icon
- Distance label (e.g., "4 min")
- Activity emoji (🍔 Hungry, 📚 Study, 🏃 Gym)
- Message button

### 2. Quick Actions Card

**Before**: Small activity bar + button at bottom
**After**: Prominent card with:
- Section header "What are you up for?"
- Activity mode buttons
- Large "I'm free right now" button with sparkles icon
- Clear call-to-action styling

### 3. Spontaneous Plan Suggestions

**NEW**: Smart suggestions based on:
- Friends free nearby
- Starred friends
- Location proximity
- Current time context

Example:
```
💡 Suggested
Coffee with John in 15 min?
They're at Squires

[Yes, let's do it! ☕]  [Not right now]
```

### 4. Timeline Now Collapsible

**Before**: Always visible, takes up space
**After**: Collapsed by default
- Tap "Schedule" to expand
- Shows chevron indicator
- Only for users who want reference view

## Visual Design Patterns

### Card Design
- Larger touch targets (min 44pt height)
- Clear hierarchy (title > subtitle > action)
- Consistent corner radius (14pt for cards)
- Shadows for depth
- Accent color for CTAs

### Iconography
- Map pin for location
- Sparkles for "free now"
- Lightbulb for suggestions
- Activity emojis (🍔📚🏃☕)
- Chevrons for expand/collapse

### Typography
- Card titles: `.cardTitle()` (semibold, prominent)
- Locations: `.caption()` with accent color
- Distances: `.caption()` with accent color
- Actions: `.secondary().weight(.semibold)`

### Color Usage
- Accent color: CTAs, active states, highlights
- Secondary: Supporting text, inactive states
- Surface: Card backgrounds
- Accent soft: Button backgrounds (12% opacity)

## Long-term Engagement Strategy

### Week 1-2: Schedule Learning Phase
- Timeline useful: "When am I free?"
- Static overlaps help plan week
- Timeline visible but collapsible

### Week 3+: Dynamic Matching Phase
- Timeline collapses by default
- Focus shifts to:
  1. **Who's free RIGHT NOW?** (changes every 30 min)
  2. **Who's nearby?** (location-based, always fresh)
  3. **What's happening today?** (events, spontaneous plans)
  4. **Quick actions** (set mode, broadcast availability)

### Engagement Hooks
1. **Location matching**: "John is at Squires (4 min walk)"
2. **Activity modes**: "Rachel is in Hungry mode"
3. **Spontaneous plans**: "Coffee in 15 min?"
4. **Event partner matching**: "3 looking for partners"
5. **Real-time updates**: Friend status changes trigger notifications

## Technical Implementation

### New Components
- `SpontaneousPlan` model
- `spontaneousPlanCard` view
- `freeNowCard` view (replaces `freeNowChip`)
- `quickActionsCard` view
- `scheduleSection` view (collapsible)

### New Methods
- `AppViewModel.spontaneousPlanSuggestion()` - Generates smart suggestions
- `AppViewModel.acceptSpontaneousPlan()` - Handles acceptance
- `AppViewModel.dismissSpontaneousPlan()` - Handles dismissal
- `AppViewModel.showToast()` - Now public for view access

### Visual Enhancements
- Activity emojis based on mode
- Distance labels with map pin icons
- Message buttons for direct contact
- Expand/collapse for timeline
- Larger cards with better spacing

## Result

**Before**: Main screen = static schedule → boring after 3 weeks
**After**: Main screen = dynamic real-time matching → always changing, always relevant

**Retention strategy**: Shift from "learn my schedule" (one-time) to "find people now" (ongoing).
