# Climbing Pyramid

**Live app:** https://019e13cd-52d7-cc56-f7a7-bb07fb5f5e26.share.connect.posit.cloud

A Shiny app that visualizes your rock climbing tick history as a grade pyramid, broken down by route type and lead style.

## What it does

Load any climber's Mountain Project ticks and the app generates an interactive pyramid chart showing how many routes they've climbed at each grade. Bars are color-coded by lead style (onsight, redpoint, flash, etc.) and faceted by route type (Sport, Trad, Toprope, Aid, Ice, Boulder).

A pitch count is displayed below the chart based on the current filters. A **Map** tab shades US states by number of ticks, with the top areas in each state on hover.

## Getting your data

1. On [Mountain Project](https://www.mountainproject.com), open the climber's profile page
2. Copy the URL from the address bar (e.g. `https://www.mountainproject.com/user/123456789/your-name`) — just the number works too
3. Paste it into the app and click **Load ticks**

Ticks must be public. You can also upload a CSV exported from the Ticks page of a profile.

## Grade conversion

For 5.10 and harder, `-` grades count as "a" and `+` grades as "d" (5.11- → 5.11a, 5.11+ → 5.11d), and a grade with no letter counts as "a" (5.12 → 5.12a). Below 5.10, and for boulder and ice grades, +/- is dropped. Aid routes use their free-climbing grade when they have one.

## Filters

- **Route Type** — Sport, Trad, Toprope, Aid, Ice, Boulder
- **Year** — populated dynamically from your tick history
- **Style** — All ticks, sends only (onsight/redpoint/pinkpoint/flash), or onsight/flash only

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
