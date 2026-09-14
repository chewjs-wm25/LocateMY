# High-level design coordinates boundaries, not implementations

> Status: Accepted — 2026-09-14

LocateMY Feature and shared-module designs freeze only the information independently owned code needs to coordinate: user-visible outcomes, module responsibilities, cross-Owner action/result semantics, security and side-effect invariants, controlled file boundaries, acceptance scenarios, and deterministic business-rule application. Internal files, language symbols, state machines, SDK adapters, timing/retry/deduplication strategies, and test organization belong to the owning implementer. Formulae remain non-negotiable product rules, but their full text has one authority in the product knowledge base; design documents record only the formula ID and required application semantics. This replaces the implementation-blueprint interpretation retained by ADR 0011 and the design templates, preserving encapsulation while keeping cross-module behavior verifiable.
