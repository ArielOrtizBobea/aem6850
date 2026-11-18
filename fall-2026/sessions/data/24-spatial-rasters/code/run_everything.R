# AEM 6850, session 24 (Spatial II: rasters). Runs the five scripts in lecture order.
# Open 24-spatial-rasters.Rproj first, so R starts in the project folder; then
#   source("code/run_everything.R")
# Each script installs the packages it needs (terra, sf, exactextractr, Matrix) if they are missing.
# Peak memory is about 3.4 GB; the whole run takes about 25 seconds.
rm(list = ls())
for (f in c("code/1_raster.R", "code/2_compute.R", "code/3_aggregate.R", "code/4_corn.R", "code/5_eaton.R")) {
  cat("\n==== ", f, " ====\n"); source(f, echo = FALSE, print.eval = TRUE)
}
