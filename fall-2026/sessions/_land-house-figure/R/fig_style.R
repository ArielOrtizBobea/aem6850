# Journal styles for figures. Widths, fonts, text sizes, line weights and
# panel letters come from a spec file in specs/, so one figure script
# draws for any journal that has a spec.

library(yaml)

# Reads specs/<journal>.yml and keeps the values of the rules.
read_spec <- function(journal) {
  r <- read_yaml(file.path("specs", paste0(journal, ".yml")))
  list(journal  = journal,
       width_mm = r$width_mm$value,
       font     = r$font$value,
       text_pt  = r$text_pt$value,
       label    = r$panel_label$value,
       line_pt  = r$line_pt$value,
       panels   = r$file$value$panels)
}

# On R's PDF devices, lwd = 1 is 1/96 inch, which is 0.75 pt.
pt_to_lwd <- function(pt) pt / 0.75

# Two line weights inside the journal's range.
line_lwd <- function(spec, weight = "thin") {
  pt <- if (weight == "thin") 1.2 * spec$line_pt$min else
          mean(c(spec$line_pt$min, spec$line_pt$max))
  pt_to_lwd(pt)
}

# Tick labels and legends sit one point below the largest text.
cex_small <- function(spec) (spec$text_pt$max - 1) / spec$text_pt$max

# Opens a PDF at the journal's width, with its font, its largest text size
# as the base size, and axis lines at the thin weight.
open_fig <- function(path, spec, width, height_mm) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  cairo_pdf(path, width = spec$width_mm[[width]] / 25.4,
            height = height_mm / 25.4,
            pointsize = spec$text_pt$max, family = spec$font)
  par(las = 1, mgp = c(1.5, 0.4, 0), tcl = -0.3, lwd = line_lwd(spec))
  invisible(path)
}

# Nature: a bold lowercase letter at the top left of the panel.
# AER: "Panel A." before the panel title; the letter is also in the file name.
draw_panel_title <- function(letter, title, spec, at = par("usr")[1]) {
  if (spec$label$placement == "inside") {
    mtext(title, side = 3, line = 0.4)
    mtext(letter, side = 3, line = 0.4, adj = 0, at = at, font = 2,
          cex = spec$label$pt / spec$text_pt$max)
  } else {
    mtext(paste0("Panel ", toupper(letter), ". ", title), side = 3,
          line = 0.4)
  }
}
