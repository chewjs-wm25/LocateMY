# Prototype precedence and manual acceptance

## Status

Superseded by ADR 0011 — 2026-09-13

For a normal visual state, the current UI prototype is authoritative; for feature meaning, interface behavior, and non-normal states, the authoritative Chinese page design document prevails. A document records conflicts and prototype follow-up in its Change Log rather than leaving an implementer to choose. Each page has manually executable acceptance steps in precondition–action–expected-result form, with automated test paths and commands added when available. The `core` module owns the shared Async UI State definition, which features reuse without copying or redefining.
