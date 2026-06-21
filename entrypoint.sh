#!/bin/bash
set -e

FHIR_VER=${FHIR_VERSION:-r4}
if [ "$FHIR_VER" = "r5" ]; then
    SAMPLE_DIR=sample_fixtures_r5
    TEST_DIR=test_files_r5
else
    SAMPLE_DIR=sample_fixtures_r4
    TEST_DIR=test_files_r4
fi

DQD_EXTERNAL_PORT=${DQD_EXTERNAL_PORT:-3838}

MATCHBOX_HEALTH="${MATCHBOX_URL:-http://matchbox:8080}/matchboxv3/actuator/health"
echo "=== Waiting for matchbox at ${MATCHBOX_HEALTH} ==="
until python3 -c "
import urllib.request, json, sys
try:
    with urllib.request.urlopen('${MATCHBOX_HEALTH}', timeout=5) as r:
        sys.exit(0 if json.load(r).get('status') == 'UP' else 1)
except Exception:
    sys.exit(1)
" 2>/dev/null; do
    echo "  matchbox not ready, retrying in 10s..."
    sleep 10
done
echo "=== matchbox is ready ==="

cd /etl

echo "=== Running FHIR ${FHIR_VER} -> OMOP ETL (test files) ==="
python3 load_duckdb.py --fixtures-dir ${TEST_DIR} --fhir-version ${FHIR_VER}
mv /omop/etl_report.html /omop/etl_report_test.html

echo "=== Running FHIR ${FHIR_VER} -> OMOP ETL (sample fixtures) ==="
python3 load_duckdb.py --fixtures-dir ${SAMPLE_DIR} --fhir-version ${FHIR_VER}
mv /omop/etl_report.html /omop/etl_report_sample.html

echo "=== Running Data Quality Dashboard checks ==="
Rscript /app/run_dqd.R

echo "=== Running unit tests ==="
MATCHBOX_URL="${MATCHBOX_URL:-http://matchbox:8080}" \
  python3 -m pytest /etl/tests/test_r5_fml_transforms.py -v \
    --html=/omop/unit_test_report.html --self-contained-html || true

echo "=== Copying fixtures for ETL report links ==="
mkdir -p /omop/fixtures
cp /etl/${TEST_DIR}/*.json /omop/fixtures/ 2>/dev/null || true
cp /etl/${SAMPLE_DIR}/*.json /omop/fixtures/ 2>/dev/null || true

echo "=== Creating index page ==="
python3 - <<PYEOF
port = "${DQD_EXTERNAL_PORT}"
ver  = "${FHIR_VER}".upper()
html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>FHIR {ver} to OMOP Reports</title>
<style>
  body {{ font-family: sans-serif; margin: 2em; background: #f9f9f9; }}
  h1 {{ color: #333; }}
  ul {{ list-style: none; padding: 0; }}
  li {{ margin: 0.75em 0; }}
  a {{ font-size: 1.1em; color: #1a6fa8; text-decoration: none; }}
  a:hover {{ text-decoration: underline; }}
</style>
</head><body>
<h1>FHIR {ver} &rarr; OMOP</h1>
<ul>
  <li><a href="etl_report_sample.html">ETL Report &mdash; Sample Fixtures</a></li>
  <li><a href="etl_report_test.html">ETL Report &mdash; Test Files</a></li>
  <li><a href="unit_test_report.html">Unit Test Report</a></li>
  <li><a href="http://localhost:{port}">Data Quality Dashboard</a></li>
</ul>
</body></html>"""
open("/omop/index.html", "w").write(html)
print("Index page written to /omop/index.html")
PYEOF

echo "=== Serving reports on port 8088 ==="
python3 -m http.server 8088 --directory /omop &

echo "=== Serving DQD dashboard on port 3838 ==="
exec Rscript /app/serve_dqd.R
