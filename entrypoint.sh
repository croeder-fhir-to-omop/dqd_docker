#!/bin/bash
set -e

echo "=== Running FHIR -> OMOP ETL ==="
cd /etl
python3 load_duckdb.py

echo "=== Running Data Quality Dashboard checks ==="
Rscript /srv/shiny-server/run_dqd.R

echo "=== Starting Shiny server ==="
exec /usr/bin/shiny-server
