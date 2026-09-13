# Design index, component catalog, and data safety

## Status

Superseded by ADR 0011 — 2026-09-13

`docs/design/README.md` is the Design Index: every navigable route is listed with its document, status, owner, dependencies, interfaces, and prototype reference, or is explicitly marked Out of scope. Stateless presentational components do not require module design documents; a small component catalog is sufficient unless a component owns state, business rules, data access, or a cross-page interface. Design documents may contain Supabase schema, query, RPC, RLS, and sanitized examples, but never credentials, service-role keys, real user data, or identifiable test data.
