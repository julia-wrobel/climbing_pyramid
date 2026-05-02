library(tidyverse)

# Lookup table: raw Mountain Project rating -> normalized grade
grade_map <- c(
  "5.0" = "5.0", "5.1" = "5.1", "5.2" = "5.2", "5.3" = "5.3",
  "5.4" = "5.4", "5.5" = "5.5", "5.6" = "5.6",
  "5.7" = "5.7",
  "5.8" = "5.8",
  "5.9" = "5.9",
  "5.10" = "5.10b", "5.10a" = "5.10a",
  "5.10b" = "5.10b",
  "5.10c" = "5.10c",
  "5.10d" = "5.10d",
  "5.11a" = "5.11a",
  "5.11b" = "5.11b",
  "5.11c" = "5.11c",
  "5.11d" = "5.11d",
  "5.12a" = "5.12a", "5.12b" = "5.12b", "5.12c" = "5.12c",
  "5.12d" = "5.12d",
  "5.13a" = "5.13a", "5.13b" = "5.13b", "5.13c" = "5.13c", "5.13d" = "5.13d",
  "5.14a" = "5.14a"
)

grade_levels <- c(
  "5.0", "5.1", "5.2", "5.3", "5.4", "5.5", "5.6",
  "5.7", "5.8", "5.9",
  "5.10a", "5.10b", "5.10c", "5.10d",
  "5.11a", "5.11b", "5.11c", "5.11d",
  "5.12a", "5.12b", "5.12c", "5.12d",
  "5.13a", "5.13b", "5.13c", "5.13d",
  "5.14a"
)

process_ticks <- function(filepath) {
  read_csv(filepath, show_col_types = FALSE) %>%
    janitor::clean_names() %>%
    filter(route_type != "Boulder") %>%
    mutate(
      rating     = str_remove(rating, "\\s+(PG13|R)$"),
      rating     = str_remove(rating, "\\s+V\\d+$"),
      rating     = str_remove(rating, "/[bcd]$"),
      rating     = str_remove(rating, "[+-]$"),
      rating_new = factor(grade_map[rating], levels = grade_levels),
      year       = as.integer(format(date, "%Y")),
      lead_style = if_else(is.na(lead_style), "Top Rope", lead_style),
      route_type = case_when(
        str_detect(route_type, "Sport") ~ "Sport",
        route_type == "TR"              ~ "Toprope",
        TRUE                            ~ "Trad"
      )
    )
}
