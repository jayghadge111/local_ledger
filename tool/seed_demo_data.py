"""Fills a TrueLedger database with demo data for marketing screenshots.
Usage: python3 tool/seed_demo_data.py path/to/local_ledger_db.sqlite
Run it with the app closed. (Extra big-ticket rows added by hand for the screenshots are not included.)
"""
import sqlite3, uuid, random, sys
from datetime import datetime, timedelta

db = sqlite3.connect(sys.argv[1])
c = db.cursor()
random.seed(7)
now = datetime.now()
ts = lambda d: int(d.timestamp())
uid = lambda: str(uuid.uuid4())

def month_start(n_back):
    y, m = now.year, now.month - n_back
    while m <= 0:
        m += 12; y -= 1
    return datetime(y, m, 1, 10, 0)

# (merchant, category, min, max, per-month count)
spend = [
    ("Swiggy", "cat_food", 280, 640, 5), ("Zomato", "cat_food", 250, 560, 3),
    ("Starbucks", "cat_food", 320, 480, 2), ("Barbeque Nation", "cat_food", 1800, 2600, 1),
    ("BigBasket", "cat_groceries", 900, 2400, 3), ("Blinkit", "cat_groceries", 250, 700, 4),
    ("Uber", "cat_transport", 140, 380, 5), ("Metro Card Recharge", "cat_transport", 500, 500, 1),
    ("Amazon", "cat_shopping", 600, 3200, 2), ("Myntra", "cat_shopping", 900, 2800, 1),
    ("Airtel Postpaid", "cat_bills", 599, 599, 1), ("BESCOM Electricity", "cat_bills", 1100, 1900, 1),
    ("Rent - Landlord", "cat_bills", 18000, 18000, 1),
    ("Netflix", "cat_entertainment", 649, 649, 1), ("BookMyShow", "cat_entertainment", 500, 1100, 1),
    ("Apollo Pharmacy", "cat_health", 250, 900, 1),
    ("HDFC Home Loan EMI", "cat_emi", 12500, 12500, 1),
    ("Zerodha SIP", "cat_investment", 5000, 5000, 1),
]
rows = []
for back in range(6, -1, -1):
    start = month_start(back)
    last_day = now.day if back == 0 else 28
    rows.append(("Salary - Acme Technologies", "cat_income", 85000, "credit", start.replace(day=1, hour=9)))
    for merch, cat, lo, hi, cnt in spend:
        n = cnt
        if back == 0:  # this month: only what has "happened" by today
            n = max(0, round(cnt * now.day / 30)) if cnt > 1 else (1 if now.day >= 2 else 0)
        for i in range(n):
            day = random.randint(1, max(1, last_day))
            d = start.replace(day=day, hour=random.randint(8, 21), minute=random.randint(0, 59))
            if d > now: d = now - timedelta(hours=random.randint(1, 20))
            amt = random.randint(lo, hi) if lo != hi else lo
            rows.append((merch, cat, amt, "debit", d))
# make this month's Shopping run over budget and Food near the limit (alerts demo)
rows.append(("Amazon", "cat_shopping", 4200, "debit", now - timedelta(days=1, hours=3)))
rows.append(("Swiggy", "cat_food", 540, "debit", now - timedelta(hours=5)))

for merch, cat, amt, typ, d in rows:
    c.execute("""insert into transactions (id, amount_minor, merchant, source, category_id, date, type, is_recurring)
                 values (?,?,?,?,?,?,?,?)""",
              (uid(), int(amt * 100), merch, "sms", cat, ts(d), typ, 1 if merch in ("Netflix","Airtel Postpaid","Rent - Landlord","HDFC Home Loan EMI","Zerodha SIP") else 0))

# budgets (standing, from 5 months back)
key = month_start(5).strftime("%Y-%m")
for cat, lim in [("cat_food", 9000), ("cat_groceries", 9000), ("cat_transport", 3500),
                 ("cat_shopping", 6000), ("cat_entertainment", 2500), ("cat_bills", 24000)]:
    c.execute("insert into budgets (id, category_id, monthly_limit_minor, from_month_key) values (?,?,?,?)",
              (uid(), cat, lim * 100, key))

# a group dinner split four ways
dinner = c.execute("select id, amount_minor from transactions where merchant='Barbeque Nation' order by date desc limit 1").fetchone()
amt = 2480 * 100
c.execute("update transactions set amount_minor=? where id=?", (amt, dinner[0]))
share = amt // 4
for name, settled in [("Priya", 0), ("Rohan", 0), ("Meera", 1)]:
    c.execute("insert into split_shares (id, transaction_id, person_name, share_minor, settled) values (?,?,?,?,?)",
              (uid(), dinner[0], name, share, settled))
trip = c.execute("select id, amount_minor from transactions where merchant='Uber' order by date desc limit 1").fetchone()
for name in ("Amit", "Priya"):
    c.execute("insert into split_shares (id, transaction_id, person_name, share_minor, settled) values (?,?,?,?,0)",
              (uid(), trip[0], name, trip[1] // 3))

# loans: lent / borrowed
def lend(person, direction, amount, days_ago, due_in, note, settled=0):
    c.execute("""insert into lending_entries (id, person, direction, amount_minor, date, due_date, note, is_settled)
                 values (?,?,?,?,?,?,?,?)""",
              (uid(), person, direction, amount * 100, ts(now - timedelta(days=days_ago)),
               ts(now + timedelta(days=due_in)) if due_in is not None else None, note, settled))
lend("Rohan Verma", "lent", 15000, 20, 12, "For bike repair")
lend("Meera Iyer", "lent", 8000, 9, 25, "Trip advance")
lend("Priya Nair", "borrowed", 3500, 5, 3, "Concert tickets")

# upcoming auto-debits / dues
def obligation(kind, biller, amount, due_in, status="upcoming", ref=None, reftype=None):
    c.execute("""insert into obligations (id, kind, status, biller, amount_minor, is_max_amount, due_date, ref_last4, ref_type, source, received_at)
                 values (?,?,?,?,?,?,?,?,?,?,?)""",
              (uid(), kind, status, biller, amount * 100, 0, ts(now + timedelta(days=due_in)), ref, reftype, "sms", ts(now - timedelta(days=1))))
obligation("pre_debit", "Netflix", 649, 2)
obligation("card_due", "HDFC Credit Card", 18420, 4, ref="4821", reftype="card")
obligation("emi_due", "HDFC Home Loan", 12500, 7, ref="1190", reftype="loan")

db.commit()
print("transactions:", c.execute("select count(*) from transactions").fetchone()[0])
