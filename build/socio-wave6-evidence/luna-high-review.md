# Luna High review — Socio-economic Feature

Review target: `git diff 73b7ba1bcf403b5dde0485ef79d9fa8fc6f43f99...d192281b758704c2e07fd8e73f07391ebcf380fa`.
Commit `77e9ae3` is treated as the stated repository-wide CI restoration; feature findings below concern the Socio implementation in `d192281`.

## Spec

### P1 — A/B partial failure can crash instead of retaining the available side

When the A analysis returns a typed failure while B succeeds, `SocioViewModel.load` leaves `a` null at [socio_view_model.dart:54-58](/home/AC79/Desktop/LocateMY-socio-economic/lib/features/socio_economic/src/presentation/socio_view_model.dart:54), because `a = a?.withoutPosition()` is a no-op on the first load. The page only checks `b != null` and then force-unwraps A at [socio_economic_page.dart:128-131](/home/AC79/Desktop/LocateMY-socio-economic/lib/features/socio_economic/src/presentation/socio_economic_page.dart:128): `SocioComparison(_model.a!, _model.b!)`. A valid A/B partial result therefore throws a null assertion instead of rendering B and an unavailable/not-comparable result. This violates the contract's requirement to retain the available side and make comparability explicit ([socio-economic.md:31-32,56-57](../docs/design/features/socio-economic.md); [socio_economic.md:12-17](../docs/knowledge_base/locatemy_product/features/socio_economic.md)).

解除条件：处理 `a == null && b != null` without force-unwrapping (skip comparison or use a nullable comparison result), plus a page test for A failure/B success.

### P1 — The Socio page has no language control in the current route

`SocioEconomicPage` exposes only Refresh in its AppBar at [socio_economic_page.dart:78-94](/home/AC79/Desktop/LocateMY-socio-economic/lib/features/socio_economic/src/presentation/socio_economic_page.dart:78). After the analysis menu pushes this page, its AppBar replaces the menu's language action. The current page consequently has no accessible way to switch language, despite the UI contract requiring a language entry in the signed-in business state and immediate current-page updates ([ui_design_spec.md:240-251](../docs/knowledge_base/locatemy_product/ui_design_spec.md)). The final emulator bilingual check demonstrates both locale renderings, but does not demonstrate switching from the Socio route itself.

解除条件：provide the shared accessible language action on this route (or an equivalent shell action that remains present while pushed) and verify current-page text updates without leaving/reloading the page.

### No additional spec findings

The service uses one public analysis seam, Geo resolved state/district facts, authenticated read-only `read_socio_inputs`, the Cost-owned `CurrentBudgetReader`, three-day public SQLite cache and exact-coordinate offline fallback. The implementation preserves district/state fallback, independent missing metrics, P1–P100 observed curves without zero filling/smoothing, group means/shares and P40/P80 thresholds, latest complete-year personal interpolation with below/above bounds, net-income non-substitution, A/B year/scope/boundary comparability, typed failures, retry and late-result disposal behavior. Budget CRUD/full budget switching remains explicitly future Wave 6 scope and is not counted as a Socio defect.

The implementation intentionally keeps a partial latest curve visible while using the latest complete curve for personal position (`socio_input_rules.dart:108-159,162-205`). It also aligns official readings against years for which the curve/structure requirements are satisfied (`socio_service.dart:230-315`). A future product clarification would be needed before treating the distinct partial-curve versus complete-position years as a defect; the page already exposes the year distinction.

## Standards

No hard documented-standard violations found in the Feature commit. The dependency direction is View → ViewModel → application service → domain/adapter, the production adapter is separate from the service, public declarations are confined to the owning entry points, and §7's explicit Dart constructor/control-flow style is followed. The `ignore_for_file: prefer_initializing_formals` comments explain the intentional explicit initialization required by Development Standard §7.

The main judgement-call smell is a large `_fromData` orchestration method in [socio_service.dart:204-347](/home/AC79/Desktop/LocateMY-socio-economic/lib/features/socio_economic/src/application/socio_service.dart:204), which handles fallback, year alignment, curve selection, structure derivation, and position preparation. This is a maintainability observation, not a release blocker; extracting a domain result assembler could improve navigability without changing the approved seam.

## Development Standard §3 assessment

1. **Production behavior/seam:** Partially met. The normal, offline, retry, cache, permissions, lifecycle and current-income paths are real and evidenced; the A-failure/B-success page crash is a current-responsibility defect.
2. **Acceptance scenarios:** Partially met. The final evidence covers the listed normal/A-B/device cases, but the asymmetric A/B partial failure scenario is not safe and has no page assertion.
3. **Page interaction/accessibility/localization:** Partially met. Device evidence passes bilingual, 200% text, semantics and route flows; the pushed Socio route lacks a current-page language action.
4. **External adapter/engineering gates:** Met by supplied evidence: authenticated live RPC/current-budget path and deny checks, official-source verification, `flutter format --set-exit-if-changed`, `flutter analyze`, 275 passing tests with 11 declared live skips, production/device debug APKs, and secret scans. Evidence is tied to `d192281` and production/device source SHA `ace7b8e21576ef7ca47d596c962c99414b8fa81cf2158cffd6e5f55dbb068596`.

## Completion decision

**Socio module: not yet `Implemented`** — two P1 production blockers above must be resolved and revalidated. This review does not declare Wave 6 or the whole product `Integrated`; complete budget CRUD/switching remains B-owned with A wiring at the stated future Wave 6 joint checkpoint.

**Current blockers:** (1) A-failure/B-success null assertion; (2) no in-route language control. After both fixes, rerun the focused A/B partial-failure and current-route language-switch checks, then repeat the required engineering/device evidence.

