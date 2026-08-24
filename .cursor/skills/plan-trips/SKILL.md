---
name: plan-trips
description: Plan Alex trips as Trip/Planning-notes HTML. Keep Teralinks, budget, and photos in sync. Audit each city for nearby must-see icons vs weak walking tours. Active GYG and food tours, not museum lectures. Use when starting a new trip, editing files under trips/ (brazil-argentina-2027, germany-2026, template), or when the user mentions itinerary, Teralink, GYG, sister trip, HYROX, or Oktoberfest.
---

# Plan trips

Read `trips/RULES.md` before adding a hotel, restaurant, tour, or day.

## Every edit

1. If flights change: rewrite Teralinks and recompute budget (hero, table, donut, bars) in the same pass.
2. Photos on a day = that day’s places.
3. Coverage audit: for each stop, would a first-timer be mad we skipped an icon that was a short Uber away? If yes, swap the weaker activity.

## New trip

1. Copy `trips/template/index.html` to `trips/<slug>/index.html`.
2. Put photos in `trips/<slug>/photos/`.
3. Fill hero, route, day cards, budget, flights, **when to buy**, laundry, bags, sun, hotel map pins. Neighborhood / safety / icons live on the day cards, not a duplicate “each stop” block.
4. Do not invent ratings. Check GYG / TripAdvisor / Expedia.
5. Link hotels to Expedia, experiences to GYG, restaurants to TripAdvisor, flights to Teralinks. Official venue tickets are the exception.

## Do not

- Leave a stale Teralink or budget after a flight change.
- Drag bags across town on foot.
- Book GYG under **4.7 / 150** or food under **TripAdvisor 4.7 / 200**.
- Split a layover into two tickets.
- Spend a full day on a history walking tour while Casa Rosada / Colón / Christ-type icons sit unused.
- Fill a race-eve or race day with a city tour. Light walk only.
- Require a food tour in every city. The bar is **one per country**, and only if a listing at a stop we sleep in clears 4.7 / 150.
- Make every city reservation-only. Keep the fancy dinners, and also mark **Reserve vs Walk-in**, plus one street / kiosk / must-try dessert or delicacy.
- Use em dashes on trip HTML. Use a period, a comma, or `·`.
- Name another trip on this trip’s HTML (Brandenburg, Florence, HYROX, UK). Analogies stay in chat, not on the page.
- Put the hotel in a neighborhood we would not walk at 10p. Sleep in relatively safe tourist areas. Mixed icons (Selarón, Caminito) are day-only with Uber or a guide.
- Write “already booked” on GYG or tickets. The page is the shopping list unless Alex said it is paid.
- Leave a Book line without a clock time or pickup window. Confirm the live GYG / official slot on the date before paying. April 2027 inventory may not be live yet. Use typical hours from the listing, not a made-up voucher.
