# AI-managed Supabase development environment

> Status: Accepted — 2026-09-15

The project owner exempts Supabase environment establishment from LocateMY's human-coded delivery boundary. AI may create, modify, verify and apply project-scoped Supabase CLI configuration, migration files, access hardening and data-import support needed to make the approved database design reproducible and secure; the project owner retains authority over product semantics and irreversible data decisions. The two students still write all Flutter application behavior, application tests and other executable product code.

This exception was chosen because migration-history recovery and urgent platform security hardening are environment work, while reserving them for student authors would prevent the approved Flutter work from starting. It amends ADR 0011's human-coded boundary without changing any Capability, data ownership rule, RLS semantics or the students' responsibility for application implementation.
