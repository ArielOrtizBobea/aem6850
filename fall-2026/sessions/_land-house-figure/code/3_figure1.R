# Draws Figure 1 for the journal named at the top. Sizes, fonts, text
# sizes, line weights and panel labels come from specs/<journal>.yml
# through R/fig_style.R.
#   a. Real farmland value per acre in 2022 as a multiple of 1940, by county
#   b. Real median value of an owner-occupied home, 2022 as a multiple of 1940
#   c. The two multiples against each other, one point per county

library(maps)
library(mapproj)
source("R/fig_style.R")

# 1). Parameters ----
journal <- "nature"                    # "nature" or "aer"
spec <- read_spec(journal)

misc <- list(
  breaks   = c(2, 4, 8, 16),           # each class doubles
  labels   = c("< 2", "2–4", "4–8", "8–16", "> 16"),
  proj     = "albers",
  proj_par = c(29.5, 45.5)
)
col <- list(
  # Blue to red through green, yellow and orange (ColorBrewer hues). Their
  # lightness, CIE L* 49, 70, 90, 62 and 34, keeps them apart in gray.
  classes   = c("#4575B4", "#66BD63", "#FEE08B", "#F46D43", "#A50026"),
  no_data   = "white",
  no_data_border = "grey50",           # outline of the No data key box
  points    = adjustcolor("grey40", alpha.f = 0.35),
  beyond    = "black"                  # counties outside the axis range
)
title <- c(a = "Change in real farmland value per acre, 1940–2022",
           b = "Change in real median home value, 1940–2022",
           c = "Both changes, by county")

# 2). Data ----
d <- readRDS("data_clean/counties.rds")
both <- d[!is.na(d$land_ratio) & !is.na(d$house_ratio), ]

# 3). Panels ----
draw_county_map <- function(ratio, letter) {
  poly <- map("county", plot = FALSE, namesonly = TRUE)
  fips <- sprintf("%05d", county.fips$fips[match(poly, county.fips$polyname)])
  cls  <- findInterval(ratio[match(fips, d$fips)], misc$breaks) + 1
  fill <- col$classes[cls]
  fill[is.na(fill)] <- col$no_data
  map("county", projection = misc$proj, parameters = misc$proj_par,
      fill = TRUE, col = fill, border = fill,           # border hides seams
      lwd = pt_to_lwd(spec$line_pt$min), mar = par("mar"))
  map("state", add = TRUE, projection = misc$proj,
      parameters = misc$proj_par,
      orientation = .Last.projection()$orientation,    # same centre
      boundary = FALSE, col = "white", lwd = line_lwd(spec))
  draw_panel_title(letter, title[[letter]], spec)
}

draw_legend <- function() {
  plot.new()
  legend("center", horiz = TRUE, bty = "n", cex = cex_small(spec),
         fill = c(col$classes, col$no_data),
         border = c(rep(NA, length(col$classes)), col$no_data_border),
         legend = c(misc$labels, "No data"), x.intersp = 0.5,
         title = "Real value in 2022 as a multiple of 1940")
}

draw_scatter <- function(letter) {
  # Both axes on a log scale from 1 to 64. Counties beyond either range are
  # drawn at its edge as open triangles.
  x <- log(both$house_ratio)
  y <- log(both$land_ratio)
  lim <- log(c(1, 64))
  out <- x < lim[1] | x > lim[2] | y < lim[1] | y > lim[2]
  xc  <- pmin(pmax(x, lim[1]), lim[2])
  yc  <- pmin(pmax(y, lim[1]), lim[2])
  plot(xc[!out], yc[!out], pch = 16, cex = 0.3, col = col$points,
       axes = FALSE, xlab = "", ylab = "", xlim = lim, ylim = lim)
  points(xc[out], yc[out], pch = 2, cex = 0.5, col = col$beyond)
  # Means of y in 20 bins of x with equal counts
  cuts <- sort(x)[round(seq(1, length(x), length.out = 21))]
  bin  <- findInterval(x, cuts, rightmost.closed = TRUE, all.inside = TRUE)
  points(tapply(x, bin, mean), tapply(yc, bin, mean), pch = 16, cex = 0.6)
  tk <- c(1, 2, 4, 8, 16, 32, 64)
  axis(1, at = log(tk), labels = tk, cex.axis = cex_small(spec))
  axis(2, at = log(tk), labels = tk, cex.axis = cex_small(spec))
  # Labels on two lines, name then unit, so they fit the panel
  mtext("Real median home value\n(multiple of 1940, log scale)",
        side = 1, line = 0.6, padj = 1)
  mtext("Real farmland value per acre\n(multiple of 1940, log scale)",
        side = 2, line = 1.9, padj = 0, las = 0)
  draw_panel_title(letter, title[[letter]], spec,
                   at = par("usr")[1] - 0.25 * diff(par("usr")[1:2]))
  # Raised so the key clears the triangles on the bottom edge
  legend("bottomright", inset = c(0, 0.07), bty = "n", cex = cex_small(spec),
         pch = c(16, 16, 2),
         pt.cex = c(0.5, 0.6, 0.5), col = c(col$points, "black", col$beyond),
         legend = c(sprintf("County (%s)", format(nrow(both), big.mark = ",")),
                    "Mean in 20 bins",
                    sprintf("Outside axis range (%d)", sum(out))))
}

map_margins     <- c(0.2, 0.4, 1.6, 0.4)
scatter_margins <- c(3.6, 4.0, 1.6, 0.6)

# 4). Figure 1 ----
if (spec$panels == "one file") {
  # All three panels in one file at double-column width
  open_fig(sprintf("figures/%s/figure1.pdf", journal), spec, "double", 62)
  layout(matrix(c(1, 2, 3,
                  4, 4, 3), nrow = 2, byrow = TRUE),
         widths = c(1.3, 1.3, 1), heights = c(1, 0.16))
  par(cex = 1)                       # layout() with 3 columns sets cex to 0.66
  par(mar = map_margins)
  draw_county_map(d$land_ratio,  "a")
  draw_county_map(d$house_ratio, "b")
  par(mar = scatter_margins)
  draw_scatter("c")
  par(mar = c(0, 0, 0, 0))
  draw_legend()
  dev.off()
} else {
  # One file per panel, the letter in the file name
  for (letter in c("a", "b")) {
    open_fig(sprintf("figures/%s/Figure1%s.pdf", journal, letter), spec,
             "panel", 85)
    layout(matrix(1:2), heights = c(1, 0.16))
    par(mar = map_margins)
    draw_county_map(if (letter == "a") d$land_ratio else d$house_ratio,
                    letter)
    par(mar = c(0, 0, 0, 0))
    draw_legend()
    dev.off()
  }
  open_fig(sprintf("figures/%s/Figure1c.pdf", journal), spec, "panel", 90)
  par(mar = scatter_margins)
  draw_scatter("c")
  dev.off()
}
