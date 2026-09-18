# AI-enabled delivery process

## Status

Accepted — amended by ADRs 0013, 0015 and 0016

LocateMY uses one Chinese authoritative design organized as a baselined system design and rolling
Feature-first Development Contracts. AI may define coordination, inspect implementations, and write,
modify, test and validate all project code, including Flutter application and application-test code
and Supabase configuration, migrations and access controls. Internal code structure remains subject
to the owning module's contract; ADRs 0012 and 0015 define the coordination boundary and
contract-first handoff.

The project owner alone approves `Baselined` and `Integrated`; ADR 0013 delegates owning-contract
`Ready for Development` approval to the design AI. An implementer may declare assigned work
`Implemented` and may report design problems, but cannot change an approved cross-Feature contract
or data model. A relevant baseline or public Interface change returns affected contracts to `Draft`
until its impact has been reviewed and the Markdown, HTML, declarations and affected tests agree.

This decision supersedes ADRs 0002 through 0010 as the governing design process. ADR 0015 supersedes
its former PDF handoff lifecycle. Their compatible architectural ideas are retained only where the current `docs/design/` standards state
them; the product knowledge base remains authoritative for product facts and university submission
commitments.
