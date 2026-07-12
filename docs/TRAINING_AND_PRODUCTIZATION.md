# Training and Productization Model

This document defines how WSMS operational work is transformed into reusable training and product assets.

## Goal

Turn real infrastructure operations into:

- training modules,
- implementation playbooks,
- reusable agent prompt templates,
- paid onboarding assets.

## Source Inputs

Use these sources as canonical input:

- `RAPORT-SESJI/` for chronological execution traces.
- `CASE-STUDIES.md` for condensed incident narratives.
- `TROUBLESHOOTING.md` for repeatable repair paths.
- `CHANGELOG.md` for behavior-level delta.

## Required Session Data Schema

Every session report should capture:

- `Context`: environment, target outcome, constraints.
- `Signal`: observed symptom/error and impact.
- `Decision path`: why each action was selected.
- `Execution`: exact commands and ordering.
- `Validation`: how success/failure was verified.
- `Metrics`: TTD (time to diagnosis), TTR (time to recovery), automation ratio.
- `Reusable assets`: what can become checklist/script/prompt block.

## Naming Convention

Session report file:

- `RAPORT-SESJI-YYYY-MM-DD_HH-MM.md`

Daily aggregate file:

- `RAPORT-DZIENNY-YYYY-MM-DD.md`

## Conversion Pipeline (Ops -> Product)

1. Capture session report in `RAPORT-SESJI/`.
2. Extract stable incident pattern into `CASE-STUDIES.md`.
3. Convert fix sequence into `TROUBLESHOOTING.md` playbook.
4. Derive reusable template blocks for training:
   - prerequisites checklist,
   - diagnostics flow,
   - rollback/safety guardrails,
   - verification checklist.
5. Package as product-ready assets (course lesson, implementation SOP, prompt kit).

## Prompt-Template Preparation (for future sales)

When creating a sellable prompt template, structure it into blocks:

- Environment discovery questions.
- Safety and backup guardrails.
- Incident classification tree.
- Action plan with command templates.
- Verification and rollback criteria.
- Reporting output format.

The buyer should answer a short question set, then the agent should generate:

- environment bootstrap steps,
- operational command plan,
- risk-aware checklist,
- documentation artifacts.

## Quality Gate Before Publishing Training Content

- Steps are reproducible on clean test environment.
- Commands are minimal and safe.
- Rollback path exists for each destructive step.
- Success criteria are measurable.
- Material is linked to at least one real case from `CASE-STUDIES.md`.

## Notes

WSMS is part of a wider ecosystem:

- `../Mental_OS/` defines adaptive learning and decision structure.
- `../Media/` supports publication and communication workflows.

Keep this document implementation-focused. Strategic narrative should live in Mental_OS.
