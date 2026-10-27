# Shopping improvements — 0.6.0 (7)

Implemented the selected ideas in order: 1, 2, 3, 5, 6, 7.

- **Recent purchases:** the registration screen opens the latest 60 purchased item records, collapsed by product name and category. One tap re-adds a product with a new ID and the current member as author, keeping its category, quantity and memo. Existing active products show “登録済み”. “すぐ買いたい！” resets for the new purchase. Older purchases that were physically deleted cannot be recovered; history starts with purchases completed using this version.
- **Unmapped products:** store selection groups products by that store’s shelf categories, then shows “場所未登録”. Null categories and categories without a shelf remain selectable and checkable, even without a map. A shelf category indicates a mapped location, not confirmed stock availability.
- **Quantity and memo:** the shared registration/edit dialog accepts optional quantity (40 characters) and memo (300 characters). The initial list stays compact; shopping and confirmation show the details. Missing fields in legacy documents default to empty strings.
- **Map/list linkage:** tapping a product name centers and zooms its first matching shelf; tapping a shelf filters the product sheet. The close icon clears the shelf filter. Checking a product is a separate action and does not move the map.
- **Undo:** purchase completion archives the current product snapshot and physically deletes it from the active list. The completion screen can restore the original ID, author, date, category, urgency and details. Restore never overwrites a product already recreated/edited by another member. The button is available while the completion screen is open; after leaving, history supports re-registration.
- **One-hand shopping:** the bottom product sheet can be dragged between map and list, with accessible expand/collapse buttons and larger right-side check targets. The confirmation action stays at the bottom above the system safe area.

## Persistence and retry behavior

History lives at `households/{hid}/purchaseHistory/{originalItemId}` with the item fields plus `purchaseId`. It is restricted to household members. Archive creation requires the matching active item to be deleted atomically, preserves all non-purchase fields, and uses a server purchase timestamp. History updates are denied. Restoring another member’s product requires consuming its history document in the same transaction.

Purchase/undo transactions process up to eight items at a time to stay within Firestore rule access limits. The confirmation page retains the operation UUID and original target IDs on failure. Retrying returns already archived records from that operation along with newly archived records, so undo includes all successful chunks. Undo checks `purchaseId`, so an old retry cannot undo a later purchase of the same ID. All reads precede writes in each transaction. Tests cover the eight-item rule budget with custom categories and legacy documents without optional fields.

## Device review

1. Edit an item, enter a quantity and memo, and check both the initial list and store selection.
2. Buy it, return to the list, open “最近買ったものから追加”, and re-add it with ＋.
3. Select an item without a mapped category; check it in “場所未登録” and complete the purchase.
4. Tap a product name to focus its shelf, then tap the shelf to expand its product list. Confirm the checkbox does not move the map.
5. Drag the bottom sheet, including on a small screen with larger text.
6. Complete a purchase, then use “購入完了を取り消す” before leaving the completion screen.

Review distribution uses the existing **TagaGOTester** group (`tagagotester`). Deploy the matching Firestore rules before distributing the APK.
