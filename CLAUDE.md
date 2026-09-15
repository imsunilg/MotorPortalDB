# CLAUDE.md — MotorPortalDB

This repo is part of the 4-repo Motor Portal system (MotorPortalAPI,
MotorPortalWEB, MotorPortalDB, MotorPortalDOC).

- Build the real, working system — no stubs, no placeholder logic, no
  "TODO: implement later".
- Keep going until it compiles and runs. Fix your own errors without
  asking for permission to proceed.
- Never end a turn with uncommitted changes. Stage, commit with a
  Conventional Commit message, and push to origin main before stopping.
  Commit in small logical chunks, not one mega-commit.
- Update README.md after every phase of work: what changed, how to
  run/test it, and the progress checklist.
- Do not rename the 15 core entities, the product/process lists, the
  batch status lifecycle values, or the agreed folder structure — other
  repos and prompts assume these exact names.

## This repo

PostgreSQL 15+ schema `motorportal` in database `motorportal`. SQL-first
(not an ORM migration tool) — this is the source of truth for structure,
constraints, and the business rules that must never be bypassed (batch
size cap, lifecycle ordering, CD-balance arithmetic). MotorPortalAPI maps
to this schema database-first.
