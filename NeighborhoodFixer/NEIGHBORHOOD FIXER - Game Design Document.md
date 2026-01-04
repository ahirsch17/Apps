## NEIGHBORHOOD FIXER: Game Design Document (GDD)

### High Concept
**NEIGHBORHOOD FIXER** is an incremental/idle clicker game where players transform a dilapidated neighborhood into a thriving smart city. Players earn currency by completing renovation tasks, hiring managers to automate work, and reinvesting profits to unlock new buildings and upgrades.

### Player Fantasy
- **Be the neighborhood hero**: watch visible, satisfying “before → after” transformations.
- **Build momentum**: move from hands-on repairs to automated, thriving city growth.
- **Master progression**: optimize upgrades, managers, and prestige to scale faster each run.

---

## Game Overview

### Core Gameplay Loop
- **Tap/Click to Renovate** to earn currency early.
- **Spend** earnings to **upgrade properties** and **hire managers**.
- **Automate** income with managers; reinvest into higher tiers and global upgrades.
- **Hit milestones** and trigger **Prestige (“Community Revival”)** to reset for permanent power via prestige currency.
- **Repeat** with faster growth, deeper upgrades, and new visual district transformations.

---

## Resources & Currency

### Neighborly Goodwill (Primary Currency)
- **Earned**: primarily from renovation activities (manual clicks and automated production).
- **Spent on**: property upgrades, unlocks, and general progression.

### Renovation Points
- **Earned/Granted**: via gameplay progression (e.g., leveling properties, achievements, milestones).
- **Spent on**: purchasing upgrades and hiring managers (or manager-related improvements).

### Community Spirit (Prestige Currency)
- **Earned**: after major milestones / on prestige.
- **Spent on**: permanent upgrades that persist across revivals.

---

## Player Actions

### Tap/Click to Renovate
- Manual action that produces immediate gains and supports “active play” bursts.
- Can be enhanced with click-based bonuses and special effects.

### Hire Managers
- Automates tasks for a specific property type.
- Adds special bonuses and personality to the game via portraits and speech bubbles.

### Upgrade Properties
- Each property type improves output and visual state through multiple levels.
- Level milestones can unlock special abilities and/or cosmetic changes.

### Prestige: Community Revival
- Resets most progression in exchange for **Community Spirit**.
- Adds long-term goals and accelerates future runs through permanent bonuses.

---

## Property System

### Property Types (5 Tiers, 3 Properties Each)
Each property:
- Has a **unique visual evolution through 10 levels**
- Generates **Neighborly Goodwill per second**
- Can be upgraded individually
- Unlocks **special abilities** at certain milestones

#### Tier 1: Basic Beautification
- **Mow Lawns**
- **Plant Flowers**
- **Community Garden**

#### Tier 2: Home Improvements
- **Fix Porches**
- **Repaint Houses**
- **Renovate Buildings**

#### Tier 3: Community Spaces
- **Open Shops**
- **Build Parks**
- **Create Plaza**

#### Tier 4: Urban Development
- **Attract Businesses**
- **Build Apartments**
- **Downtown District**

#### Tier 5: Metropolis
- **Stadiums**
- **Skyscrapers**
- **Smart City**

---

## Managers & Specializations
Managers automate one property type and provide bonuses:

- **Bobbi the Builder**
  - **Role**: Tier 1 specialist
  - **Bonus**: +50% speed to Tier 1 renovations
  - **Portrait**: Young woman in hard hat with tool belt

- **Grumpy Gus**
  - **Role**: Tier 2 specialist
  - **Bonus**: 2x output for Tier 2, but complains in speech bubbles
  - **Portrait**: Older contractor with crossed arms and grumpy expression

- **Designer Dana**
  - **Role**: cosmetics & style
  - **Bonus**: Unlocks special cosmetic upgrades
  - **Portrait**: HGTV-style host with clipboard and stylish glasses

- **Fix-It Felix**
  - **Role**: click-based support
  - **Bonus**: Chance for bonus materials on click
  - **Portrait**: Handyman with patched overalls and big smile

- **Permit Patty**
  - **Role**: progression smoothing
  - **Bonus**: Reduces unlock requirements for new properties
  - **Portrait**: City planner with blueprints and coffee cup

- **Investor Ivan**
  - **Role**: idle economy
  - **Bonus**: Provides idle earnings bonus
  - **Portrait**: Suit-wearing businessman with briefcase

---

## Upgrades System

### Individual Property Upgrades
- Increase a specific property’s output and/or speed.
- Often tied to level milestones and visual changes.

### Global Upgrades
- Affect all properties (e.g., overall multiplier, automation efficiency, milestone bonuses).

### Manager Upgrades
- Improve manager efficiency, bonuses, or unlock extra traits (e.g., reduced automation interval).

### Prestige Upgrades (Permanent)
- Purchased with **Community Spirit**.
- Provide long-term multipliers, faster unlocks, and stronger automation.

---

## Achievements & Goals
- **Quick Mower**: Mow 100 lawns
- **Block Captain**: Fully upgrade one block
- **Green Thumb**: Plant 1,000 flowers
- **Downtown Developer**: Unlock all Tier 4 properties
- **City Visionary**: Reach smart city status

---

## UI/UX (Screens & Key Interfaces)

### Main Screen
- **Side-scrolling neighborhood** that transforms visually as the player progresses.

### Upgrade Menu
- **Tablet-like interface** with property cards.

### Manager Desk
- **Office bulletin board** with manager profiles and unlock status.

### Achievement Wall
- **Community center trophy case** showing earned achievements.

### Prestige Screen
- **“City Hall” interior** featuring a monument and revival options.

---

## Visual Effects (VFX)
- **Dollar Signs → Hearts**: currency gains appear as hearts instead of dollar signs.
- **Construction Particles**: small hammers/wrenches fly toward properties during upgrades/renovations.
- **Neighborhood Glow**: areas pulse when ready to upgrade.
- **Transformation Animation**: before/after crossfade when properties upgrade.

---

## Visual Assets Needed (Sora Prompt Targets)

### Tier 1: Basic Beautification
- **Mow Lawns**: Overgrown lawn → freshly mowed lawn with visible stripes
- **Plant Flowers**: Empty flower beds → vibrant tulips/marigolds
- **Community Garden**: Vacant lot → thriving vegetable garden with neighbors gardening

### Tier 2: Home Improvements
- **Fix Porches**: Sagging porch with broken steps → freshly painted porch with new furniture
- **Repaint Houses**: Faded, peeling house → bright, freshly painted house
- **Renovate Buildings**: Rundown building → completely restored Victorian house

### Tier 3: Community Spaces
- **Open Shops**: Empty storefront → bustling cafe with outdoor seating
- **Build Parks**: Trash-filled lot → playground with benches and trees
- **Create Plaza**: Intersection with potholes → brick plaza with fountain and string lights

### Tier 4: Urban Development
- **Attract Businesses**: Small shops → modern office building with logos
- **Build Apartments**: Single-family homes → stylish apartment complex
- **Downtown District**: Mixed-use development with shops below, apartments above

### Tier 5: Metropolis
- **Stadiums**: Empty field → modern sports stadium with lights on
- **Skyscrapers**: Low-rise buildings → glass skyscrapers with reflective surfaces
- **Smart City**: Traditional city → futuristic city with green roofs, solar panels, flying vehicles

### Character Portraits (Managers)
- **Bobbi the Builder**: Young woman in hard hat with tool belt
- **Grumpy Gus**: Older contractor with crossed arms and grumpy expression
- **Designer Dana**: HGTV-style host with clipboard and stylish glasses
- **Fix-It Felix**: Handyman with patched overalls and big smile
- **Permit Patty**: City planner with blueprints and coffee cup
- **Investor Ivan**: Suit-wearing businessman with briefcase

---

## Monetization Strategy
- **Remove Ads**: One-time purchase
- **Golden Toolbox**: Permanent 2x multiplier
- **Community Care Package**: Starter pack of currency and managers
- **Architect's Bundle**: Unlock next tier early
- **Cosmetic Skins**: Different architectural styles (Victorian, Modern, Art Deco)

---

## Technical Specifications for Assets

### File Format
- **PNG with transparency**

### Dimensions
- **Property cards**: 256x256px
- **Character portraits**: 128x128px
- **Background elements**: 1024x576px
- **UI elements**: Various; use **9-slice** where appropriate

### Art Style
- **Bright, cartoony** but with **realistic textures**
- Similar to **AdVenture Capitalist**, but with **more detailed environments**

### Color Palette Progression
- **Early game**: Browns/greys (rundown) → greens/blues (refreshed)
- **Late game**: Vibrant city colors → futuristic neon accents

---

## Open Design Decisions (Fill In As You Build)
- **Progression curves**: cost scaling, output scaling, milestone pacing
- **Prestige formula**: how Community Spirit is calculated per run
- **Manager acquisition**: direct purchase vs. milestone unlocks vs. random events
- **Offline earnings**: cap, duration, and monetization tie-ins (if any)
- **Cosmetic skins**: whether purely visual or with minor bonuses


