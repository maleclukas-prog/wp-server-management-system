# INTERNAL TEMPLATE (reference only)

This file is safe to keep in public repo.
It defines the structure to use in local-only internal folders ignored by git.

## Recommended local folder

Create one of these locally (not synced):

- `INTERNAL/`
- `INTERNAL_ORG/`
- `PRIVATE/`

## Suggested structure

- `INTERNAL_ORG/00_Strategy/`
- `INTERNAL_ORG/01_Product_Market_Fit/`
- `INTERNAL_ORG/02_Client_Onboarding/`
- `INTERNAL_ORG/03_Pricing_and_Offers/`
- `INTERNAL_ORG/04_Sensitive_Infra_Notes/`
- `INTERNAL_ORG/05_Internal_Retrospectives/`

## Rules

- Never store secrets in tracked files.
- Keep customer-specific sensitive notes only in ignored local folders.
- If a note becomes public-safe, move a sanitized version to regular docs.
