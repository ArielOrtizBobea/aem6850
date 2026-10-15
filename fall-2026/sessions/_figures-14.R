# Diagrams for the session 14 page and slides (APIs). Base R, plus jsonlite
# to read the saved replies the diagrams quote. Run from fall-2026/sessions:
#   Rscript _figures-14.R
# Writes figures/14-apis/D01-three-ways.png to D16-model-or-r.png.
# D09 is not drawn: the deck prints the saved model reply with a chunk.
# Numbers and fields come from data/14-apis/saved/, so a re-saved reply
# redraws with its own values.
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left)
# and drawn at res 200. The comment above each figure gives the width it was
# sized for on the 1050 x 700 slide; at that width its text prints at about
# 19 to 23 px, and its code at about the size of the deck's code blocks.

library(jsonlite)
sv  <- "data/14-apis/saved"
out <- "figures/14-apis"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

ink  <- "#222222"
acc  <- "#B31B1B"    # the one accent
grey <- "#666666"
rule <- "#BBBBBB"
fill <- "#F2F2F2"    # neutral box fill
tint <- "#F7E6E6"    # a light tint of the accent
mono <- if (file.exists("/System/Library/Fonts/Menlo.ttc")) "Menlo" else "mono"

# ---- Helpers ----
W <- H <- NA
open_d <- function(name, w, h) {
  W <<- w; H <<- h
  png(file.path(out, name), width = w, height = h, units = "in", res = 200,
      bg = "white", pointsize = 12)
  par(mar = c(0, 0, 0, 0), family = "sans", xpd = NA, col = ink, fg = ink,
      lend = 1, ljoin = 1)
  plot.new()
  plot.window(c(0, w), c(0, h), xaxs = "i", yaxs = "i")
}
close_d <- function() invisible(dev.off())

# text, with a warning when a label runs off the canvas
tx <- function(x, y, s, cex = 1.2, font = 1, col = ink, adj = c(0.5, 0.5),
               fam = "sans", ...) {
  text(x, y, s, cex = cex, font = font, col = col, adj = adj, family = fam, ...)
  wd <- strwidth(s, cex = cex, font = font, family = fam)
  ht <- strheight(s, cex = cex, font = font, family = fam)
  if (any(x - adj[1] * wd < 0 | x + (1 - adj[1]) * wd > W |
          y - adj[2] * ht < 0 | y + (1 - adj[2]) * ht > H))
    warning("off canvas: ", paste(s, collapse = " "), call. = FALSE)
  invisible(wd)
}
sw <- function(s, cex = 1.2, font = 1, fam = "sans")
  strwidth(s, cex = cex, font = font, family = fam)

# rounded rectangle
rbox <- function(x0, y0, x1, y1, r = 0.08, col = NA, border = ink, lwd = 2) {
  q <- seq(0, pi / 2, length.out = 12)
  polygon(c(x1 - r + r * cos(q), x0 + r - r * sin(q),
            x0 + r - r * cos(q), x1 - r + r * sin(q)),
          c(y1 - r + r * sin(q), y1 - r + r * cos(q),
            y0 + r - r * sin(q), y0 + r - r * cos(q)),
          col = col, border = border, lwd = lwd)
}

# arrow with a filled head
arr <- function(x0, y0, x1, y1, col = ink, lwd = 2.2, head = 0.14, wid = 0.065) {
  a <- atan2(y1 - y0, x1 - x0)
  xb <- x1 - head * cos(a); yb <- y1 - head * sin(a)
  segments(x0, y0, xb, yb, col = col, lwd = lwd)
  polygon(c(x1, xb + wid * sin(a), xb - wid * sin(a)),
          c(y1, yb - wid * cos(a), yb + wid * cos(a)), col = col, border = col)
}

# square bracket under (dir = -1) or over (dir = 1) a span, with a centre tick
brk <- function(x0, x1, y, dir = -1, h = 0.07, col = acc, lwd = 2) {
  segments(c(x0, x0, x1), c(y, y + dir * h, y), c(x0, x1, x1),
           c(y + dir * h, y + dir * h, y + dir * h), col = col, lwd = lwd)
  segments((x0 + x1) / 2, y + dir * h, (x0 + x1) / 2, y + dir * 2 * h,
           col = col, lwd = lwd)
}
# square bracket to the right of a block of lines
vbrk <- function(x, y0, y1, h = 0.07, col = acc, lwd = 2) {
  segments(c(x, x + h, x), c(y0, y0, y1), c(x + h, x + h, x + h),
           c(y0, y1, y1), col = col, lwd = lwd)
  segments(x + h, (y0 + y1) / 2, x + 2 * h, (y0 + y1) / 2, col = col, lwd = lwd)
}

# one line of monospace text drawn in coloured pieces; returns where each
# piece starts and ends, for the brackets and arrows
mono_pieces <- function(x, y, pieces, cols, cex = 1.2) {
  cw <- sw("M", cex = cex, fam = mono)            # one width for every character
  x0 <- x + cw * c(0, cumsum(nchar(pieces)))[seq_along(pieces)]
  x1 <- x0 + cw * nchar(pieces)
  for (i in seq_along(pieces))
    text(x0[i], y, pieces[i], adj = c(0, 0.5), cex = cex, family = mono,
         col = cols[i])
  if (max(x1) > W) warning("off canvas: ", paste(pieces, collapse = ""), call. = FALSE)
  data.frame(piece = pieces, x0 = x0, x1 = x1)
}

# ---- The saved replies the diagrams quote ----
wb   <- fromJSON(file.path(sv, "wb_2023_p1.json"), simplifyVector = FALSE)
info <- wb[[1]]                      # page information
eia1 <- fromJSON(file.path(sv, "eia_nyis_0.json"))
eia2 <- fromJSON(file.path(sv, "eia_nyis_5000.json"))
eia  <- rbind(eia1$response$data, eia2$response$data)
eia$demand <- as.numeric(eia$value)
eia  <- eia[substr(eia$period, 1, 4) == "2025", ]
peak <- eia[which.max(eia$demand), ]
peak_hour <- as.numeric(substr(peak$period, 12, 13))
mwh  <- format(peak$demand, big.mark = ",")
stopifnot(info$total == 266, peak$period == "2025-06-24T19-04", peak$demand == 31857)


# ---- D01. Three ways to the same series (slide 4; sized for about 940 px wide) ----
open_d("D01-three-ways.png", 9.6, 4.5)
lx <- c(1.85, 4.45, 7.05); lw <- 2.5; lc <- lx + lw / 2
rbox(1.85, 3.88, 9.55, 4.42, col = fill, border = ink, lwd = 1.5)
tx(5.7, 4.15, "One World Bank series: access to electricity (% of population)",
   cex = 1.15, font = 2)
for (i in 1:3) arr(lc[i], 3.88, lc[i], 3.53, lwd = 2)
for (i in 1:3)
  rbox(lx[i], 0.12, lx[i] + lw, 3.5, border = if (i == 2) acc else "#999999",
       lwd = if (i == 2) 3 else 1.5)
head <- c("Download a file", "Request it from an API", "Scrape a page")
how  <- c("click Download, then CSV,\non the series' web page",
          "a program sends a web\naddress, a reply comes back",
          "a program reads the page\nbuilt for people")
who  <- c("you", "your program", "your program")
what <- c("a file", "a structured reply\n(JSON)", "the page's HTML")
when <- c("one download", "repeated or\nmany requests", "no file and\nno API")
for (i in 1:3) {
  tx(lc[i], 3.2, head[i], cex = 1.15, font = 2, col = if (i == 2) acc else ink)
  tx(lc[i], 2.68, how[i], cex = 1.0, col = grey)
  segments(lx[i] + 0.12, c(2.28, 1.66, 1.04), lx[i] + lw - 0.12, col = rule, lwd = 1)
  tx(lc[i], 1.97, who[i], cex = 1.15)
  tx(lc[i], 1.35, what[i], cex = 1.15)
  tx(lc[i], 0.62, when[i], cex = 1.15)
}
tx(0.1, 1.97, "Who does\nthe work", cex = 1.05, font = 2, col = grey, adj = c(0, 0.5))
tx(0.1, 1.35, "What comes\nback", cex = 1.05, font = 2, col = grey, adj = c(0, 0.5))
tx(0.1, 0.62, "When it fits", cex = 1.05, font = 2, col = grey, adj = c(0, 0.5))
close_d()


# ---- D02. Akbar et al.: one trip at several departure times (slide 7, right column, about 300 px) ----
open_d("D02-akbar-trip.png", 2.9, 3.3)
rbox(0.08, 2.35, 2.82, 3.24, col = fill, border = NA)
tx(0.18, 3.1, "one trip in one city", cex = 1.0, adj = c(0, 0.5))
o <- c(0.5, 2.66); d <- c(2.4, 2.86)
bz <- function(t, p) (1 - t)^3 * p[1] + 3 * (1 - t)^2 * t * p[2] + 3 * (1 - t) * t^2 * p[3] + t^3 * p[4]
tt <- seq(0, 1, length.out = 80)
lines(bz(tt, c(o[1], 1.3, 1.5, d[1])), bz(tt, c(o[2], 2.55, 3.0, d[2])), lwd = 3)
points(o[1], o[2], pch = 21, bg = ink, col = ink, cex = 1.6)
points(d[1], d[2], pch = 21, bg = acc, col = acc, cex = 1.6)
tx(o[1], o[2] - 0.19, "origin", cex = 1.0)
tx(d[1], d[2] + 0.21, "destination", cex = 1.0, col = acc)
tx(1.45, 2.0, "requested at about\n21 departure times", cex = 1.05, font = 2)
yy <- c(1.55, 1.18, 0.81)
hrs <- c("depart 3:00", "depart 9:00", "depart 18:00")
for (k in seq_along(yy)) {
  rbox(0.08, yy[k] - 0.15, 1.3, yy[k] + 0.15, border = ink, lwd = 1.2)
  tx(0.69, yy[k], hrs[k], cex = 1.0)
  arr(1.34, yy[k], 1.58, yy[k], lwd = 1.8, head = 0.1, wid = 0.05)
  rbox(1.62, yy[k] - 0.15, 2.82, yy[k] + 0.15, border = acc, lwd = 1.2, col = tint)
  tx(2.22, yy[k], "minutes, km", cex = 1.0)
}
tx(c(0.69, 2.22), 0.56, "...", cex = 1.2, font = 2)
tx(1.45, 0.24, "2.7 million trips \u00d7 21 times\n= 57 million requests", cex = 1.0)
close_d()


# ---- D03. Fujiwara et al.: festival account to counts by county (slide 8, right column, about 300 px) ----
open_d("D03-fujiwara.png", 2.9, 3.3)
rbox(0.25, 2.93, 2.65, 3.25, col = fill, border = ink, lwd = 1.5)
tx(1.45, 3.09, "the festival's account", cex = 1.05)
arr(0.6, 2.93, 0.6, 2.6)
tx(0.73, 2.765, "Twitter's API", cex = 1.0, col = acc, font = 2, adj = c(0, 0.5))
rbox(0.1, 1.55, 2.8, 2.55, border = ink, lwd = 1.5)
tx(1.45, 2.36, "each follower's profile", cex = 1.05, font = 2)
segments(0.22, 2.2, 2.68, 2.2, col = rule, lwd = 1)
tx(0.22, 1.98, "join date", cex = 1.0, col = acc, font = 2, adj = c(0, 0.5))
tx(0.22, 1.72, "typed location", cex = 1.0, col = acc, font = 2, adj = c(0, 0.5))
tx(1.6, 1.98, "March 2007", cex = 1.0, adj = c(0, 0.5))
tx(1.6, 1.72, "free text", cex = 1.0, adj = c(0, 0.5))
arr(0.6, 1.55, 0.6, 1.22)
tx(0.73, 1.385, "location to county", cex = 1.0, col = acc, font = 2, adj = c(0, 0.5))
rbox(0.1, 0.05, 2.8, 1.17, col = fill, border = ink, lwd = 1.5)
tx(1.45, 0.99, "early users by county", cex = 1.05, font = 2)
bx <- seq(0.5, 2.18, length.out = 7); bh <- c(0.35, 0.6, 0.2, 0.75, 0.45, 0.3, 0.55)
rect(bx, 0.42, bx + 0.2, 0.42 + bh * 0.48, col = grey, border = NA)
segments(0.35, 0.42, 2.55, 0.42, col = ink, lwd = 1.2)
tx(1.45, 0.24, "illustration: one bar per county", cex = 0.9, col = grey)
close_d()


# ---- D04. A request and its reply (slide 10; about 940 px wide) ----
open_d("D04-request-reply.png", 9.6, 3.1)
rbox(0.12, 0.25, 1.85, 2.85, col = fill, border = ink, lwd = 1.5)
tx(0.985, 1.72, "your R\nsession", cex = 1.2, font = 2)
tx(0.985, 1.12, "(or your\nbrowser)", cex = 1.05, col = grey)
rbox(7.75, 0.25, 9.48, 2.85, col = fill, border = ink, lwd = 1.5)
tx(8.615, 1.72, "the server", cex = 1.2, font = 2)
tx(8.615, 1.3, "api.worldbank.org", cex = 0.85, fam = mono)
arr(1.95, 2.4, 7.65, 2.4, lwd = 2.5)
tx(4.8, 2.7, "request", cex = 1.2, font = 2, col = acc)
tx(4.8, 2.13, "GET https://api.worldbank.org/v2/country/IND/...", cex = 0.95, fam = mono)
tx(4.8, 1.92, "India's access to electricity, 2023", cex = 0.95, col = grey)
arr(7.65, 1.72, 1.95, 1.72, lwd = 2.5)
tx(4.8, 1.48, "reply", cex = 1.2, font = 2, col = acc)
rbox(2.15, 0.25, 7.45, 1.26, border = acc, lwd = 1.5)
lab <- c("status code", "headers", "body")
val <- c("200", "content-type: application/json",
         "[{\"page\":1,...},[{...\"value\":99.5...}]]")
yv  <- c(1.06, 0.76, 0.46)
for (k in 1:3) {
  tx(2.3, yv[k], lab[k], cex = 1.05, font = 2, adj = c(0, 0.5))
  tx(3.5, yv[k], val[k], cex = 0.9, fam = mono, adj = c(0, 0.5))
}
close_d()


# ---- D05. The parts of the World Bank request URL (slide 12; about 900 px wide) ----
# The India request students type in the browser.
url1 <- c("https://api.worldbank.org/v2", "/country/IND/indicator/EG.ELC.ACCS.ZS")
url2 <- c("?", "date=2023", "&", "format=json")
stopifnot(paste0(c(url1, url2), collapse = "") ==
  "https://api.worldbank.org/v2/country/IND/indicator/EG.ELC.ACCS.ZS?date=2023&format=json")
open_d("D05-url-parts.png", 8.4, 3.4)
cx <- 1.18
p1 <- mono_pieces(0.2, 2.55, url1, c(ink, ink), cex = cx)
brk(min(p1$x0), max(p1$x1), 2.78, dir = 1, col = acc)
tx(mean(range(p1$x0, p1$x1)), 3.13, "endpoint", cex = 1.2, font = 2, col = acc)
for (i in 1:2) brk(p1$x0[i] + 0.03, p1$x1[i] - 0.03, 2.32, dir = -1, col = grey)
tx(mean(c(p1$x0[1], p1$x1[1])), 1.95, "base address\nthe World Bank's API, version 2", cex = 1.0)
tx(mean(c(p1$x0[2], p1$x1[2])), 1.95, "path\none country (India), one series", cex = 1.0)
tx(0.2, 1.35, "the same URL continues", cex = 0.95, col = grey, adj = c(0, 0.5))
tx(3.0, 1.35, "?  starts the options      &  joins them", cex = 1.0, col = acc,
   font = 2, adj = c(0, 0.5))
p2 <- mono_pieces(0.2, 0.92, url2, ifelse(url2 %in% c("?", "&"), acc, ink), cex = cx)
prm  <- p2[!p2$piece %in% c("?", "&"), ]
plab <- c("the year", "the reply's format")
for (i in seq_len(nrow(prm))) {
  brk(prm$x0[i] + 0.02, prm$x1[i] - 0.02, 0.69, dir = -1, col = acc)
  tx(mean(c(prm$x0[i], prm$x1[i])), 0.35, plab[i], cex = 1.0)
}
close_d()


# ---- D06. The JSON reply and the row it becomes (slide 13; about 940 px wide) ----
# The reply to the India request in D05 (the browser request, S02). Its record
# is India's record in saved/wb_2023_p2.json; a request for one country and one
# year has one page of the default 50 rows, with total 1.
p2rec <- fromJSON(file.path(sv, "wb_2023_p2.json"), simplifyVector = FALSE)[[2]]
rec   <- Filter(function(r) r$countryiso3code == "IND", p2rec)[[1]]
ipg   <- list(page = 1, pages = 1, per_page = 50, total = 1,
              sourceid = info$sourceid, lastupdated = info$lastupdated)
stopifnot(rec$value == 99.5, rec$date == "2023")
js <- list(
  list("["),
  list(" {\"page\": ", ipg$page, ", \"pages\": ", ipg$pages,
       ", \"per_page\": ", ipg$per_page, ","),
  list("  \"total\": ", ipg$total, ", \"sourceid\": \"", ipg$sourceid, "\","),
  list("  \"lastupdated\": \"", ipg$lastupdated, "\"},"),
  list(" ["),
  list("  {\"indicator\": {\"id\": \"", rec$indicator$id, "\", \"value\":"),
  list("     \"", rec$indicator$value, "\"},"),
  list("   \"country\": {\"id\": \"", rec$country$id, "\","),
  list("     \"value\": ", "@", paste0("\"", rec$country$value, "\""), "},"),
  list("   \"countryiso3code\": ", "@", paste0("\"", rec$countryiso3code, "\""), ","),
  list("   \"date\": ", "@", paste0("\"", rec$date, "\""), ","),
  list("   \"value\": ", "@", format(rec$value, digits = 15), ","),
  list("   \"unit\": \"\", \"obs_status\": \"\", \"decimal\": ", rec$decimal, "}"),
  list(" ]"),
  list("]"))
open_d("D06-json-to-row.png", 10.0, 4.45)
jx <- 1.4; lh <- 0.262; y_top <- 4.0
yl <- function(k) y_top - (k - 1) * lh
ends <- numeric(0); right <- numeric(0)
for (k in seq_along(js)) {
  el <- vapply(js[[k]], as.character, "")
  hot <- which(el == "@") + 1                     # the piece after "@" maps to a column
  cols <- rep(ink, length(el)); cols[hot] <- acc
  keep <- el != "@"
  pc <- mono_pieces(jx, yl(k), el[keep], cols[keep], cex = 0.98)
  right[k] <- max(pc$x1)
  if (length(hot)) ends <- c(ends, pc$x1[match(el[hot], el[keep])])
}
# the reply's two parts
segments(1.25, yl(2) + 0.1, 1.25, yl(4) - 0.1, col = acc, lwd = 2.5)
tx(1.12, yl(3), "page\ninformation", cex = 1.0, col = acc, font = 2, adj = c(1, 0.5))
segments(1.25, yl(6) + 0.1, 1.25, yl(13) - 0.1, col = acc, lwd = 2.5)
tx(1.12, yl(9.5), "records\n(one here)", cex = 1.0, col = acc, font = 2, adj = c(1, 0.5))
# the row, above and to the right of the records
edges <- c(6.55, 7.95, 8.5, 9.02, 9.95)
cen <- (head(edges, -1) + tail(edges, -1)) / 2
stopifnot(edges[1] > max(right[1:8]) + 0.1)        # clear of the JSON above the mapped lines
tb0 <- 2.7; tb1 <- 3.8; th <- 3.47
rect(edges[1], tb0, edges[5], tb1, border = ink, lwd = 1.5)
segments(edges[1], th, edges[5], th, lwd = 1.2)
segments(edges[2:4], tb0, edges[2:4], tb1, col = rule, lwd = 1)
tx(cen, (th + tb1) / 2, c("country", "iso3", "year", "access"), cex = 1.0, font = 2)
vals <- c(sub(" and ", "\nand ", rec$country$value), rec$countryiso3code, rec$date,
          format(rec$value, digits = 7))           # as R prints it in the data frame
for (i in 1:4) tx(cen[i], (tb0 + th) / 2, vals[i], cex = 1.0, col = acc)
tx(mean(edges[c(1, 5)]), 4.27, "the row in a data frame", cex = 1.0, col = grey)
tx(mean(edges[c(1, 5)]), 4.02, "iso3: three-letter code; access: % of population",
   cex = 0.95, col = grey)
# elbow arrows: along each mapped line, then up into its column; none cross
for (i in 1:4) {
  yk <- yl(8 + i)
  segments(ends[i] + 0.06, yk, cen[i], yk, col = acc, lwd = 1.3, lty = 3)
  arr(cen[i], yk, cen[i], tb0, col = acc, lwd = 1.6, head = 0.11, wid = 0.05)
}
close_d()


# ---- D07. 266 rows in pages of 50 and of 100 (slide 15; about 940 px wide) ----
tot <- info$total
seg <- function(per) c(rep(per, tot %/% per), if (tot %% per) tot %% per)
open_d("D07-pages.png", 9.6, 2.95)
x0 <- 2.2; L <- 5.8; sc <- L / tot
bars <- list(seg(50), seg(100)); yb <- c(1.55, 0.25); bh <- 0.5
brk(x0, x0 + L, 2.43, dir = 1, col = acc)
tx(x0 + L / 2, 2.77, paste0("\"total\": ", tot, " rows"), cex = 1.15, font = 2, col = acc)
for (b in 1:2) {
  s <- bars[[b]]; e <- x0 + cumsum(s) * sc; st <- c(x0, head(e, -1))
  part <- s < max(s)
  rect(st, yb[b], e, yb[b] + bh, col = ifelse(part, tint, fill), border = ink, lwd = 1.5)
  tx((st + e) / 2, yb[b] + bh / 2, s, cex = 1.1)
  for (i in seq_along(s))
    tx((st[i] + e[i]) / 2, yb[b] + bh + 0.17, paste("page", i), cex = 0.95, col = grey)
  tx(8.2, yb[b] + bh / 2, paste(length(s), "requests"), cex = 1.15, font = 2,
     adj = c(0, 0.5))
}
tx(2.0, yb[1] + bh / 2 + 0.11, "per_page=50", cex = 1.0, fam = mono, adj = c(1, 0.5))
tx(2.0, yb[1] + bh / 2 - 0.15, "the default", cex = 0.95, col = grey, adj = c(1, 0.5))
tx(2.0, yb[2] + bh / 2, "per_page=100", cex = 1.0, fam = mono, adj = c(1, 0.5))
close_d()


# ---- D08. The key: from ~/.Renviron to the request (slide 30; about 940 px wide) ----
open_d("D08-renviron.png", 9.8, 2.05)
bxs <- list(c(0.1, 2.25), c(2.6, 4.4), c(4.75, 7.3), c(7.65, 9.7)); yb0 <- 0.15; yb1 <- 1.9
for (k in 1:4) rbox(bxs[[k]][1], yb0, bxs[[k]][2], yb1, col = if (k == 1) "white" else fill,
                    border = if (k %in% c(1, 4)) acc else ink, lwd = 1.5)
mid <- vapply(bxs, mean, 0)
segments(0.1, 1.5, 2.25, 1.5, col = acc, lwd = 1)
tx(mid[1], 1.7, "~/.Renviron", cex = 1.0, fam = mono, font = 2)
tx(0.25, 1.1, "EIA_KEY=...", cex = 1.0, fam = mono, adj = c(0, 0.5))
tx(mid[1], 0.55, "a file in your\nhome folder", cex = 0.95, col = grey)
tx(mid[2], 1.4, "R starts", cex = 1.15, font = 2)
tx(mid[2], 0.75, "and reads\nthe file", cex = 1.05, col = grey)
tx(mid[3], 1.4, "Sys.getenv(\"EIA_KEY\")", cex = 1.0, fam = mono)
tx(mid[3], 0.75, "the script holds\nonly the name", cex = 1.05, col = grey)
tx(mid[4], 1.4, "the request", cex = 1.15, font = 2)
tx(mid[4], 0.75, "carries the key\nas api_key", cex = 1.05, col = grey)
for (k in 1:3) arr(bxs[[k]][2] + 0.04, 1.05, bxs[[k + 1]][1] - 0.04, 1.05, lwd = 2.2,
                   head = 0.12, wid = 0.055)
close_d()


# ---- D10. The parts of the one-day EIA request URL (slide 31; about 700 px wide) ----
eia_lines <- c("https://api.eia.gov/v2/electricity/rto/region-data/data/",
               "?api_key=YOUR_KEY", "&frequency=local-hourly", "&data[0]=value",
               "&facets[respondent][]=NYIS", "&facets[type][]=D",
               "&start=2025-06-24T00-04", "&end=2025-06-24T23-04",
               "&sort[0][column]=period", "&sort[0][direction]=asc")
stopifnot(paste0(eia_lines, collapse = "") == paste0(
  "https://api.eia.gov/v2/electricity/rto/region-data/data/?api_key=YOUR_KEY",
  "&frequency=local-hourly&data[0]=value&facets[respondent][]=NYIS&facets[type][]=D",
  "&start=2025-06-24T00-04&end=2025-06-24T23-04&sort[0][column]=period",
  "&sort[0][direction]=asc"))
open_d("D10-eia-url.png", 6.4, 4.3)
cx <- 1.05; ex <- 0.2
ly <- c(3.55, 3.0 - (0:8) * 0.31)
e1 <- mono_pieces(ex, ly[1], eia_lines[1], ink, cex = cx)
brk(e1$x0, e1$x1, ly[1] + 0.2, dir = 1, col = acc)
tx((e1$x0 + e1$x1) / 2, ly[1] + 0.5, "endpoint: hourly data on the grid, by region",
   cex = 1.1, font = 2, col = acc)
for (k in 2:10) {
  s <- eia_lines[k]
  mono_pieces(ex, ly[k], c(substr(s, 1, 1), substring(s, 2)), c(acc, ink), cex = cx)
}
bx0 <- ex + sw(eia_lines[5], cex = cx, fam = mono) + 0.15
grp  <- list(2, 3, 4, 5:6, 7:8, 9:10)
glab <- c("your key goes here",
          "hours in New York time",
          "the column to return",
          "facets, the filters: New York's\ngrid (NYIS), demand (D)",
          "rows labelled 00 to 23\non 24 June 2025, New York\nsummer time (-04)",
          "sort by period, oldest first")
for (g in seq_along(grp)) {
  r <- range(ly[grp[[g]]])
  vbrk(bx0, r[1] - 0.12, r[2] + 0.12, col = acc)
  tx(bx0 + 0.25, mean(r), glab[g], cex = 1.0, adj = c(0, 0.5))
}
tx(ex, 0.12, "One address, split here before each & so the parts can be read.",
   cex = 0.95, col = grey, adj = c(0, 0.5))
close_d()


# ---- D11. The EIA reply as a tree (slide 33; about 800 px wide) ----
r1 <- eia1
leaf <- list(
  warnings = list(c("warning", paste0("\"", r1$warnings$warning, "\"")),
                  c("description", "at most 5,000 rows in JSON")),
  response = list(c("total", paste0("\"", r1$response$total, "\", text, not a number")),
                  c("dateFormat", "how the periods are written"),
                  c("frequency", paste0("\"", r1$response$frequency, "\"")),
                  c("data", paste0(format(nrow(r1$response$data), big.mark = ","),
                                   " rows, ", ncol(r1$response$data), " columns")),
                  c("description", "the series and its source")),
  request  = list(c("command", "the endpoint's path"),
                  c("params", "the parameters sent, without the key")))
hot <- c("warning", "total", "data")
open_d("D11-eia-tree.png", 8.6, 3.45)
n <- sum(lengths(leaf)); yy <- 3.25 - (seq_len(n) - 1) * 0.33
yy <- yy - c(0, 0, 0.12, 0.12, 0.12, 0.12, 0.12, 0.24, 0.24)
rbox(0.1, 1.38, 1.8, 2.12, col = fill, border = ink, lwd = 1.5)
tx(0.95, 1.86, "the reply", cex = 1.1, font = 2)
tx(0.95, 1.58, "eia_nyis_0.json", cex = 0.75, fam = mono, col = grey)
k <- 0
for (g in names(leaf)) {
  idx <- k + seq_along(leaf[[g]]); k <- max(idx)
  gy <- mean(yy[idx])
  segments(c(1.8, 2.15, 2.15), c(1.75, 1.75, gy), c(2.15, 2.15, 2.35), c(1.75, gy, gy), lwd = 1.5)
  tx(2.4, gy, g, cex = 1.05, fam = mono, font = 2, adj = c(0, 0.5),
     col = if (g %in% c("warnings", "response")) acc else ink)
  gx <- 2.4 + sw(g, cex = 1.05, font = 2, fam = mono) + 0.1
  segments(gx, gy, 3.75, gy, lwd = 1.2, col = grey)
  segments(3.75, min(yy[idx]), 3.75, max(yy[idx]), lwd = 1.2, col = grey)
  for (j in seq_along(idx)) {
    segments(3.75, yy[idx[j]], 3.9, yy[idx[j]], lwd = 1.2, col = grey)
    nm <- leaf[[g]][[j]][1]
    tx(3.95, yy[idx[j]], nm, cex = 1.0, fam = mono, adj = c(0, 0.5),
       col = if (nm %in% hot) acc else ink, font = if (nm %in% hot) 2 else 1)
    tx(5.6, yy[idx[j]], leaf[[g]][[j]][2], cex = 1.0, col = grey, adj = c(0, 0.5))
  }
}
close_d()


# ---- D12. One hour, labelled by its end and by its start (slide 35; about 940 px wide) ----
open_d("D12-hour-ending.png", 9.6, 2.3)
h0 <- 14; h1 <- 21; ax0 <- 0.9; ax1 <- 9.3
hx <- function(h) ax0 + (h - h0) / (h1 - h0) * (ax1 - ax0)
ya <- 0.62; bt <- ya + 0.42
segments(hx(h0), ya, hx(h1), ya, lwd = 1.8)
segments(hx(h0:h1), ya, hx(h0:h1), ya - 0.08, lwd = 1.5)
tx(hx(h0:h1), ya - 0.27, sprintf("%d:00", h0:h1), cex = 1.0, col = grey)
tx(hx(h1), ya + 0.22, "24 June 2025, New York time", cex = 0.95, col = grey, adj = c(1, 0.5))
rect(hx(peak_hour - 1), ya, hx(peak_hour), bt, col = tint, border = acc, lwd = 2)
# the EIA labels the hour by its end
y_e <- 2.0
segments(hx(peak_hour), bt, hx(peak_hour), y_e, col = acc, lwd = 1.5, lty = 2)
tx(hx(peak_hour) - 0.1, y_e,
   paste0("EIA row ", peak$period, ": the hour ending at ", peak_hour, ":00, ", mwh, " MWh"),
   cex = 1.05, adj = c(1, 0.5), col = acc)
# NYSRC labels the same hour by its start
y_n <- 1.48
segments(hx(peak_hour - 1), bt, hx(peak_hour - 1), y_n, col = ink, lwd = 1.5, lty = 2)
tx(hx(peak_hour - 1) - 0.1, y_n,
   paste0("NYSRC: the hour beginning at ", peak_hour - 1, ":00, ", mwh, " MW"),
   cex = 1.05, adj = c(1, 0.5))
close_d()


# ---- D13. Script, saved replies, table (slide 6, beside the list, about 300 px wide) ----
open_d("D13-script-flow.png", 2.9, 4.4)
yb <- list(c(3.3, 4.25), c(1.8, 2.75), c(0.3, 1.25))
ttl <- c("the script", "the saved replies", "the table")
sub <- c("asks for a series,\nplaces and years", "each reply as it\narrived, on disk",
         "one row per country\nand year")
for (k in 1:3) {
  rbox(0.15, yb[[k]][1], 2.75, yb[[k]][2], col = if (k == 2) tint else fill,
       border = if (k == 2) acc else ink, lwd = 1.5)
  tx(1.45, yb[[k]][2] - 0.22, ttl[k], cex = 1.15, font = 2)
  tx(1.45, yb[[k]][1] + 0.3, sub[k], cex = 1.0, col = grey)
}
arr(1.45, 3.3, 1.45, 2.8); arr(1.45, 1.8, 1.45, 1.3)
close_d()


# ---- D14. Getting a model key, step by step (slides 38-39; about 960 px wide) ----
open_d("D14-console-steps.png", 10.2, 2.6)
bw <- c(2.15, 1.6, 1.6, 1.6, 1.6); gap <- 0.3
bx0 <- 0.3 + c(0, cumsum(bw + gap))[1:5]; bx1 <- bx0 + bw
ttl <- c("Sign in", "Billing", "API keys", "Copy the key", "~/.Renviron")
sub <- c("", "add credits,\nset a spend limit", "Create key,\nname it",
         "shown only once,\nstarts sk-ant-", "paste it in,\nthen restart R")
yb0 <- 0.12; yb1 <- 1.62
for (k in 1:5) {
  rbox(bx0[k], yb0, bx1[k], yb1, col = if (k == 5) tint else fill,
       border = if (k == 5) acc else ink, lwd = 1.5)
  symbols(bx0[k], yb1, circles = 0.17, inches = FALSE, add = TRUE, bg = acc, fg = acc)
  tx(bx0[k], yb1, k, cex = 1.0, font = 2, col = "white")
  tx((bx0[k] + bx1[k]) / 2, 1.25, ttl[k], cex = if (k == 5) 1.05 else 1.15, font = 2,
     fam = if (k == 5) mono else "sans")
  if (k == 1) {
    tx((bx0[k] + bx1[k]) / 2, 0.8, "or create an account", cex = 1.0, col = grey)
    tx((bx0[k] + bx1[k]) / 2, 0.42, "platform.claude.com", cex = 0.9, fam = mono)
  } else {
    tx((bx0[k] + bx1[k]) / 2, 0.62, sub[k], cex = 1.0, col = grey)
  }
  if (k < 5) arr(bx1[k] + 0.03, 0.87, bx0[k + 1] - 0.03, 0.87, lwd = 2, head = 0.11, wid = 0.05)
}
brk(bx0[1], bx1[4], 2.0, dir = 1, col = grey)
tx((bx0[1] + bx1[4]) / 2, 2.35, "in the browser, on the provider's developer console",
   cex = 1.0, col = grey)
brk(bx0[5], bx1[5], 2.0, dir = 1, col = acc)
tx((bx0[5] + bx1[5]) / 2, 2.35, "on your computer", cex = 1.0, col = acc, font = 2)
close_d()


# ---- D15. The ~/.Renviron file in an editor, placeholders only (slide 40; about 600 px wide) ----
open_d("D15-renviron-editor.png", 6.6, 2.2)
pl <- 0.1; pr <- 4.45; pt <- 2.08; pb <- 0.12; tb <- 1.7
rect(pl, pb, pr, pt, col = "white", border = ink, lwd = 1.5)
rect(pl, tb, pr, pt, col = fill, border = ink, lwd = 1.5)
tx(pl + 0.15, (tb + pt) / 2, "~/.Renviron", cex = 1.0, fam = mono, font = 2, adj = c(0, 0.5))
rect(pl, pb, pl + 0.42, tb, col = "#F8F8F8", border = NA)
segments(pl + 0.42, pb, pl + 0.42, tb, col = rule, lwd = 1)
rect(pl, pb, pr, tb, border = ink, lwd = 1.5)
lns <- c("EIA_KEY=xxxxxxxx", "ANTHROPIC_API_KEY=sk-ant-xxxxxxxx", "")
yl5 <- c(1.38, 0.98, 0.58)
for (k in 1:3) {
  tx(pl + 0.3, yl5[k], k, cex = 0.95, fam = mono, col = grey, adj = c(1, 0.5))
  if (nchar(lns[k])) tx(pl + 0.55, yl5[k], lns[k], cex = 1.0, fam = mono, adj = c(0, 0.5))
}
note <- c("your EIA key", "the line you add", "an empty last line")
for (k in 1:3) {
  arr(pr + 0.55, yl5[k], pr + 0.1, yl5[k], col = acc, lwd = 1.5, head = 0.1, wid = 0.045)
  tx(pr + 0.62, yl5[k], note[k], cex = 1.0, col = acc, adj = c(0, 0.5))
}
close_d()

# ---- D16. A model called from R, and a model that writes R (Part 5, last slide; about 880 px wide) ----
# Each lane: who calls whom. The model's box carries the accent in both.
open_d("D16-model-or-r.png", 9.8, 2.85)
bw <- 2.0; gp <- 0.8; bx0 <- 2.1 + c(0, bw + gp, 2 * (bw + gp)); bx1 <- bx0 + bw
lanes <- list(
  list(y = 2.08, head = "Call a model\nfrom R", foot = "each item needs reading",
       box = c("your R script", "the model", "labels, as data"),
       sub = c("one instruction and\nthe list of items", "labels each item,\nthrough its API",
               "saved, compared\nwith a reference"),
       arrow = c("prompt", "reply"), model = 2),
  list(y = 0.66, head = "Have a model\nwrite R", foot = "a rule gives the answer",
       box = c("the model", "R code", "the exact answer"),
       sub = c("a chat assistant or\na coding agent", "you read it\nand keep it",
               "a maximum, a sum,\na regression, a figure"),
       arrow = c("writes", "runs in R"), model = 1))
segments(0.1, 1.37, 9.7, 1.37, col = rule, lwd = 1)
for (L in lanes) {
  y0 <- L$y - 0.56; y1 <- L$y + 0.56
  tx(0.12, L$y + 0.16, L$head, cex = 1.15, font = 2, adj = c(0, 0.5))
  tx(0.12, L$y - 0.42, L$foot, cex = 1.0, col = grey, adj = c(0, 0.5))
  for (k in 1:3) {
    m <- k == L$model
    rbox(bx0[k], y0, bx1[k], y1, col = if (m) tint else if (k == 3) "white" else fill,
         border = if (m) acc else ink, lwd = if (m) 2 else 1.5)
    tx((bx0[k] + bx1[k]) / 2, L$y + 0.28, L$box[k], cex = 1.1, font = 2,
       col = if (m) acc else ink)
    tx((bx0[k] + bx1[k]) / 2, L$y - 0.18, L$sub[k], cex = 1.0, col = grey)
  }
  for (k in 1:2) {
    arr(bx1[k] + 0.05, L$y - 0.08, bx0[k + 1] - 0.05, L$y - 0.08, lwd = 2, head = 0.11, wid = 0.05)
    tx((bx1[k] + bx0[k + 1]) / 2, L$y + 0.14, L$arrow[k], cex = 0.92, col = grey)
  }
}
close_d()

cat("Wrote", length(list.files(out, "^D[0-9]{2}-.*\\.png$")), "diagrams to", out, "\n")
