# 🐘 Materialized Views in PostgreSQL — The Ultimate Practical Guide (With Real SQL Examples)

**Author:** Rasifrazak  
**Reading Time:** 6 min

---

If you've ever faced slow reports, heavy JOINs, or aggregation queries killing your database, this article is for you.

By the end of this post, you'll clearly understand:

- What a Materialized View really is
- How it's different from a normal View
- When to use it (and when NOT to)
- How to create, refresh, and optimize it
- Real-world use cases you can apply immediately

All examples use PostgreSQL and can be executed directly in pgAdmin.

---

## 🧠 The Core Problem (Why This Exists)

Imagine this query:

```sql
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;
```

- Works fine with 1k records
- Becomes painfully slow with millions
- Runs again and again for dashboards & reports

👉 This is where Materialized Views become a game-changer.

---

## 🔍 What Is a Normal View?

A View is just a stored SQL query.

```sql
CREATE VIEW user_order_summary AS
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;
```

### How it works:
- No data is stored
- Query runs every time
- Always shows latest data
- Performance = underlying query performance

Think of it as a saved SELECT statement.

---

## 💥 What Is a Materialized View?

A Materialized View:
- ✅ Executes the query once
- ✅ Stores the result on disk
- ✅ Acts like a table
- ❌ Does NOT auto-update

```sql
CREATE MATERIALIZED VIEW user_order_summary_mv AS
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;
```

Now when you run:

```sql
SELECT * FROM user_order_summary_mv;
```

⚡ It's blazing fast.

---

## 🔁 Refreshing a Materialized View

Because data is stored, it must be refreshed manually.

```sql
REFRESH MATERIALIZED VIEW user_order_summary_mv;
```

### Non-blocking refresh (important in production):

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY user_order_summary_mv;
```

⚠️ Requires a unique index:

```sql
CREATE UNIQUE INDEX idx_user_order_mv
ON user_order_summary_mv (id);
```

---

## 🧪 Hands-On Demo: Views vs Materialized Views (With pgAdmin Screenshots)

Theory is important — but seeing performance differences live is what makes Materialized Views click.

In this section, we'll walk through real SQL execution in pgAdmin and visually prove why Materialized Views exist.

### 🔹 Step 1: Creating Sample Tables

We start with creating two tables:
- users
- orders

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    amount NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 🔹 Step 2: Inserting Sample Data

We start inserting sample data to two tables:
- users → 500,000 records
- orders → 300,000 records

```sql
-- Insert to user table
INSERT INTO users (name, email)
SELECT
    'User ' || generate_series,
    'user' || generate_series || '@example.com'
FROM generate_series(1, 500000);

-- Insert to order table
INSERT INTO orders (user_id, amount)
SELECT
    (random() * 499999 + 1)::INT,
    round((random() * 1000)::numeric, 2)
FROM generate_series(1, 300000);
```

### 🔹 Step 3: Running a Heavy Aggregation Query

We execute a query with:
- JOINs
- COUNT
- SUM
- GROUP BY
- EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;
```

**Result:** pgAdmin Query Tool showing high execution time

💡 This represents what dashboards and reports usually do — and why databases slow down under load.

### 🔹 Step 4: Using a Normal View (No Performance Gain)

We now create a regular View and query it.

```sql
CREATE VIEW user_order_summary_view AS
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;
```

```sql
EXPLAIN ANALYZE
SELECT * FROM user_order_summary_view;
```

**Result:** Querying the View with nearly identical execution time

📌 A View does NOT store data — it simply re-runs the original query every time.

### 🔹 Step 5: Creating a Materialized View (⚡ Performance Boost)

Now we create a Materialized View, which executes the query once and stores the result.

```sql
CREATE MATERIALIZED VIEW user_order_summary_mv AS
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;
```

```sql
EXPLAIN ANALYZE
SELECT * FROM user_order_summary_mv;
```

**Result:** Execution time reduced from seconds to milliseconds

This is where the mindset shift happens.

### 🔹 Step 6: ⚡Lightning Speed with Indexing

We create the index and query the Materialized View again.

```sql
CREATE UNIQUE INDEX idx_user_order_mv_id
ON user_order_summary_mv (id);

EXPLAIN ANALYZE
SELECT * FROM user_order_summary_mv;
```

**Result:** Again the execution time reduces by half 💥

### 🔹 Step 7: Proving Data Is NOT Auto-Updated

We insert a new order and query the Materialized View again.

```sql
INSERT INTO orders (user_id, amount)
VALUES (497034, 9999.99);

SELECT * FROM user_order_summary_mv WHERE id = 497034;
```

**Result:** Still fetching the old data (before refresh)

Then we refresh:

```sql
REFRESH MATERIALIZED VIEW user_order_summary_mv;
```

**Result:** Updated data after refresh

📌 This visually explains why freshness is a trade-off.

> "Same query. Same data. Different architecture."

---

## 🧠 What This Demo Proves

- Views are about abstraction
- Materialized Views are about performance
- Materialized Views trade freshness for speed
- Real systems use them for dashboards, analytics, and reporting

---

## 📊 Real-World Use Cases (Very Practical)

### Dashboards & Admin Panels
- Daily sales
- Monthly revenue
- User activity summaries

### BI & Reporting
- KPI calculations
- Analytics queries
- Historical aggregates

### Read-Heavy Systems
- SaaS admin dashboards
- Management reports
- Export systems

---

## 🚫 When NOT to Use Materialized Views

❌ Real-time data required  
❌ Frequent writes/updates  
❌ Highly volatile datasets

### Example bad fit:
- Frequently updating queries
- Live chat messages
- Real-time stock prices
- Payment transaction status

---

## 🧠 Smart Design Pattern (Used in Large Systems)

**Architecture Tip:**

```
Transactional Tables → Materialized Views → Dashboards
```

This separates:
- Write-heavy workload
- Read-heavy workload

**Result:** stable, scalable systems

---

## ⚡ Performance Optimization Tips

### ✅ Add Indexes

```sql
CREATE INDEX idx_total_spent
ON user_order_summary_mv (total_spent);
```

### ✅ Schedule Refresh (Cron / pg_cron)

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY user_order_summary_mv;
```

Schedule:
- Every hour
- Every night
- After batch jobs

---

## Final Rule of Thumb

**Use Views for correctness.**  
**Use Materialized Views for performance.**

If your system:
- Reads more than it writes
- Runs expensive queries repeatedly
- Powers dashboards or analytics

---

## 🔚 Closing Thoughts

Materialized Views are not magic — they are engineering trade-offs:

- Faster reads
- Controlled freshness
- Predictable performance

Used correctly, they can transform slow systems into lightning-fast platforms 🚀

---

**Original Article by Rasifrazak**