# Prototype-led UI and integration handoff

## Status

Superseded by ADR 0011 — 2026-09-13

The current UI prototype is the visual baseline for normal page states; design documents add only behavior the prototype cannot show, including loading, empty, error, and relevant permission-denied states. A database interface links to a schema source only when it uses a device-local database; Supabase schema changes are centrally controlled by the project manager. All data-facing pages use the shared Async UI State contract (`initial`, `loading`, `data`, `empty`, `error`, plus permission denied where applicable), and a handoff includes the page document, referenced shared-module documents, required local schema source, visual references, and an executable acceptance entry; critical information cannot remain only in chat.
