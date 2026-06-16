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
| `docker-compose.matchbox-dev.yml` | Overlay for local OMOP IG development: mounts `igs/` and `config/` from a sibling `matchbox_docker` clone |
| `docker-compose.build.yml` | Builds and tags the image for publishing |
| `entrypoint.sh` | Runs ETL → DQD checks → starts both HTTP servers |
| `run_dqd.R` | Executes DQD checks against the DuckDB OMOP database; dynamically skips empty tables |
| `serve_dqd.R` | Serves the DQD Shiny dashboard on port 3838 |

## Running (no clone required)

The only files you need locally are the two large OMOP vocabulary files from [Athena](https://athena.ohdsi.org):
- `CONCEPT.csv`
- `CONCEPT_RELATIONSHIP.csv`

Place them in a working directory alongside the compose file, then:

**Linux / macOS / Windows (PowerShell)**

```bash
curl -O https://raw.githubusercontent.com/croeder-fhir-to-omop/dqd_docker/main/docker-compose.yml
```

**FHIR R4 (default)**

```bash
docker compose --profile r4 up
```

**FHIR R5**

```bash
docker compose --profile r5 up
```

If your vocabulary files are not in the current directory, set environment variables to point to them:

```bash
CONCEPT_CSV=/path/to/CONCEPT.csv \
CONCEPT_RELATIONSHIP_CSV=/path/to/CONCEPT_RELATIONSHIP.csv \
docker compose --profile r4 up
```

| Profile | URL | Description |
|---|---|---|
| r4 | http://localhost:3838 | OHDSI Data Quality Dashboard (R4) |
| r4 | http://localhost:8088/etl_report.html | ETL report — per-fixture status, StructureMap used, root cause of any failures |
| r5 | http://localhost:3839 | OHDSI Data Quality Dashboard (R5) |
| r5 | http://localhost:8089/etl_report.html | ETL report (R5) |

On first run matchbox loads the OMOP IG (~1 min). Subsequent runs use the cached volume.

## Developing matchbox_scripts locally

Clone `matchbox_scripts` alongside this repo, then rebuild and run with the dev overlay:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

The `--build` flag rebuilds the `dqd` image so that your local `matchbox_scripts` changes are baked in. When you're happy with changes, commit and push from the `matchbox_scripts` repo and rebuild the published image.

## Developing the OMOP IG locally

Clone `matchbox_docker` alongside this repo, build your local IG version into `matchbox_docker/igs/`, and update `matchbox_docker/config/application.yaml` with the new version (see the [matchbox_docker README](https://github.com/croeder-fhir-to-omop/matchbox_docker) for the full workflow). Then run with the matchbox dev overlay:

```bash
docker compose -f docker-compose.yml -f docker-compose.matchbox-dev.yml up
```

No image rebuild is required — the overlay mounts `../matchbox_docker/igs` and `../matchbox_docker/config` into the matchbox container at runtime.

## Using a different terminology server (e.g. echidna)

By default, matchbox uses **enchilada** — a local OMOP-backed terminology container included in `docker-compose.yml`. You can swap it for any FHIR-compatible terminology server such as [echidna.fhir.org](https://echidna.fhir.org).

**1. Create a config override file** in your working directory, e.g. `application.yaml`:

```yaml
matchbox:
  fhir:
    context:
      txServer: https://echidna.fhir.org/r4   # or /r5 for the R5 profile
```

**2. Mount it into the matchbox service** by adding a volume to `docker-compose.yml` under the `matchbox` (or `matchbox-r5`) service:

```yaml
volumes:
  - matchbox-db:/database
  - ./application.yaml:/config/application.yaml:ro   # add this line
```

The enchilada container will still start (it is listed as a healthcheck dependency) but matchbox will route all terminology lookups to the server you configured instead.

**Parameter format difference:** When calling `ConceptMap/$translate` directly against enchilada, use flat `system`/`code`/`targetsystem` parameters. Echidna expects a nested `coding`/`valueCoding` body with `targetSystem` (camelCase). See `matchbox_scripts/enchilada_test.sh` for both formats.

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
