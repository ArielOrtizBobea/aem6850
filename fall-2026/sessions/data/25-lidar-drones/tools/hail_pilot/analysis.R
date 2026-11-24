suppressMessages({ library(data.table); library(fixest); library(terra) })
st <- c(8, 19, 20, 27, 31, 38, 46)
mon <- c(JAN=1, FEB=2, MAR=3, APR=4, MAY=5, JUN=6, JUL=7, AUG=8, SEP=9, OCT=10, NOV=11, DEC=12)
## counties, land area, population density
cty <- vect("counties_7states.gpkg")
cdt <- data.table(geoid = cty$GEOID, name = cty$NAME, st = cty$STUSPS, aland_km2 = cty$ALAND / 1e6)
pop <- fread("pop.csv", encoding = "Latin-1")[SUMLEV == 50]
pop[, geoid := sprintf("%02d%03d", STATE, COUNTY)]
cdt <- merge(cdt, pop[, .(geoid, pop = POPESTIMATE2023)], by = "geoid", all.x = TRUE)
cdt[, dens := pop / aland_km2]
cdt[, dens_q := cut(dens, quantile(dens, 0:5 / 5, na.rm = TRUE), include.lowest = TRUE, labels = paste0("Q", 1:5))]
## days the radar pipeline has processed
lg <- readLines("mesh_pipeline.log"); done <- as.Date(sub(" .*", "", lg[grepl(" ok", lg)]))
## Storm Events hail reports -> UTC -> convective day (12Z-12Z)
se <- rbindlist(lapply(list.files("se", full.names = TRUE), function(f)
  fread(cmd = paste("gunzip -c", shQuote(f)), select = c("EVENT_ID", "EVENT_TYPE", "STATE_FIPS", "CZ_TYPE", "CZ_FIPS", "BEGIN_DATE_TIME", "CZ_TIMEZONE", "MAGNITUDE", "BEGIN_LAT", "BEGIN_LON"))))
se <- se[EVENT_TYPE == "Hail" & STATE_FIPS %in% st & CZ_TYPE == "C"]
p <- tstrsplit(se$BEGIN_DATE_TIME, "[- :]")
se[, t_local := as.POSIXct(sprintf("%s-%02d-%s %s:%s:%s", 2000 + as.integer(p[[3]]), mon[p[[2]]], p[[1]], p[[4]], p[[5]], p[[6]]), tz = "UTC")]
se[, off := as.numeric(sub("^[A-Z]+", "", CZ_TIMEZONE))]
se[, cday := as.Date(t_local - off * 3600 - 12 * 3600)]
se[, geoid := sprintf("%02d%03d", STATE_FIPS, CZ_FIPS)]
se <- se[cday %in% done]
## radar county-days
m <- fread("mesh_county_day.csv", colClasses = c(geoid = "character")); m[, cday := as.Date(date)]; m <- m[cday %in% done]
## crop insurance, hail cause of loss (code 21), by county x year-of-loss x month-of-loss
rma <- rbindlist(lapply(list.files("rma", pattern = "txt$", full.names = TRUE), function(f) fread(f, sep = "|", header = FALSE, colClasses = "character", select = c(2, 4, 7, 12, 14, 16, 28, 29))))
setnames(rma, c("stc", "coc", "crop", "cause", "mo", "yr", "acres", "indem"))
rma <- rma[trimws(cause) == "21" & as.integer(stc) %in% st]
rma[, `:=`(geoid = paste0(stc, coc), yr = as.integer(yr), mo = as.integer(mo), indem = as.numeric(indem))]
rma_m <- rma[, .(indem = sum(indem)), by = .(geoid, yr, mo)]
cat(sprintf("days processed: %d | reports: %d | radar county-days: %d | hail indemnity rows: %d\n", length(done), nrow(se), nrow(m), nrow(rma)))

## 1. Does a report exist where the radar saw severe hail? county-days with >= 25 km2 of hail >= 1 inch
rep_cd <- se[, .(n_rep = .N, rep_max_in = max(MAGNITUDE, na.rm = TRUE)), by = .(geoid, cday)]
cd <- merge(m, rep_cd, by = c("geoid", "cday"), all = TRUE)
for (v in c("area_19mm", "area_25mm", "area_38mm", "area_51mm", "max_mm", "n_rep")) set(cd, which(is.na(cd[[v]])), v, 0)
cd <- merge(cd, cdt[, .(geoid, dens, dens_q, aland_km2)], by = "geoid")
big <- cd[area_25mm >= 25]
cat("\n== County-days where radar shows >= 25 km2 of hail >= 1 inch:", nrow(big), "\n")
print(big[, .(county_days = .N, share_with_report = round(mean(n_rep > 0), 2), median_density = round(median(dens), 1)), by = dens_q][order(dens_q)])
print(big[, .(county_days = .N, share_with_report = round(mean(n_rep > 0), 2)), by = .(radar_max = cut(max_mm, c(25.4, 38.1, 50.8, 76.2, 200), labels = c("1-1.5 in", "1.5-2 in", "2-3 in", ">3 in"), include.lowest = TRUE))][order(radar_max)])
cat("\n== County-days with a hail report: share where radar max >= 0.75 in:", round(cd[n_rep > 0, mean(max_mm >= 19.05)], 2), " | >= 1 in:", round(cd[n_rep > 0, mean(max_mm >= 25.4)], 2), "\n")

## 2. County-month panel: which tracks insured hail losses?
mm <- m[, .(a19 = sum(area_19mm), a25 = sum(area_25mm), a38 = sum(area_38mm), a51 = sum(area_51mm)), by = .(geoid, yr = year(cday), mo = month(cday))]
rm_ <- se[, .(nrep = .N, nrep1 = sum(MAGNITUDE >= 1, na.rm = TRUE)), by = .(geoid, yr = year(cday), mo = month(cday))]
ym <- unique(data.table(yr = year(done), mo = month(done)))
pan <- CJ(geoid = cdt$geoid, k = seq_len(nrow(ym))); pan[, `:=`(yr = ym$yr[k], mo = ym$mo[k])][, k := NULL]
pan <- Reduce(function(a, b) merge(a, b, by = c("geoid", "yr", "mo"), all.x = TRUE), list(pan, mm, rm_, rma_m))
for (v in c("a19", "a25", "a38", "a51", "nrep", "nrep1", "indem")) set(pan, which(is.na(pan[[v]])), v, 0)
pan <- merge(pan, cdt[, .(geoid, dens, dens_q, st)], by = "geoid")
pan[, `:=`(y = asinh(indem), xa = asinh(a25), xr = asinh(nrep))]
fA <- feols(y ~ xa | geoid + yr^mo, pan, cluster = ~geoid)
fB <- feols(y ~ xr | geoid + yr^mo, pan, cluster = ~geoid)
fC <- feols(y ~ xa + xr | geoid + yr^mo, pan, cluster = ~geoid)
cat("\n== County-month panel:", nrow(pan), "county-months,", uniqueN(pan$geoid), "counties\n")
etable(fA, fB, fC, fitstat = ~ n + wr2, digits = 3)
auc <- function(score, ylab) { r <- rank(score); n1 <- sum(ylab); n0 <- sum(!ylab); (sum(r[ylab]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
for (thr in c(1e4, 1e5)) { yl <- pan$indem > thr
  cat(sprintf("AUC for hail indemnity > $%s: radar area %.3f | report count %.3f | (n positive %d)\n", format(thr, big.mark = ","), auc(pan$a25, yl), auc(pan$nrep, yl), sum(yl))) }

## 3. Losses the report record does not see
tot <- pan[, sum(indem)]
cat(sprintf("\n== Hail indemnity, total $%.0f M | in county-months with no hail report: %.0f%% | of which radar saw hail >= 1 in: %.0f%%\n",
            tot / 1e6, 100 * pan[nrep == 0, sum(indem)] / tot, 100 * pan[nrep == 0 & a25 > 0, sum(indem)] / pan[nrep == 0, sum(indem)]))
print(pan[, .(indemnity_musd = round(sum(indem) / 1e6, 1), share_months_with_report = round(mean(nrep > 0), 2), radar_km2_ge1in = round(sum(a25))), by = dens_q][order(dens_q)])
fwrite(pan, "panel_county_month.csv"); fwrite(cd, "county_day.csv")
