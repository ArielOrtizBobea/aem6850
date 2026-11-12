# AEM 6850, session 22. Tool, run before class: the 2024 street panoramas of Ithaca, NY,
# from Mapillary (CC BY-SA 4.0), thinned to one every 20 m or more along each drive.
# Needs a free Mapillary client token in ~/.Renviron as MAPILLARY_TOKEN. Students do not run it.
#   Rscript tools/pull_ithaca.R        from the 22-photos-ii folder
want <- c("httr2", "jsonlite"); need <- setdiff(want, rownames(installed.packages()))
if (length(need)) install.packages(need, repos = "https://cloud.r-project.org")
library(httr2); library(jsonlite)
readRenviron("~/.Renviron"); tok <- Sys.getenv("MAPILLARY_TOKEN"); stopifnot(nzchar(tok))
dir.create("data/ithaca/mapillary", recursive = TRUE, showWarnings = FALSE); dir.create("data/ithaca/panoramas", showWarnings = FALSE)
# the city as a grid of small boxes: the API answers a small box with every photo in it
lons <- seq(-76.520, -76.470, by = 0.005); lats <- seq(42.430, 42.460, by = 0.005)
rows <- list()
for (i in seq_len(length(lons) - 1)) for (j in seq_len(length(lats) - 1)) {
  f <- sprintf("data/ithaca/mapillary/cell_%02d_%02d.json", i, j)
  if (!file.exists(f)) {
    r <- request("https://graph.mapillary.com/images") |>
      req_headers(Authorization = paste("OAuth", tok)) |>
      req_url_query(fields = "id,captured_at,geometry,compass_angle,is_pano,sequence,creator,width,height",
                    bbox = paste(lons[i], lats[j], lons[i + 1], lats[j + 1], sep = ","), limit = 2000) |>
      req_retry(max_tries = 3) |> req_perform()
    writeLines(resp_body_string(r), f); Sys.sleep(0.3)
  }
  d <- fromJSON(f)$data
  if (length(d) && nrow(d)) rows[[length(rows) + 1]] <- data.frame(id = d$id, t = d$captured_at,
    lon = sapply(d$geometry$coordinates, `[`, 1), lat = sapply(d$geometry$coordinates, `[`, 2),
    heading = d$compass_angle, pano = d$is_pano, sequence = d$sequence, contributor = d$creator$username, width = d$width, height = d$height)
}
all <- do.call(rbind, rows); all <- all[!duplicated(all$id), ]
all$taken <- as.POSIXct(all$t / 1000, origin = "1970-01-01", tz = "America/New_York")
p <- all[all$pano & format(all$taken, "%Y") == "2024", ]; p <- p[order(p$sequence, p$t), ]
# thin: along each drive keep a panorama only when it is 20 m or more from the last one kept
metres <- function(lon1, lat1, lon2, lat2) sqrt(((lon2 - lon1) * 111320 * cos(lat1 * pi / 180))^2 + ((lat2 - lat1) * 110540)^2)
keep <- logical(nrow(p)); last <- NA
for (k in seq_len(nrow(p))) {
  if (is.na(last) || p$sequence[k] != p$sequence[last] || metres(p$lon[last], p$lat[last], p$lon[k], p$lat[k]) >= 20) { keep[k] <- TRUE; last <- k }
}
p <- p[keep, ]; p$file <- paste0(p$id, ".jpg"); p$date <- format(p$taken, "%Y-%m-%d"); p$time <- format(p$taken, "%H:%M")
cat("photos listed:", nrow(all), "| 2024 panoramas:", sum(all$pano & format(all$taken, "%Y") == "2024"), "| kept after thinning:", nrow(p), "\n"); print(table(p$date))
for (k in seq_len(nrow(p))) {
  out <- file.path("data/ithaca/panoramas", p$file[k]); if (file.exists(out) && file.size(out) > 50000) next
  u <- request(paste0("https://graph.mapillary.com/", p$id[k])) |> req_headers(Authorization = paste("OAuth", tok)) |>
    req_url_query(fields = "thumb_original_url") |> req_retry(max_tries = 3) |> req_perform() |> resp_body_json()
  tryCatch(download.file(u$thumb_original_url, out, quiet = TRUE, mode = "wb"), error = function(e) cat("failed", p$id[k], "\n"))
  if (k %% 25 == 0) cat(k, "of", nrow(p), format(Sys.time(), "%H:%M:%S"), "\n")
}
p$have <- file.exists(file.path("data/ithaca/panoramas", p$file))
write.csv(p[p$have, c("id", "file", "date", "time", "lon", "lat", "heading", "sequence", "contributor", "width", "height")],
          "data/ithaca/panoramas.csv", row.names = FALSE)
cat("panoramas saved:", sum(p$have), "of", nrow(p), "\n")
