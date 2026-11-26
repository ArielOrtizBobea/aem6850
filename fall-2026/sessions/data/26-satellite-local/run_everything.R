# AEM 6850, session 26 (Drone & satellite imagery). Runs the seven scripts in order.
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("run_everything.R")
# Each script installs the packages it needs (terra, sf, rpart) if they are missing. Nothing in tools/ runs.
rm(list = ls())
for (f in c("code/1_sensors.R", "code/2_drone.R", "code/3_sentinel2.R", "code/4_uses.R",
            "code/5_resolution.R", "code/6_error.R", "code/7_lake.R")) {
  cat("\n==== ", f, " ====\n"); source(f, echo = FALSE, print.eval = TRUE)
}
