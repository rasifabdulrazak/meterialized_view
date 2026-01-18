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

INSERT INTO users (name, email)
SELECT
    'User ' || generate_series,
    'user' || generate_series || '@example.com'
FROM generate_series(1, 500000);

INSERT INTO orders (user_id, amount)
SELECT
    (random() * 499999 + 1)::INT,
    round((random() * 1000)::numeric, 2)
FROM generate_series(1, 300000);

EXPLAIN ANALYZE
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;

CREATE VIEW user_order_summary_view AS
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;

EXPLAIN ANALYZE
SELECT * FROM user_order_summary_view;

CREATE MATERIALIZED VIEW user_order_summary_mv AS
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS total_orders,
    SUM(o.amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;

EXPLAIN ANALYZE
SELECT * FROM user_order_summary_mv;

CREATE UNIQUE INDEX idx_user_order_mv_id
ON user_order_summary_mv (id);

REFRESH MATERIALIZED VIEW user_order_summary_mv;

REFRESH MATERIALIZED VIEW CONCURRENTLY user_order_summary_mv;

INSERT INTO orders (user_id, amount)
VALUES (497034, 9999.99);

SELECT * FROM user_order_summary_mv WHERE id = 497034;

REFRESH MATERIALIZED VIEW user_order_summary_mv;





