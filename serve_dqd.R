library(DataQualityDashboard)

results_path <- Sys.getenv("DQD_RESULTS", "/omop/dqd_results.json")
port <- as.integer(Sys.getenv("DQD_PORT", "3838"))

cat("Launching DQD dashboard on port", port, "\n")
DataQualityDashboard::viewDqDashboard(
  jsonPath       = results_path,
  port           = port,
  launch.browser = FALSE
)
