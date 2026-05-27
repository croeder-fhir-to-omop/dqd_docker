library(DBI)
library(duckdb)
library(DataQualityDashboard)

db_path <- Sys.getenv("OMOP_DB_PATH", "/omop/omop.ddb")
results_path <- "/srv/shiny-server/dqd_results.json"

con <- dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)

DataQualityDashboard::executeDqChecks(
  connectionDetails = DatabaseConnector::createConnectionDetails(
    dbms        = "duckdb",
    server      = db_path,
    pathToDriver = ""
  ),
  cdmDatabaseSchema    = "main",
  resultsDatabaseSchema = "main",
  cdmSourceName        = "FHIR-to-OMOP Demo",
  numThreads           = 1,
  sqlOnly              = FALSE,
  outputFolder         = "/srv/shiny-server",
  outputFile           = "dqd_results.json",
  verboseMode          = TRUE,
  writeToTable         = FALSE,
  checkLevels          = c("TABLE", "FIELD", "CONCEPT"),
  checkNames           = c()
)

dbDisconnect(con)
cat("DQD checks complete. Results at", results_path, "\n")
