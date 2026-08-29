# Implementation Plan - AppShell Tab Reduction and New Map Page

Modify the application to have only two main tabs: "Home" and "Map". The "Map" page will serve as the primary entry point for exploring location-based data (Cost of Living, Security, etc.).

## Proposed Changes

### Localization

#### [app_zh.arb](file:///D:/Work/Mobile Application/Assignment/lib/l10n/app_zh.arb)
- Add keys for Map page: `navMap`, `titleMap`, `displayMode`, `comparisonMode`, `currentAddress`, `newAddress`, `searchLocation`, `selectOnMap`.

#### [app_en.arb](file:///D:/Work/Mobile Application/Assignment/lib/l10n/app_en.arb)
- Add corresponding English keys.

---

### Core State Management

#### [NEW] [location_provider.dart](file:///D:/Work/Mobile Application/Assignment/lib/providers/location_provider.dart)
- Create a `LocationProvider` to store:
    - Current map mode (Display or Comparison).
    - Selected location (for Display mode).
    - Origin and Destination locations (for Comparison mode).

#### [main.dart](file:///D:/Work/Mobile Application/Assignment/lib/main.dart)
- Initialize `LocationProvider` using `MultiProvider`.

---

### Views

#### [app_shell.dart](file:///D:/Work/Mobile Application/Assignment/lib/views/app_shell.dart)
- Update `_widgetOptions` to only contain `HomeScreen` and the new `MapView`.
- Update `BottomNavigationBar` to have two items: `navHome` and `navMap`.

#### [NEW] [map_view.dart](file:///D:/Work/Mobile Application/Assignment/lib/views/map/map_view.dart)
- Implement a map of Malaysia using `flutter_map`.
- Add a mode switch in the top-left (Display/Comparison).
- Implement location selection:
    - Search box at the top.
    - Click on map to select/mark a location.
- Add quick access buttons in the top-right to navigate to:
    - Cost of Living
    - Crime & Security
    - Socio-Economic
    - Infrastructure
    - Transportation
- Buttons should pass selected location(s) context to the destination views.

---

### Navigation & Integration

#### [cost_of_living_view.dart](file:///D:/Work/Mobile Application/Assignment/lib/views/cost_of_living/cost_of_living_view.dart) (and other data views)
- Modify to optionally accept location parameters or read from `LocationProvider`.
- Ensure they can function as standalone pages (with their own Scaffold if needed, though they already have one).

## Verification Plan

### Automated Tests
- N/A (Project seems to rely on manual verification for UI).

### Manual Verification
- Run the app and check if `AppShell` only has two tabs.
- Navigate to the Map page and verify:
    - Map loads correctly centered on Malaysia.
    - Mode switch works.
    - Search box works (can simulate selection).
    - Clicking on map updates selected location.
    - Top-right buttons navigate to the correct data views.
    - Data views show relevant location info (mocked or pre-selected).
