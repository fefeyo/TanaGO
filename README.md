# TanaGO

TanaGO is a shared grocery shopping app for people living in the same household.

Someone at home adds what they want bought. The person going shopping checks the shared list, selects a supermarket, and uses the store map to find the required sections.

## MVP

1. Create or join a household
2. Add items to the household shopping list
3. Select a household store
4. Open the store's indoor map
5. See where the requested items are located
6. Mark items as purchased

## Tech stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Riverpod
- go_router

## Current implementation

The repository currently contains the domain/UI foundation before Firebase configuration:

- household-aware domain model
- shared shopping-list model with added/purchased user metadata
- local shopping-list prototype
- household-owned store model
- store registration prototype
- grid-based store map editor
- shelf / wall / entrance / register placement

Firebase synchronization will be connected after the Firebase project configuration is available.

## Architecture

Feature-oriented structure under `lib/src/features`.

Map editing and future route-finding logic are kept independent from Firebase so they can be unit tested as pure Dart logic.
