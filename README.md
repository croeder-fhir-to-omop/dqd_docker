# dqd_docker

Automated FHIR→OMOP ETL pipeline followed by the [OHDSI Data Quality Dashboard](https://github.com/OHDSI/DataQualityDashboard). On startup it transforms all sample FHIR fixtures into an OMOP CDM 5.4 DuckDB database, runs DQD checks, and serves two dashboards.

Part of the [croeder-fhir-to-omop](https://github.com/croeder-fhir-to-omop) FHIR→OMOP pipeline:

| Repo | Role |
|---|---|
| [matchbox](https://github.com/croeder-fhir-to-omop/matchbox) | FHIR server with OMOP IG (fork of ahdis/matchbox) |
| [matchbox_docker](https://github.com/croeder-fhir-to-omop/matchbox_docker) | Docker config and IGs for matchbox |
| [matchbox_scripts](https://github.com/croeder-fhir-to-omop/matchbox_scripts) | Transform functions, ETL script, and FHIR fixtures |
| [jupyter_docker](https://github.com/croeder-fhir-to-omop/jupyter_docker) | Interactive Jupyter notebook environment |
| **[dqd_docker](https://github.com/croeder-fhir-to-omop/dqd_docker)** | **Automated ETL + OHDSI Data Quality Dashboard ← you are here** |

## Contents

| Path | Description |
|---|---|
| `Dockerfile` | Installs Python, R, DuckDB, and `DataQualityDashboard`; copies ETL scripts and fixtures from `matchbox_scripts` |
| `docker-compose.yml` | Starts matchbox + the ETL/DQD container |
| `entrypoint.sh` | Runs ETL → DQD checks → starts both HTTP servers |
| `run_dqd.R` | Executes DQD checks against the DuckDB OMOP database; dynamically skips empty tables |
| `serve_dqd.R` | Serves the DQD Shiny dashboard on port 3838 |

## Running

Requires `matchbox_docker` and `matchbox_scripts` cloned into the same parent directory.

```bash
docker compose up
```

| URL | Description |
|---|---|
| http://localhost:3838 | OHDSI Data Quality Dashboard |
| http://localhost:8088/etl_report.html | ETL report — per-fixture status, StructureMap used, root cause of any failures |

On first run matchbox downloads the OMOP IG (~1 min). Subsequent runs use the cached volume.

## Stopping

```bash
docker compose down      # keep data volumes
docker compose down -v   # also remove volumes (fresh start)
```

## Adding fixtures

Fixtures are baked into the image at build time. To add one, drop it in `matchbox_scripts/` and rebuild:

```bash
docker compose up --build
```

See the [organisation README](https://github.com/croeder-fhir-to-omop) for full usage and fixture/engine extension guidance.
