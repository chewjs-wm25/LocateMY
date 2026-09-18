# Crime & Security Feature Implementation Plan

Implement the official crime statistics and safety index feature based on the [Crime & Security Development Contract](file:///home/william/StudioProjects/LocateMY/docs/design/features/crime-and-security.md).

## User Review Required

> [!IMPORTANT]
> The implementation strictly follows the state-level aggregation of the `crime_district` dataset. It does not provide district-level safety analysis or personal victim probability.

> [!NOTE]
> Hazard reports and official crime statistics are isolated. Hazards will not affect the safety index.

## Proposed Changes

### [Crime & Security Component]

#### [NEW] [crime_and_security.dart](file:///home/william/StudioProjects/LocateMY/lib/features/crime_and_security/crime_and_security.dart)
Define the public interface `SAFETY-001` and `ShellIntent` markers as specified in the contract.

#### [NEW] [safety_models.dart](file:///home/william/StudioProjects/LocateMY/lib/features/crime_and_security/src/domain/safety_models.dart)
Implement the data models for safety requests, snapshots, trends, and outcomes.

#### [NEW] [safety_service.dart](file:///home/william/StudioProjects/LocateMY/lib/features/crime_and_security/src/application/safety_service.dart)
Implement the core logic:
- Geographic resolution using `GEO-001`.
- Crime statistics fetching and aggregation via Supabase.
- Safety index calculation (log-scaled percentile).
- Trend data processing.
- Cache management (3-day TTL).

#### [NEW] [crime_repository.dart](file:///home/william/StudioProjects/LocateMY/lib/features/crime_and_security/src/data/crime_repository.dart)
Handle Supabase queries for the `crime_district` dataset and local caching in `crime_public_cache`.

#### [NEW] [crime_security_page.dart](file:///home/william/StudioProjects/LocateMY/lib/features/crime_and_security/src/presentation/crime_security_page.dart)
Implement the UI:
- Safety index card.
- Latest annual crime count.
- 5-year trend chart with category filtering.
- Navigation back to map and property archives.

---

## Verification Plan

### Automated Tests
- **Unit Tests**:
    - Safety index calculation logic (verify log-scaling and weights).
    - Cache TTL logic.
    - `GEO-001` resolution mapping to `SAFETY-001` unavailable reasons.
- **Integration Tests**:
    - Mock Supabase response for `crime_district` and verify aggregation.

### Manual Verification
- Navigate from Map to Crime & Security page.
- Switch between crime categories (Assault, Property, All) and verify trend chart updates.
- Verify "Temporarily Unavailable" states when location is outside Malaysia or data is missing.
- Verify navigation back to Map and to Property Add/Archive.
