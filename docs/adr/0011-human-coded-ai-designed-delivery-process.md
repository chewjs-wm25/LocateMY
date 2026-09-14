# Human-coded, AI-designed delivery process

## Status

Accepted — 2026-09-13

LocateMY uses one Chinese authoritative design organized as a baselined system design and rolling
Feature-first high-level designs. AI defines the coordination necessary for independently owned
code to work together, and may inspect implementations, but the two students write and modify all
compilable application, migration and test code. Internal code structure and strategy remain with
the owning implementer; ADR 0012 defines the coordination boundary. Human work packages are
version-locked projections of the authoritative design rather than a second maintained specification.

The project owner alone approves `Baselined`, `Ready for Development`, and `Integrated`. A student
implementer may declare assigned work `Implemented` and may report design problems, but cannot
change an approved cross-Feature contract or data model. Detailed Feature design proceeds one
dependency wave ahead of human implementation; a relevant baseline change invalidates affected
work packages and returns affected ready designs to `Draft` until their impact has been reviewed.

This decision supersedes ADRs 0002 through 0010 as the governing design and handoff process. Their
compatible architectural ideas are retained only where the current `docs/design/` standards state
them; the product knowledge base remains authoritative for product facts and university submission
commitments.
