# TanaGO

TanaGO is a shared grocery shopping app for people living in the same household.

Someone at home adds what they want bought. The person going shopping checks the shared list, selects a supermarket, and uses the store map to find the required sections.

## MVP

1. Create or join a household
2. Add items to the household shopping list
3. Select a household store
4. Open the store's indoor map
5. See highlighted shelves for requested items
6. Tap a shelf to see the items to buy there
7. Mark items as purchased

## Tech stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Riverpod
- go_router

## Current implementation

The app uses Firebase Authentication (anonymous sessions) and Cloud Firestore in production:

- household-aware shopping lists and stores
- automatic product-category classification with manual correction
- grid-based store map editor
- category assignment for shelves
- shopping map with highlighted required shelves
- selected-shelf item panel
- repository contracts for shopping lists, stores, and maps
- in-memory repository implementations used by unit tests
- authentication abstraction with local and Firebase Auth adapters
- Firestore repository adapters with transactional edits and membership-based security rules
- unit tests for household/store isolation and shopping-map matching

## Data boundaries

Application state is scoped so data from different households and stores cannot mix:

- shopping list: `householdId`
- stores: `householdId`
- store map: `householdId + storeId`

The Firestore hierarchy is:

```text
users/{uid}
householdInvites/{inviteCode}
households/{householdId}
  members/{uid}
  shoppingLists/active
    items/{itemId}
  stores/{storeId}
    mapObjects/{mapObjectId}
```

Household creation and invitation joins atomically bind users to membership documents. Invite lookups do not expose household documents to non-members.

## Architecture

Feature-oriented structure under `lib/src/features`.

Presentation code depends on repository contracts instead of Firestore directly. Production providers use Firebase/Firestore; tests override them with in-memory implementations. Firebase initialization happens in `main.dart`, and authentication bootstrap precedes household loading.

See [Firebase setup, security model, existing-data migration and tests](docs/firebase-security.md) before deploying the rules. Existing short invite codes must be migrated alongside the app update.
