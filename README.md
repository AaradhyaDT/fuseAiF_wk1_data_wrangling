**Overview**

- Project: Week 1 — Data wrangling and preparation for cardiac event analysis.

**Structure**

- **Root files:** main notebooks and assignment materials remain in the root of the folder.
- **Data:** [M1/WK1/data](M1/WK1/data) — CSV and SQL seed files used for exercises and reproducibility.
- **Notebooks:** [M1/WK1/notebooks](M1/WK1/notebooks) — working and submitted notebooks.
- **Docs:** [M1/WK1/docs](M1/WK1/docs) — assignment sheets, journals, and SQL scripts.
- **Tools:** [M1/WK1/tools](M1/WK1/tools) — helper scripts and test utilities (created if needed).
- **Misc:** [M1/WK1/misc](M1/WK1/misc) — logs and generated outputs.
- **Plots:** [M1/WK1/plots](M1/WK1/plots) — saved figures and visualizations.

**Quick Run (local)**

1. Create and activate a Python virtual environment, then install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. Open and run notebooks from [M1/WK1/notebooks](M1/WK1/notebooks) in Jupyter or VS Code.

3. To initialize the sample SQL database (if required for exercises):

```powershell
# run this from the WK1 root
psql -f "data\mysqlsampledatabase (1).sql"  # or use your DB client to run the SQL file
```

**Notes**

- I moved raw data files into `data/`, notebooks into `notebooks/`, and docs into `docs/` to reduce top-level clutter. Helper scripts belong in `tools/` and should reference the repository root using a path pattern like `Path(__file__).resolve().parent.parent`.
- `__pycache__/` directories have been removed. Add `__pycache__/` to your global or repo `.gitignore` to avoid committing caches.
- If you want, I can update `requirements.txt`, add a `Makefile` or `run.sh` helper, or commit these reorganizations to Git.