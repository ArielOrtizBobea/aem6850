# Figure 1 as R draws it when nothing is set: the default device, panel
# layout, colours and class breaks.

library(maps)

d <- readRDS("data_clean/counties.rds")
poly <- map("county", plot = FALSE, namesonly = TRUE)
fips <- sprintf("%05d", county.fips$fips[match(poly, county.fips$polyname)])

dir.create("figures/default", showWarnings = FALSE, recursive = TRUE)
pdf("figures/default/figure1.pdf")
par(mfrow = c(1, 3))
map("county", fill = TRUE,
    col = heat.colors(6)[cut(d$land_ratio[match(fips, d$fips)], 6)])
title("Farmland")
map("county", fill = TRUE,
    col = heat.colors(6)[cut(d$house_ratio[match(fips, d$fips)], 6)])
title("Houses")
plot(d$house_ratio, d$land_ratio)
dev.off()
