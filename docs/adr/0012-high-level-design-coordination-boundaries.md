# High-level design coordinates boundaries, not implementations

> Status: Accepted — amended by ADR 0015 on 2026-09-15

LocateMY Feature and shared-module designs freeze the information code needs to coordinate: user-visible outcomes, module responsibilities, exact declaration-level public entry points and caller-visible types, cross-Owner result semantics, security and side-effect invariants, acceptance scenarios, and deterministic business-rule application. Internal files and symbols, function or Widget bodies, state machines, SDK adapters, timing/retry/deduplication strategies, and test organization remain implementation choices and may be authored by AI or an Owner. Formulae remain non-negotiable product rules, but their full text has one authority in the product knowledge base; Development Contracts record the inputs, bounds and application semantics that an implementation must satisfy.
