placements$postdoc <- grepl("post[- ]?doc", placements$position, ignore.case = TRUE)

# Country of the organization. The page does not list it, so it is inferred
# from the organization name: the first matching pattern below wins, and
# anything unmatched is treated as United States (the large majority).
# International organizations (IMF, World Bank, IDB, USAID) are assigned the
# country of their headquarters. "DTUM" is read as TUM (Munich).
country_patterns <- c(
  "Australia"    = "Monash|New South Wales|University of Sydney",
  "Canada"       = "Alberta|Calgary|Ottawa",
  "China"        = "Beijing|Peking|Renmin|Industrial and Commercial Bank of China|Xi.an Jiaotong",
  "Finland"      = "Finland",
  "France"       = "Paris School of Economics",
  "Germany"      = "Ludwig-Maximilian|DTUM",
  "Hong Kong"    = "Hong Kong",
  "India"        = "Azim Premji|Indian Institute of Management|IIMA|Krea",
  "New Zealand"  = "New Zealand",
  "Norway"       = "Norwegian",
  "Saudi Arabia" = "KAPSARC",
  "Singapore"    = "Nanyang|^NUS$",
  "South Korea"  = "KDI",
  "Switzerland"  = "Bern",
  "Vietnam"      = "VNUHCM",
  "Zambia"       = "Zambia"
)
placements$country <- "United States"
for (ctry in names(country_patterns)) {
  hit <- grepl(country_patterns[[ctry]], placements$organization) &
    placements$country == "United States"
  placements$country[hit] <- ctry
}

dir.create