# ADR 0002 — Enrichment queue built on Postgres, not a message broker

**Status:** Accepted
**Date:** 2026-08-02

## Context

Enrichment runs asynchronously, one job per property per data source. The pipeline must
demonstrate, live: atomic claiming across concurrent workers, execution leases, retry
with backoff, dead-lettering, manual replay, and automatic recovery when a worker dies
mid-job.

The obvious alternatives were SQS with a dead-letter queue, or a Redis-backed library.

## Decision

Build the queue in PostgreSQL using `SELECT … FOR UPDATE SKIP LOCKED` with a lease
column.

```sql
UPDATE job SET
  status           = 'RUNNING',
  lease_owner      = :workerId,
  lease_expires_at = now() + :leaseDuration,
  attempt_count    = attempt_count + 1
WHERE id IN (
  SELECT id FROM job
  WHERE (status = 'PENDING' AND available_at <= now())
     OR (status = 'RUNNING' AND lease_expires_at < now())   -- reclaim a dead worker's job
  ORDER BY available_at
  FOR UPDATE SKIP LOCKED
  LIMIT :batchSize
)
RETURNING *;
```

## Consequences

**One statement gives atomic claim and crash recovery.** `SKIP LOCKED` lets concurrent
workers claim disjoint rows with no distributed lock. The second `WHERE` branch means a
worker killed mid-job needs no reaper process or timeout sweeper — the next poll simply
reclaims the expired lease.

**The mechanics stay visible.** SQS would provide visibility timeouts and dead-letter
queues natively, but it would hide exactly the behaviour this project sets out to
demonstrate. A managed queue is the right production answer and the wrong answer here.

**No second datastore.** Nothing to provision, pay for, or keep running alongside the
database. Job history, attempt counts, worker identity and error detail live in the same
transaction as the enrichment result they describe, so the operations view is a plain
query rather than a reconciliation between two systems.

**At-least-once delivery, so every handler must be idempotent.** Enrichment writes use
`INSERT … ON CONFLICT (property_id, source_key) DO UPDATE`. A job that runs twice
produces one row.

**Polling, not push.** A poll loop trades a little latency for a great deal of
simplicity. Enrichment latency is dominated by third-party API calls measured in seconds,
so the poll interval is not the bottleneck.

**This does not scale to high throughput, and does not need to.** The load is a few
hundred properties times four sources. If throughput ever mattered, the handler interface
and job table would survive a move to a real broker; the claim query would not.
