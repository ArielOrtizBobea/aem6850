# =============================================================
# AEM 6850 - Session 18: Documents & scans
# Master file. Runs every script, in the order the lecture uses them.
#
# Open 18-documents.Rproj first. It sits at the project root, so the
# working directory is 18-documents/ and every path below is relative to it.
#
#   source("code/run_everything.R")     from the R console
#   Rscript code/run_everything.R       from a terminal, run in 18-documents/
#
# 1_fed_table6.R      part 2: Table 6 of the Fed's H.4.1 from its text layer
# 2_ocr_runs.R        part 3: tesseract and the archive's OCR on the 1899 page
# 3_model_1899.R      part 3: a vision model on the 1899 page
# 4_model_sheets.R    part 4: a vision model on the five rainfall sheets
# 5_sheets_to_csv.R   part 4: the volunteers' and the model's readings as long tables
# 6_compare_sheets.R  part 4: the model against the volunteers, cell by cell
# 7_model_sizes.R     part 5: the same pages read by a smaller and a larger model
# 8_compare_sizes.R   part 5: cells right by model size
#
# Scripts 3, 4 and 7 call a model only for a reply missing from replies/,
# so with the folder as shipped they make no call and need no API key.
# Script 2 runs tesseract on six page images and takes a minute or two.
# =============================================================

  rm(list = ls())

  source("code/1_fed_table6.R")
  source("code/2_ocr_runs.R")
  source("code/3_model_1899.R")
  source("code/4_model_sheets.R")
  source("code/5_sheets_to_csv.R")
  source("code/6_compare_sheets.R")
  source("code/7_model_sizes.R")
  source("code/8_compare_sizes.R")
