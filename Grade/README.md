# Grade

Color grading for photos and videos you're about to post. Pick a look (each one is a 3D LUT), fix the light, then change individual colors in the photo: whiter teeth, bluer water, greener grass. It keeps the shading, so it doesn't look like a filter. Edit one shot from a trip or a couple shoot and paste the edit onto the rest.

In development. Not on the App Store.

## How it works

| Piece | Behavior |
|-------|----------|
| Looks | 18 built-in looks in Portrait (Bright & Airy, Portra, Golden Hour, Peach), Travel (Vivid, Azure, Tropical, Teal & Orange, Sunset Pop, Desert), Film (Green Film, Vintage, Matte, Pastel), Moody (Moody, Nordic) and B&W (Noir, Soft B&W), previewed on your own photo. Each one is a recipe (white balance, curve, fade, split tone, per-hue shifts) baked into a 33×33×33 LUT and applied with Core Image. Vibrance and per-hue shifts leave near-whites and skin alone, so white dresses and clouds don't pick up a tint. Strength slider. |
| Protect skin | On by default. Pulls skin tones back toward the original so faces don't go orange or green under strong looks. |
| Auto | One tap fixes exposure and white balance from the photo's histogram: brightens dark shots, leaves sunsets alone, lifts shadows on backlit faces, recovers blown skies, neutralizes color casts. Tap again to undo. |
| Tune | Light: brightness, contrast, recover highlights, lift shadows. Color: warmth, tint, saturation, vibrance. Finish: fade, soften highlights, glow, vignette, grain. Split toning, black & white. |
| Color | Grade lists what it found in the photo (Skin, Sky, Water, Greenery, Golden light, Whites); tap one, or tap any color yourself. Similar colors are found by distance in LCh (lightness counts least, so shadowed and lit parts of the same thing match), and the change is relative, not a fill. Grass keeps its texture, teeth keep their shading. Suggestions depend on what you picked (off-white: Clean white; greens: Lush, Teal, Golden; skin: Glow, Less red…), or pick an exact color. Range slider, "show selection" view. |
| Area | Optional mask per color change: brush, lasso, erase, adjustable edge softness. Example: tap a tooth, choose Clean white, lasso the face. Teeth and eye whites go white; skin, lips and the white shirt below don't change. |
| Crop | 4:5 (feed), 1:1, 9:16 (Stories / Reels / TikTok), 16:9, 3:2. Drag to reposition, zoom slider. Applied on export for photos and videos. |
| Match | Copy the colors of a reference photo (Lab mean/std transfer, partly on lightness so faces don't blow out). Or match one of your other shots so a set looks consistent. Saved matches adapt to each photo. |
| Sets | Copy an edit and paste it onto one photo or all of them. Color changes carry over by color, not position; drawn areas stay with their photo. Save all exports everything edited. |
| Undo | Undo / redo for every change. Slider drags count as one step. |
| Share | Renders at full quality and opens the share sheet (Instagram, Messages, AirDrop), or saves to Photos. |
| Your looks | Save the current look + Tune as a LUT, import `.cube` files, export `.cube` for Lightroom / CapCut / Premiere / Resolve. |
| Video | Same edit applied per frame (`AVVideoComposition` + Core Image), including crop and moving grain. Live preview player, export to Photos. Masks are fixed to the frame (no tracking). |

Render order, same for preview and export: highlights/shadows → look → Tune → color changes inside their areas → glow / vignette / grain → crop. Photos export at full resolution as JPEG with original metadata, in the original's color space (Display P3 for iPhone photos). Previews run on a 1600 px copy.

## Install

Requires iOS 17+.

```bash
cd Grade && xcodegen generate   # optional, the .xcodeproj is checked in
```

Open `Grade.xcodeproj`, set your signing team, run. Grade only asks for "add to Photos" access; the photo picker doesn't need library permission.

CI builds the app for the simulator on every change to `Grade/` (`.github/workflows/grade.yml`).

## Layout

```
Grade/
  Engine/   LUT math, looks, effects, crop, auto fix, color finder, color shifts, masks, render pipeline, export, .cube files
  Models/   Media items, edit state, copy/paste, importing
  Store/    Look library (saved looks on disk), editor session (undo, preview, color picks)
  Views/    Library grid, editor, Looks / Tune / Color / Match / Crop panels
```
