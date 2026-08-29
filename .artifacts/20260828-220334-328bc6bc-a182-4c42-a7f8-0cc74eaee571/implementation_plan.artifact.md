# LocateMY Component-Based Documentation Implementation Plan

This plan outlines the reorganization of the project documentation into a component-based structure following the MVVM architecture. Each functional module will be decomposed into components residing in specific layer directories.

## Proposed Changes

### Documentation Structure
The `docs/` directory will be organized by MVVM layers. Each file will describe a specific component related to a module.

#### [NEW] docs/architecture.md
- High-level overview of the MVVM implementation in LocateMY.
- Communication patterns (Reactive streams, Dependency Injection).

#### [NEW] docs/view/ (Folder)
Contains UI Component documents. Each document specifies:
- Widget structure and layout.
- Data visualization types (Charts/Maps) and libraries (e.g., `fl_chart`).
- User interaction events.
- **Files**:
    - `cost_of_living_view.md`: Histogram (Pre vs Post), Pie Chart (Expenses).
    - `crime_security_view.md`: Line Chart (Trends), Pie Chart (Categories).
    - `socio_economic_view.md`: Distribution Plot, Gauge (Gini).
    - `climate_flood_view.md`: Map Overlay (Flood zones), Forecast Cards.
    - `transportation_view.md`: Map Overlay (Station density).
    - `infrastructure_view.md`: Radar Chart (ICI scores).
    - `account_view.md`: Auth forms (Magic Link), Profile/Settings UI.

#### [NEW] docs/viewmodel/ (Folder)
Contains business logic and state management component documents.
- State definitions (Loading, Success, Error).
- Command/Method signatures.
- Data transformation logic (e.g., calculating ICI score).
- **Files**:
    - `cost_of_living_viewmodel.md`
    - `crime_security_viewmodel.md`
    - `socio_economic_viewmodel.md`
    - `climate_flood_viewmodel.md`
    - `transportation_viewmodel.md`
    - `infrastructure_viewmodel.md`
    - `account_viewmodel.md`: Auth state, preference management.

#### [NEW] docs/model/ (Folder)
Contains data entity and DTO documents.
- JSON mapping/serialization.
- Domain objects.
- **Files**:
    - `cost_of_living_model.md`
    - `crime_security_model.md`
    - `socio_economic_model.md`
    - `climate_flood_model.md`
    - `transportation_model.md`
    - `infrastructure_model.md`
    - `account_model.md`: User Profile, Preferences schema.

#### [NEW] docs/repository/ (Folder)
Contains data access component documents.
- API endpoint mappings (Data.gov.my, Supabase).
- Caching strategies.
- Error handling.
- **Files**:
    - `cost_of_living_repository.md`
    - `crime_security_repository.md`
    - `socio_economic_repository.md`
    - `climate_flood_repository.md`
    - `transportation_repository.md`
    - `infrastructure_repository.md`
    - `account_repository.md`: Supabase Auth & DB interactions.

---

### Account Module Components
- **View**: Login screen (Email field), Profile screen (Preferences toggles, Social links).
- **ViewModel**: `AuthViewModel` (Login/Logout), `UserViewModel` (Profile/Preferences).
- **Model**: `User`, `UserPreferences`.
- **Repository**: `AuthRepository` (Magic Link), `UserRepository` (Profile persistence).

## Verification Plan

### Manual Verification
- Check that the `docs/` folder contains the four layer sub-folders: `view/`, `viewmodel/`, `model/`, `repository/`.
- Verify that each module (7 total) has a corresponding component document in each layer.
- Ensure `view/` documents explicitly define the data visualization method (e.g., Radar Chart for ICI).
- Confirm that `account/` components cover Magic Link login and preference storage.
