# High-Level System Design & Distributed Systems Standards

This reference details industry standards, fundamental theorems, and battle-tested patterns for high-level system architecture and distributed systems.

---

## 1. Fundamental Theorems & Distributed Trade-offs

### 1.1 CAP & PACELC Theorems
- **CAP Theorem (Brewer)**: In any asynchronous network subject to partitions ($P$):
  - **CP (Consistency + Partition Tolerance)**: When a partition occurs, reject or stall writes to prevent split-brain/stale reads (e.g., Raft, Paxos, Spanner, ZooKeeper, HBase).
  - **AP (Availability + Partition Tolerance)**: When a partition occurs, accept reads/writes locally and reconcile later (e.g., DynamoDB, Cassandra, CouchDB).
  - *Note*: "CA" without P does not exist in distributed systems over real networks.
- **PACELC Theorem (Abadi)**:
  - If there is a **P**artition, how does the system trade off **A**vailability and **C**onsistency?
  - **E**lse (normal execution), how does the system trade off **L**atency and **C**onsistency?
  - *Examples*:
    - **PA/EL**: Dynamo, Cassandra (optimizes for availability and low latency).
    - **PC/EC**: Bigtable, Spanner (optimizes for strong consistency in all regimes).
    - **PA/EC**: MongoDB (replicated sets: write concern compromises).

### 1.2 Consistency Hierarchy
1. **Linearizability (Strict Consistency)**: Single global clock perspective; all operations appear instantaneous at a point in real time.
2. **Sequential Consistency (Lamport)**: All processes observe the same global sequence of operations consistent with program order.
3. **Causal Consistency**: Causally related operations are seen in the same order by all nodes; concurrent operations may be seen in different orders.
4. **Read-Your-Writes (Session Consistency)**: A client always observes its own updates immediately.
5. **Monotonic Reads**: Once a client reads a state, it never reads an older state.
6. **Eventual Consistency**: If no new updates are made, all replicas eventually converge.

### 1.3 Consensus Algorithms
- **Raft**: Leader election, log replication, safety invariants. Used in etcd, Consul, CockroachDB.
- **Paxos**: Classic distributed consensus; foundation of Google Chubby, Spanner.
- **Two-Phase Commit (2PC)**: Blocking atomic commitment across multiple resources. High latency, coordinator is a single point of failure. Avoid across microservices.
- **Three-Phase Commit (3PC)**: Non-blocking under crash failures, but still vulnerable to network partitions.

---

## 2. Distributed Data Management

### 2.1 Partitioning & Sharding
- **Horizontal Sharding**:
  - **Range-Based**: Easy range scans; risk of hotspots on append-heavy workloads (e.g., timestamps).
  - **Hash-Based**: Uniform key distribution; range queries require scatter-gather.
  - **Consistent Hashing**: Virtual nodes (tokens) mapped to a hash ring ($2^{32}-1$ or $2^{64}-1$). Adding or removing a node rebalances only $K/N$ keys, where $K$ is keys and $N$ is nodes.
- **Re-sharding & Live Migration**:
  - Dual-write phase $\to$ Backfill phase $\to$ Verification shadow reads $\to$ Cutover $\to$ Deprecate old storage.

### 2.2 Replication Topologies
- **Single-Leader (Master-Replica)**: All writes go to leader; reads distributed to replicas. Vulnerable to replication lag and stale reads on replicas.
- **Multi-Leader**: Writes accepted across multiple data centers. Requires conflict resolution strategies:
  - Last-Write-Wins (LWW) via NTP/logical clocks (data-loss prone).
  - Conflict-Free Replicated Data Types (CRDTs).
  - Operational Transformation (OT) for collaborative editing.
- **Leaderless (Dynamo-Style)**: Client writes to $W$ replicas, reads from $R$ replicas.
  - Quorum condition: $R + W > N$ guarantees read overlap with latest write.
  - Sloppy Quorum & Hinted Handoff for transient failure recovery.
  - Read Repair and Anti-Entropy via Merkle trees.

### 2.3 Distributed Transactions Across Services
- **The Saga Pattern**:
  - Broken into a sequence of local transactions. Each step updates its local DB and publishes an event.
  - Failure triggers **Compensating Transactions** executed in reverse order.
  - **Orchestration**: Central coordinator drives steps (clear control flow, avoid cyclic dependencies).
  - **Choreography**: Event-driven handoff between services (loose coupling, harder to trace complex flows).
- **Transactional Outbox Pattern**:
  - Write business state and outgoing events in the **same local database transaction** (into an `outbox` table).
  - A separate process (Debezium CDC or Polling Publisher) reads the outbox and publishes to the broker.
  - Eliminates the dual-write anti-pattern!

---

## 3. High-Level Architectural Styles

### 3.1 Modular Monolith vs Microservices
- **Modular Monolith First**:
  - Clear in-process module boundaries, strict dependency inversion, independent packages.
  - Scales development without distributed network failure overhead, deployment complexity, or network latency.
  - Extract to microservices only when independent deployment velocity, heterogeneous tech stacks, or independent resource scaling bounds necessitate it.
- **Service Boundaries (Domain-Driven)**:
  - Bounded Contexts define service perimeters.
  - Avoid "Entity Services" (services that are thin CRUD wrappers around single database tables).
  - High cohesion around business capabilities, loose coupling via versioned APIs and domain events.

### 3.2 Event-Driven Architecture (EDA) & CQRS
- **Event Sourcing**:
  - State is stored as an append-only log of immutable domain events. Current state is reconstructed by replaying events.
  - Built-in audit trail, temporal queries, event replay capabilities.
- **CQRS (Command Query Responsibility Segregation)**:
  - Separate write model (Command: domain rules, consistency, high normalization) from read model (Query: denormalized, read-optimized views, ElasticSearch/Redis).
  - Commands return `202 Accepted` or void; updates project asynchronously to read stores.

---

## 4. Scalability, Caching & Performance

### 4.1 Caching Topologies & Strategies
- **Cache-Aside (Lazy Loading)**: Application reads cache; if miss, reads DB, writes to cache, returns data.
- **Write-Through**: Application writes to cache; cache writes synchronously to DB.
- **Write-Behind (Write-Back)**: Application writes to cache; cache writes asynchronously to DB. High write performance; risk of data loss on crash.
- **Refresh-Ahead**: Cache automatically refreshes items before expiry based on access patterns.

### 4.2 Cache Pathology Mitigation
- **Cache Stampede (Thundering Herd)**:
  - Multiple concurrent requests miss the cache simultaneously and all hammer the database.
  - *Fix*: Distributed lock on miss, probabilistic early expiration (XFetch algorithm), or mutex in application layer.
- **Cache Penetration**:
  - Queries for non-existent keys bypass cache and hit DB every time.
  - *Fix*: Cache null values with short TTL, or use a Bloom filter at the cache boundary.
- **Cache Avalanche**:
  - Large volume of keys expire simultaneously, overwhelming the database.
  - *Fix*: Add random jitter to TTLs ($\text{TTL} = \text{base} \pm \text{random}(0, \delta)$).

---

## 5. Resiliency, Stability & SRE Patterns

- **Circuit Breaker**: Transitions between `CLOSED` $\to$ `OPEN` $\to$ `HALF-OPEN` based on error thresholds over sliding windows.
- **Retry with Exponential Backoff + Full Jitter**:
  $$\text{Sleep} = \text{random}(0, \min(M, B \times 2^{\text{attempt}}))$$
- **Bulkhead Pattern**: Isolate thread pools, connection pools, and memory per dependency so one degraded subsystem cannot starve the entire process.
- **Rate Limiting Algorithms**:
  - Token Bucket (burst-tolerant).
  - Leaky Bucket (smooth rate smoothing).
  - Sliding Window Counter (accurate boundary rate limiting).
- **Idempotency**: Every mutating operation carries a client-generated `Idempotency-Key`. The server checks a deduplication store before executing.
