#!/bin/bash
set -e

echo "=== Running FHIR -> OMOP ETL ==="
cd /etl
python3 load_duckdb.py

echo "=== Running Data Quality Dashboard checks ==="
Rscript /app/run_dqd.R

echo "=== Serving DQD dashboard on port 3838 ==="
exec Rscript /app/serve_dqd.R
