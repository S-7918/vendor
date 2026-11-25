-- Query 1: Top Vendors by Total Spend
-- Ranks all vendors by total billed amount, showing paid vs. unpaid balances.
SELECT
	vendor_id,
	vendor_name,
	COUNT(*) AS invoice_count,
	ROUND(SUM(amount), 2) AS total_spend,
	ROUND(SUM(CASE WHEN status = 'Paid' THEN amount ELSE 0 END), 2) AS paid_spend,
	ROUND(SUM(CASE WHEN status != 'Paid' THEN amount ELSE 0 END), 2) AS unpaid_balance
FROM vendor_payments
GROUP BY vendor_id, vendor_name
ORDER BY total_spend DESC;

-- Query 2: Duplicate Payments Detection
-- Flags same-vendor, same-date, same-amount payments (including modified invoice suffixes).
SELECT
	vendor_id,
	vendor_name,
	invoice_date,
	ROUND(amount, 2) AS amount,
	COUNT(*) AS duplicate_count,
	GROUP_CONCAT(payment_id, ', ') AS payment_ids,
	GROUP_CONCAT(invoice_number, ', ') AS invoice_numbers
FROM vendor_payments
GROUP BY vendor_id, vendor_name, invoice_date, amount
HAVING COUNT(*) > 1;

-- Query 3: Monthly Spend Totals
-- Summarizes total invoices, total spend, and settled spend by billing month.
SELECT
	STRFTIME('%Y-%m', invoice_date) AS billing_month,
	COUNT(*) AS invoice_count,
	ROUND(SUM(amount), 2) AS monthly_spend,
	ROUND(SUM(CASE WHEN status = 'Paid' THEN amount ELSE 0 END), 2) AS paid_spend
FROM vendor_payments
GROUP BY STRFTIME('%Y-%m', invoice_date)
ORDER BY billing_month;

-- Query 4: Late Payments Report
-- Lists all paid invoices settled after their due date and calculates days overdue.
SELECT
	payment_id,
	vendor_name,
	invoice_number,
	due_date,
	payment_date,
	CAST(JULIANDAY(payment_date) - JULIANDAY(due_date) AS INTEGER) AS days_late,
	ROUND(amount, 2) AS amount
FROM vendor_payments
WHERE status = 'Paid'
  AND DATE(payment_date) > DATE(due_date)
ORDER BY days_late DESC;

-- Query 5: Spend by Department
-- Shows total spend and percentage share across internal departments.
SELECT
	department,
	COUNT(*) AS invoice_count,
	ROUND(SUM(amount), 2) AS total_spend,
	ROUND(100.0 * SUM(amount) / (SELECT SUM(amount) FROM vendor_payments), 1) AS pct_of_total
FROM vendor_payments
GROUP BY department
ORDER BY total_spend DESC;

-- Query 6: Spend by Expense Category
-- Breaks down total spend and average invoice size by category.
SELECT
	category,
	COUNT(*) AS invoice_count,
	ROUND(SUM(amount), 2) AS total_spend,
	ROUND(AVG(amount), 2) AS avg_invoice
FROM vendor_payments
GROUP BY category
ORDER BY total_spend DESC;

-- Query 7: Unpaid and Overdue Exposure
-- Summarizes all open ('Pending' and 'Overdue') balances and lists the affected vendors.
SELECT
	status,
	COUNT(*) AS invoice_count,
	ROUND(SUM(amount), 2) AS total_unpaid,
	GROUP_CONCAT(vendor_name || ' ($' || printf('%.2f', amount) || ')', '; ') AS breakdown
FROM vendor_payments
WHERE status != 'Paid'
GROUP BY status
ORDER BY total_unpaid DESC;

-- Query 8: Payment Method Utilization
-- Compares transaction count, total volume, and average ticket size by payment rail.
SELECT
	payment_method,
	COUNT(*) AS txn_count,
	ROUND(SUM(amount), 2) AS total_volume,
	ROUND(AVG(amount), 2) AS avg_txn_amount
FROM vendor_payments
GROUP BY payment_method
ORDER BY total_volume DESC;

-- Query 9: Contractual Payment Terms vs. Actual Days Taken
-- Compares allowed payment window against actual average days from invoice to payment.
SELECT
	payment_terms,
	COUNT(*) AS paid_invoices,
	ROUND(AVG(JULIANDAY(due_date) - JULIANDAY(invoice_date)), 1) AS allowed_days,
	ROUND(AVG(JULIANDAY(payment_date) - JULIANDAY(invoice_date)), 1) AS actual_avg_days
FROM vendor_payments
WHERE status = 'Paid'
  AND payment_date IS NOT NULL
GROUP BY payment_terms;

-- Query 10: High-Value Invoices Above $10,000
-- Surfaces large individual disbursements exceeding $10,000 for audit review.
SELECT
	payment_id,
	vendor_name,
	department,
	invoice_number,
	invoice_date,
	ROUND(amount, 2) AS amount,
	status
FROM vendor_payments
WHERE amount > 10000
ORDER BY amount DESC;
