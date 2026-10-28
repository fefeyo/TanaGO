# Milk × pistachio — 0.7.0 (8)

The selected visual direction uses ivory backgrounds, pistachio controls and apricot accents. Shared colors live in `lib/src/design/app_palette.dart` and feed the Material theme, shared headings, lists, map and completion screen.

- Replace the registration screen’s large green banner with a compact household/today heading, count pill and registration action.
- Keep ordinary product rows within 60 logical pixels at default text size; preserve category grouping and pinned headers. Category icons and rounded surfaces provide visual character without extra metadata rows.
- Use apricot rows and a small rounded “すぐ買いたい！” label for urgent products. Unclassified products retain their category-assignment prompt on a pale yellow background.
- Highlight relevant map shelves with pistachio fill, a dark count badge and a stronger selected outline. Counts represent unchecked selected products during a trip and registered products while browsing. Small shelves use a compact count. Color and count update together as products are checked.
- Use a quiet grid, soft product-sheet shadow, rounded checkboxes and a short color transition. Newly added animations respect reduced-motion settings.
- Add a small vector shopping-bag illustration and a friendly completion message. The illustration is painted locally and stays sharp at different screen densities.

Validation: existing Flutter tests cover the shopping flow, history, undo, map gestures, compact rows, pinned headers, safe areas and larger text. The shelf-highlight test now also checks count updates. Japanese rendered previews cover the main screens, including a 320×640 display with 1.3× text. No Firestore schema or rule change is part of this release.

Review delivery: Firebase App Distribution, **TagaGOTester** (`tagagotester`).
