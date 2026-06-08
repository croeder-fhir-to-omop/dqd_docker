library(DBI)
library(duckdb)
library(DataQualityDashboard)

db_path <- Sys.getenv("OMOP_DB_PATH", "/omop/omop.ddb")
results_path <- "/srv/shiny-server/dqd_results.json"

con <- dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)

# Tables that don't exist in this pipeline at all
always_exclude <- c("VISIT_DETAIL", "NOTE", "NOTE_NLP", "SPECIMEN",
                    "FACT_RELATIONSHIP", "LOCATION", "CARE_SITE",
                    "PROVIDER", "PAYER_PLAN_PERIOD", "COST",
                    "DRUG_ERA", "DOSE_ERA", "CONDITION_ERA",
                    "EPISODE", "EPISODE_EVENT")

# DQD crashes on measureValueCompleteness when a table is empty;
# exclude any CDM table that has zero rows so errors surface properly.
cdm_tables <- c("PERSON", "OBSERVATION_PERIOD", "VISIT_OCCURRENCE",
                "CONDITION_OCCURRENCE", "DRUG_EXPOSURE", "PROCEDURE_OCCURRENCE",
                "DEVICE_EXPOSURE", "MEASUREMENT", "OBSERVATION", "DEATH")
empty_tables <- Filter(function(t) {
  n <- dbGetQuery(con, sprintf("SELECT COUNT(*) AS n FROM %s", tolower(t)))$n
  n == 0
}, cdm_tables)
if (length(empty_tables) > 0)
  cat("Excluding empty tables from DQD:", paste(empty_tables, collapse=", "), "\n")

tables_to_exclude <- unique(c(always_exclude, empty_tables))

DataQualityDashboard::executeDqChecks(
  connectionDetails = DatabaseConnector::createConnectionDetails(
    dbms        = "duckdb",
    server      = db_path,
    pathToDriver = ""
  ),
  cdmDatabaseSchema    = "main",
  resultsDatabaseSchema = "main",
  cdmSourceName        = "FHIR-to-OMOP Demo",
  cdmVersion           = "5.4",
  numThreads           = 1,
  sqlOnly              = FALSE,
  outputFolder         = "/srv/shiny-server",
  outputFile           = "dqd_results.json",
  verboseMode          = TRUE,
  writeToTable         = FALSE,
  checkLevels          = c("TABLE", "FIELD", "CONCEPT"),
  checkNames           = c(),
  tablesToExclude      = tables_to_exclude
)

dbDisconnect(con)
cat("DQD checks complete. Results at", results_path, "\n")
