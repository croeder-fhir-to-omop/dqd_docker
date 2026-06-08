#!/bin/bash
set -e

echo "=== Running FHIR -> OMOP ETL ==="
cd /etl
python3 load_duckdb.py

echo "=== Running Data Quality Dashboard checks ==="
Rscript /app/run_dqd.R

echo "=== Copying fixtures for ETL report links ==="
mkdir -p /omop/fixtures
cp /etl/*.json /omop/fixtures/

echo "=== Serving ETL report on port 8088 ==="
python3 -m http.server 8088 --directory /omop &

echo "=== Serving DQD dashboard on port 3838 ==="
exec Rscript /app/serve_dqd.R
