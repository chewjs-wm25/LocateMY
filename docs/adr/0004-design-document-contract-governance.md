# Design-document contract governance

## Status

Superseded by ADR 0011 — 2026-09-13

Page design documents live in `docs/design/pages/` and shared-module documents live in `docs/design/modules/`, using kebab-case names. Chinese is the sole authoritative language; after all Chinese documents have been completed and validated, English translations may be delivered to English-speaking collaborators but cannot override them. Shared interfaces have one complete contract in their owning module document and pages refer to it by ID and usage; a shared-file owner controls changes, and contract changes follow add–migrate–remove unless explicitly recorded as breaking with every affected page. Every page document includes concise Chinese explanations alongside unaltered English code identifiers, and has acceptance checks for local behavior, each external interface's success/empty/failure paths, and one adjacent-page end-to-end flow.
