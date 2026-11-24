# AEM 6850, session 25 (Radar & LiDAR). Runs the six scripts in order.
# Open 25-lidar-drones.Rproj first, so R starts in the project folder; then
#   source("run_everything.R")
# Each script installs the packages it needs (lidR, terra, sf, exactextractr) if they are missing.
rm(list = ls())
for (f in c("code/1_radar.R", "code/2_lidar.R", "code/3_heights.R", "code/4_slope.R",
            "code/5_views.R", "code/6_watershed.R")) {
  cat("\n==== ", f, " ====\n"); source(f, echo = FALSE, print.eval = TRUE)
}
