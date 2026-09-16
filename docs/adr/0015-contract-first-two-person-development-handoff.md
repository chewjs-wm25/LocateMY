# Contract-first two-person development handoff

> Status: Accepted — 2026-09-15

LocateMY uses each owning Feature or shared-module Markdown as its sole Development Contract. The contract fixes the exact declaration-level public entry point and caller-visible Dart types, results, failures, lifecycle, permissions and joint scenarios needed by the other Owner; private implementation remains with the owning module and may be authored by AI or an Owner. A same-basename HTML file is a semantically equivalent human-readable export, while Git and reviewed PRs provide history. This replaces versioned PDF packages, manifests, checksums, Generation Gates, Development Releases and artifact invalidation because their audit cost outweighed their value for a two-student project.

This ADR supersedes ADR 0014. Function bodies, Widget implementations, private helpers, SDK mappings and test implementations may be produced by AI or an Owner, while still complying with the owning contract and the repository's security rules. Providers merge the public declaration seam first; providers test real adapters, consumers use fakes at that seam, and cross-module flow tests remain consequential. Public Interface changes require the provider to explain impact, every affected consumer to confirm, and one PR to update declarations, the Development Contract, its HTML export and affected tests.
