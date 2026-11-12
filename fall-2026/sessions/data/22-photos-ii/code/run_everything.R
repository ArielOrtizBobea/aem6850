# AEM 6850, session 22. Runs the three scripts in lecture order, from the 22-photos-ii folder.
# Base R only; nothing to install. No model runs: what the models returned is in data_clean/.
for (f in c("code/1_count.R", "code/2_houses.R", "code/3_faces.R")) {
  cat("\n==== ", f, " ====\n"); source(f, echo = FALSE, print.eval = TRUE)
}
