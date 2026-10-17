# API Design & Data Persistence Standards

This reference establishes standards for external and internal API contracts, database modeling, indexing strategies, and asynchronous messaging topologies.

---

## 1. API Design Standards

### 1.1 RESTful API Guidelines
- **HTTP Methods & Semantics**:
  - `GET`: Safe, idempotent, cacheable. Never mutates server state.
  - `POST`: Non-idempotent. Creates new resources or processes commands.
  - `PUT`: Idempotent. Replaces the target resource state in its entirety.
  - `PATCH`: Non-idempotent (or idempotent if using RFC 6902 / 7396). Partial resource updates.
  - `DELETE`: Idempotent. Removes the target resource.
- **Status Codes**:
  - `200 OK`: Successful read or update with body returned.
  - `201 Created`: Successful creation; MUST include `Location` header to new URI.
  - `202 Accepted`: Request accepted for asynchronous processing.
  - `204 No Content`: Successful mutation returning no payload (e.g. `DELETE`).
  - `400 Bad Request`: Malformed syntax, invalid parameters.
  - `401 Unauthorized`: Authentication missing or invalid.
  - `403 Forbidden`: Authenticated, but lacks required permissions.
  - `404 Not Found`: Target resource does not exist.
  - `409 Conflict`: Business invariant collision (e.g. duplicate key, state transition conflict).
  - `422 Unprocessable Entity`: Syntactically valid JSON/payload that fails semantic validation rules.
  - `429 Too Many Requests`: Rate limit exceeded. Include `Retry-After` header.
  - `500 Internal Server Error`: Unexpected unhandled runtime error.
  - `502 / 503 / 504`: Bad Gateway, Service Unavailable, Gateway Timeout.
- **Error Payloads (RFC 7807 - Problem Details)**:
  Standardize on RFC 7807 for all HTTP APIs:
  ```json
  {
    "type": "https://api.example.com/errors/insufficient-balance",
    "title": "Insufficient Balance",
    "status": 409,
    "detail": "Account 9871 has a balance of $12.50, but transfer requires $50.00.",
    "instance": "/accounts/9871/transfers/87214",
    "invalidParams": [
      { "name": "amount", "reason": "exceeds available balance" }
    ]
  }
  ```

### 1.2 Pagination Strategies: Offset vs Keyset (Cursor)
| Feature | Offset / Limit (`?page=2&pageSize=20`) | Keyset / Cursor (`?after=cursor_token&limit=20`) |
| :--- | :--- | :--- |
| **Complexity** | Simple; supports direct jump to page $N$. | Requires deterministic ordering on indexed columns. |
| **Performance** | $O(N)$ degradation. Reading page 10,000 scans 200,000 rows before discarding. | $O(1)$ constant time lookup via B-Tree index scan. |
| **Consistency** | Drift / duplicate rows if items are inserted or deleted between page views. | Stable against insertions/deletions during traversal. |
| **Rule** | Acceptable only for small datasets ($< 1,000$ rows) or internal admin dashboards. | **Mandatory** for infinite scrolling, public APIs, and high-volume tables. |

### 1.3 gRPC & Protocol Buffers Standards
- **Backward & Forward Compatibility Rules**:
  1. **Never change existing field numbers (tags)**. Field numbers are the wire identity.
  2. **Never change field types** (unless compatible according to Protobuf specification).
  3. When deprecating a field, mark it `reserved <number>, "<name>"`; never reuse deleted tags or names.
  4. Always treat new fields as optional in client/server code.
  5. Use `enums` with an explicit zero-value default (e.g., `STATUS_UNSPECIFIED = 0`).

---

## 2. Database Modeling & Indexing Standards

### 2.1 Relational Database Indexing
- **The B-Tree Composite Index Rule (E-R-S)**:
  When designing multi-column indexes for a query, order columns as:
  $$\text{Index Order} = [\text{Equality Columns}] \to [\text{Range Columns}] \to [\text{Sort / Order By Columns}]$$
  *Example*: `WHERE org_id = 5 AND status = 'ACTIVE' AND created_at >= '2026-01-01' ORDER BY created_at DESC`:
  - Index: `(org_id, status, created_at)`.
- **Covering Index (Index-Only Scan)**:
  - An index containing all columns requested by the `SELECT` query (via keys or Postgres `INCLUDE` clause).
  - Eliminates the expensive heap lookup (table page access) entirely!
- **Partial Indexes**:
  - Index only rows matching a specific predicate:
    `CREATE INDEX idx_pending_jobs ON jobs (created_at) WHERE status = 'PENDING';`
  - Dramatically smaller index size and lightning-fast queries for hot working sets.
- **The N+1 Query Problem**:
  - Selecting $N$ records and then executing a separate SQL query for each record to fetch associated children.
  - *Fix*: Eager load with batch `IN (...)` queries, subquery joins, or ORM dataloaders.

### 2.2 Concurrency & Locking Strategies
- **Optimistic Locking**:
  - Add a `version` integer or timestamp column to the row.
  - Update: `UPDATE orders SET status = 'PAID', version = version + 1 WHERE id = 10 AND version = 2;`
  - If rows affected is 0, conflict detected $\to$ retry or abort. Ideal for low-contention workloads.
- **Pessimistic Locking**:
  - `SELECT ... FOR UPDATE` acquires row-level locks on read.
  - Blocks other concurrent transactions until commit/rollback. Use with care to prevent deadlocks.
- **Isolation Levels**:
  - `Read Committed`: Prevents dirty reads. Vulnerable to non-repeatable reads and phantom reads.
  - `Repeatable Read` / `Snapshot Isolation`: Transaction sees a consistent snapshot of the database at start time.
  - `Serializable`: Strongest isolation; eliminates anomalies (including write skew) via SSI or 2PL.

---

## 3. Asynchronous Messaging & Event Streams

### 3.1 Message Delivery Semantics
- **At-Most-Once**: Message sent once without retry; loss possible, zero duplicates.
- **At-Least-Once**: Message retried on transient failure; zero loss, duplicates possible.
- **Effectively-Once**: At-least-once delivery + **Consumer Idempotency**.

### 3.2 Consumer Best Practices & Failure Handling
- **Idempotent Consumers**:
  - Every message carries a unique `message_id` or `event_id`.
  - Consumer wraps processing and idempotency recording in a single transaction:
    `INSERT INTO processed_events (event_id, processed_at) VALUES (?, NOW()) ON CONFLICT DO NOTHING;`
- **Dead Letter Queue (DLQ)**:
  - Messages that fail processing after max retries are moved to a DLQ for offline analysis and replay.
- **Poison Pill Handling**:
  - Malformed payloads that will permanently crash the consumer must be routed to DLQ immediately without blocking the partition.
