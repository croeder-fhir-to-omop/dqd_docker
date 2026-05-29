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
| `Dockerfile` | Installs Python, R, DuckDB, and `DataQualityDashboard`; bakes in ETL scripts and fixtures from `matchbox_scripts` |
| `docker-compose.yml` | Starts matchbox + the ETL/DQD container using published images — no repo clones required |
| `docker-compose.dev.yml` | Overlay for `matchbox_scripts` development: rebuilds locally from source |
| `docker-compose.build.yml` | Builds and tags the image for publishing |
| `entrypoint.sh` | Runs ETL → DQD checks → starts both HTTP servers |
| `run_dqd.R` | Executes DQD checks against the DuckDB OMOP database; dynamically skips empty tables |
| `serve_dqd.R` | Serves the DQD Shiny dashboard on port 3838 |

## Running

No repo clones required. Pull and start with:

```bash
docker compose up
```

| URL | Description |
|---|---|
| http://localhost:3838 | OHDSI Data Quality Dashboard |
| http://localhost:8088/etl_report.html | ETL report — per-fixture status, StructureMap used, root cause of any failures |

On first run matchbox loads the OMOP IG (~1 min). Subsequent runs use the cached volume.

## Developing matchbox_scripts locally

Clone `matchbox_scripts` alongside this repo, then rebuild and run with the dev overlay:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

The `--build` flag rebuilds the `dqd` image so that your local `matchbox_scripts` changes are baked in. When you're happy with changes, commit and push from the `matchbox_scripts` repo and rebuild the published image.

## Stopping

```bash
docker compose down      # keep data volumes
docker compose down -v   # also remove volumes (fresh start)
```

## Building and publishing the image

Requires `matchbox_scripts` cloned alongside this repo (the build context is the parent directory).

```bash
docker compose -f docker-compose.build.yml build
docker compose -f docker-compose.build.yml push
```

See the [organisation README](https://github.com/croeder-fhir-to-omop) for full usage and fixture/engine extension guidance.
