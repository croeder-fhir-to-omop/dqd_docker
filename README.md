# dqd_docker

Automated FHIR→OMOP ETL pipeline followed by the [OHDSI Data Quality Dashboard](https://github.com/OHDSI/DataQualityDashboard). On startup it transforms all sample FHIR fixtures into an OMOP CDM 5.4 DuckDB database, runs DQD checks, and serves two dashboards.

Part of the [croeder-fhir-to-omop](https://github.com/croeder-fhir-to-omop) FHIR→OMOP pipeline:

| Repo | Role |
|---|---|
| [fhir-omop-ig](https://github.com/croeder-fhir-to-omop/fhir-omop-ig) | HL7 FHIR-to-OMOP Implementation Guide — StructureMaps and ConceptMaps |
| [matchbox](https://github.com/croeder-fhir-to-omop/matchbox) | FHIR server with OMOP IG (fork of ahdis/matchbox) |
| [matchbox_docker](https://github.com/croeder-fhir-to-omop/matchbox_docker) | Docker config and IGs for matchbox |
| [matchbox_scripts](https://github.com/croeder-fhir-to-omop/matchbox_scripts) | Transform functions, ETL script, and FHIR fixtures |
| [jupyter_docker](https://github.com/croeder-fhir-to-omop/jupyter_docker) | Interactive Jupyter notebook environment |
| **[dqd_docker](https://github.com/croeder-fhir-to-omop/dqd_docker)** | **Automated ETL + OHDSI Data Quality Dashboard ← you are here** |
| [enchilada](https://github.com/croeder-fhir-to-omop/enchilada) | Local OMOP-backed FHIR terminology server |

## Contents

| Path | Description |
|---|---|
| `Dockerfile` | Installs Python, R, DuckDB, and `DataQualityDashboard`; bakes in ETL scripts and fixtures from `matchbox_scripts` |
| `docker-compose.yml` | Starts enchilada + matchbox + the ETL/DQD container using published images — no repo clones required |
| `docker-compose.profiles.yml` | Multi-stack compose for R4/R5 × 1.0.0/1.0.1 combinations (advanced) |
| `docker-compose.build.yml` | Builds and tags the image for publishing |
| `entrypoint.sh` | Runs ETL → DQD checks → starts both HTTP servers |
| `run_dqd.R` | Executes DQD checks against the DuckDB OMOP database; dynamically skips empty tables |
| `serve_dqd.R` | Serves the DQD Shiny dashboard on port 3838 |

## Running (no clone required)

The only files you need locally are the two large OMOP vocabulary files from [Athena](https://athena.ohdsi.org):
- `CONCEPT.csv`
- `CONCEPT_RELATIONSHIP.csv`

Place them in a working directory, then pull and start the stack in one command:

```bash
curl -fsSL https://raw.githubusercontent.com/croeder-fhir-to-omop/dqd_docker/main/docker-compose.yml | docker compose -f - up
```

Or download the compose file first if you want to edit it:

```bash
curl -O https://raw.githubusercontent.com/croeder-fhir-to-omop/dqd_docker/main/docker-compose.yml
docker compose up
```

If your vocabulary files are not in the current directory, set environment variables:

```bash
CONCEPT_CSV=/path/to/CONCEPT.csv \
CONCEPT_RELATIONSHIP_CSV=/path/to/CONCEPT_RELATIONSHIP.csv \
docker compose up
```

| URL | Description |
|---|---|
| http://localhost:3838 | OHDSI Data Quality Dashboard |
| http://localhost:8088 | ETL and unit test reports |

On first run, enchilada loads the vocabulary CSVs (~1–2 min) and matchbox loads the OMOP IG (~1 min). Both are cached in Docker volumes and skipped on subsequent starts.

## Terminology server

By default, matchbox uses **enchilada** — the local OMOP-backed terminology container bundled in `docker-compose.yml`. The image defaults to [echidna.fhir.org](https://echidna.fhir.org) (public), and the compose file overrides it to enchilada via the `MATCHBOX_FHIR_CONTEXT_TXSERVER` environment variable.

To switch to echidna instead, override the variable:

```bash
MATCHBOX_FHIR_CONTEXT_TXSERVER=https://echidna.fhir.org/r4 docker compose up
```

Or set it in a `.env` file alongside your compose file:

```
MATCHBOX_FHIR_CONTEXT_TXSERVER=https://echidna.fhir.org/r4
```

When using echidna, enchilada still starts (it is a healthcheck dependency) but matchbox routes all terminology lookups to echidna instead.

> **Licensing:** echidna's [terms of use](https://echidna.fhir.org/terms/) restrict access to personal use and prohibit commercial use or redistribution of the OMOP vocabulary data it provides. SNOMED CT license requirements still apply for users outside SNOMED International member countries. See [NOTICES.md](https://github.com/croeder-fhir-to-omop/.github/blob/main/profile/NOTICES.md) for details.

## Stopping

```bash
docker compose down      # keep volumes (fast restart — vocabulary cache preserved)
docker compose down -v   # also remove volumes (fresh start, full CSV reload)
```

## Developing matchbox_scripts locally

Clone `matchbox_scripts` alongside this repo, then rebuild and run with the dev overlay:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

The `--build` flag rebuilds the `dqd` image so that your local `matchbox_scripts` changes are baked in. When you're happy with changes, commit and push from the `matchbox_scripts` repo and rebuild the published image.

## Developing the OMOP IG locally

Clone `matchbox_docker` alongside this repo, build your local IG version into `matchbox_docker/igs/`, and run with the matchbox dev overlay:

```bash
docker compose -f docker-compose.yml -f docker-compose.matchbox-dev.yml up
```

No image rebuild is required — the overlay mounts `../matchbox_docker/igs` and `../matchbox_docker/config` into the matchbox container at runtime.

## Building and publishing the image

Requires `matchbox_scripts` cloned alongside this repo (the build context is the parent directory).

```bash
docker compose -f docker-compose.build.yml build
docker compose -f docker-compose.build.yml push
```

See the [organization README](https://github.com/croeder-fhir-to-omop) for running the pipeline end-to-end, and the [matchbox_scripts README](https://github.com/croeder-fhir-to-omop/matchbox_scripts) for fixture and engine extension guidance.

## License

Licensed under the [Apache License 2.0](./LICENSE). Copyright 2026 Christophe Roeder.

See the [organization README](https://github.com/croeder-fhir-to-omop) for full pipeline documentation and vocabulary licensing notices ([NOTICES.md](https://github.com/croeder-fhir-to-omop/.github/blob/main/profile/NOTICES.md)).
