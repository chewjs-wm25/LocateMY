# Autonomous design-AI Ready approval

> Status: Accepted — 2026-09-14

## Decision

The project owner has delegated approval of `Ready for Development` to the design AI for the
remaining owning-design GitHub Issues. For each Issue, the design AI must complete the specified
authoritative design work, perform an independent review, resolve or explicitly record every
finding, and then record its own approval before closing the Issue.

The delegation applies only to the rolling owning-design Ready gate. The project owner remains the
sole authority for product and architecture decisions, system `Baselined`, human implementer
assignment, design changes that alter an approved contract or data model, human work packages, and
`Integrated` acceptance. When an Issue exposes one of those decisions, the AI stops that Issue and
asks the project owner rather than inventing an answer.

## Rationale

The remaining work is a dependency-ordered set of design tickets whose acceptance criteria already
require an independent review. Delegating their Ready approval lets the AI carry the sequence to
completion while preserving human authority at the irreversible product, architecture and
integration boundaries.

## Consequences

- A completed design records `设计 AI（项目负责人授权）` as its Ready approver and links this ADR.
- A GitHub Issue closes only after the design and its independent review are complete.
- ADR 0011 is superseded only where it says the project owner alone approves `Ready for
  Development`; all of its human-coded boundary remains in force.
