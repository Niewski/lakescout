# LakeScout

**LakeScout evaluates lake vacation properties against the criteria that listings don't cover.**

A listing tells you price, bedrooms and square footage. It does not tell you whether the lake is a 40-acre weedy pond or 900 acres you can actually run a pontoon on, whether the parcel sits in a FEMA flood zone, whether there's a public boat launch within a reasonable drive, or how clear the water actually is. That information exists in public datasets, scattered across half a dozen agencies. Nobody assembles it per-property.

> **You bring the listings. LakeScout tells you what the listings leave out.**

## Status

Week 1 of 8. Scaffolding complete: Spring Boot 4.1 / Java 21 backend, React 19 / Vite frontend, PostGIS via Docker Compose, Flyway migrations, CI.

## Why this exists

LakeScout replaces a working spreadsheet. The spreadsheet does a lot right — a weighted two-tier model, explicit hard filters, honest research notes — and its scoring model is ported here verbatim. Four things it cannot do:

1. **Water clarity stops being homework.** The spreadsheet's research notes list *"collect recent Secchi depth and trophic-status records"* as **To Research** for every candidate. Michigan EGLE publishes Secchi depth, chlorophyll, CDOM and bathymetry for 6,524 inland lakes. LakeScout reads it automatically and feeds it into the highest-weighted category (Swimming & clarity, 0.28).

2. **Unknowns stop silently scoring zero.** A spreadsheet's `Σ(rating × weight)` treats an empty cell as `0`, so an under-researched lake gets *punished* rather than *flagged*. LakeScout drops unknown inputs from both numerator and denominator, renormalizes the remaining weights, and reports coverage alongside every score.

3. **Lake identity becomes spatial.** Michigan has **23 lakes named "Bear Lake."** Bear Lake in Manistee County is 1,875 acres with 3.91 m of clarity. Bear Lake in Kalkaska County is 44 acres with 0.21 m of clarity and a chlorophyll reading of 98. A name can't tell them apart; a spatial join can.

4. **Flood zone, drive time and boat access get computed.** All three are eyeballed or unresearched today.

## Principles

1. **Unknown stays unknown.** A missing data point is displayed as missing — never estimated, filled in, or silently defaulted into the score.
2. **Every enriched value carries provenance.** Source name, retrieval timestamp and confidence travel with the data and are visible in the UI.
3. **The score is legible.** Every factor, its weight, its input value, its origin (`DERIVED` / `USER` / `UNKNOWN`) and its contribution are visible. No opaque ranking.
4. **Data acquisition is legitimate.** Public and open datasets plus user-supplied information only.

## Data sources

All open/public. Every endpoint below was verified before being written into the design.

| Purpose | Source |
|---|---|
| Lake reference: clarity, depth, area | [Michigan EGLE — Inland Lakes Water Clarity](https://services1.arcgis.com/FNjlrOFR0aGJ71Tg/arcgis/rest/services/Michigan_Inland_Lakes_Water_Clarity/FeatureServer/0) |
| Public boat launches | [Michigan DNR — Public Boating Access Sites](https://services3.arcgis.com/Jdnp1TjADvSDxMAX/arcgis/rest/services/dnrParksAndRecreation/FeatureServer/1) |
| Flood hazard zones | [FEMA National Flood Hazard Layer](https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28) |
| Nearby amenities | [OpenStreetMap via Overpass](https://overpass-api.de/) (ODbL) |
| Drive time | [OSRM](https://router.project-osrm.org/) |
| Geocoding | [US Census Geocoder](https://geocoding.geo.census.gov/) |
| Basemap tiles | [OpenFreeMap](https://openfreemap.org/) |

Coverage region: the northern half of Michigan's Lower Peninsula — roughly 995 lakes of 25 acres or more.

## Architecture

```
frontend/   React 19 + TypeScript + Vite + MapLibre GL, built into the backend jar
backend/    Spring Boot 4.1 / Java 21
            ├── property/     intake, CSV import, pipeline status
            ├── lake/         seeded reference data
            ├── linkage/      spatial nearest-lake, shoreline distance
            ├── enrichment/   async handlers, one per data source
            ├── preference/   profile, hard filters, both weight vectors
            ├── scoring/      two-tier scoring engine (pure, no DB access)
            ├── jobs/         queue: atomic claim, leases, backoff, dead-letter
            ├── geo/          geocoding client, PostGIS helpers
            └── security/     role seam
seed/       Node scripts: ArcGIS + spreadsheet -> seed SQL
infra/      Terraform: EC2, Elastic IP, SSM, budget alarm
```

**PostgreSQL + PostGIS** is the only datastore. It holds the domain, the spatial indexes, *and* the job queue.

**The job queue is hand-built on `SELECT … FOR UPDATE SKIP LOCKED`** with an execution lease, exponential backoff, dead-lettering and manual replay. A single claim statement handles both atomic multi-worker claiming and recovery from a worker that died mid-job — no reaper process, no second piece of infrastructure. See [ADR 0002](docs/adr/0002-postgres-job-queue.md).

**Scoring is two-tier** — a lake score feeds the listing score as one weighted input. See [ADR 0001](docs/adr/0001-two-tier-scoring.md).

## Running locally

Requires Java 21, Node 24 and Docker.

```bash
docker compose up -d
```

```bash
cd backend && ./mvnw spring-boot:run
```

```bash
cd frontend && npm install && npm run dev
```

The frontend dev server proxies `/api` to the backend on port 8080.

Run the backend test suite (spins up a PostGIS container via Testcontainers):

```bash
cd backend && ./mvnw verify
```

## Scope

What v1 deliberately is *not*, and why, is recorded in [docs/roadmap.md](docs/roadmap.md).

## Demo data disclaimer

The seeded demonstration properties are **fabricated illustrations, not real listings**. They sit at real coordinates on real lakes so the enrichment pipeline operates on genuine geography, but their prices, bedroom counts and conditions are invented. Nothing in this repository should be read as market data or as a property valuation.

Lake scores are a screening model, not a water-quality certification or a real-estate appraisal.
