# Roadmap and deferred scope

Everything below was considered for v1 and deliberately left out. The reasoning matters
more than the list: each item is deferred for a stated reason, not forgotten.

## Deferred from v1

| Deferred | Rationale |
|---|---|
| AI-generated property assessments | Scoring must be defensible on its own first. AI is additive, not foundational — an assessment grounded in a score nobody trusts is worse than no assessment. |
| Python intelligence service | No workload in v1 justifies a second runtime. |
| AI code-review platform | A separate product. Shares only the scheduler. |
| Notifications and alerting | Requires a stable definition of "new match," which requires a listing feed we do not have. |
| Property comparison view | Valuable but not on the critical path. First stretch item. |
| MLS / licensed listing feeds | Cost and access barriers. The intake path is shaped so a provider abstraction can be introduced later without reshaping `Property`. |
| Multi-user accounts, sharing, collaboration | No user need at portfolio scale. |
| Price history and market trend analysis | Requires longitudinal data v1 does not collect. |
| Short-term-rental restriction lookup | No consistent public dataset; it is municipality-by-municipality research. |

## Deferred from the source spreadsheet

The spreadsheet this replaces has structure beyond what v1 implements.

| Deferred | Rationale |
|---|---|
| Research Notes sub-table per property | The spreadsheet tracks per-topic research items with `Confirmed` / `To Research` / `Rule` statuses (septic permits, rental rules, insurance quotes, ownership tenure). v1 ships only `status` and `next_action` on a property. The full checklist is real value but is workflow, not scoring, and would crowd out the enrichment pipeline. |
| `Est. Immediate Work` cost modelling | Captured as free text in v1, not as a number feeding the Carrying costs or Price value categories. Turning repair estimates into score inputs needs a cost model that does not exist yet. |
| Dashboard KPI panel | The list view carries pipeline counts. A separate dashboard adds a surface without adding information. |
| Market-search links per lake | Seeded from the scorecard and displayed, but not crawled. Scraping listing aggregators would violate their terms; see Principle 4. |

## Stretch items in v1

Built only if hours remain after the required feature set.

- **F9 — Access control.** Standards-based OAuth 2.0 / OIDC sign-in distinguishing buyer, administrator and read-only demo visitor. A `CurrentUser` abstraction and a mutation guard ship from week 1 seeded with a fixed demo identity, so wiring a real identity provider later touches one class rather than every controller. If this slips, v1 ships as a read-only public demo with mutation disabled — a working demo without authentication beats authentication in front of nothing.
- **F10 — Property comparison.** Side-by-side comparison of 2–4 properties across all score categories.

## Beyond v1

In rough priority order, each contingent on v1 being tagged and deployed.

1. Property comparison view
2. AI-generated property assessment — structured, grounded strictly in enriched data, with unknowns preserved
3. Saved searches and match notifications
4. Listing-provider interface with a licensed or officially supported feed
5. Price history and market context
6. Internet-availability enrichment — currently an input to the Risk category that permanently reads `UNKNOWN`, because no public dataset covers it at parcel resolution without a licensed feed
