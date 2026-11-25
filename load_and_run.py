import csv
import sqlite3
from pathlib import Path

base_dir = Path(__file__).parent
csv_path = base_dir / "vendor_payments.csv"
db_path = base_dir / "vendor_payments.db"

conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("DROP TABLE IF EXISTS vendor_payments;")
cur.execute("""
CREATE TABLE vendor_payments (
    payment_id TEXT PRIMARY KEY,
    vendor_id TEXT,
    vendor_name TEXT,
    category TEXT,
    department TEXT,
    invoice_number TEXT,
    invoice_date DATE,
    due_date DATE,
    payment_date DATE,
    amount REAL,
    payment_method TEXT,
    payment_terms TEXT,
    status TEXT
);
""")

with open(csv_path, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    rows = [
        (
            r["payment_id"], r["vendor_id"], r["vendor_name"], r["category"],
            r["department"], r["invoice_number"], r["invoice_date"], r["due_date"],
            r["payment_date"] or None, float(r["amount"]), r["payment_method"],
            r["payment_terms"], r["status"]
        )
        for r in reader
    ]

cur.executemany(
    "INSERT INTO vendor_payments VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
    rows
)
conn.commit()

cur.execute("SELECT COUNT(*) FROM vendor_payments;")
print("Loaded rows:", cur.fetchone()[0])

sql_text = (base_dir / "queries.sql").read_text(encoding="utf-8", errors="ignore").replace("\x00", "")

buffer = ""
query_num = 0
for line in sql_text.splitlines():
    stripped = line.strip()
    if not stripped or stripped.startswith("--"):
        continue
    buffer += line + "\n"
    if sqlite3.complete_statement(buffer):
        query_num += 1
        cur.execute(buffer.strip())
        print(f"\n--- Query {query_num} ---")
        for row in cur.fetchall():
            print(row)
        buffer = ""

conn.close()