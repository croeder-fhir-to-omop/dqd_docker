library(DataQualityDashboard)

results_path <- "/srv/shiny-server/dqd_results.json"
port <- as.integer(Sys.getenv("DQD_PORT", "3838"))

options(shiny.host = "0.0.0.0")

cat("Launching DQD dashboard on port", port, "\n")
DataQualityDashboard::viewDqDashboard(
  jsonPath       = results_path,
  port           = port,
  launch.browser = FALSE
)
