# Page document template and flow notation

## Status

Superseded by ADR 0011 — 2026-09-13

Every page design document uses the same nine sections: Overview, File Manifest, Responsibilities and Non-responsibilities, UI States, Interfaces, Data and Algorithms, Communication Flow, Acceptance Checks, and Change Log; inapplicable sections state `N/A` with a reason. Pages involving more than two external interfaces, writes, or cross-page navigation also include a compact Mermaid sequence diagram or numbered flow showing call order, payload, and failure handling; simple static pages do not require one.
