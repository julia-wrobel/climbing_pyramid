# Climbing Pyramid

**Live app:** https://019e13cd-52d7-cc56-f7a7-bb07fb5f5e26.share.connect.posit.cloud

A Shiny app that visualizes your rock climbing tick history as a grade pyramid, broken down by route type and lead style.

## What it does

Upload a CSV export from Mountain Project and the app generates an interactive pyramid chart showing how many routes you've climbed at each grade. Bars are color-coded by lead style (onsight, redpoint, flash, etc.) and faceted by route type (Sport, Trad, Toprope).

A pitch count is displayed below the chart based on the current filters.

## Getting your data

1. Log in to [Mountain Project](https://www.mountainproject.com)
2. Go to your profile → Ticks
3. Export your ticks as a CSV

## Filters

- **Route Type** — Sport, Trad, Toprope
- **Year** — populated dynamically from your tick history
- **Style** — All ticks, sends only (onsight/redpoint/pinkpoint/flash), or onsight/flash only

Boulder problems are excluded automatically.

## Running locally

```r
# Install dependencies
install.packages(c("shiny", "tidyverse", "plotly", "janitor"))

# Launch the app
shiny::runApp()
```

## Files

| File | Description |
|------|-------------|
| `ui.R` | Shiny UI layout and input controls |
| `server.R` | Shiny server logic and plot rendering |
| `make_pyramid.R` | Data processing and grade normalization |
| `ticks.csv` | Sample tick data |
