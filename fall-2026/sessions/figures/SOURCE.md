# Figure provenance

Both PNGs were carried over from the instructor's AEM 7010 (Spring 2026)
intro deck (`aem7010/spring-2026/intro/slides/figures/`), which excerpted
them from the published papers below. Used in teaching with attribution;
captions on the session pages carry the citations.

- `trend1-methods.png` — Figure 2 of Daniel S. Hamermesh (2025), update to
  "Six Decades of Top Economics Publishing: Who and How?" (*Journal of
  Economic Literature* 2013, 51:1, 162-172; doi 10.1257/jel.51.1.162).
  Distribution of methodologies, 1963-2024, three leading US general
  economics journals.
- `trend6-ai.png` — Figure 3 of Alexander Bick, Adam Blandin, and David
  Deming (2024), "The Rapid Adoption of Generative AI," NBER Working Paper
  32966 (later published in *Management Science*, 2026). GenAI vs computer
  and internet adoption by years since first mass-market product; genAI
  data from the Real-Time Population Survey, Aug/Nov 2024 waves.
- `trend6-ai-chart.png` — same figure, notes block cropped off for the
  slide version (the page shows the full figure with notes).
- `la-fires-modis-20250110.jpg` / `la-fires-2025-annotated.jpg` — NASA
  Terra/MODIS, 2025-01-10, from NASA Earth Observatory "Smoke Streams from
  Palisades and Eaton Fires" (science.nasa.gov/earth/earth-observatory/
  smoke-streams-from-palisades-and-eaton-fires-153813). Public domain
  (NASA); annotated copy adds fire/city labels for the session-1 context
  slide.
- `Rlogo.svg` — the R logo, downloaded 2026-08-26 from
  https://www.r-project.org/logo/Rlogo.svg (724x561 viewBox, 2 KB).
  © The R Foundation, used unmodified under CC-BY-SA 4.0
  (https://creativecommons.org/licenses/by-sa/4.0/). The session-2 page
  carries the credit line and the licence link, as CC-BY-SA requires.

## 15-scraping/

- `D01-three-routes.png` … `D07-browser-agent.png` — drawn by
  `sessions/_figures-15.R` (base R) on 2026-10-18. D01 embeds three page
  thumbnails (S12, S13, S02 below); D05 embeds the rendered January 2024
  calendar row (S06-row) beside the row's real HTML from `data/15-scraping/cache/`;
  D07 embeds S01-calendar-2025-top and draws a run of the Claude desktop
  app's browser pane (its steps and its answer, as they happened).
- `S01-calendar.png`, `S01-calendar-2025-top.png`, `S02-statement-20220615*.png`,
  `S03-pressreleases-list.png`, `S06-row-2024-01-rendered.png`,
  `S06-statement-20081029.png`, `S01-disclaimer-copyright.png`,
  `S12-h15-page.png`, `S13-feed-raw.png` — federalreserve.gov pages captured
  with headless Chrome on 2026-10-18 (public domain; the Board's disclaimer
  asks for a citation, given on the session page).
- `S02-transcript-reporter.png` — three lines of the 31 January 2024
  press-conference transcript PDF (federalreserve.gov, public domain),
  rasterised with pdftoppm on 2026-10-18.
- `S04-zillow-robots.png` — zillow.com/robots.txt as a browser shows it,
  2026-10-18 (a plain-text file; quoted for comment).
- `S05-bls-sitemap.png` — bls.gov/sitemap.xml as a browser shows it,
  2026-10-18 (US government work).
- `S04-inspector.png`, `S05-network.png` — Chrome DevTools' Elements and
  Network panels on the Fed's calendar and press-release pages, captured
  2026-10-18 through headless Chrome's own DevTools frontend; S05 joins two
  parts of one panel with a dashed cut line.
- `S07-wiki-chairs-table-top.png` — the top of the table in the Wikipedia
  article "Chair of the Federal Reserve", 2026-10-18 (text CC BY-SA 4.0;
  portraits are Wikimedia Commons images in their own licences).
- `S08-wayback-calendar-2015.png` — web.archive.org showing its 2 January
  2015 capture of the Fed's calendar page with the archive's toolbar,
  captured 2026-10-18.
- `S08-agent-closing.png` — the coding agent's closing message, rendered
  from `data/15-scraping/agent_run/transcript.txt` in a terminal style
  (no tool interface is shown).
- Tighter crops added 2026-10-19 in the language pass, cut from the
  captures above: `S01-calendar-2025-jan-mar.png` (the 2025 panel's first
  two rows), `S01-disclaimer-public-domain.png` (the Copyright/trademark
  heading and its first paragraph), `S02-statement-20220615-top.png`,
  `S04-inspector-row.png` (the calendar row in the Elements panel),
  `S08-agent-closing-crop.png` (the first and last paragraphs of the
  agent's closing message).
