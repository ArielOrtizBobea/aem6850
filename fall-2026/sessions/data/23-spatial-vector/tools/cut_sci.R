# AEM 6850, session 23. Cuts Tompkins County's row of Meta's Social Connectedness Index.
# Run once, in the 23-spatial-vector folder, after tools/fetch_data.R has saved data/meta/us_counties.csv
# (245 MB, 10.3 million county pairs; it stays out of the class zip).
# Reads: data/meta/us_counties.csv. Writes: data_clean/sci_tompkins.csv.
  sci <- read.csv("data/meta/us_counties.csv", colClasses = "character")
  sci <- sci[sci$user_region == "36109", ]                         # Tompkins and each county its users have friends in
  out <- data.frame(GEOID = sci$friend_region, sci = as.numeric(sci$scaled_sci))
  stopifnot(nrow(out) == length(unique(out$GEOID)), "36109" %in% out$GEOID)
  write.csv(out, "data_clean/sci_tompkins.csv", row.names = FALSE)
