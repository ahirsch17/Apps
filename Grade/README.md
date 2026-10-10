# Grade

Color grading for photos and videos. Pick a look (each one is a 3D LUT), then change individual colors in the photo: whiter teeth, bluer water, greener grass. It keeps the shading, so it doesn't look like a filter.

## How it works

| Piece | Behavior |
|-------|----------|
| Looks | 15 built-in looks (Golden Hour, Film 400, Teal & Orange, Tropical, Matte, Noir…), previewed on your own photo. Each one is a recipe (white balance, curve, fade, split tone, per-hue shifts) baked into a 33×33×33 LUT and applied with Core Image. Strength slider. |
| Protect skin | On by default. Pulls skin tones back toward the original so faces don't go orange or green under strong looks. |
| Tune | Brightness, contrast, warmth, tint, saturation, vibrance, fade, highlight softening, split toning, black & white. |
| Color | Tap any color in the photo. Similar colors are found by distance in LCh (lightness counts least, so shadowed and lit parts of the same thing match), and the change is relative, not a fill: lighter / more or less saturated / hue-rotated by the same amount. Grass keeps its texture, teeth keep their shading. Suggestions depend on what you tapped (off-white: Clean white; greens: Lush, Teal, Golden; skin: Glow, Less red…), or pick an exact color. Range slider, "show selection" view. |
| Area | Optional mask per color change: brush, lasso, erase, adjustable edge softness. Example: tap a tooth, choose Clean white, lasso the face. Teeth and eye whites go white; skin, lips and the white shirt below don't change. |
| Match | Copy the colors of a reference photo (Lab mean/std transfer, partly on lightness so faces don't blow out). Or match one of your other shots so a set looks consistent. Saved matches adapt to each photo. |
| Your looks | Save the current look + Tune as a LUT, import `.cube` files, export `.cube` for Lightroom / CapCut / Premiere / Resolve. |
| Video | Same edit applied per frame (`AVVideoComposition` + Core Image), live preview player, export to Photos. Masks are fixed to the frame (no tracking). |
| Batch | Use one look on every imported photo, then Save all. |

Photos export at full resolution as JPEG with original metadata, in the original's color space (Display P3 for iPhone photos). Previews run on a 1600 px copy.

## Install

Requires iOS 17+.

```bash
cd Grade && xcodegen generate   # optional, the .xcodeproj is checked in
```

Open `Grade.xcodeproj`, set your signing team, run. Grade only asks for "add to Photos" access; the photo picker doesn't need library permission.

## Layout

```
Grade/
  Engine/   LUT math, looks, color shifts, masks, render pipeline, export, .cube files
  Models/   Media items, edit state, importing
  Store/    Look library (saved looks on disk), editor session
  Views/    Library grid, editor, Looks / Tune / Color / Match panels
```
