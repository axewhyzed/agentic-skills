# Reliability, Performance & Capacity Engineering Standards

This reference establishes concrete standards for quantitative capacity estimation, performance profiling, latency budgets, and Google SRE reliability principles.

---

## 1. Numbers Every Software Engineer Must Know

### 1.1 Latency Numbers (Order of Magnitude)
| Operation | Latency | Scaled Comparison (1 ns = 1 s) |
| :--- | :--- | :--- |
| **L1 CPU Cache reference** | $0.5\text{ ns}$ | 0.5 seconds |
| **Branch mispredict** | $3\text{ ns}$ | 3 seconds |
| **L2 CPU Cache reference** | $7\text{ ns}$ | 7 seconds |
| **Mutex lock / unlock** | $25\text{ ns}$ | 25 seconds |
| **Main Memory (RAM) reference** | $100\text{ ns}$ | 1.7 minutes |
| **Compress 1KB with Snappy** | $2,000\text{ ns} = 2\,\mu\text{s}$ | 33 minutes |
| **Read 1 MB sequentially from RAM** | $3\,\mu\text{s}$ | 50 minutes |
| **NVMe SSD random read (4KB)** | $10\text{--}50\,\mu\text{s}$ | 2.7 to 13.8 hours |
| **Read 1 MB sequentially from NVMe SSD** | $200\,\mu\text{s}$ | 2.3 days |
| **Same-datacenter Network RTT** | $500\,\mu\text{s} = 0.5\text{ ms}$ | 5.8 days |
| **Disk seek (mechanical HDD)** | $4\text{--}10\text{ ms}$ | 1.5 to 3.8 months |
| **Cross-country Network RTT (e.g. SF to NYC)** | $40\text{ ms}$ | 1.3 years |
| **Trans-oceanic Network RTT (e.g. US to EU/Asia)**| $150\text{ ms}$ | 4.7 years |

---

## 2. Quantitative Capacity Planning (Back-of-the-Envelope)

### 2.1 Standard Rule-of-Thumb Constants
- 1 day $= 86,400\text{ seconds} \approx 10^5\text{ seconds}$ (conservative rounding: $86,400 \to 100,000$).
- Peak-to-Average Traffic Ratio: typically $2\times$ to $5\times$ (default to $3\times$ unless known).
- 1 Million requests/day $\approx \frac{1,000,000}{86,400} \approx 12\text{ RPS}$ (Requests per second).
- 1 Billion requests/day $\approx \frac{1,000,000,000}{86,400} \approx 12,000\text{ RPS}$.

### 2.2 Five-Step Capacity Calculation Framework
1. **Throughput (QPS / RPS)**:
   $$\text{Avg QPS} = \frac{\text{Daily Active Users (DAU)} \times \text{Requests per User per Day}}{86,400}$$
   $$\text{Peak QPS} = \text{Avg QPS} \times \text{Peak Multiplier (e.g., 2.5 - 3.0)}$$
2. **Network Bandwidth (Ingress / Egress)**:
   $$\text{Bandwidth (MB/s)} = \text{QPS} \times \text{Average Payload Size (Bytes)} \div 10^6$$
   $$\text{Bandwidth (Gbps)} = \text{Bandwidth (MB/s)} \times 8 \div 1,000$$
3. **Storage Growth (Disk / Database)**:
   $$\text{Storage per Day} = \text{Writes per Day} \times \text{Row/Record Size}$$
   $$\text{Storage per 3 Years} = \text{Storage per Day} \times 365 \times 3 \times \text{Replication Factor (typically 3)}$$
4. **Cache Memory Requirements (RAM)**:
   - Apply the **80/20 Pareto Principle**: 20% of items generate 80% of read traffic.
   $$\text{Cache RAM} = 0.20 \times (\text{Daily Read Volume} \times \text{Item Size})$$
5. **Connection & Concurrency Bounds (Little's Law)**:
   $$L = \lambda \times W$$
   - Where $L$ is concurrent in-flight requests, $\lambda$ is arrival rate (RPS), and $W$ is average latency (seconds).
   - *Example*: At $1,000\text{ RPS}$ with $200\text{ ms}$ ($0.2\text{ s}$) average response time:
     $$L = 1,000 \times 0.2 = 200\text{ concurrent active connections / worker threads}$$

---

## 3. Site Reliability Engineering (SRE) & Operational Standards

### 3.1 SLI, SLO, SLA Hierarchy
- **SLI (Service Level Indicator)**: A quantifiable metric measured in real-time (e.g., ratio of successful HTTP requests: $\frac{\text{status} < 500}{\text{total}}$).
- **SLO (Service Level Objective)**: Target reliability agreed with engineering and product (e.g., 99.9% successful requests over rolling 30-day window).
- **SLA (Service Level Agreement)**: Legal contract with customers with financial penalties for breach (e.g., 99.5% uptime). Must be looser than SLO!
- **Error Budget**: $100\% - \text{SLO}$. If SLO is 99.9%, the error budget is 0.1% (43 minutes of allowed downtime per month).

### 3.2 High-Availability "Nines" Table
| Availability | Allowed Downtime per Year | Allowed Downtime per Month | Allowed Downtime per Day |
| :--- | :--- | :--- | :--- |
| **99% (Two Nines)** | 3.65 days | 7.3 hours | 14.4 minutes |
| **99.9% (Three Nines)** | 8.76 hours | 43.8 minutes | 1.44 minutes |
| **99.99% (Four Nines)** | 52.6 minutes | 4.38 minutes | 8.64 seconds |
| **99.999% (Five Nines)** | 5.26 minutes | 26.3 seconds | 0.86 seconds |

---

## 4. Performance Profiling & Bottleneck Isolation

1. **CPU Profiling**:
   - Collect CPU samples using flame graphs.
   - Look for wide plateaus (hot paths) and unexpected serialization loops (e.g. JSON parse/stringify, hashing, regex compiling).
2. **I/O Wait vs CPU Saturation**:
   - High CPU with low throughput $\to$ algorithm inefficiency, lock spinning, serialization overhead.
   - Low CPU with low throughput $\to$ waiting on database queries, network calls, thread pool starvation, or disk I/O.
3. **Memory Leaks & GC Pressure**:
   - Increasing baseline heap after repeated Garbage Collection cycles indicates an object retention leak.
   - Common culprits: Event listeners not removed, unbounded caches without LRU/TTL bounds, closures retaining large scopes, static Maps.
