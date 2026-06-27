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

## Remaining Journal Entries (to be added)

- [ ] EDA — distribution findings and surprises
- [ ] EDA — bivariate analysis: what features actually relate to risk?
- [ ] Correlation — Pearson vs Spearman differences and what they mean
- [ ] Final reflection writing process
- [ ] SQL — setup errors and query debugging
- [ ] SQL — concepts that were unclear and how I resolved them

---

## Running List of Concepts I Want to Understand Better

- [ ] MCAR vs MAR vs MNAR — I know the definitions, I want to see a
      real example of each in health data
- [ ] When to use Spearman vs Pearson — beyond "Spearman is robust to
      outliers", what does that actually look like in practice?
- [ ] Class imbalance — 64/36 split here. At what ratio does this become
      a serious problem? What techniques exist to handle it?
- [ ] Log transform vs Box-Cox — when is each appropriate?
- [ ] Window functions in SQL — RANK() is in the assignment, I need to
      understand how PARTITION BY works

---

*Journal started: April 30, 2026*
*Last updated: April 30, 2026*
*Next update: After EDA section*
