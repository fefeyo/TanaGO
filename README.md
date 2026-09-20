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

The repository currently contains the app foundation before Firebase project configuration:

- household-aware shopping lists and stores
- automatic product-category classification with manual correction
- grid-based store map editor
- category assignment for shelves
- shopping map with highlighted required shelves
- selected-shelf item panel
- repository contracts for shopping lists, stores, and maps
- in-memory repository implementations used by the app today
- authentication abstraction with local and Firebase Auth adapters
- Firestore repository adapters prepared for the final Firebase connection
- unit tests for household/store isolation and shopping-map matching

## Data boundaries

Application state is scoped so data from different households and stores cannot mix:

- shopping list: `householdId`
- stores: `householdId`
- store map: `householdId + storeId`

The planned Firestore hierarchy is:

```text
households/{householdId}
  shoppingLists/active
    items/{itemId}
  stores/{storeId}
    mapObjects/{mapObjectId}
```

Household members will also live under the household when authentication and invitations are connected.

## Architecture

Feature-oriented structure under `lib/src/features`.

Presentation code depends on repository contracts instead of Firestore directly. The current providers use in-memory repositories, while Firestore implementations live in each feature's `data` layer. Once Firebase configuration is available, the repository providers can be switched to the Firestore implementations without changing the screens or feature controllers.

Firebase initialization, security rules, and the provider switch from the in-memory adapters to Firebase Auth / Firestore will be connected after the Firebase project configuration is available.
