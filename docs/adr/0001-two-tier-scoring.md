# ADR 0001 — Two-tier scoring, ported from the source spreadsheet

**Status:** Accepted
**Date:** 2026-08-02

## Context

Two documents defined this project: a product scope describing a flat six-category score
(Property fit, Lake fit, Location fit, Risk, Financial, Amenities), and the spreadsheet
actually being used to shop for a lake house.

They disagree. The spreadsheet scores in two tiers: a **lake score** built from eight
weighted categories, which then enters a **listing score** as a single input weighted at
0.25 alongside eight property-specific categories.

## Decision

Implement the spreadsheet's two-tier model. The scope document's six categories were a
sketch; the spreadsheet is a validated mental model that has already been used to rank 24
real candidate lakes.

### Tier 1 — Lake score (0–100)

`lakeScore = round(Σ(rating × weight) × 10, 1)`, ratings on 1–10.

| Category | Weight |
|---|---:|
| Swimming & clarity | 0.28 |
| Affordability | 0.20 |
| Pontoon cruising | 0.14 |
| Scenic / Up North feel | 0.12 |
| Family atmosphere | 0.08 |
| Fishing | 0.07 |
| Nearby amenities | 0.06 |
| Drive convenience | 0.05 |

### Tier 2 — Listing score (0–100)

Hard filter first — `price ≤ 400000 AND baths ≥ 2 AND tenure ≠ LEASEHOLD`, plus the
profile's drive-time ceiling. Failures are **excluded with a stated reason**, never
penalized with a low score.

| Category | Weight |
|---|---:|
| Lake fit score (`lakeScore / 10`) | 0.25 |
| Price value | 0.20 |
| Swimming frontage | 0.15 |
| Home condition | 0.12 |
| Frontage quality | 0.08 |
| Bedrooms / layout | 0.06 |
| Septic / well / utilities | 0.06 |
| Access / slope | 0.04 |
| Carrying costs | 0.04 |

Price value is ported verbatim:
`priceValue = max(0, min(10, (targetPrice − price) / priceStep + 5))`, with `targetPrice`
and `priceStep` parameterized onto the preference profile rather than hard-coded.

## Consequences

**Why two tiers rather than one flat score.** Collapsing them loses the distinction
between a great lake with a mediocre house and a great house on a mediocre lake. Those
are different decisions — one is fixable with money, the other is not.

**Every input carries an origin: `DERIVED`, `USER`, or `UNKNOWN`.** Four of the eight lake
categories can be derived from public data (clarity from Secchi and chlorophyll, pontoon
cruising from area and depth, amenities from OSM, drive convenience from routing). The
rest are genuine human judgment. Displaying which is which is what makes the score
legible rather than merely transparent.

**Unknown handling diverges from the spreadsheet, deliberately.** A spreadsheet cell left
blank multiplies to zero and drags the total down, so an under-researched lake scores
*worse* than a researched bad one. LakeScout drops unknown inputs from both numerator and
denominator, renormalizes the remaining weights, and reports coverage. This is a
correctness fix, and it is the one place where the app is intentionally not
bug-compatible with its source.

**The 24 hand-rated lakes become a validation set.** Derived ratings can be checked
against ratings a human already assigned. Where they disagree badly, either the
derivation curve is wrong or the lake deserves a note — both are useful findings.
