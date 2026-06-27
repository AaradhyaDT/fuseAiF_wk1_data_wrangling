# Learning Journal — Fuse AI Fellowship 2026
## Week 1: Data Wrangling

*Aaradhya Dev Tamrakar*
*Started: April 30, 2026*

---

> This journal documents my honest process — what I tried, what broke,
> what surprised me, and what I actually understood vs what I just ran.
> Written for myself first, assignment second.

---

## April 29, 2026 — Setup Day

### What I did
Set up the Colab environment. Located the CSV files in Google Drive under
`Classroom/AI Fellowship 2026/`. Confirmed all three files are present.
Opened the starter notebook `DataWranglingPreW1.ipynb`.

### What I learned
- Google Colab connects to Drive via `drive.mount()` — the files aren't
  local, they live in Drive and Colab accesses them through a mount path.
- `os.walk()` is more reliable than hardcoding paths — it finds files
  even if the folder structure changes.
- The starter notebook is a shell — it has section headers and hints but
  no actual code. Everything needs to be written from scratch.

### Feeling
Comfortable with setup. The environment is simpler than I expected —
no installs, no config, just mount and go.

---

## April 30, 2026 — Inspection, Cleaning, Merge

### Entry 1 — The equal row count assumption

When I saw all three files had 8763 rows I assumed the same 8763 patients
were in all three. My instinct said: verify this before assuming.

Wrote set intersection/difference checks. Found on the Drive copies:
- 5 IDs in demographics were missing from clinical
- 5 IDs in clinical were missing from lifestyle
- The two missing groups had zero overlap — meaning potentially 10
  different patients affected

Then looked more carefully at the actual IDs:
```
demo - clinical  : {'MAR6599', 'JUL2572', 'JAN3249', 'JUN5410', 'MAY4858'}
clinical - life  : {'May-58',  'Jul-72',  'Mar-99',  'Jan-49',  'Jun-10'}
```

These were the same 5 patients — IDs had been corrupted. MAY4858 became
May-58, JUN5410 became Jun-10, etc. Excel had interpreted them as dates
and reformatted them when someone opened the CSV in Excel before uploading
to Drive.

**Re-downloaded directly from Google Classroom — files were clean.**
All intersections = 8763, all differences = 0.

*Breakthrough:* Equal row counts do not mean matching keys. A merge on
mismatched keys would have silently dropped those 5 patients with no
error or warning. The only way to catch it is to explicitly check.

*Lesson:* Always verify ID overlap before merging. Never trust shape alone.

---

### Entry 2 — Reading output before writing code

Got into the habit this session of reading `.info()` and `.describe()`
output carefully before deciding what to do next, instead of just
running the next cell mechanically.

From demographics `.describe()` I noticed:
- Income mean (~158k) ≈ Income median (~158k)
- Real income data is right-skewed — mean is always pulled above median
  by high earners. Equal mean and median means uniform distribution.
- This is a synthetic data indicator.

Same pattern appeared in Age (mean 53.7, median 54) and later in
Exercise Hours Per Week (mean exactly 10.0).

*Lesson:* Mean ≈ median → symmetric/uniform distribution. In real-world
health data this is rare. When you see it across multiple columns, it
tells you something about how the data was generated.

---

### Entry 3 — Blood Pressure dtype

Blood Pressure came in as `object` dtype. Before this session I would
have just accepted it and moved on. This time I asked: *why does the
dtype matter?*

You cannot:
- Compute `clinical['Blood Pressure'].mean()` — it's a string
- Compare `clinical['Blood Pressure'] > 140` — meaningless on strings
- Feed it into any model — strings aren't numeric

The format "158/88" encodes two separate measurements — systolic and
diastolic — which have different clinical meanings. Systolic (top number)
measures pressure when the heart beats. Diastolic (bottom) measures
pressure between beats. They need to be treated as separate features.

```python
clinical[['bp_systolic', 'bp_diastolic']] = (
    clinical['Blood Pressure']
    .str.split('/', expand=True)
    .astype(float)
)
```

Post-split ranges: systolic 90–180, diastolic 60–110. Zero suspicious
values. Clean split.

*Lesson:* Dtype is not just a label — it determines what operations are
legal on that column. Object dtype = string = no math.

---

### Entry 4 — Bug: missing parentheses on method call

Wrote `merged.isnull().sum` instead of `merged.isnull().sum()`.

Output was a giant boolean table — 8763 rows of True/False values —
instead of a clean column-by-column count.

*Why:* In Python, `object.method` without `()` returns the method object
itself. You're referencing the function, not calling it. Adding `()` 
executes it and returns the result.

*Fix:* Added `()`. Got the clean summary I wanted.

*Lesson:* When output looks completely wrong — especially when it looks
like raw data instead of a summary — check for missing parentheses first.

---

### Entry 5 — Left join rationale

The merge decision felt obvious at first: just join them. But thinking
about *why* left join vs inner join matters:

**Inner join:** keeps only patients present in ALL three files.
If a patient has demographics but no clinical data (maybe they refused
lab tests), they get dropped entirely. You'd never know.

**Left join with demographics as anchor:** keeps all 8763 patients.
If clinical or lifestyle data is missing for someone, those fields
become NULL — which is visible and handleable.

In health data this matters a lot. Patients who skip lab tests or don't
fill out lifestyle surveys are not random — they tend to be healthier,
more avoidant of medical care, or from specific demographic groups.
Dropping them silently biases the dataset toward more compliant or sicker
patients.

*Lesson:* Join type is a decision about what bias you're willing to
introduce. Inner join = hidden data loss. Left join = transparent nulls.

---

### Entry 6 — Synthetic data pattern recognition

By the end of the inspection phase I had accumulated multiple indicators
that this is synthetic data:

| Observation | Why suspicious |
|---|---|
| All three files have exactly 8763 rows | Real systems rarely sync perfectly |
| Zero nulls across all 23 columns | Real surveys always have missing responses |
| Country counts nearly uniform (435–477) | Real global data has huge geographic skew |
| Diet: 33.78% / 33.23% / 32.99% | ~33/33/33 impossible in real surveys |
| Smoking rate 89.68% | Real global average is ~20-25% |
| Obesity 50.14% | Near perfect 50/50 |
| Family History 49.3% | Near perfect 50/50 |
| Income mean ≈ median | Real income is right-skewed |
| Exercise mean exactly 10.0 hrs/week | Suspiciously round |

None of these alone is conclusive. Together they make a strong case.

*Why it matters:* Findings from this dataset cannot be generalised to
real patient populations. The 89.68% smoking rate does not mean 89.68%
of real heart attack patients smoke. Correlations found here may not
exist in real data. This needs to be stated clearly in the final reflection.

---

## May 2, 2026 — Final Reflection

### Entry 7 — Writing the reflection collaboratively

Wrote the 5 final reflection answers today. The approach: Claude gave guiding
questions for each, I answered rough, Claude refined in my own voice — not
rewriting into formal prose, just cleaning grammar and filling gaps.

Key things that came out of writing each answer:

**Q1 — Most significant data quality issue:**
The Excel ID corruption was the clearest answer. Not because it was hardest
to fix — re-downloading from Classroom took 30 seconds — but because it was
the most dangerous. Silent data loss on merge with no error, no warning.
Only catchable by explicitly checking ID overlap. BP string format was second:
object dtype = no math, no model input. Zero nulls noted as synthetic
artifact, not a problem to clean.

**Q2 — What EDA revealed:**
Synthetic generation pattern clear only after accumulating enough indicators
together. The most interesting insight: data generated attribute by attribute,
not as a coherent population system — visible in Age vs Smoking (r=0.39)
being the only non-trivial correlation, artifact of a sub-prompt like
"higher age → more smoking probability."

**Q3 — Left join rationale:**
The framing that worked: "we classify data of a person, not a person of
the data." Also argued inner join is right in some contexts — when NULL
propagation cost exceeds row loss cost. Join type is a bias decision,
not a default.

**Q4 — Real patient data differences:**
Smoking curve declines with age due to life expectancy — Japan demographic
inversion example breaks the synthetic linear assumption immediately. Income
right-skewed: 1 gold + 99,999 gold averages to 50,000 gold. Real
correlations much higher → predictions actually meaningful. Privacy must
balance against clinical necessity — cannot override life-or-death access.

**Q5 — AI as tool:**
Kept mostly in original voice. Tubewell analogy felt right and stayed.
"We classify data of a person, not a person of the data" — kept verbatim.

*Lesson from this process:* Guiding questions force thinking before writing.
Rough answers first, refinement second — opposite of starting with a blank
formal document. The thinking is the work; the prose is packaging.

---

## May 3–4, 2026 — SQL Assignment

### Entry 8 — MySQL setup

Setting up MySQL on Windows. Two errors before loading the database:

**Error 1:** `source` command with backslashes failed — `\U`, `\A`, `\D` etc
interpreted as escape characters by MySQL.
*Fix:* Use forward slashes: `source C:/Users/.../mysqlsampledatabase.sql;`
*Lesson:* MySQL source command always uses forward slashes, even on Windows.

**Error 2:** Path had spaces — no quoting needed for source, forward slashes handle it.

Database loaded cleanly. 8 tables confirmed with `SHOW TABLES;`.

---

### Entry 9 — Q1: Basic WHERE filter

First real query. Instinct was right — customers table, filter on creditLimit.
Initial attempt said `search` instead of `SELECT` — not a SQL keyword.
First version only selected `customerName` — missing the actual credit limit value in output.

*Lesson:* `SELECT *` returns every column — useful for quick exploration,
bad practice in real queries. Always specify the columns you actually need.
Output without the filtered column (creditLimit) is half-blind.

```sql
SELECT customerName, creditLimit FROM customers 
WHERE creditLimit > 20000 
ORDER BY creditLimit DESC;
```

97 rows. Euro+ Shopping Channel at top: 227,600.

---

### Entry 10 — Q2: Subquery (scalar)

Task: find employees who report to VP Sales.

Key insight: `reportsTo` stores an int (employeeNumber), not a name or title.
Can't filter directly on job title — have to look up the number first.

Errors made:
- Forgot `FROM employees` → "Unknown column" error
- Typed `employee` instead of `employees` → table doesn't exist
- Typo: `jopbTitle` → unknown column

*How subquery works:*
- Inner query runs first, returns: 1056
- Outer query uses that result: `WHERE reportsTo = 1056`
- Use `=` because inner query returns exactly one value

```sql
SELECT employeeNumber, firstName, lastName, jobTitle 
FROM employees 
WHERE reportsTo = (SELECT employeeNumber FROM employees WHERE jobTitle = 'VP Sales');
```

Result: 4 employees — 3 Sales Managers + Mami Nishi (Sales Rep).
Interesting: not all direct reports to VP Sales are managers.

---

### Entry 11 — Q3: Multiple conditions + NULL check

Three conditions: country = USA, state IS NOT NULL, creditLimit BETWEEN 100000 AND 200000.

First attempt: `AND state NOT NULL` — invalid syntax.
SQL requires `IS` when checking for NULL. `!= NULL` also doesn't work.

*Why:* NULL is not a value — it's the absence of a value. You can't compare
nothing to something with `=`.

BETWEEN is inclusive on both ends.

```sql
SELECT customerNumber, customerName, state, country, creditLimit 
FROM customers 
WHERE country = 'USA' 
  AND creditLimit BETWEEN 100000 AND 200000 
  AND state IS NOT NULL;
```

8 rows.

*Lesson:* NULL checks require IS NOT NULL. BETWEEN is inclusive.

---

### Entry 12 — Q4: IN vs = for multi-row subqueries

Q2 used `=` because the subquery returned exactly 1 value.
Q4 needs employees reporting to ANY Sales Manager — multiple people.

If inner query returns multiple rows and you use `=`, MySQL errors:
"Subquery returns more than 1 row." Solution: use `IN` instead.

Also found: Sales Manager titles in this DB are inconsistent:
- 'Sales Manager (APAC)'
- 'Sales Manager (NA)'
- 'Sale Manager (EMEA)' ← typo in the database

Used `LIKE '%Sale% %Manage%'` to catch all three.

```sql
SELECT employeeNumber, firstName, lastName, jobTitle, reportsTo
FROM employees
WHERE reportsTo IN (
    SELECT employeeNumber FROM employees WHERE jobTitle LIKE '%Sale% %Manage%'
);
```

15 rows. Distribution: APAC→3, EMEA→6, NA→6.

*Lesson:* Multi-row subquery → IN not =. `employees` is self-referencing —
`reportsTo` is a foreign key pointing back to `employeeNumber` in the same table.

---

### Entry 13 — Q5: GROUP BY and AVG

First aggregation query. Key rule: every column in SELECT must either be in
GROUP BY or wrapped in an aggregate function.

First attempt forgot to include `country` in SELECT — got averages with no
labels, impossible to read.

Two observations from output:
1. Norway appears twice with different averages — whitespace variant in the
   data. GROUP BY groups on exact string match, so two spellings = two groups.
2. Six countries show 0.000000 — creditLimit defaulted to 0 instead of NULL.
   Unlike the Python notebook where missing = NULL, here missing = 0.

```sql
SELECT country, AVG(creditLimit) AS avg_credit 
FROM customers 
GROUP BY country 
ORDER BY avg_credit DESC;
```

*Lesson:* GROUP BY + aggregate functions collapse rows into groups. Dirty data
(whitespace variants, 0 vs NULL) shows up in aggregation output.

---

### Entry 14 — Q6: HAVING

HAVING filters groups after aggregation. WHERE filters rows before grouping.
You can't write `WHERE COUNT(*) > 10` — COUNT doesn't exist at the WHERE stage.

SQL clause order is fixed: `WHERE → GROUP BY → HAVING → ORDER BY`

Query was correct. Returned empty set — max orders per (date, customer) in
this dataset is 2. The threshold of 10 simply exceeds what the data contains.
Verified by running same query without HAVING, ordered by count DESC.

*Lesson:* Empty result ≠ wrong query. Always verify by removing the HAVING
filter to check what counts actually exist in the data.

---

### Entry 15 — Q7 & Q8: Self-referencing table, two approaches

Q7 (without JOIN) — correlated subquery in SELECT:
```sql
SELECT firstName, lastName, jobTitle,
    (SELECT COUNT(*) FROM employees e2 WHERE e2.reportsTo = e1.employeeNumber) AS supervisee_count
FROM employees e1
HAVING supervisee_count > 0;
```

Error made: tried `WHERE supervisee_count > 0` — alias not yet defined at
WHERE stage. WHERE runs before SELECT; HAVING runs after. Fixed with HAVING.

Q8 (with JOIN) — self-JOIN + GROUP BY:
```sql
SELECT e2.firstName, e2.lastName, e2.jobTitle, COUNT(e1.employeeNumber) AS supervisee_count
FROM employees e2
JOIN employees e1 ON e2.employeeNumber = e1.reportsTo
GROUP BY e2.employeeNumber;
```

Error made: wrote `JOIN e2.employees` — treated alias as database name.
Correct syntax: `JOIN employees e1` — alias goes after the table name.

Both queries produce identical output. 6 supervisors identified.
Interesting: Mami Nishi (Sales Rep) supervises 1 person — org structure is messier
than the job titles suggest.

*Lesson:* Correlated subquery = readable. Self-JOIN + GROUP BY = scalable.
For large tables, JOINs are generally faster because the DB can optimize them
better than running a subquery once per row.

---

### Entry 16 — Q9: CTE (WITH clause)

CTE = named temporary result. Compute once, reference by name.

Error: tried `WHERE creditLimit > AVG(creditLimit)` — aggregate function
not allowed in WHERE. Must alias it inside the CTE, then reference the alias.

```sql
WITH cte_name AS (
    SELECT AVG(creditLimit) AS avg_credit FROM customers
)
SELECT customerNumber, customerName, creditLimit
FROM customers, cte_name
WHERE creditLimit > avg_credit;
```

`FROM customers, cte_name` = cross join. Since CTE returns exactly 1 row,
it just attaches that value to every customer row.

69 customers above average. *Lesson:* WITH = cleaner than nested subqueries.
Alias aggregates inside the CTE — you can't call AVG() again in WHERE.

---

### Entry 17 — Q10: Window functions

`RANK() OVER (ORDER BY creditLimit DESC)` — window function. Adds a computed
column per row without collapsing rows, unlike GROUP BY.

`RANK()` skips numbers on ties. `DENSE_RANK()` doesn't skip.
For this dataset it didn't matter, but in real ranking problems the choice matters.

Used CTE to isolate rank 3:
```sql
WITH ranked AS (
    SELECT customerName, creditLimit, RANK() OVER (ORDER BY creditLimit DESC) AS rnk
    FROM customers
)
SELECT * FROM ranked WHERE rnk = 3;
```

Result: Vida Sport, Ltd — 141,300.

---

### Entry 18 — Q11–Q14: Multi-table JOIN chain

Q11–Q14 all follow the same pattern: chain LEFT JOINs from offices → employees
→ customers → orders/payments, then GROUP BY office.

The chain: offices → employees (officeCode) → customers (salesRepEmployeeNumber)
→ orders (customerNumber) → orderdetails (orderNumber)

Each step uses LEFT JOIN to preserve all offices even if no data exists downstream.

---

### Entry 19 — Q15: Row multiplication trap

Joining both `orderdetails` and `payments` to the same customer in one query
caused massive row multiplication. Each payment row multiplied against each
order row — SUMs became hundreds of millions, signs went negative.

Fix: pre-aggregate each path independently in subqueries, then join the
pre-aggregated results:

```sql
LEFT JOIN (
    SELECT customerNumber, SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM orders JOIN orderdetails ON orders.orderNumber = orderdetails.orderNumber
    GROUP BY customerNumber
) sales ON c.customerNumber = sales.customerNumber
LEFT JOIN (
    SELECT customerNumber, SUM(amount) AS total_payments
    FROM payments GROUP BY customerNumber
) pay ON c.customerNumber = pay.customerNumber
```

Also hit `only_full_group_by` error — MySQL strict mode. Fixed by wrapping
the subtraction in SUM().

*Lesson:* Never join two independent aggregation paths to the same table
directly. Pre-aggregate first, then join the summaries.

---

### Entry 20 — Q16–Q20: Proportion, VIEW, DML

**Q16** — Proportion within country: self-join `customers` to itself on
`c.country = c2.country`, then divide individual creditLimit by SUM of group.
NULL proportion for countries where total creditLimit = 0 (division by zero).

**Q17** — CREATE VIEW: saved query, reusable like a table. CONCAT for address,
COALESCE to replace NULL addressLine2 with empty string.

**Q18** — UPDATE: `UPDATE customers SET country = 'Nepal' WHERE customerNumber = 103;`
Always use WHERE — without it, every row gets updated.

**Q19** — DELETE: `DELETE FROM payments WHERE amount < 20000;`
78 rows removed, 195 remaining.

**Q20** — INSERT: `INSERT INTO payments (customerNumber, checkNumber, paymentDate, amount) VALUES (...);`
New payment added for customer 103.

*Lesson:* UPDATE and DELETE without WHERE affect the entire table. Always
verify with a SELECT before running destructive operations.

---

## Running List of Concepts I Want to Understand Better

- [x] NULL checks — IS NOT NULL vs != NULL (answered: NULL is absence of value, not comparable with =)
- [x] Scalar subquery vs multi-row subquery — = vs IN
- [x] Window functions in SQL — RANK() OVER(), DENSE_RANK() vs RANK()
- [x] Self-JOIN — joining a table to itself for hierarchy queries
- [ ] MCAR vs MAR vs MNAR — I know the definitions, I want to see a real example of each in health data
- [ ] When to use Spearman vs Pearson — beyond "Spearman is robust to outliers"
- [ ] Class imbalance — 64/36 split here. At what ratio does this become a serious problem?
- [ ] Log transform vs Box-Cox — when is each appropriate?
- [ ] PARTITION BY in window functions — RANK() within groups, not across entire table

---

*Journal started: April 30, 2026*
*Last updated: May 4, 2026 — Week 1 complete. SQL Q1–Q20 done.*
