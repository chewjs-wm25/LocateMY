# Feature-first implementation design standard

## Status

Accepted — 2026-09-13

## Decision

Implementation design is organized around a deliverable **Feature**, not a navigable page. `docs/design/` is the sole authoritative location for Chinese implementation design:

```text
docs/design/
  README.md
  features/<feature>.md
  modules/<shared-module>.md
  data/schema-catalog.md
```

A Feature document is a complete vertical-slice specification. It describes all applicable UI, MVVM responsibilities, business rules, data access, interfaces, calculations, flows, files, and verification required to deliver one independently testable user capability. A Feature may contain several pages. A shared-module document exists only when a cross-Feature module owns state, business rules, data access, or a public interface.

New Feature documents record their Prototype visual references and any unresolved product or implementation differences.

## Implementation architecture

Each Feature uses Feature-First + MVVM. Create only layers that have a real responsibility:

```text
lib/features/<feature>/
  presentation/  # View, routes, and presentational widgets
  application/   # ViewModel, immutable UI state, Facade/use-case coordination
  domain/         # entities, value objects, pure rules, Repository contracts
  data/           # DTOs and Supabase, SQLite, or Storage Adapter implementations
```

`lib/core/` contains shared technical primitives such as `AsyncResult`, and `lib/app/` is the composition root. The composition root constructs adapters, repositories, facades, and ViewModels and passes dependencies through constructors. A Widget, ViewModel, domain rule, or Adapter does not locate its own global dependency.

Dependencies flow from `presentation` to `application` to `domain`. `data` implements contracts owned by `domain` and has no Widget dependency. Domain code has no Flutter, page, or Supabase dependency. A Feature never imports another Feature's internal ViewModel, Widget, Adapter, DTO, or local store.

Use `ChangeNotifier`, immutable UI state, and `ListenableBuilder` for the initial state mechanism. Any replacement requires its own ADR.

## Interface standard

Each Feature exposes only the small `FeatureFacade` or application Use Case interfaces needed by other Features. Cross-Feature UI interaction uses a registered Facade/Use Case, typed route parameters and results, or data read afresh from persistence. It never changes another page's widget or ViewModel.

Every exposed or consumed Interface has a globally searchable `<OWNER>-<NNN>` ID and a complete contract in its owner document. The contract shows its Dart-style signature, callers, parameters, return type, normal and failure semantics, authorization, asynchronous behavior, and side effects. Its input and output types are domain entities, value objects, input objects, or `AsyncResult`; they never expose database rows, `Map` values, DTOs, or Storage path construction.

All expected data operations use the shared result contract:

```dart
sealed class AsyncResult<T> {
  const AsyncResult();
}

final class Success<T> extends AsyncResult<T> {
  // data, source, fetchedAt, dataDate
}

final class Empty<T> extends AsyncResult<T> {
  // reason
}

final class Failure<T> extends AsyncResult<T> {
  // code, message, retryable, cause
}
```

Loading is ViewModel UI state, not an `AsyncResult` variant. Permission denial is `FailureCode.permissionDenied`. A usable offline cache is `Success` and carries enough source and date metadata for the View to disclose it.

## Data-design standard

`docs/design/data/schema-catalog.md` is the readable directory of every Supabase table, View, RPC, Storage bucket, and SQLite table. It states object status (`proposed`, `implemented`, or `deprecated`), physical name, owner, authority/source, fields and types, keys, RLS/access policy, indexes, migration source, and consuming Features.

The executable source of truth for Supabase DDL, RLS, and indexes is `supabase/migrations/<timestamp>_<name>.sql`; the catalog links to it. The SQLite catalog entry links to the implementation migration source. A Feature's Data Access Matrix lists the exact objects, fields, operation, filters, write/cache effect, and account or offline boundary it uses. It links to the catalog instead of duplicating an object's full definition.

Government mirror tables are read by Flutter only through a stable read-only View or RPC. Project-owned Supabase tables define account isolation and RLS. SQLite entries define account partitioning plus cache TTL or queue retry semantics. Storage entries define object-path shape and access policy.

## Readiness and verification

A Feature stays `Draft` until every interface has a complete contract, every data object is cataloged or explicitly `proposed`, all business rules and formulae are reproducible, UI non-normal states are specified, and its File Manifest has no unowned responsibility. Only then may it become `Ready for Development`.

Every public Interface has a contract-test matrix covering success, empty, retryable failure, and non-retryable failure, plus permission denial and offline cache when applicable. Each Feature specifies ViewModel state tests and at least one cross-Feature acceptance flow. Documents state executable scenarios and expected results; they do not invent commands that do not yet exist.

Formula-bearing Features provide inputs, sources, units, formula or pseudocode, normalization, missing-data handling, version, and a worked verification example. Product knowledge-base formula documents remain the authority for product facts; the Feature document links to them and states the implementation-ready application of those facts.

## Consequences

Implementers receive one coherent vertical-slice specification instead of reconstructing contracts and data paths from page documents. Schema details remain single-sourced, while every Feature still states precisely what it reads and writes.

This decision supersedes the following parts of prior ADRs: the page as the primary design unit in 0002 and 0006; the `docs/design/pages/` location in 0004; and any conflicting page-only wording in 0005, 0007, 0008, and 0009. Their still-compatible requirements—Chinese authority, prototype references, acceptance checks, data safety, and explicit contracts—remain in force through this standard.
