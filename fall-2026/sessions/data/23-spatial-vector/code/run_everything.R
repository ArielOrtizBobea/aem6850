# AEM 6850, session 23 (Spatial I: vectors). Runs the six scripts in lecture order.
# Open 23-spatial-vector.Rproj first, so R starts in the project folder; then
#   source("code/run_everything.R")
# Each script installs the packages it needs (sf, igraph, fixest, magick, jsonlite) if they are missing.
# Peak memory is about 1 GB; the whole run takes about a minute.
rm(list = ls())
for (f in c("code/1_vector.R", "code/2_measure.R", "code/3_relations.R", "code/4_smoke.R", "code/5_medicaid.R", "code/6_amazon.R")) {
  cat("\n==== ", f, " ====\n"); source(f, echo = FALSE, print.eval = TRUE)
}
