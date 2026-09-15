# Human-coded, AI-designed delivery process

## Status

Accepted — amended by ADRs 0013, 0015 and 0016

LocateMY uses one Chinese authoritative design organized as a baselined system design and rolling
Feature-first Development Contracts. AI defines the coordination necessary for independently owned
code to work together, and may inspect implementations, but the two students write and modify all
Flutter application and application-test code. ADR 0016 permits AI to establish and secure the
Supabase development environment, including migrations and related configuration. Internal Flutter
code structure and strategy remain with the owning implementer; ADRs 0012 and 0015 define the
coordination boundary and contract-first handoff.

The project owner alone approves `Baselined` and `Integrated`; ADR 0013 delegates owning-contract
`Ready for Development` approval to the design AI. A student implementer may declare assigned work
`Implemented` and may report design problems, but cannot change an approved cross-Feature contract
or data model. A relevant baseline or public Interface change returns affected contracts to `Draft`
until its impact has been reviewed and the Markdown, HTML, declarations and affected tests agree.

This decision supersedes ADRs 0002 through 0010 as the governing design process. ADR 0015 supersedes
its former PDF handoff lifecycle. Their compatible architectural ideas are retained only where the current `docs/design/` standards state
them; the product knowledge base remains authoritative for product facts and university submission
commitments.
