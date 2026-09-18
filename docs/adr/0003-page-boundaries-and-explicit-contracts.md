# Page boundaries and explicit contracts

## Status

Superseded by ADR 0011 — 2026-09-13

Page implementations use **MVVM + Feature-First Architecture**: a feature contains its View in `presentation`, its ViewModel and use-case coordination in `application`, independent business rules in `domain` when needed, and persistence or remote access in `data` when needed. Dependencies flow from View to ViewModel and then to domain or data; domain has no Flutter, page, or Supabase dependency, and data has no widget dependency. Interfaces are typed, explicit contracts that document their callers, inputs, outputs, failure semantics, and side effects; pages communicate only through route parameters, named shared-state commands or subscriptions, or persisted data read afresh, never by directly changing another page's widget or state.
