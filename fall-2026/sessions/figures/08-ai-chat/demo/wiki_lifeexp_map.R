# wiki_lifeexp_map.R: life expectancy by country from Wikipedia, drawn as a
# world map. Reads the CIA World Factbook (2024) table on the page
# "List of countries by life expectancy"; writes output/lifeexp_map.png and
# output/lifeexp_wikipedia.csv. Packages: rvest (the page), maps (the map).

library(rvest)
library(maps)

URL <- "https://en.wikipedia.org/wiki/List_of_countries_by_life_expectancy"
CAPTION_STARTS <- "CIA World Factbook"

# 1) The table --------------------------------------------------------------
page <- read_html(URL)
tables <- html_elements(page, "table.wikitable")
captions <- sapply(tables, function(t) html_text2(html_element(t, "caption")))
pick <- which(startsWith(captions, CAPTION_STARTS))
stopifnot(length(pick) == 1)
tab <- html_table(tables[[pick]], fill = TRUE)
tab <- as.data.frame(tab)
names(tab)[1:2] <- c("country", "life_exp")
tab$country  <- gsub("\\[.*?\\]", "", tab$country)      # footnote marks
tab$country  <- trimws(tab$country)
tab$life_exp <- as.numeric(tab$life_exp)
tab <- tab[!is.na(tab$life_exp), c("country", "life_exp")]
tab <- tab[!grepl("^(World|European Union)", tab$country), ]   # aggregate rows
stopifnot(nrow(tab) > 150, all(tab$life_exp > 40 & tab$life_exp < 95))
cat(nrow(tab), "countries; range", range(tab$life_exp), "\n")

dir.create("output", showWarnings = FALSE)
write.csv(tab, "output/lifeexp_wikipedia.csv", row.names = FALSE,
          fileEncoding = "UTF-8")

# 2) Match names to the maps package ----------------------------------------
fix <- c("United States" = "USA", "United Kingdom" = "UK",
         "Czechia" = "Czech Republic", "Burma" = "Myanmar",
         "Korea, South" = "South Korea", "Korea, North" = "North Korea",
         "Congo (Kinshasa)" = "Democratic Republic of the Congo",
         "Congo (Brazzaville)" = "Republic of Congo",
         "C\u00f4te d\u2019Ivoire" = "Ivory Coast", "Eswatini" = "Swaziland",
         "Bahamas, The" = "Bahamas", "Gambia, The" = "Gambia",
         "Turkey (Turkiye)" = "Turkey", "Cabo Verde" = "Cape Verde",
         "Timor-Leste" = "Timor-Leste",
         "Micronesia, Federated States of" = "Micronesia")
hit <- tab$country %in% names(fix)
tab$region <- tab$country
tab$region[hit] <- fix[tab$country[hit]]

regions <- map("world", plot = FALSE)$names
regions <- sub(":.*$", "", regions)          # "France:Corsica" -> "France"
matched <- tab$region %in% regions
cat(sum(matched), "of", nrow(tab), "matched to the map;",
    "unmatched:", paste(head(tab$country[!matched], 12), collapse = ", "), "\n")

# 3) The map ----------------------------------------------------------------
breaks <- c(50, 60, 65, 70, 75, 80, 90)
pal <- hcl.colors(length(breaks) - 1, "YlGnBu", rev = TRUE)
tab$bin <- cut(tab$life_exp, breaks, right = FALSE)

polys <- map("world", plot = FALSE)$names
poly_region <- sub(":.*$", "", polys)
col <- pal[tab$bin[match(poly_region, tab$region)]]
col[is.na(col)] <- "grey85"

png("output/lifeexp_map.png", width = 2400, height = 1300, res = 200)
par(mar = c(0, 0, 2, 0))
map("world", fill = TRUE, col = col, border = "white", lwd = 0.3)
title("Life expectancy at birth, 2024 (CIA World Factbook via Wikipedia)")
legend("bottomleft", legend = levels(tab$bin), fill = pal, bty = "n",
       title = "years", cex = 1.1, inset = c(0.02, 0.05))
dev.off()
cat("wrote output/lifeexp_map.png\n")
